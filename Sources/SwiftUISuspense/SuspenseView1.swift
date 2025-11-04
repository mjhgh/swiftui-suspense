import SwiftUI

public struct SuspenseViewWithConfig<CONTENT: View, PROGRESS: View, ERROR: View>: View {
  enum ViewResult {
    case notYetResolved
    case success(CONTENT)
    case failure(Error)
  }
  let content: () throws -> CONTENT
  let progressViewBuilder: () -> PROGRESS
  let errorViewBuilder: (Error) -> ERROR
  init(
    @ViewBuilder content: @escaping () throws -> CONTENT,
    @ViewBuilder progressViewBuilder: @escaping () -> PROGRESS,
    @ViewBuilder errorViewBuilder: @escaping (Error) -> ERROR
  ) {
    self.content = content
    self.progressViewBuilder = progressViewBuilder
    self.errorViewBuilder = errorViewBuilder
  }

  public func withProgressView<NEW_PROGRESS: View>(@ViewBuilder builder: @escaping () -> NEW_PROGRESS)
    -> SuspenseViewWithConfig<CONTENT, NEW_PROGRESS, ERROR>
  {
    SuspenseViewWithConfig<CONTENT, NEW_PROGRESS, ERROR>(
      content: content,
      progressViewBuilder: builder,
      errorViewBuilder: errorViewBuilder
    )
  }

  public func withErrorView<NEW_ERROR: View>(@ViewBuilder builder: @escaping (Error) -> NEW_ERROR)
    -> SuspenseViewWithConfig<CONTENT, PROGRESS, NEW_ERROR>
  {
    SuspenseViewWithConfig<CONTENT, PROGRESS, NEW_ERROR>(
      content: content,
      progressViewBuilder: progressViewBuilder,
      errorViewBuilder: builder
    )
  }

  // This is necessary becuase SwiftUI View body cannot throw,
  func getActualContent() -> ViewResult {
    do {
      let c = try content()
      return .success(c)
    } catch _ as NotYetResolvedError {
      return .notYetResolved
    } catch {
      return .failure(error)
    }
  }

  public var body: some View {

    switch getActualContent() {
    case .success(let contentView):
      contentView
    case .notYetResolved:
      progressViewBuilder()
    case .failure(let error):
      errorViewBuilder(error)
    }
  }
}

@MainActor
public func SuspenseView<CONTENT: View>(@ViewBuilder content: @escaping () throws -> CONTENT)
  -> SuspenseViewWithConfig<CONTENT, some View, some View>
{
  SuspenseViewWithConfig(
    content: content,
    progressViewBuilder: {
      ProgressView()
    },
    errorViewBuilder: { error in
      Text("Error: \(error.localizedDescription)")
    }
  )
}
