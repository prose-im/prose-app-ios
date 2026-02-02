//
// This file is part of prose-app-ios.
// Copyright (c) 2025 Prose Foundation
//

import AvatarFeature
import Deps
import Domain
import Foundation
import OrderedCollections
import SwiftUI

@MainActor @Observable
final class InfoSectionModel: Identifiable {
  struct Identity {
    var availability: Availability
    var avatarModel: AvatarModel
    var name: String
    var role: LocalizedStringKey?
    var email: String?
    var phone: String?
  }

  struct Item: Identifiable, Equatable {
    enum Icon: Equatable {
      case systemImage(String)
      case emoji(String)
    }

    enum Title: Equatable {
      case localized(String)
      case verbatim(String)
    }

    var id: ItemOrder
    var icon: Icon
    var title: Title
  }

  enum ItemOrder: Int {
    case description
    case members
    case userId
    case email
    case phone
    case lastActivity
    case localTime
    case location
    case status
  }

  @ObservationIgnored @Dependency(\.client) var client
  @ObservationIgnored @Dependency(\.logger[category: "ChatInfo"]) var logger
  @ObservationIgnored @Dependency(\.room) var room
  @ObservationIgnored @Dependency(\.openURL) var openURL

  private(set) var identity: Identity?
  private(set) var items = IdentifiedArrayOf<Item>()

  private var loadProfileTask: Task<Void, Never>?
  private var loadMetadataTask: Task<Void, Never>?
  private var loadPresenceInfoTask: Task<Void, Never>?

  init() {
    @Dependency(\.room) var room

    if let room = room as? RoomMucClient, let topic = room.topic() {
      self.items.append(.init(
        id: .description,
        icon: .systemImage("megaphone.fill"),
        title: .verbatim(topic),
      ))
    }

    guard
      room.roomType() == .directMessage,
      let participant = room.participants().first
    else {
      return
    }

    self.identity = .init(
      availability: participant.availability,
      avatarModel: AvatarModel(participantId: participant.id, bundle: participant.avatarBundle),
      name: participant.name,
    )
  }

  func task() async {
    self.loadData()

    for await event in self.client.events() {
      guard
        case let .roomChanged(room, .attributesChanged) = event,
        room.id == self.room.id()
      else {
        continue
      }

      self.loadData()
    }
  }

  func emailActionTapped() {
    guard
      let email = self.identity?.email,
      let url = URL(string: "mailto:\(email)")
    else {
      return
    }
    Task {
      await self.openURL(url)
    }
  }

  func phoneActionTapped() {
    guard
      let phone = self.identity?.phone,
      let url = URL(string: "tel:\(phone)")
    else {
      return
    }
    Task {
      await self.openURL(url)
    }
  }
}

private extension InfoSectionModel {
  func loadData() {
    self.loadProfileTask?.cancel()
    self.loadMetadataTask?.cancel()
    self.loadPresenceInfoTask?.cancel()

    self.loadProfileTask = nil
    self.loadMetadataTask = nil
    self.loadPresenceInfoTask = nil

    let participants = self.room.participants()

    guard self.room.roomType() == .directMessage else {
      self.items.append(.init(
        id: .members,
        icon: .systemImage("person.3.sequence.fill"),
        title: .localized("\(participants.count) members"),
      ))
      return
    }

    guard let participant = participants.first else {
      self.logger.error("No participant in room.")
      return
    }

    guard let userId = participant.userId else {
      return
    }

    self.loadProfileTask = Task {
      do {
        try await self.loadProfile(for: userId)
      } catch {
        self.logger.error("Failed to load user profile. \(error.localizedDescription)")
      }
    }

    self.loadMetadataTask = Task {
      do {
        try await self.loadMetadata(for: userId)
      } catch {
        self.logger.error("Failed to load metadata. \(error.localizedDescription)")
      }
    }

    self.loadPresenceInfoTask = Task {
      do {
        try await self.loadPresenceInfo(for: userId)
      } catch {
        self.logger.error("Failed to load presence info. \(error.localizedDescription)")
      }
    }
  }

  func loadProfile(for userId: UserId) async throws {
    let profile = try await self.client.loadProfile(userId: userId)

    guard let profile else {
      self.items.append(.init(
        id: .userId,
        icon: .systemImage("bubble.fill"),
        title: .verbatim(userId.rawValue),
      ))
      self.items.sort()
      return
    }

    if let email = profile.email {
      self.items.append(.init(
        id: .email,
        icon: .systemImage("envelope.fill"),
        title: .verbatim(email),
      ))
      self.identity?.email = email
    }

    if let phone = profile.tel {
      self.items.append(.init(
        id: .phone,
        icon: .systemImage("iphone"),
        title: .verbatim(phone),
      ))
      self.identity?.phone = phone
    }

    self.identity?.role = switch (profile.title, profile.org) {
    case let (.some(title), .some(org)):
      "\(title) at \(org)"
    case let (.some(title), .none):
      LocalizedStringKey(title)
    case let (.none, .some(org)):
      LocalizedStringKey(org)
    case (.none, .none):
      nil
    }

    if let country = profile.address?.country {
      let countryCode = country.uppercased()

      let icon: Item.Icon
      let countryName: String

      if Locale.Region.isoRegions.contains(where: { $0.identifier == countryCode }) {
        icon = .emoji(countryCode.flagEmoji)
        countryName = Locale.current.localizedString(forRegionCode: countryCode) ?? country
      } else {
        icon = .systemImage("location.fill")
        countryName = country
      }

      self.items.append(.init(
        id: .location,
        icon: icon,
        title: profile.address?.locality.map { locality in
          .verbatim("\(locality), \(countryName)")
        } ?? .verbatim(countryName),
      ))
    } else if let locality = profile.address?.locality {
      self.items.append(.init(
        id: .location,
        icon: .systemImage("location.fill"),
        title: .verbatim(locality),
      ))
    }

    self.items.sort()
  }

  func loadPresenceInfo(for userId: UserId) async throws {
    let info = try await self.client.loadUserPresenceInfo(userId: userId)

    if let status = info?.status {
      self.items.append(.init(
        id: .status,
        icon: .emoji(status.emoji),
        title: status.status.map { .verbatim($0) } ?? .localized("<no status>"),
      ))
    }

    self.items.sort()
  }

  func loadMetadata(for userId: UserId) async throws {
    let metadata = try await self.client.loadUserMetadata(userId: userId)

    if let lastActivity = metadata?.lastActivity {
      let relativeTime = lastActivity.timestamp.formatted(.relative(presentation: .named))

      self.items.append(.init(
        id: .lastActivity,
        icon: .systemImage("hand.wave.fill"),
        title: .localized("Active \(relativeTime)"),
      ))
    }

    if
      let localTime = metadata?.localTime,
      let timeZone = TimeZone(secondsFromGMT: Int(localTime.timezoneOffset))
    {
      let style = Date.FormatStyle(timeZone: timeZone).hour().minute().timeZone()

      self.items.append(.init(
        id: .localTime,
        icon: .systemImage("clock.fill"),
        title: .verbatim(localTime.timestamp.formatted(style)),
      ))
    }

    self.items.sort()
  }
}

extension InfoSectionModel.Item: Comparable {
  static func < (lhs: Self, rhs: Self) -> Bool {
    lhs.id.rawValue < rhs.id.rawValue
  }
}

private extension String {
  var flagEmoji: String {
    let base: UInt32 = 127_397 // Regional indicator A minus ASCII A
    return self.uppercased().unicodeScalars.compactMap {
      UnicodeScalar(base + $0.value).map { String($0) }
    }.joined()
  }
}
