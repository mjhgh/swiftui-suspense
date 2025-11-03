import SwiftUI

public struct SuspenseView<CONTENT: View>: View {
  enum ViewResult {
    case content(CONTENT)
    case notYetResolved
    case failure(Error)
  }
  let content: () throws -> CONTENT
  public init(@ViewBuilder content: @escaping () throws -> CONTENT) {
    self.content = content
  }

  func getActualContent() -> ViewResult {
    do {
      let c = try content()
      return .content(c)
    } catch _ as NotYetResolvedError {
      return .notYetResolved
    } catch {
      return .failure(error)
    }
  }

  public var body: some View {
    switch getActualContent() {
    case .content(let c):
      c
    case .notYetResolved:
      ProgressView()
    case .failure(let error):
      Text("Error: \(error)")
        .onAppear {
          print("error:", error)
        }
    }
  }
}
