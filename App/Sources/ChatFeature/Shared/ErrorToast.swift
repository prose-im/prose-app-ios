//
// This file is part of prose-app-ios.
// Copyright (c) 2025 Prose Foundation
//

import SwiftUI

struct ErrorToast: View {
  let error: any Error
  let onCancel: () -> Void

  var body: some View {
    HStack(spacing: 12) {
      VStack(alignment: .leading) {
        Text("Download Failed")
          .fontWeight(.semibold)

        Text(self.error.localizedDescription)
          .foregroundStyle(.secondary)
          .multilineTextAlignment(.leading)
          .lineLimit(2)
      }
      .font(.footnote)
      .frame(maxWidth: .infinity)

      Button("Ok") {
        self.onCancel()
      }
      .buttonStyle(.borderedProminent)
    }
    .frame(maxWidth: .infinity)
    .padding()
    .controlSize(.mini)
    .background {
      RoundedRectangle(cornerRadius: 12)
        .fill(Color(.secondarySystemBackground))
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
    .padding(.horizontal)
  }
}
