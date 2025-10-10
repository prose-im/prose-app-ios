//
// This file is part of prose-app-ios.
// Copyright (c) 2025 Prose Foundation
//

import Foundation
import ProseSDK

public struct Credentials: Equatable, Sendable {
  public let id: UserId
  public let password: String

  public init(
    id: UserId,
    password: String,
  ) {
    self.id = id
    self.password = password
  }
}
