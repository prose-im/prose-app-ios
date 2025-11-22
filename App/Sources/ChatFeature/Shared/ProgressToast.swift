//
// This file is part of prose-app-ios.
// Copyright (c) 2025 Prose Foundation
//

import SwiftUI

struct ProgressToast: View {
  enum Progress {
    case indeterminate(LocalizedStringKey)
    case determinate(Double)
  }

  let progress: Progress
  let onCancel: () -> Void

  var body: some View {
    HStack(spacing: 12) {
      switch self.progress {
      case let .indeterminate(text):
        HStack(spacing: 6) {
          ProgressView()
          Text(text)
        }

      case let .determinate(value):
        ProgressView(value: value, total: 1.0)
          .frame(width: 100)
      }

      Button("Cancel") {
        self.onCancel()
      }
      .buttonStyle(.bordered)
    }
    .padding()
    .controlSize(.mini)
    .background {
      Capsule()
        .fill(Color(.secondarySystemBackground))
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
  }
}
