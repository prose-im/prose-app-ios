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
  @ObservationIgnored @SharedReader var sessionState: SessionState
  @ObservationIgnored @Dependency(\.client) var client
  @ObservationIgnored @Dependency(\.room) var room
  @ObservationIgnored @Dependency(\.logger[category: "Room"]) var logger

  let chatModel: ChatModel

  var name: String = ""
  var messages = IdentifiedArrayOf<Message>()

  public init(sessionState: SharedReader<SessionState>) {
    self._sessionState = sessionState
    self.chatModel = ChatModel(sessionState: sessionState)
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
