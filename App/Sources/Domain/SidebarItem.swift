//
// This file is part of prose-app-ios.
// Copyright (c) 2025 Prose Foundation
//

import Foundation
import ProseSDK

public struct SidebarItem: Equatable, Hashable {
  public enum Kind: Equatable, Hashable {
    case directMessage(
      availability: Availability,
      initials: String,
      color: HexColor,
      avatar: Avatar?,
      status: UserStatus?,
    )
    case group
    case privateChannel
    case publicChannel
    case generic
  }

  public struct User: Equatable, Hashable {
    public var availability: Availability
    public var initials: String
    public var color: HexColor
    public var avatar: Avatar?
    public var status: UserStatus?
  }

  public var name: String
  public var roomId: RoomId
  public var type: Kind
  public var roomState: RoomState
  public var isFavorite: Bool
  public var hasDraft: Bool
  public var unreadCount: UInt32
  public var mentionsCount: UInt32
}

extension SidebarItem: Identifiable {
  public var id: Int {
    self.hashValue
  }
}

extension SidebarItem: Comparable {
  public static func < (lhs: Self, rhs: Self) -> Bool {
    switch (lhs.type, rhs.type) {
    case
      (.directMessage, .group),
      (.privateChannel, .publicChannel),
      (.privateChannel, .generic),
      (.publicChannel, .generic):
      true
    case
      (.group, .directMessage),
      (.publicChannel, .privateChannel),
      (.generic, .privateChannel),
      (.generic, .publicChannel):
      false
    case (.directMessage, _), (.group, _), (.privateChannel, _), (.publicChannel, _), (.generic, _):
      lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
    }
  }
}

public extension SidebarItem {
  init(sdkSidebarItem: ProseSDK.SidebarItem) {
    self.name = sdkSidebarItem.name
    self.roomId = sdkSidebarItem.roomId
    self.type = .init(sdkType: sdkSidebarItem.type)
    self.roomState = sdkSidebarItem.roomState
    self.isFavorite = sdkSidebarItem.isFavorite
    self.hasDraft = sdkSidebarItem.hasDraft
    self.unreadCount = sdkSidebarItem.unreadCount
    self.mentionsCount = sdkSidebarItem.mentionsCount
  }
}

extension SidebarItem.Kind {
  init(sdkType: SidebarItemType) {
    switch sdkType {
    case let .directMessage(availability, initials, color, avatar, status):
      self = .directMessage(
        availability: availability,
        initials: initials,
        color: color,
        avatar: avatar,
        status: status,
      )
    case .group:
      self = .group
    case .privateChannel:
      self = .privateChannel
    case .publicChannel:
      self = .publicChannel
    case .generic:
      self = .generic
    }
  }
}
