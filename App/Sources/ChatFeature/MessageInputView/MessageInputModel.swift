//
// This file is part of prose-app-ios.
// Copyright (c) 2025 Prose Foundation
//

import Deps
import Domain
import Foundation

@MainActor @Observable
public final class MessageInputModel {
  @ObservationIgnored @Dependency(\.logger[category: "Chat"]) var logger
  @ObservationIgnored @Dependency(\.room) var room

  var messageText: String = "" { didSet { self.validate() } }
  var canSendMessage = false

  init() {}

  func sendMessage() {
    Task { [messageText = self.messageText] in
      do {
        try await self.room.baseRoom.sendMessage(request: .init(
          body: .init(text: messageText),
          attachments: [],
        ))
      } catch {
        self.logger.error("Failed to send message. Reason: \(error.localizedDescription)")
      }
    }

    self.messageText = ""
  }
}

private extension MessageInputModel {
  func validate() {
    self.canSendMessage = !self.messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }
}
