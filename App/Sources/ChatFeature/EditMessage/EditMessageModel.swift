//
// This file is part of prose-app-ios.
// Copyright (c) 2025 Prose Foundation
//

import Domain
import Foundation

@MainActor @Observable
final class EditMessageModel: Identifiable {
  enum Action {
    case cancel
    case updateMessage(text: String, attachments: [Attachment])
  }

  let messageId: MessageId
  var messageText: String
  let attachments: [Attachment]

  let handleAction: (Action) -> Void

  init(
    messageId: MessageId,
    body: String,
    attachments: [Attachment],
    handleAction: @escaping (Action) -> Void,
  ) {
    self.messageId = messageId
    self.messageText = body
    self.attachments = attachments
    self.handleAction = handleAction
  }

  func updateMessageTapped() {
    self.handleAction(.updateMessage(text: self.messageText, attachments: self.attachments))
  }

  func cancelTapped() {
    self.handleAction(.cancel)
  }
}
