//
// This file is part of prose-app-ios.
// Copyright (c) 2025 Prose Foundation
//

import PhotosUI
import SwiftUI

struct MessageInputView<T: View>: View {
  @Bindable var model: MessageInputModel

  let attachmentMenu: T

  init(model: MessageInputModel, @ViewBuilder attachmentMenu: () -> T) {
    self.model = model
    self.attachmentMenu = attachmentMenu()
  }

  var body: some View {
    HStack(spacing: 12) {
      Menu {
        self.attachmentMenu
      } label: {
        Button(action: {}) {
          Image(systemName: "paperclip")
            .padding(6)
        }
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.circle)
      }

      TextField("Send a message", text: self.$model.messageText, axis: .vertical)
        .textFieldStyle(.plain)
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)

      Button(action: {
        self.model.sendMessage()
      }) {
        Image(systemName: "paperplane.fill")
          .padding(6)
      }
      .buttonStyle(.borderedProminent)
      .buttonBorderShape(.circle)
      .disabled(!self.model.canSendMessage)
    }
    .padding(.horizontal)
    .padding(.bottom, 6)
    .task {
      await self.model.task()
    }
  }
}
