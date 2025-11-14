//
// This file is part of prose-app-ios.
// Copyright (c) 2025 Prose Foundation
//

import CasePaths
import Deps
import Domain
import Foundation
import SharedUI
import SwiftUI

@MainActor @Observable
public final class ChatModel {
  @CasePathable
  enum Route {
    case emojiPicker(ReactionsModel)
  }

  @ObservationIgnored @SharedReader var account: Account

  @ObservationIgnored @Dependency(\.client) var client
  @ObservationIgnored @Dependency(\.room) var room
  @ObservationIgnored @Dependency(\.logger[category: "Chat"]) var logger

  var route: Route? {
    didSet {
      if
        let model = self.route?[case: \.emojiPicker],
        let emoji = model.emoji?.emoji
      {
        self.toggleReaction(for: model.messageId, reaction: emoji)
      }
    }
  }

  let messageInputModel: MessageInputModel

  var error: UIError?
  var messages = IdentifiedArrayOf<Message>()
  var webViewIsReady = false

  public init(account: SharedReader<Account>) {
    self._account = account
    self.messageInputModel = MessageInputModel(account: account)
  }

  func task() async {
    try? await self.loadMessages()

    for await event in self.client.events() {
      guard
        case let .roomChanged(room: room, type: roomEvent) = event,
        room.id == self.room.id
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

  func showEmojiPicker(for messageId: MessageId) {
    self.route = .emojiPicker(.init(messageId: messageId))
  }

  func toggleReaction(for messageId: MessageId, reaction emoji: Emoji) {
    Task {
      do {
        try await self.room.baseRoom.toggleReactionToMessage(messageId: messageId, emoji: emoji)
      } catch {
        self.logger.error("Failed to toggle emoji. \(error.localizedDescription)")
      }
    }
  }
}

private extension ChatModel {
  func loadMessages() async throws {
    do {
      self.error = nil

      let result = try await self.room.baseRoom.loadLatestMessages()
      self.logger.info("Loaded \(result.messages.count) messages.")

      self.messages = .init(uniqueElements: result.messages.map {
        Message(sdkMessage: $0)
      })
    } catch {
      self.error = UIError(title: "Failed to load messages", error: error)
    }
  }

  func handleRoomEvent(_ event: ClientRoomEventType) async throws {
    let room = self.room.baseRoom

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
