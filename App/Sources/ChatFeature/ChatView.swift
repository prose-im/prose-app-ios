//
// This file is part of prose-app-ios.
// Copyright (c) 2025 Prose Foundation
//

import ElegantEmojiPicker
import SharedUI
import SwiftUI
import SwiftUINavigation

public struct ChatView: View {
  @Bindable var model: ChatModel

  public init(model: ChatModel) {
    self.model = model
  }

  public var body: some View {
    VStack {
      if let error = self.model.error {
        ErrorView(error: error)
      } else {
        MessagesView(model: self.model)
          .onShowReactions { messageId, _ in
            self.model.showEmojiPicker(for: messageId)
          }
          .onShowMessageMenu { messageId in
            self.model.showMessageMenu(for: messageId)
          }
          .onToggleEmoji { messageId, emoji in
            self.model.toggleReaction(for: messageId, reaction: emoji)
          }
          .ignoresSafeArea()
      }

      MessageInputView(model: self.model.messageInputModel)
        .fixedSize(horizontal: false, vertical: true)
    }
    .sheet(item: self.$model.route.emojiPicker) { model in
      ElegantEmojiPickerRepresentable(
        isPresented: .constant(true),
        selectedEmoji: model.emoji,
        configuration: .init(
          showRandom: false,
          showReset: false,
          showClose: false,
          supportsPreview: false,
        ),
        localization: .init(),
      )
      .presentationDetents([.medium, .large])
      .ignoresSafeArea(.container, edges: .bottom)
    }
    .sheet(item: self.$model.route.messageMenu) { model in
      MessageMenu(model: model)
        .ignoresSafeArea()
        .fittedPresentationDetent()
    }
    .alert(
      item: self.$model.route.deleteMessageConfirmation,
      title: { _ in Text("Are you sure you want to remove this message?") },
      actions: { messageId in
        Button("Remove Message", role: .destructive) {
          self.model.messageDeletionConfirmed(messageId: messageId)
        }
        Button("Cancel", role: .cancel) {
          self.model.messageDeletionCancelled()
        }
      },
      message: { _ in
        Text(
          "The message will disappear from your inbox. We will also try to remove it on your recipient end, although removal is not guaranteed.",
        )
      },
    )
    .sheet(item: self.$model.route.editMessage) { model in
      EditMessageView(model: model)
    }
    .task { await self.model.task() }
  }
}
