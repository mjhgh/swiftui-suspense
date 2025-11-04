// The Swift Programming Language
// https://docs.swift.org/swift-book
import Foundation
import SwiftUI
import SwiftUISuspense

struct RedditListingView: View {
  static func Async(url: URL) -> some View {
    SuspenseView {
      let resp = try RedditListingResponse.cache.read(key: url)
      RedditListingView(url: url, resp: resp)
    }

    .withProgressView {
      ProgressView("LOADING!!")
        .progressViewStyle(.circular)
        .border(.blue)
    }
    .withErrorView { err in
      Text("Error: \(err)")
    }
  }
  let url: URL
  let resp: RedditListingResponse

  var body: some View {
    ScrollView {
      ForEach(resp.data.children.map { $0.data }) { thread in
        HStack {
          if let image = thread.preview?.images.first {
            AsyncImageView(url: URL(string: image.source.url.replacing("&amp;", with: "&"))!)
              .frame(width: 300, height: 300)
          } else {
            Rectangle()
              .fill(.gray)
              .frame(width: 300, height: 300)
          }
          Divider()
          Text(thread.title)
            .font(.system(size: 50))
          Spacer()
        }
        .border(.blue)
      }
    }
  }
}

struct ContentView: View {
  @State
  var subreddit = "swift"
  @State
  var inputText: String = "swift"

  var body: some View {
    AsyncImageView(url: URL(string: "https://apple.com/favicon.ico")!)

    RedditListingView.Async(
      url: URL(string: "https://old.reddit.com/r/\(subreddit)/hot.json")!
    )

    .toolbar {
      ToolbarItem(placement: .primaryAction) {
        HStack {
          TextField(
            "subreddit", text: $inputText,
            onCommit: {
              subreddit = inputText
            })

          Button("remove all caches") {
            Task {
              RedditListingResponse.cache.cacheDict = [:]
              AsyncImageView.imageDataCache.cacheDict = [:]
            }
          }
        }
      }
      ToolbarItem(placement: .status) {
        HStack {
          Text("/r/\(subreddit)")
          Divider()
          Text("ImageCache count=\(AsyncImageView.imageDataCache.cacheDict.count)")
          Divider()
          Text("RedditListingResponse.cache count=\(RedditListingResponse.cache.cacheDict.count)")
          Divider()
        }
      }

    }

  }
}

struct ExampleApp: App {
  var body: some Scene {
    Window("", id: "") {
      ContentView()
    }
  }
}
Task {
  NSApplication.shared.setActivationPolicy(.regular)
  NSApplication.shared.activate()
}
ExampleApp.main()
