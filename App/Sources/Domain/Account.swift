//
// This file is part of prose-app-ios.
// Copyright (c) 2025 Prose Foundation
//

import Foundation
import ProseSDK

public struct Account: Identifiable, Sendable {
  public var id: UserId
  public var connectionStatus: ConnectionStatus
  public var name: String
  public var avatar: URL?
  public var availability: Availability
  public var status: UserStatus?
  public var profile: UserProfile?
  public var contacts: [UserId: Contact]

  public init(
    id: UserId,
    connectionStatus: ConnectionStatus,
    name: String,
    avatar: URL?,
    availability: Availability,
    status: UserStatus?,
    profile: UserProfile? = nil,
    contacts: [UserId: Contact] = [:],
  ) {
    self.id = id
    self.connectionStatus = connectionStatus
    self.name = name
    self.avatar = avatar
    self.availability = availability
    self.status = status
    self.profile = profile
    self.contacts = contacts
  }
}

public extension Account {
  static func placeholder(for userId: UserId) -> Self {
    Account(
      id: userId,
      connectionStatus: .connecting,
      name: userId,
      avatar: nil,
      availability: .unavailable,
      status: nil,
      profile: nil,
      contacts: [:],
    )
  }
}
