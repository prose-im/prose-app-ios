//
// This file is part of prose-app-ios.
// Copyright (c) 2025 Prose Foundation
//

import Dependencies
import UIKit

extension Pasteboard: DependencyKey {
  public static let liveValue = Pasteboard { string in
    UIPasteboard.general.string = string
  }
}
