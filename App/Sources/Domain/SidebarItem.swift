//
// This file is part of prose-app-ios.
// Copyright (c) 2025 Prose Foundation
//

import Foundation
import ProseSDK

public struct SidebarItem: Equatable {
  public var name: String
  public var room: RoomEnvelope
  public var isFavorite: Bool
  public var hasDraft: Bool
  public var unreadCount: UInt32
  public var mentionsCount: UInt32
  public var avatar: URL?
}

public extension SidebarItem {
  /// Available if the underlying room is a Direct Message
  var availability: Availability? {
    switch self.room {
    case let .directMessage(room):
      room.participants().first?.availability
    default:
      nil
    }
  }

  var roomId: RoomId {
    self.room.id
  }
}

extension SidebarItem: Identifiable, Hashable {
  public var id: Int {
    self.hashValue
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(self.name)
    hasher.combine(self.availability)
    hasher.combine(self.isFavorite)
    hasher.combine(self.hasDraft)
    hasher.combine(self.unreadCount)
    hasher.combine(self.mentionsCount)
    hasher.combine(self.avatar)
  }
}

extension SidebarItem: Comparable {
  public static func < (lhs: Self, rhs: Self) -> Bool {
    lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
  }
}

public extension SidebarItem {
  init(sdkSidebarItem: ProseSDK.SidebarItem) {
    self.name = sdkSidebarItem.name
    self.room = sdkSidebarItem.room
    self.isFavorite = sdkSidebarItem.isFavorite
    self.hasDraft = sdkSidebarItem.hasDraft
    self.unreadCount = sdkSidebarItem.unreadCount
    self.mentionsCount = sdkSidebarItem.mentionsCount
    self.avatar = nil
  }
}
