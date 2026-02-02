//
// This file is part of prose-app-ios.
// Copyright (c) 2025 Prose Foundation
//

import AvatarFeature
import SharedUI
import SwiftUI

struct InfoSection: View {
  @Bindable var model: InfoSectionModel

  init(model: InfoSectionModel) {
    self.model = model
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      if let identity = self.model.identity {
        VStack(alignment: .leading, spacing: 0) {
          VStack(alignment: .leading) {
            HStack {
              ZStack(alignment: .bottomTrailing) {
                AvatarView(model: identity.avatarModel)
                  .size(72)
                AvailabilityIndicator(identity.availability)
                  .isOwnStatus(true)
                  .size(12)
                  .border(width: 3, color: Color(.systemGroupedBackground))
                  .offset(x: 3, y: 3)
              }

              VStack(alignment: .leading, spacing: 4) {
                Text(verbatim: identity.name)
                  .font(.title2)
                  .fontWeight(.semibold)

                if let role = identity.role {
                  Text(role)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                }
              }

              Spacer()
            }

            if identity.phone != nil || identity.email != nil {
              HStack(spacing: 12) {
                if identity.phone != nil {
                  ActionButton(icon: "phone.fill", title: "Phone") {
                    self.model.phoneActionTapped()
                  }
                }
                if identity.email != nil {
                  ActionButton(icon: "envelope.fill", title: "Email") {
                    self.model.emailActionTapped()
                  }
                }

                Spacer()
              }
              .padding(.top)
            }
          }
          .padding()

          Divider()
        }
      }

      GroupBox("Information") {
        Grid(alignment: .leading, verticalSpacing: 8) {
          ForEach(self.model.items) { item in
            GridRow {
              Group {
                switch item.icon {
                case let .systemImage(image):
                  Image(systemName: image)
                case let .emoji(emoji):
                  Text(verbatim: emoji)
                }
              }
              .gridColumnAlignment(.center)
              .foregroundStyle(.secondary)

              Group {
                switch item.title {
                case let .localized(title):
                  Text(title)
                case let .verbatim(title):
                  Text(verbatim: title)
                }
              }.foregroundStyle(item.id == .status ? .secondary : .primary)
            }
          }
        }
      }
    }
    .task { await self.model.task() }
  }
}

struct ActionButton: View {
  private let icon: String
  private let title: LocalizedStringKey
  private let action: () -> Void

  init(icon: String, title: LocalizedStringKey, action: @escaping () -> Void) {
    self.icon = icon
    self.title = title
    self.action = action
  }

  var body: some View {
    Button(action: self.action) {
      VStack(spacing: 8) {
        Image(systemName: self.icon)
          .font(.system(size: 20))
        Text(self.title)
          .font(.caption)
      }
      .foregroundColor(.blue)
      .padding()
      .padding(.horizontal)
      .background(
        RoundedRectangle(cornerRadius: 10)
          .fill(Color(.secondarySystemBackground))
          .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1),
      )
    }
    .fixedSize()
  }
}
