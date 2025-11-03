//
// This file is part of prose-app-ios.
// Copyright (c) 2025 Prose Foundation
//

import ChatFeature
import Deps
import Domain
import Foundation

@MainActor @Observable
public final class RoomModel {
  @ObservationIgnored @SharedReader var account: Account

  @ObservationIgnored @Dependency(\.client) var client
  @ObservationIgnored @Dependency(\.credentials) var credentials
  @ObservationIgnored @Dependency(\.room) var room
  @ObservationIgnored @Dependency(\.logger[category: "Room"]) var logger

  let chatModel: ChatModel

  var name: String = ""
  var messages = IdentifiedArrayOf<Message>()

  public init(account: SharedReader<Account>) {
    self._account = account
    self.chatModel = ChatModel(account: account)
    self.name = self.room.baseRoom.name()
  }

  func task() async {
    await self.markAsRead()

    for await event in self.client.events() {
      guard
        case let .roomChanged(room, type) = event,
        room.id == self.room.id
      else {
        continue
      }

      switch type {
      case .messagesNeedReload, .messagesDeleted, .messagesUpdated, .messagesAppended:
        await self.markAsRead()
      default:
        continue
      }
    }
  }

  func reconnect() {
    if let credentials = try? self.credentials.loadCredentials(self.account.id) {
      Task {
        try? await self.client.connect(credentials, retry: false)
      }
    }
  }
}

private extension RoomModel {
  func markAsRead() async {
    do {
      try await self.room.baseRoom.markAsRead()
    } catch {
      self.logger.error("Failed to mark room as read. \(error.localizedDescription)")
    }
  }
}
