//
// This file is part of prose-app-ios.
// Copyright (c) 2025 Prose Foundation
//

import Domain
import Foundation
import IdentifiedCollections

public struct MessagingStore {
  public let insertMessages: JSRestFunc1<[Message], Void>
  public let retractMessage: JSFunc1<MessageId, Void>
  public let highlightMessage: JSFunc1<MessageId?, Void>
  public let interact: JSFunc3<MessageId, MessageAction, Bool, Void>
//  public let identify: JSFunc2<BareJid, UserInfo, Void>

  private let update: JSFunc2<MessageId, Message, Void>

  init(evaluator: @escaping JSEvaluator) {
    let cls = JSClass(name: "MessagingStore", evaluator: evaluator)
    self.insertMessages = cls.insert
    self.update = cls.update
    self.retractMessage = cls.retract
    self.highlightMessage = cls.highlight
//    self.identify = cls.identify
    self.interact = cls.interact
  }

  public func updateMessages(
    to messages: [Message],
    oldMessages: inout IdentifiedArrayOf<Message>,
  ) {
    let messages = IdentifiedArrayOf<Message>(uniqueElements: messages)
    defer { oldMessages = messages }

    let diff = messages.difference(from: oldMessages)

    for messageId in diff.removedIds {
      self.retractMessage(messageId)
    }
    for messageId in diff.updatedIds {
      if let message = messages[id: messageId] {
        self.updateMessage(message)
      }
    }
    self.insertMessages(diff.insertedIds.compactMap { messages[id: $0] })
  }

  public func updateMessage(_ message: Message) {
    self.update(message.id, message)
  }
}
