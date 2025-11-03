//
// This file is part of prose-app-ios.
// Copyright (c) 2025 Prose Foundation
//

import Foundation

public struct TimeoutError: Error, Equatable {}

@discardableResult
public func withTimeout<T: Sendable>(
  duration: Duration,
  operation: @Sendable @escaping () async throws -> T,
) async rethrows -> T {
  try await withThrowingTaskGroup(of: T.self, returning: T.self) { group in
    group.addTask(operation: operation)
    group.addTask {
      try await Task.sleep(for: duration)
      throw TimeoutError()
    }
    let result = await group.nextResult().expect("No tasks in task group")
    group.cancelAll()
    return try result.get()
  }
}
