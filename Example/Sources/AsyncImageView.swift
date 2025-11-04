import SwiftUI
import SwiftUISuspense

struct AsyncImageView: View {
  static let imageDataCache = SuspenseCacheStore<URL, Data> { url in
    let (data, _) = try await URLSession.shared.data(from: url)
    return data
  }

  let url: URL
  var body: some View {
    SuspenseView {
      let data = try Self.imageDataCache.read(key: url)
      if let nsImage = NSImage(data: data) {
        Image(nsImage: nsImage)
          .resizable()
          .scaledToFit()
      }
    }
    .withProgressView {
      ProgressView()
        .progressViewStyle(.linear)
    }
  }
}
