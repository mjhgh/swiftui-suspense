/// An error indicating that a value has not yet been resolved, 
/// In SuspenseView, 
/// wait for the content() no longer throw this error, 
/// which implies all cache is filled, and ready to render Success/Failure view.
public struct NotYetResolvedError: Error {
}
