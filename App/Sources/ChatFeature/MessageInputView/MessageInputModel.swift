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

  var messageText: String = "" {
    didSet {
      if self.messageText != oldValue {
        self.messageTextDidChange()
      }
    }
  }

  var canSendMessage = false

  var saveDraftTask: Task<Void, Never>?

  init() {}

  func task() async {
    if let draft = try? await self.room.baseRoom.loadDraft() {
      self.messageText = draft
    }
  }

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
  func messageTextDidChange() {
    self.canSendMessage = !self.messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

    self.saveDraftTask?.cancel()
    self.saveDraftTask = Task { [message = self.messageText] in
      do {
        try await Task.sleep(for: .milliseconds(500))
        self.logger.info("Saving draft \(message)…")
        try await self.room.baseRoom.saveDraft(message: message)
      } catch {
        if !(error is CancellationError) {
          self.logger.error("Failed to save draft. \(error.localizedDescription)")
        }
      }
    }
  }
}
