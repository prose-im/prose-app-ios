//
// This file is part of prose-app-ios.
// Copyright (c) 2025 Prose Foundation
//

import SwiftUI

// Source: https://gist.github.com/alobaili/43aa2fea8885cf237e360373bf903652
// Unfortunately .presentationSizing(.fitted) only works on iPad OS, hence why
// we need a custom solution.

public extension View {
  func fittedPresentationDetent() -> some View {
    modifier(FittedPresentationDetentModifier())
  }
}

private struct ReadHeightModifier: ViewModifier {
  let action: (Double) -> Void

  func body(content: Content) -> some View {
    content
      .onGeometryChange(for: Double.self) { proxy in
        proxy.size.height
      } action: { newValue in
        self.action(newValue)
      }
  }
}

struct FittedPresentationDetentModifier: ViewModifier {
  @State private var height = 0.0

  func body(content: Content) -> some View {
    content
      .readHeight { height in
        // this guard is to avoid the following layout error that will
        // crash in future releases:
        //
        // A presentation preference is rapidly switching between values,
        // possibly because the presentation's preferences depend on its size.
        //
        // -- Previous Preferences --
        // presentationsDetents: Height 389.3333333333333
        //
        // -- Most Recent Preferences --
        // presentationsDetents: Height 376.6666666666667
        //
        // The most recent value was ignored to avoid cyclic layout.
        // Please update your code to avoid this issue.
        // This may become a crash in a future release.
        guard height >= self.height else { return }

        self.height = height
      }
      .presentationDetents([.height(self.height)])
  }
}

private extension View {
  func readHeight(_ perform: @escaping (Double) -> Void) -> some View {
    modifier(ReadHeightModifier(action: perform))
  }
}
