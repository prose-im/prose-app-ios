//
// This file is part of prose-app-ios.
// Copyright (c) 2025 Prose Foundation
//

import Dependencies
import Domain
import Foundation

private struct RoomDisconnected: Error {}

public class RoomClient: @unchecked Sendable {
  private let _id: RoomId
  private let _room: (any RoomBaseProtocol)?

  init(id: RoomId, room: (any RoomBaseProtocol)?) {
    self._id = id
    self._room = room
  }

  private func room() throws -> any RoomBaseProtocol {
    guard let _room else {
      throw RoomDisconnected()
    }
    return _room
  }

  public func id() -> RoomId {
    self._id
  }

  public func roomType() -> RoomType {
    .generic
  }

  public func state() -> RoomState {
    self._room?.state() ?? .disconnected(error: nil, canRetry: true)
  }

  public func name() -> String {
    self._room?.name() ?? self._id.description
  }

  public func description() -> String? {
    self._room?.description()
  }

  public func participants() -> [ParticipantInfo] {
    self._room?.participants() ?? []
  }

  public func sendMessage(request: SendMessageRequest) async throws {
    try await self.room().sendMessage(request: request)
  }

  public func updateMessage(
    messageId: MessageId,
    request: SendMessageRequest,
  ) async throws {
    try await self.room().updateMessage(messageId: messageId, request: request)
  }

  public func retractMessage(messageId: MessageId) async throws {
    try await self.room().retractMessage(messageId: messageId)
  }

  public func toggleReactionToMessage(
    messageId: MessageId,
    emoji: Emoji,
  ) async throws {
    try await self.room().toggleReactionToMessage(messageId: messageId, emoji: emoji)
  }

  public func loadLatestMessages() async throws -> MessageResultSet {
    try await self.room().loadLatestMessages()
  }

  public func loadMessagesBefore(
    before messageId: MessageId,
  ) async throws -> MessageResultSet {
    try await self.room().loadMessagesBefore(before: messageId)
  }

  public func loadMessagesWithIds(ids: [MessageId]) async throws -> [Message] {
    try await self.room().loadMessagesWithIds(ids: ids).map(Message.init(sdkMessage:))
  }

  public func loadUnreadMessages() async throws -> MessageResultSet {
    try await self.room().loadUnreadMessages()
  }

  public func setUserIsComposing(isComposing: Bool) async throws {
    try await self.room().setUserIsComposing(isComposing: isComposing)
  }

  public func loadComposingUsers() async throws -> [ParticipantBasicInfo] {
    try await self.room().loadComposingUsers()
  }

  public func saveDraft(message: String?) async throws {
    try await self.room().saveDraft(message: message)
  }

  public func loadDraft() async throws -> String? {
    try await self.room().loadDraft()
  }

  public func markAsRead() async throws {
    try await self.room().markAsRead()
  }

  public func setLastReadMessage(messageId: MessageId) async throws {
    try await self.room().setLastReadMessage(messageId: messageId)
  }
}

public extension RoomClient {
  static func live(id: RoomId, room: RoomEnvelope?) -> RoomClient {
    switch room {
    case .none:
      RoomClient(id: id, room: nil)
    case let .directMessage(room):
      RoomDirectMessageClient(id: id, room: room)
    case let .group(room):
      RoomGroupClient(id: id, room: room)
    case let .privateChannel(room):
      RoomPrivateChannelClient(id: id, room: room)
    case let .publicChannel(room):
      RoomPublicChannelClient(id: id, room: room)
    case let .generic(room):
      RoomGenericClient(id: id, room: room)
    }
  }
}

public final class RoomDirectMessageClient: RoomClient, @unchecked Sendable {
  private let _directMessage: RoomDirectMessage?

  init(id: RoomId, room: RoomDirectMessage?) {
    self._directMessage = room
    super.init(id: id, room: room)
  }

  override public func roomType() -> RoomType {
    .directMessage
  }
}

public class RoomMucClient: RoomClient, @unchecked Sendable, MucRoomProtocol {
  private let _room: (any MucRoomProtocol)?

  private func room() throws -> any MucRoomProtocol {
    guard let _room else {
      throw RoomDisconnected()
    }
    return _room
  }

  init(id: RoomId, room: (any MucRoomProtocol & RoomBaseProtocol)?) {
    self._room = room
    super.init(id: id, room: room)
  }

  public func topic() -> String? {
    self._room?.topic()
  }

  public func setTopic(topic: String?) async throws {
    try await self.room().setTopic(topic: topic)
  }
}

public final class RoomGroupClient: RoomMucClient, @unchecked Sendable {
  private let _group: RoomGroup?

  init(id: RoomId, room: RoomGroup?) {
    self._group = room
    super.init(id: id, room: room)
  }

  override public func roomType() -> RoomType {
    .group
  }
}

public class RoomMutableNameClient: RoomMucClient, @unchecked Sendable, HasMutableNameProtocol {
  private let _room: (any HasMutableNameProtocol)?

  private func room() throws -> any HasMutableNameProtocol {
    guard let _room else {
      throw RoomDisconnected()
    }
    return _room
  }

  init(id: RoomId, room: (any MucRoomProtocol & HasMutableNameProtocol & RoomBaseProtocol)?) {
    self._room = room
    super.init(id: id, room: room)
  }

  public func setName(name: String) async throws {
    try await self.room().setName(name: name)
  }
}

public final class RoomGenericClient: RoomMutableNameClient, @unchecked Sendable {
  private let _generic: RoomGeneric?

  init(id: RoomId, room: RoomGeneric?) {
    self._generic = room
    super.init(id: id, room: room)
  }
}

public class RoomChannelClient: RoomMutableNameClient, @unchecked Sendable, ChannelProtocol {
  private let _room: (any ChannelProtocol)?

  private func room() throws -> any ChannelProtocol {
    guard let _room else {
      throw RoomDisconnected()
    }
    return _room
  }

  init(
    id: RoomId,
    room: (any MucRoomProtocol & HasMutableNameProtocol & ChannelProtocol & RoomBaseProtocol)?,
  ) {
    self._room = room
    super.init(id: id, room: room)
  }

  public func inviteUsers(users: [UserId]) async throws {
    try await self.room().inviteUsers(users: users)
  }
}

public final class RoomPrivateChannelClient: RoomChannelClient, @unchecked Sendable {
  private let _privateChannel: RoomPrivateChannel?

  init(id: RoomId, room: RoomPrivateChannel?) {
    self._privateChannel = room
    super.init(id: id, room: room)
  }

  override public func roomType() -> RoomType {
    .privateChannel
  }
}

public final class RoomPublicChannelClient: RoomChannelClient, @unchecked Sendable {
  private let _publicChannel: RoomPublicChannel?

  init(id: RoomId, room: RoomPublicChannel?) {
    self._publicChannel = room
    super.init(id: id, room: room)
  }

  override public func roomType() -> RoomType {
    .publicChannel
  }
}
