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
  let emojiSelected: (String) -> Void

  var emoji: Emoji? {
    didSet {
      if let emoji {
        self.emojiSelected(emoji.emoji)
      }
    }
  }

  init(messageId: MessageId, emojiSelected: @escaping (String) -> Void) {
    self.messageId = messageId
    self.emojiSelected = emojiSelected
  }
}
