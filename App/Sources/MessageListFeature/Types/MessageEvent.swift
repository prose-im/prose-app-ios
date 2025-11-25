//
// This file is part of prose-app-ios.
// Copyright (c) 2025 Prose Foundation
//

import Domain
import Foundation

public enum MessageEvent {
  case showMenu(MessageMenuHandlerPayload)
  case toggleReaction(ToggleReactionHandlerPayload)
  case showReactions(ShowReactionsHandlerPayload)
  case reachedEndOfList(ReachedEndOfListPayload)
  case openLink(OpenLinkPayload)
  case viewFile(ViewFilePayload)
}

public struct MessageMenuHandlerPayload: Decodable {
  public let id: MessageId
  public let origin: EventOrigin
}

public struct ShowReactionsHandlerPayload: Decodable {
  public let id: MessageId
  public let origin: EventOrigin
}

public struct ToggleReactionHandlerPayload: Decodable {
  public let id: MessageId
  public let reaction: Emoji
}

public struct ReachedEndOfListPayload: Decodable {
  public enum Direction: String, Decodable {
    case forwards
    case backwards
  }

  public let direction: Direction
}

public struct OpenLinkPayload: Decodable {
  public struct Link: Equatable {
    public var url: URL
    public var scheme: String?
  }

  public let id: MessageId
  public let link: Link
}

public struct ViewFilePayload: Decodable {
  public enum FileAction: String, Decodable {
    case expand
    case download
  }

  public enum FileType: String, Decodable {
    case image
    case video
    case audio
    case other
  }

  public struct File: Decodable {
    public let type: FileType
    public let name: String?
    public let url: URL
  }

  public struct Adjacents: Decodable {
    public let before: [ViewFilePayload]
    public let after: [ViewFilePayload]
  }

  public let id: MessageId
  public let action: FileAction
  public let file: File
  public let adjacents: Adjacents?
}

extension OpenLinkPayload.Link: Decodable {
  private enum CodingKeys: String, CodingKey {
    case url
    case scheme = "protocol"
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.url = try container.decode(URL.self, forKey: .url)
    self.scheme = try container.decodeIfPresent(String.self, forKey: .scheme)
  }
}

public extension MessageEvent {
  enum Kind: String {
    case showMenu = "message:actions:view"
    case toggleReaction = "message:reactions:react"
    case showReactions = "message:reactions:view"
    case reachedEndOfList = "message:history:seek"
    case openLink = "message:link:open"
    case viewFile = "message:file:view"
  }
}
