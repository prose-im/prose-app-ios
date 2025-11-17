//
// This file is part of prose-app-ios.
// Copyright (c) 2025 Prose Foundation
//

import SwiftUI

struct EditMessageView: View {
  enum FocusField: Hashable {
    case field
  }

  @FocusState private var fieldFocussed: Bool
  @Bindable var model: EditMessageModel

  var body: some View {
    NavigationStack {
      VStack(spacing: 20) {
        TextField("Edit message…", text: self.$model.messageText, axis: .vertical)
          .multilineTextAlignment(.leading)
          .lineLimit(5...Int.max)
          .textFieldStyle(.plain)
          .focused(self.$fieldFocussed, equals: true)
          .onAppear {
            self.fieldFocussed = true
          }
          .padding()
          .background(Color(.secondarySystemBackground))
          .cornerRadius(12)

        Spacer()

        HStack {
          Spacer()

          Button("Cancel", role: .cancel) {
            self.model.cancelTapped()
          }
          .buttonStyle(.bordered)

          Button("Update") {
            self.model.updateMessageTapped()
          }
          .buttonStyle(.borderedProminent)
        }
      }
      .padding()
      .navigationBarTitle("Edit message")
      .navigationBarTitleDisplayMode(.inline)
    }
  }
}
