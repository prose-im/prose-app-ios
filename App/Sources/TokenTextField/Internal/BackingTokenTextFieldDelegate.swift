//
// This file is part of prose-app-ios.
// Copyright (c) 2025 Prose Foundation
//

import UIKit

final class BackingTokenTextFieldDelegate: NSObject, UITextViewDelegate {
  private let handleReturnPress: () -> Void
  private let handleTextChanged: () -> Void
  private let handleDeleteBackward: () -> Bool
  private let handleDidChangeSelection: () -> Void

  init(
    handleReturnPress: @escaping () -> Void,
    handleTextChanged: @escaping () -> Void,
    handleDeleteBackward: @escaping () -> Bool,
    handleDidChangeSelection: @escaping () -> Void,
  ) {
    self.handleReturnPress = handleReturnPress
    self.handleTextChanged = handleTextChanged
    self.handleDeleteBackward = handleDeleteBackward
    self.handleDidChangeSelection = handleDidChangeSelection
  }

  func textViewDidChange(_: UITextView) {
    self.handleTextChanged()
  }

  func textViewDidChangeSelection(_: UITextView) {
    self.handleDidChangeSelection()
  }

  func textView(
    _: UITextView,
    shouldChangeTextIn _: NSRange,
    replacementText text: String,
  ) -> Bool {
    switch text {
    case "\n":
      self.handleReturnPress()
      return false

    case "":
      return self.handleDeleteBackward()

    default:
      return true
    }
  }
}
