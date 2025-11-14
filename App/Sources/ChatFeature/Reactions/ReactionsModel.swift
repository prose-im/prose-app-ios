//
// This file is part of prose-app-ios.
// Copyright (c) 2025 Prose Foundation
//

import struct Domain.MessageId
import ElegantEmojiPicker
import Foundation

@MainActor @Observable
final class ReactionsModel: Identifiable {
  let messageId: MessageId
  var emoji: Emoji?

  init(messageId: MessageId) {
    self.messageId = messageId
    self.emoji = self.emoji
  }
}
