//
// This file is part of prose-app-ios.
// Copyright (c) 2025 Prose Foundation
//

import SharedUI
import SwiftUI

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
          .task { await self.model.task() }
          .ignoresSafeArea()
      }

      MessageInputView(model: self.model.messageInputModel)
        .fixedSize(horizontal: false, vertical: true)
    }
  }
}
