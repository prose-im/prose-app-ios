//
// This file is part of prose-app-ios.
// Copyright (c) 2025 Prose Foundation
//

import SwiftUI

struct MessageInputView: View {
  @Bindable var model: MessageInputModel

  var body: some View {
    HStack(spacing: 12) {
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
  }
}
