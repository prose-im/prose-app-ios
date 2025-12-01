//
// This file is part of prose-app-ios.
// Copyright (c) 2025 Prose Foundation
//

import Dependencies
import DependenciesMacros
import Domain

@DependencyClient
public struct RoomClient: Sendable {
  public var id: @Sendable () -> RoomId = { .user(.init("bot@prose.org")!) }
  public var state: @Sendable () -> RoomState = { .disconnected(error: nil, canRetry: true) }
  public var name: @Sendable () -> String = { "bot" }
  public var participants: @Sendable () -> [ParticipantInfo] = { [] }

  public var sendMessage: @Sendable (_ request: SendMessageRequest) async throws -> Void
  public var updateMessage: @Sendable (
    _ messageId: MessageId,
    _ request: SendMessageRequest,
  ) async throws -> Void
  public var retractMessage: @Sendable (_ messageId: MessageId) async throws -> Void
  public var toggleReactionToMessage: @Sendable (
    _ messageId: MessageId,
    _ emoji: Emoji,
  ) async throws -> Void

  public var loadLatestMessages: @Sendable () async throws -> MessageResultSet
  public var loadMessagesBefore: @Sendable (_ before: MessageId) async throws -> MessageResultSet
  public var loadMessagesWithIds: @Sendable (_ ids: [MessageId]) async throws -> [Message]
  public var loadUnreadMessages: @Sendable () async throws -> MessageResultSet

  public var setUserIsComposing: @Sendable (_ isComposing: Bool) async throws -> Void
  public var loadComposingUsers: @Sendable () async throws -> [ParticipantBasicInfo]

  public var saveDraft: @Sendable (_ message: String?) async throws -> Void
  public var loadDraft: @Sendable () async throws -> String?

  public var markAsRead: @Sendable () async throws -> Void
  public var setLastReadMessage: @Sendable (_ messageId: MessageId) async throws -> Void
}

public extension DependencyValues {
  var room: RoomClient {
    get { self[RoomClient.self] }
    set { self[RoomClient.self] = newValue }
  }
}

extension RoomClient: TestDependencyKey {}

extension RoomClient: DependencyKey {
  public static var liveValue: RoomClient {
    fatalError("Room dependency not set")
  }
}
