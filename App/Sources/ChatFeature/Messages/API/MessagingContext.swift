//
// This file is part of prose-app-ios.
// Copyright (c) 2025 Prose Foundation
//

import Domain
import Foundation

public struct MessagingContext {
  public let setAccountJID: JSFunc1<UserId, Void>
  public let setStyleTheme: JSFunc1<StyleTheme?, Void>

  public init(evaluator: @escaping JSEvaluator) {
    let cls = JSClass(name: "MessagingContext", evaluator: evaluator)
    self.setAccountJID = cls.setAccountJID
    self.setStyleTheme = cls.setStyleTheme
  }
}
