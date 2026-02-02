//
// This file is part of prose-app-ios.
// Copyright (c) 2025 Prose Foundation
//

import Dependencies
import DependenciesMacros
import Domain

private enum RoomClientKey: DependencyKey {
  static var liveValue: RoomClient { fatalError("Room live dependency not set") }
  static var testValue: RoomClient { fatalError("Room test dependency not set") }
}

public extension DependencyValues {
  var room: RoomClient {
    get { self[RoomClientKey.self] }
    set { self[RoomClientKey.self] = newValue }
  }
}
