//
// This file is part of prose-app-ios.
// Copyright (c) 2025 Prose Foundation
//

import Foundation
import ProseSDK

public struct Message: Identifiable, Equatable, Sendable {
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
  public let attachments: [Attachment]
}

public extension Message {
  init(sdkMessage: ProseSDK.Message) {
    self.id = sdkMessage.id
    self.date = ISO8601DateFormatter().string(from: sdkMessage.timestamp)
    self.from = sdkMessage.from.id.description
    // The prose-core-views chokes on an empty message body so we'll use a placeholder
    self.content = sdkMessage.body.raw.isEmpty ? "<empty>" : sdkMessage.body.raw
    self.formatted = Formatted(content: sdkMessage.body.html)
    self.metas = .init(encrypted: false, edited: false, transient: false, lastRead: false)
    self.reactions = sdkMessage.reactions.map {
      .init(reaction: $0.emoji, authors: $0.from.map(\.id.description))
    }
    self.attachments = sdkMessage.attachments
  }
}

extension Message: Encodable {
  enum CodingKeys: String, CodingKey {
    case id
    case type
    case date
    case from
    case content
    case formatted
    case metas
    case reactions
    case files
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(self.id, forKey: .id)
    try container.encode(self.type, forKey: .type)
    try container.encode(self.date, forKey: .date)
    try container.encode(self.from, forKey: .from)
    try container.encode(self.content, forKey: .content)
    try container.encode(self.formatted, forKey: .formatted)
    try container.encode(self.metas, forKey: .metas)
    try container.encode(self.reactions, forKey: .reactions)
    try container.encode(self.attachments.map(JSAttachment.init(sdkAttachment:)), forKey: .files)
  }
}

private struct JSAttachment: Encodable, Equatable, Sendable {
  struct Preview: Encodable, Equatable, Sendable {
    struct Size: Encodable, Equatable, Sendable {
      var width: UInt32
      var height: UInt32
    }

    var url: URL?
    var size: Size?
    var duration: UInt64?
  }

  var name: String
  var type: String
  var url: URL
  var preview: Preview?

  init(sdkAttachment: ProseSDK.Attachment) {
    self.name = sdkAttachment.fileName
    self.type = sdkAttachment.mediaType
    self.url = sdkAttachment.url
    self.preview = .init(sdkPreview: sdkAttachment.type)
  }
}

extension JSAttachment.Preview {
  init?(sdkPreview: ProseSDK.AttachmentType) {
    switch sdkPreview {
    case .file:
      return nil

    case let .audio(duration: duration):
      self.duration = duration

    case let .image(thumbnail):
      self.url = thumbnail?.url
      if let width = thumbnail?.width, let height = thumbnail?.height {
        self.size = .init(width: width, height: height)
      }

    case let .video(duration, thumbnail):
      self.url = thumbnail?.url
      if let width = thumbnail?.width, let height = thumbnail?.height {
        self.size = .init(width: width, height: height)
      }
      self.duration = duration
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
