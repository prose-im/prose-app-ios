//
// This file is part of prose-app-ios.
// Copyright (c) 2025 Prose Foundation
//

import CasePaths
import Deps
import Domain
import Foundation
import MessageListFeature
import SharedUI
import SwiftUI

@MainActor @Observable
public final class ChatModel {
  @CasePathable
  enum Route {
    case messageMenu(MessageMenuModel)
    case emojiPicker(ReactionsModel)
    case deleteMessageConfirmation(MessageId)
    case editMessage(EditMessageModel)
    case safariView(URL)
    case filePreview(FilePreviewModel)
  }

  @ObservationIgnored @SharedReader var account: Account
  @ObservationIgnored @Shared var messages: IdentifiedArrayOf<Message>

  @ObservationIgnored @Dependency(\.client) var client
  @ObservationIgnored @Dependency(\.room) var room
  @ObservationIgnored @Dependency(\.logger[category: "Chat"]) var logger
  @ObservationIgnored @Dependency(\.pasteboard) var pasteboard

  var route: Route?

  let messageListModel: MessageListModel
  let messageInputModel: MessageInputModel
  let fileUploadModel: FileUploadModel

  var error: UIError?

  public init(account: SharedReader<Account>) {
    let messages = Shared(value: IdentifiedArrayOf<Message>())

    self._account = account
    self._messages = messages

    self.messageListModel = MessageListModel(messages: SharedReader(messages))
    self.messageInputModel = MessageInputModel(account: account)
    self.fileUploadModel = FileUploadModel()
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

  func showMessageMenu(for messageId: MessageId) {
    guard let message = self.messages[id: messageId] else {
      self.logger.error("Could not present menu for \(messageId). Message is missing.")
      return
    }

    self.route = .messageMenu(.init(messageId: messageId) { action in
      self.route = nil

      switch action {
      case let .addEmoji(emoji):
        self.toggleReaction(for: messageId, reaction: emoji)

      case .showEmojis:
        self.showEmojiPicker(for: messageId)

      case .editMessage:
        let model = EditMessageModel(
          messageId: messageId,
          body: message.content,
          attachments: message.attachments,
        ) { action in
          self.route = nil

          switch action {
          case let .updateMessage(text, attachments):
            self.updateMessage(id: messageId, body: text, attachments: attachments)

          case .cancel:
            break
          }
        }

        self.route = .editMessage(model)

      case .copyMessage:
        self.pasteboard.copyString(message.content)

      case .deleteMessage:
        self.route = .deleteMessageConfirmation(messageId)
      }
    })
  }

  func showEmojiPicker(for messageId: MessageId) {
    self.route = .emojiPicker(.init(messageId: messageId) { emoji in
      self.toggleReaction(for: messageId, reaction: emoji)
    })
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

  func messageDeletionConfirmed(messageId: MessageId) {
    self.route = nil

    Task { [room = self.room, logger = self.logger] in
      do {
        try await room.baseRoom.retractMessage(messageId: messageId)
      } catch {
        logger.error("Failed to retract message. \(error.localizedDescription)")
      }
    }
  }

  func messageDeletionCancelled() {
    self.route = nil
  }

  func updateMessage(id: MessageId, body: String, attachments: [Attachment]) {
    Task {
      do {
        try await self.room.baseRoom.updateMessage(
          messageId: id,
          request: .init(body: .init(text: body), attachments: attachments),
        )
      } catch {
        self.logger.error("Failed to update message. \(error.localizedDescription)")
      }
    }
  }

  func openURL(url: URL) {
    self.route = .safariView(url)
  }

  func previewFile(messageId: MessageId, url: URL) {
    let mimeType = self.messages[id: messageId]?
      .attachments
      .first { $0.url == url }
      .map(\.mediaType)

    let model = withDependencies(from: self) {
      FilePreviewModel(
        url: url,
        mimeType: mimeType,
        roomId: self.room.id,
      ) {
        self.route = nil
      }
    }

    self.route = .filePreview(model)
  }
}

private extension ChatModel {
  func loadMessages() async throws {
    do {
      self.error = nil

      let result = try await self.room.baseRoom.loadLatestMessages()
      self.logger.info("Loaded \(result.messages.count) messages.")

      self.$messages.withLock {
        $0 = .init(uniqueElements: result.messages.map {
          Message(sdkMessage: $0)
        })
      }
    } catch {
      self.error = UIError(title: "Failed to load messages", error: error)
    }
  }

  func handleRoomEvent(_ event: ClientRoomEventType) async throws {
    let room = self.room.baseRoom

    switch event {
    case let .messagesAppended(messageIds), let .messagesUpdated(messageIds):
      let newOrUpdatedMessages = try await room.loadMessagesWithIds(ids: messageIds)
      self.$messages.withLock { messages in
        for message in newOrUpdatedMessages {
          messages.updateOrAppend(Message(sdkMessage: message))
        }
      }

    case let .messagesDeleted(messageIds):
      self.$messages.withLock { messages in
        for id in messageIds {
          messages.remove(id: id)
        }
      }

    case .messagesNeedReload:
      break

    default:
      break
    }
  }
}
