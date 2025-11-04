import Foundation
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

  init(url: URL) async throws {
    print("fetching", url)
    self = try await JSONDecoder().decode(
      RedditListingResp.self,
      from: URLSession.shared.data(from: url).0
    )
  }
}
