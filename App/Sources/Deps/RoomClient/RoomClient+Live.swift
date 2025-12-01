//
// This file is part of prose-app-ios.
// Copyright (c) 2025 Prose Foundation
//

import Dependencies
import Domain
import Foundation

private struct RoomDisconnected: Error {}

public extension RoomClient {
  static func live(id: RoomId, room: RoomEnvelope?) -> Self {
    @Sendable func baseRoom() throws -> any RoomBaseProtocol {
      guard let room else {
        throw RoomDisconnected()
      }
      return room.baseRoom
    }

    return .init(
      id: { id },
      state: { room?.baseRoom.state() ?? .disconnected(error: nil, canRetry: true) },
      name: { room?.baseRoom.name() ?? id.description },
      participants: { room?.baseRoom.participants() ?? [] },
      sendMessage: { request in
        try await baseRoom().sendMessage(request: request)
      },
      updateMessage: { messageId, request in
        try await baseRoom().updateMessage(messageId: messageId, request: request)
      },
      retractMessage: { messageId in
        try await baseRoom().retractMessage(messageId: messageId)
      },
      toggleReactionToMessage: { messageId, emoji in
        try await baseRoom().toggleReactionToMessage(messageId: messageId, emoji: emoji)
      },
      loadLatestMessages: {
        try await baseRoom().loadLatestMessages()
      },
      loadMessagesBefore: { messageId in
        try await baseRoom().loadMessagesBefore(before: messageId)
      },
      loadMessagesWithIds: { ids in
        try await baseRoom().loadMessagesWithIds(ids: ids).map(Message.init(sdkMessage:))
      },
      loadUnreadMessages: {
        try await baseRoom().loadUnreadMessages()
      },
      setUserIsComposing: { isComposing in
        try await baseRoom().setUserIsComposing(isComposing: isComposing)
      },
      loadComposingUsers: {
        try await baseRoom().loadComposingUsers()
      },
      saveDraft: { draft in
        try await baseRoom().saveDraft(message: draft)
      },
      loadDraft: {
        try await baseRoom().loadDraft()
      },
      markAsRead: {
        try await baseRoom().markAsRead()
      },
      setLastReadMessage: { messageId in
        try await baseRoom().setLastReadMessage(messageId: messageId)
      },
    )
  }
}
