import Foundation
import SwiftUISuspense

struct RedditListingResponse: Codable {
  static let cache = SuspenseResourceCache(RedditListingResponse.init(url:))
  struct ResponseData: Codable {
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

  let data: ResponseData

  init(url: URL) async throws {
    print("fetching", url)
    self = try await JSONDecoder().decode(
      RedditListingResponse.self,
      from: URLSession.shared.data(from: url).0
    )
  }
}
