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
    .task { await self.model.task() }
  }
}
