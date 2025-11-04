// The Swift Programming Language
// https://docs.swift.org/swift-book
import Foundation
import SwiftUI
import SwiftUISuspense

struct RedditListingView: View {
  static func Async(url: URL) -> some View {
    SuspenseView {
      let resp = try RedditListingResp.cache.read(key: url)
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
  let resp: RedditListingResp

  var body: some View {
    ScrollView {
      ForEach(resp.data.children.map { $0.data }) { thread in
        HStack {
          if let image = thread.preview?.images.first {
            AsyncImageView(url: URL(string: image.source.url.replacing("&amp;", with: "&"))!)
              .frame(width: 500, height: 500)
          }
          Text(thread.title)
            .font(.system(size: 50))
          Spacer()
        }
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

    RedditListingView.Async(
      url: URL(string: "https://old.reddit.com/r/\(subreddit)/hot.json")!
    )
    .toolbar {
      TextField(
        "subreddit", text: $inputText,
        onCommit: {
          subreddit = inputText
        })
      Button("refresh") {
        Task {
          RedditListingResp.cache.cacheDict = [:]
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
