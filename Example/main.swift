// The Swift Programming Language
// https://docs.swift.org/swift-book
import Foundation
import SwiftUI
import SwiftUISuspense

struct RedditListingResp: Codable {
  static let cache = SuspenseCacheStore(RedditListingResp.init(url:))
  struct RespData: Codable {
    struct Child: Codable {
      struct T3: Codable, Identifiable {
        struct Preview: Codable {
          struct Image: Codable {
            struct Source: Codable {
              let url: String
              let width: Int
              let height: Int
            }
            let source: Source
          }
          let images: [Image]

        }

        let id: String
        let title: String
        let preview: Preview?
      }
      let data: T3

    }
    let children: [Child]
  }

  let data: RespData
  // let children: [Child]

  init(url: URL) async throws {
    print("fetching", url)
    self = try await JSONDecoder().decode(
      RedditListingResp.self,
      from: URLSession.shared.data(from: url).0
    )
  }
}

let imageDataCache = SuspenseCacheStore<URL, Data> { url in
  let (data, _) = try await URLSession.shared.data(from: url)
  return data
}

struct RedditListing: View {
  static func Async(url: URL) -> some View {
    SuspenseView {
      let resp = try RedditListingResp.cache.read(key: url)
      
      // The concise version
      // try RedditListing(url:url, resp: .cache.read(key: url))

      RedditListing(url: url, resp: resp) 
    }
  }
  let url: URL
  let resp: RedditListingResp

  var body: some View {
    ScrollView {
      ForEach(resp.data.children.map { $0.data }) { thread in
        Text(thread.title)
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
    RedditListing.Async(
      url: URL(
        string: "https://old.reddit.com/r/\(subreddit)/top.json?limit=50&t=day"
      )!
    )
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
