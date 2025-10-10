//
// This file is part of prose-app-ios.
// Copyright (c) 2025 Prose Foundation
//

import Foundation

public enum ConnectionStatus: Equatable, Sendable {
  case disconnected
  case connecting
  case connected
  case error(Error)
}

public extension ConnectionStatus {
  var isError: Bool {
    if case .error = self {
      return true
    }
    return false
  }
}

public extension ConnectionStatus {
  static func == (lhs: Self, rhs: Self) -> Bool {
    switch (lhs, rhs) {
    case (.disconnected, .disconnected):
      true
    case (.connecting, .connecting):
      true
    case (.connected, .connected):
      true
    case let (.error(lErr), .error(rErr)):
      _isEqual(lErr, rErr) == true
    case (.disconnected, _), (.connecting, _), (.connected, _), (.error, _):
      false
    }
  }
}

private func _isEqual(_ lhs: Any, _ rhs: Any) -> Bool? {
  (lhs as? any Equatable)?.isEqual(other: rhs)
}

private extension Equatable {
  func isEqual(other: Any) -> Bool {
    self == other as? Self
  }
}
