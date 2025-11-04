//
// This file is part of prose-app-ios.
// Copyright (c) 2025 Prose Foundation
//

import Foundation
import ProseSDK

public struct Message: Encodable, Identifiable, Equatable, Sendable {
  public struct Metas: Encodable, Equatable, Sendable {
    public let encrypted: Bool
    public let edited: Bool
    public let transient: Bool
    public let lastRead: Bool
  }

  public struct Formatted: Encodable, Equatable, Sendable {
    public let encoding = "html"
    public let content: String
  }

  public struct Reaction: Encodable, Equatable, Sendable {
    public let reaction: String
    public let authors: [String]
  }

  public let id: MessageId
  public let type = "text"
  public let date: String
  public let from: String
  public let content: String
  public let formatted: Formatted
  public let metas: Metas
  public let reactions: [Reaction]
}

public extension Message {
  init(sdkMessage: ProseSDK.Message) {
    self.id = sdkMessage.id
    self.date = ISO8601DateFormatter().string(from: sdkMessage.timestamp)
    self.from = sdkMessage.from.id.description
    self.content = sdkMessage.body.raw
    self.formatted = Formatted(content: sdkMessage.body.html)
    self.metas = .init(encrypted: false, edited: false, transient: false, lastRead: false)
    self.reactions = sdkMessage.reactions.map {
      .init(reaction: $0.emoji, authors: $0.from.map(\.id.description))
    }
  }
}

extension ProseSDK.ParticipantId {
  var description: String {
    switch self {
    case let .occupant(id):
      id
    case let .user(id):
      id.rawValue
    }
  }
}
