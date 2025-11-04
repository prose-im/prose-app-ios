//
// This file is part of prose-app-ios.
// Copyright (c) 2025 Prose Foundation
//

import SwiftUI

@MainActor
public enum ToolbarButton {}

public extension ToolbarButton {
  @ViewBuilder
  static func cancel(action: @escaping () -> Void) -> some View {
    if #available(iOS 26.0, *) {
      Button(role: .cancel, action: action)
    } else {
      Button("Cancel", action: action)
    }
  }

  @ViewBuilder
  static func confirm(
    label: LocalizedStringKey = "Done",
    action: @escaping () -> Void,
  ) -> some View {
    if #available(iOS 26.0, *) {
      Button(role: .confirm, action: action)
    } else {
      Button(label, action: action)
    }
  }
}
