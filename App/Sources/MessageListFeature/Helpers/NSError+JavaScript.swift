//
// This file is part of prose-app-ios.
// Copyright (c) 2025 Prose Foundation
//

import Foundation

public extension NSError {
  var prose_javaScriptExceptionMessage: String {
    (self.userInfo["WKJavaScriptExceptionMessage"] as? String) ?? self.localizedDescription
  }
}
