//
// This file is part of prose-app-ios.
// Copyright (c) 2025 Prose Foundation
//

import Domain
import SwiftUI

struct AccountView: View {
  @Bindable var model: AccountModel

  var body: some View {
    VStack {
      HStack(spacing: 12) {
        ZStack(alignment: .bottomTrailing) {
          AsyncImage(url: self.model.account.avatar) { image in
            image
              .resizable()
              .aspectRatio(contentMode: .fill)
          } placeholder: {
            Color.gray.opacity(0.3)
              .overlay(
                Image(systemName: "person.fill")
                  .font(.title2)
                  .foregroundColor(.gray),
              )
          }
          .frame(width: 56, height: 56)
          .clipShape(RoundedRectangle(cornerRadius: 12))

          Circle()
            .fill(Color.green)
            .frame(width: 12, height: 12)
            .overlay(
              Circle().stroke(Color.white, lineWidth: 2),
            )
            .offset(x: 2, y: 2)
        }

        VStack(alignment: .leading, spacing: 2) {
          Text(verbatim: self.model.account.name)
            .fontWeight(.bold)

          if let status = self.model.account.status {
            HStack(spacing: 4) {
              Text(verbatim: status.emoji)
              if let text = status.status {
                Text(verbatim: text)
                  .foregroundColor(.secondary)
              }
            }
          }
        }

        Spacer()

        Button(action: {
          self.model.logout()
        }) {
          Image(systemName: "power")
            .imageScale(.small)
        }
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.circle)
      }
      .padding(.horizontal)

      Divider()
    }
  }
}

#Preview {
  AccountView(model: .init(account: SharedReader(value: .placeholder(for: "bot@prose.org"))))
}
