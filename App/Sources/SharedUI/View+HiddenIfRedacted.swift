//
// This file is part of prose-app-ios.
// Copyright (c) 2025 Prose Foundation
//

import SwiftUI

public extension View {
  func hiddenIfRedacted(
    for reasons: RedactionReasons = .placeholder,
    reserveSpace: Bool = true,
  ) -> some View {
    modifier(HiddenIfRedacted(for: reasons, reserveSpace: reserveSpace))
  }
}

struct HiddenIfRedacted: ViewModifier {
  @Environment(\.redactionReasons) var redactionReasons

  let hideForReasons: RedactionReasons
  let reserveSpace: Bool

  init(for reasons: RedactionReasons = .placeholder, reserveSpace: Bool = true) {
    self.hideForReasons = reasons
    self.reserveSpace = reserveSpace
  }

  func body(content: Content) -> some View {
    if self.reserveSpace {
      content
        .opacity(self.redactionReasons.contains(self.hideForReasons) ? 0 : 1)
    } else {
      if !self.redactionReasons.contains(self.hideForReasons) {
        content
      }
    }
  }
}
