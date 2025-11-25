//
// This file is part of prose-app-ios.
// Copyright (c) 2025 Prose Foundation
//

import Foundation

public struct FFI {
  public let messagingContext: MessagingContext
  public let messagingStore: MessagingStore

  public init(evaluator: @escaping JSEvaluator) {
    self.messagingContext = MessagingContext(evaluator: evaluator)
    self.messagingStore = MessagingStore(evaluator: evaluator)
  }
}
