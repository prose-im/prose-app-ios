//
// This file is part of prose-app-ios.
// Copyright (c) 2025 Prose Foundation
//

import Dependencies
import DependenciesMacros

@DependencyClient
public struct Pasteboard: Sendable {
  public var copyString: @Sendable (String) -> Void
}

public extension DependencyValues {
  var pasteboard: Pasteboard {
    get { self[Pasteboard.self] }
    set { self[Pasteboard.self] = newValue }
  }
}

extension Pasteboard: TestDependencyKey {
  public static let testValue = Self()
}
