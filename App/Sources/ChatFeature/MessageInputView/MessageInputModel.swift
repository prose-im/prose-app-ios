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

  let selectedItem: SidebarItem

  var messageText: String = "" { didSet { self.validate() } }
  var canSendMessage = false

  init(selectedItem: SidebarItem) {
    self.selectedItem = selectedItem
  }

  func sendMessage() {
    Task { [messageText = self.messageText] in
      do {
        try await self.selectedItem.room.baseRoom.sendMessage(request: .init(
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
