//
// This file is part of prose-app-ios.
// Copyright (c) 2025 Prose Foundation
//

import Foundation
import SwiftUI

public struct UIError: Equatable {
  public var title: LocalizedStringKey
  public var systemImage: String
  public var description: Text?

  public init(
    title: LocalizedStringKey,
    systemImage: String = "exclamationmark.circle.fill",
    description: LocalizedStringKey? = nil,
  ) {
    self.title = title
    self.systemImage = systemImage
    self.description = description.map { Text($0) }
  }
}

public extension UIError {
  init(
    title: LocalizedStringKey,
    systemImage: String = "exclamationmark.circle.fill",
    error: any Error,
  ) {
    self.title = title
    self.systemImage = systemImage
    self.description = Text(error.localizedDescription)
  }
}
