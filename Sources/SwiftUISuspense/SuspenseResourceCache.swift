import SwiftUI

@Observable
final public class SuspenseResourceCache<K: Hashable, V: Sendable>: Sendable {
  public enum Outcome {
    case progress(Task<Void, Never>)
    case resolved(Result<V, Error>)
  }
  // it's public for now, since manipulating cache is something people will do.
  @MainActor
  public var cacheDict: [K: Outcome] = [:]
  @MainActor
  public let execute: @Sendable (K) async throws -> V

  public init(_ execute: @escaping @Sendable (K) async throws -> V) {
    self.execute = execute
  }

  /// You would use this if you do not want to block, `try read(key:)` will block all further progress`
  @MainActor
  public func fill(key: K) {
    guard cacheDict[key] == nil else { return }

    let task: Task<Void, Never> = Task {
      do {
        let value = try await execute(key)
        if Task.isCancelled { return }
        cacheDict[key] = .resolved(.success(value))
      } catch {
        cacheDict[key] = .resolved(.failure(error))
      }
    }
    cacheDict[key] = .progress(task)

  }
  @MainActor
  public func read(key: K) throws -> V {
    fill(key: key)
    switch cacheDict[key] {
    case .resolved(let result):
      return try result.get()
    case .progress(_):
      throw NotYetResolvedError()
    case .none:
      fatalError("Unreachable state")
    }
  }
  
  @MainActor
  public func set(key: K, value: V) {
    cacheDict[key] = .resolved(.success(value))
  }
}
