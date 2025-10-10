//
// This file is part of prose-app-ios.
// Copyright (c) 2025 Prose Foundation
//

import Foundation

public enum JSEventError: Error, Equatable {
  case badSerialization, decodingError(String)
}

extension JSEventError: CustomDebugStringConvertible {
  public var debugDescription: String {
    switch self {
    case .badSerialization:
      "JS message body should be serialized as a String"
    case let .decodingError(debugDescription):
      debugDescription
    }
  }
}
