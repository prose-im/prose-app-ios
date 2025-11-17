//
// This file is part of prose-app-ios.
// Copyright (c) 2025 Prose Foundation
//

import SwiftUI

struct MessageMenu: View {
  @Bindable var model: MessageMenuModel

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      self.emojiBar

      self.menuItem(icon: "bubble.and.pencil", title: "Edit Message", action: .editMessage)
      self.menuItem(icon: "document.on.document", title: "Copy Message", action: .copyMessage)
      Divider()
      self.menuItem(
        icon: "trash",
        title: "Delete Message",
        isDestructive: true,
        action: .deleteMessage,
      )
    }
  }

  var emojiBar: some View {
    HStack(spacing: 0) {
      ForEach(["👍", "😬", "😊", "🙌", "✅", "😍"], id: \.self) { emoji in
        Button(action: { self.model.actionSelected(.addEmoji(emoji)) }) {
          Text(emoji)
            .padding(2)
            .fixedSize()
        }
        Spacer(minLength: 0)
      }

      Button(action: { self.model.actionSelected(.showEmojis) }) {
        Image("custom.face.smiling.badge.plus", bundle: .module)
          .padding(2)
          .fixedSize()
      }
    }
    .buttonStyle(.bordered)
    .buttonBorderShape(.circle)
    .padding([.top, .leading, .trailing])
    .padding(.bottom, 8)
  }

  func menuItem(
    icon: String,
    title: LocalizedStringKey,
    isDestructive: Bool = false,
    action: MessageMenuModel.Action,
  ) -> some View {
    Button(action: { self.model.actionSelected(action) }) {
      Label(title, systemImage: icon)
        .foregroundColor(isDestructive ? .red : .primary)
        .padding(.vertical, 14)
        .padding(.horizontal)
        .contentShape(Rectangle())
        .frame(maxWidth: .infinity, alignment: .leading)
    }
  }
}
