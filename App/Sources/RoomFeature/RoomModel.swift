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
  @ObservationIgnored @Dependency(\.client) var client: ProseCoreClient
  @ObservationIgnored @Dependency(\.logger[category: "Room"]) var logger

  let selectedItem: SidebarItem
  let chatModel: ChatModel

  var messages = IdentifiedArrayOf<Message>()

  public init(sessionState: SharedReader<SessionState>, selectedItem: SidebarItem) {
    self._sessionState = sessionState
    self.selectedItem = selectedItem
    self.chatModel = ChatModel(sessionState: sessionState, selectedItem: selectedItem)
  }

  func task() async {
    await self.markAsRead()

    for await event in self.client.events() {
      guard
        case let .roomChanged(room, type) = event,
        room.id == selectedItem.roomId
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
      try await self.selectedItem.room.baseRoom.markAsRead()
    } catch {
      self.logger.error("Failed to mark room as read. \(error.localizedDescription)")
    }
  }
}
