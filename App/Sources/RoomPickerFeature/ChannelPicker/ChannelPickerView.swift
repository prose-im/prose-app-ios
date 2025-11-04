//
// This file is part of prose-app-ios.
// Copyright (c) 2025 Prose Foundation
//

import SharedUI
import SwiftUI

public struct ChannelPickerView: View {
  @Bindable var model: ChannelPickerModel
  @Environment(\.dismiss) var dismiss

  let onSubmit: (ChannelPickerModel.Action) -> Void

  public init(model: ChannelPickerModel, onSubmit: @escaping (ChannelPickerModel.Action) -> Void) {
    self.model = model
    self.onSubmit = onSubmit
  }

  public var body: some View {
    NavigationStack {
      VStack(spacing: 0) {
        TextField("Enter channel name or address", text: self.$model.text)
          .keyboardType(.emailAddress)
          .autocorrectionDisabled(true)
          .textInputAutocapitalization(.never)
          .textFieldStyle(.plain)
          .padding()
          .background(Color(.systemBackground))

        if self.model.action.isCreateAction {
          HStack {
            Spacer()
            Toggle("Create private channel", isOn: self.$model.createPrivateChannel)
          }
          .padding()
          .background(Color(.secondarySystemBackground))
          .zIndex(-1)
          .transition(.move(edge: .top))
        }

        Divider()

        List(self.model.channels, selection: self.$model.selectedRoom) { channel in
          HStack {
            Image(systemName: "circle.grid.2x2")
              .foregroundStyle(.blue)
              .frame(width: 24, height: 24)

            Text(verbatim: channel.name ?? "<untitled>")
          }
        }
      }
      .listStyle(.plain)
      .navigationTitle("Join or create Channel")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          ToolbarButton.cancel {
            self.dismiss()
          }
        }

        ToolbarItem(placement: .topBarTrailing) {
          Button(self.model.action.isCreateAction ? "Create room" : "Join room") {
            self.dismiss()
            self.onSubmit(self.model.action)
          }
          .disabled(!self.model.isFormValid)
        }
      }
      .onChange(of: self.model.selectedRoom) { _, roomId in
        guard let roomId else {
          return
        }
        self.dismiss()
        self.onSubmit(.join(roomId))
      }
    }
    .task {
      await self.model.task()
    }
  }
}
