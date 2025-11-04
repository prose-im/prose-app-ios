//
// This file is part of prose-app-ios.
// Copyright (c) 2025 Prose Foundation
//

import AvatarFeature
import Domain
import SharedUI
import SwiftUI

public struct ContactPickerView: View {
  @Bindable var model: ContactPickerModel
  @Environment(\.dismiss) var dismiss

  let onSubmit: ([UserId]) -> Void

  public init(model: ContactPickerModel, onSubmit: @escaping ([UserId]) -> Void) {
    self.model = model
    self.onSubmit = onSubmit
  }

  public var body: some View {
    NavigationStack {
      VStack(spacing: 0) {
        ZStack(alignment: .topLeading) {
          TokenTextField(data: self.$model.data) { token, isSelected in
            Text(verbatim: token.rawValue)
              .padding(.vertical, 2)
              .padding(.horizontal, 6)
              .lineLimit(1)
              .foregroundStyle(isSelected ? .blue : .white)
              .background {
                RoundedRectangle(cornerRadius: 4)
                  .fill(isSelected ? .white : .blue)
                  .stroke(isSelected ? .blue : .clear, lineWidth: 1)
              }
          } createToken: { text in
            UserId(text)
          }
          .font(.preferredFont(forTextStyle: .body))
          .keyboardType(.emailAddress)
          .frame(minHeight: UIFont.preferredFont(forTextStyle: .body).lineHeight + 8)

          if self.model.data.isEmpty {
            Text("Enter contact address")
              .foregroundStyle(Color(.placeholderText))
          }
        }
        .padding()

        Divider()

        List(self.model.contacts, selection: self.$model.listSelection) { contact in
          HStack {
            AvatarView(model: self.model.avatarModel(
              for: contact.id,
              bundle: contact.avatarBundle,
            ))
            Text(verbatim: contact.name)
          }
          .tag(contact.id)
        }
        .environment(\.editMode, .constant(.active))
      }
      .listStyle(.plain)
      .navigationTitle("Add Contact")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          ToolbarButton.cancel {
            self.dismiss()
          }
        }
        ToolbarItem(placement: .topBarTrailing) {
          ToolbarButton.confirm(label: "Start chat") {
            self.dismiss()
            self.onSubmit(self.model.selectedUserIds)
          }
          .disabled(!self.model.isFormValid)
        }
      }
    }
    .task {
      await self.model.task()
    }
  }
}
