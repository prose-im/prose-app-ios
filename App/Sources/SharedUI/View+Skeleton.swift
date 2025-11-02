//
// This file is part of prose-app-ios.
// Copyright (c) 2025 Prose Foundation
//

import SwiftUI

// Source: https://manu.show/2025-06-15-ep089-skeleton-modifier/

public extension View {
  @ViewBuilder
  func skeleton(condition: Bool = true) -> some View {
    if condition {
      modifier(Shimmer())
    } else {
      self
    }
  }
}

struct Shimmer: ViewModifier {
  @State private var isInitialState = true

  func body(content: Content) -> some View {
    content
      .redacted(reason: .placeholder)
      .disabled(true)
      .mask(
        LinearGradient(
          gradient: Gradient(
            colors: [
              .white.opacity(0.9),
              .white.opacity(0.6),
              .white.opacity(0.5),
              .white.opacity(0.3),
              .white.opacity(0),
              .white.opacity(0.3),
              .white.opacity(0.6),
              .white.opacity(0.9),
            ],
          ),
          startPoint: self.isInitialState ? .init(x: -1.0, y: 0) : .init(x: 1, y: 1),
          endPoint: self.isInitialState ? .init(x: 0, y: 0) : .init(x: 1.9, y: 1),
        ),
      )
      .animation(
        .easeIn(duration: 1.25)
          .delay(0.25)
          .repeatForever(autoreverses: false),
        value: self.isInitialState,
      )
      .onAppear {
        self.isInitialState = false
      }
  }
}
