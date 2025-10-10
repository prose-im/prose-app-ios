//
// This file is part of prose-app-ios.
// Copyright (c) 2025 Prose Foundation
//

import SwiftUI

public struct ErrorView: View {
  let error: UIError

  public init(error: UIError) {
    self.error = error
  }

  public var body: some View {
    ContentUnavailableView(
      self.error.title,
      systemImage: self.error.systemImage,
      description: self.error.description,
    )
  }
}
