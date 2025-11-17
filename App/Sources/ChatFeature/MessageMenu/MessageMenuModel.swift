//
// This file is part of prose-app-ios.
// Copyright (c) 2025 Prose Foundation
//

import Domain
import Foundation

@MainActor @Observable
final class MessageMenuModel: Identifiable {
  enum Action {
    case addEmoji(String)
    case showEmojis
    case editMessage
    case copyMessage
    case deleteMessage
  }

  let messageId: MessageId
  let handleAction: (Action) -> Void

  init(messageId: MessageId, handleAction: @escaping (Action) -> Void) {
    self.messageId = messageId
    self.handleAction = handleAction
  }

  func actionSelected(_ action: Action) {
    self.handleAction(action)
  }
}
