//
// This file is part of prose-app-ios.
// Copyright (c) 2025 Prose Foundation
//

import Foundation

public enum Iteration<T> {
  case next(T)
  case finish
}

@MainActor
public func observeUntilFinished<T: Equatable & Sendable>(
  of value: @MainActor @escaping () -> Iteration<T>,
  execute: @MainActor @escaping (T, T) -> Void,
) {
  _observeUntilFinished(of: value, execute: execute, previousValue: nil)
}

@MainActor
private func _observeUntilFinished<T: Equatable & Sendable>(
  of value: @MainActor @escaping () -> Iteration<T>,
  execute: @MainActor @escaping (T, T) -> Void,
  previousValue: T?,
) {
  var previousValue = previousValue
  var isFinished = false

  withObservationTracking {
    guard case let .next(currentValue) = value() else {
      isFinished = true
      return
    }

    defer { previousValue = currentValue }

    guard let previousValue, previousValue != currentValue else {
      return
    }

    execute(previousValue, currentValue)
  } onChange: {
    Task { @MainActor in
      if !isFinished {
        _observeUntilFinished(of: value, execute: execute, previousValue: previousValue)
      }
    }
  }
}
