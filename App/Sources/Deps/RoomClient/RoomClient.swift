//
// This file is part of prose-app-ios.
// Copyright (c) 2025 Prose Foundation
//

import Dependencies
import Domain

public extension DependencyValues {
  var room: RoomEnvelope {
    get { self[RoomEnvelope.self] }
    set { self[RoomEnvelope.self] = newValue }
  }
}

extension RoomEnvelope: @retroactive TestDependencyKey {}

extension RoomEnvelope: @retroactive DependencyKey {
  public static var liveValue: RoomEnvelope {
    fatalError("Room dependency not set")
  }
}
