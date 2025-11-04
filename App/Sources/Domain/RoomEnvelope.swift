//
// This file is part of prose-app-ios.
// Copyright (c) 2025 Prose Foundation
//

import ProseSDK

extension RoomEnvelope: @retroactive Identifiable {
  public var id: RoomId {
    switch self {
    case let .directMessage(room):
      room.id()
    case let .group(room):
      room.id()
    case let .privateChannel(room):
      room.id()
    case let .publicChannel(room):
      room.id()
    case let .generic(room):
      room.id()
    }
  }
}

// UniFFI can generate Equatable conformances but not for structs that contain objects.
// See https://github.com/mozilla/uniffi-rs/issues/2409
extension RoomEnvelope: @retroactive Equatable {
  public static func == (lhs: Self, rhs: Self) -> Bool {
    let (lBase, rBase) = (lhs.baseRoom, rhs.baseRoom)

    return
      lBase.id() == rBase.id() &&
      lBase.state() == rBase.state() &&
      lBase.name() == rBase.name() &&
      lBase.participants() == rBase.participants()
  }
}

extension RoomId: @retroactive CustomStringConvertible {
  public var description: String {
    switch self {
    case let .user(id):
      id.rawValue
    case let .muc(id):
      id.rawValue
    }
  }
}

public extension RoomEnvelope {
  var baseRoom: any RoomBaseProtocol {
    switch self {
    case let .directMessage(room): room
    case let .generic(room): room
    case let .group(room): room
    case let .privateChannel(room): room
    case let .publicChannel(room): room
    }
  }
}
