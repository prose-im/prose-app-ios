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

extension RoomEnvelope: @retroactive Equatable {
  public static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.id == rhs.id
  }
}

extension RoomId: @retroactive CustomStringConvertible {
  public var description: String {
    switch self {
    case let .user(id):
      id
    case let .muc(id):
      id
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
