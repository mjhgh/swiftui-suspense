import SwiftUI
import SwiftUISuspense

struct AsyncImageView: View {
  // [1] define a SuspenseResourceCache
  static let imageDataCache: SuspenseResourceCache<URL, Data> = SuspenseResourceCache { url in
    // generally you would want to use a URLSession.shared, ephemeral config avoids caching to make loading more visible.
    let (data, _) = try await URLSession(configuration: .ephemeral).data(from: url)

    // This closure will run ONCE per URL, until you delete the cache URL entry.
    // meaning multiple SuspenseView reading the same URL will share the same fetch result.
    return data
  }

  let url: URL
  var body: some View {
    SuspenseView {

      // async/await is NOT available here.
      // just like React Suspense, use the .read(key:) API to read from a cache, which you may use async/await there.
      // There are a lot of pitfalls in allowing async/await in declarative UI.
      // so we will follow React Suspense's simple design here.

      // [2] use the cache to run async code, but get result synchronously,

      let imgData = try Self.imageDataCache.read(key: url)

      // the try above will throw NotYetResolvedError, if cache is not yet filled.
      // And it will reactively re-render the View when the data status is changed.
      // - NotYetResolved: halt, render ProgressView
      // - Failure: halt, render ErrorView
      // - Success: continue, render content below

      // There is nothing wrong to have non-cache `try` here, but it will be re-run on every re-render.

      // [3] ViewBuilder part with the fetched variables.
      if let nsImage = NSImage(data: imgData) {
        Image(nsImage: nsImage)
          .resizable()
          .scaledToFit()
      }
    }
    // [4] optional: configure the SuspenseView
    .withProgressView {
      // also known as placeholder in builtin AsyncImage.
      ProgressView("Loading Image (\(url))")
        .progressViewStyle(.linear)
    }
    .withErrorView { err in
      Image(systemName: "exclamationmark.triangle")
    }

    // [5] optional: unload cache on disappear to save memory
    .onDisappear {
      // There's no built-in cache eviction policy. DIY.
      Self.imageDataCache.cacheDict.removeValue(forKey: url)
    }
    // [6] optional: refresh is exactly the same as unloading cache, as long as the View is still remains in the hierarchy, it will re-fetch.
    .refreshable {
      Self.imageDataCache.cacheDict.removeValue(forKey: url)
      // This will cause ProgressView to show again, and screen may flicker.
      // If that's undesirable, do this manually.
      // Task { Self.imageDataCache.cacheDict[url] = .resolved(.success(Data())) }
    }
  }
}
