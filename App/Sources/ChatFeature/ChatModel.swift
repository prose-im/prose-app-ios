//
// This file is part of prose-app-ios.
// Copyright (c) 2025 Prose Foundation
//

import Deps
import Domain
import Foundation
import SharedUI

@MainActor @Observable
public final class ChatModel {
  @ObservationIgnored @SharedReader var sessionState: SessionState

  @ObservationIgnored @Dependency(\.client) var client
  @ObservationIgnored @Dependency(\.logger[category: "Chat"]) var logger

  let selectedItem: SidebarItem
  let messageInputModel: MessageInputModel

  var error: UIError?
  var messages = IdentifiedArrayOf<Message>()
  var webViewIsReady = false

  public init(sessionState: SharedReader<SessionState>, selectedItem: SidebarItem) {
    self._sessionState = sessionState
    self.selectedItem = selectedItem
    self.messageInputModel = MessageInputModel(selectedItem: selectedItem)
  }

  func task() async {
    try? await self.loadMessages()

    for await event in self.client.events() {
      guard
        case let .roomChanged(room: room, type: roomEvent) = event,
        room.id == self.selectedItem.id
      else {
        continue
      }

      do {
        try await self.handleRoomEvent(roomEvent)
      } catch {
        self.logger.error("Failed to handle room event. Reason: \(error.localizedDescription)")
      }
    }
  }
}

private extension ChatModel {
  func loadMessages() async throws {
    do {
      self.error = nil

      let result = try await self.selectedItem.room.baseRoom.loadLatestMessages()
      self.logger.info("Loaded \(result.messages.count) messages.")

      self.messages = .init(uniqueElements: result.messages.map {
        Message(sdkMessage: $0)
      })
    } catch {
      self.error = UIError(title: "Failed to load messages", error: error)
    }
  }

  func handleRoomEvent(_ event: ClientRoomEventType) async throws {
    let room = self.selectedItem.room.baseRoom

    switch event {
    case let .messagesAppended(messageIds), let .messagesUpdated(messageIds):
      let messages = try await room.loadMessagesWithIds(ids: messageIds)
      for message in messages {
        self.messages.updateOrAppend(Message(sdkMessage: message))
      }

    case let .messagesDeleted(messageIds):
      for id in messageIds {
        self.messages.remove(id: id)
      }

    case .messagesNeedReload:
      break

    default:
      break
    }
  }
}
