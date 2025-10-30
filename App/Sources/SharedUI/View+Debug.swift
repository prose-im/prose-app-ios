//
// This file is part of prose-app-ios.
// Copyright (c) 2025 Prose Foundation
//

#if DEBUG
  import SwiftUI

  public extension View {
    func debug() -> some View {
      self.background(Color.random)
    }
  }

  private extension Color {
    static var random: Color {
      Color(
        red: .random(in: 0...1),
        green: .random(in: 0...1),
        blue: .random(in: 0...1),
      )
    }
  }
#endif
