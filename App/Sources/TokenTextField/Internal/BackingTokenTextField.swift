//
// This file is part of prose-app-ios.
// Copyright (c) 2025 Prose Foundation
//

import UIKit
import UniformTypeIdentifiers

let tokenFileType = UTType.plainText.identifier

public final class BackingTokenTextField<Token: Hashable>: UITextView {
  private var textFieldDelegate: BackingTokenTextFieldDelegate?
  private let buildTokenView: (Token, Bool) -> UIView
  private let createToken: (String) -> Token?
  private let defaultTextAttributes: [NSAttributedString.Key: any Sendable]
  private var isApplyingText = false

  private var _data: [TokenData<Token>] = []

  private var selectedToken: Token? {
    didSet {
      guard self.selectedToken != oldValue else {
        return
      }
      // Redraw tokens
      let currentData = self.data(from: self.textStorage)
      self.apply(
        attributedText: self.attributedText(for: currentData),
        restoreSelection: true,
      )
    }
  }

  var onDataChanged: (([TokenData<Token>]) -> Void)?

  var data: [TokenData<Token>] {
    get { self._data }
    set {
      guard newValue != self._data else {
        return
      }
      self._data = newValue
      self.selectedToken = nil
      self.apply(attributedText: self.attributedText(for: self._data))
    }
  }

  init(
    buildTokenView: @escaping (Token, Bool) -> UIView,
    createToken: @escaping (String) -> Token?,
    defaultTextAttributes: [NSAttributedString.Key: any Sendable],
  ) {
    self.buildTokenView = buildTokenView
    self.createToken = createToken
    self.defaultTextAttributes = defaultTextAttributes

    super.init(frame: .zero, textContainer: nil)

    self.textContainer.lineFragmentPadding = 0
    self.typingAttributes = defaultTextAttributes
    self.textContainerInset = .zero

    self.backgroundColor = nil
    self.autocorrectionType = .no
    self.autocapitalizationType = .none

    NSTextAttachment.registerViewProviderClass(
      TokenTextAttachmentViewProvider<Token>.self,
      forFileType: tokenFileType,
    )

    let textFieldDelegate = BackingTokenTextFieldDelegate(
      handleReturnPress: { [weak self] in
        self?.convertPendingTextToToken()
      },
      handleTextChanged: { [weak self] in
        self?.dataChanged()
      },
      handleDeleteBackward: { [weak self] in
        guard let self else {
          return true
        }

        if self.selectedToken != nil {
          self.deleteSelectedToken()
          return false
        }

        return true
      },
      handleDidChangeSelection: { [weak self] in
        guard let self, !self.isApplyingText else {
          return
        }
        self.selectedToken = nil
      },
    )
    self.textFieldDelegate = textFieldDelegate
    self.delegate = textFieldDelegate
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override public func resignFirstResponder() -> Bool {
    self.selectedToken = nil
    return super.resignFirstResponder()
  }

  func toggleSelection(for token: Token) {
    if self.selectedToken == token {
      self.selectedToken = nil
    } else {
      self.selectedToken = token
    }

    // If we're not firstResponder we won't receive key events…
    if !self.isFirstResponder {
      self.becomeFirstResponder()
    }
  }
}

private extension BackingTokenTextField {
  func attributedText(for data: [TokenData<Token>]) -> NSAttributedString {
    let result = NSMutableAttributedString(string: "", attributes: self.defaultTextAttributes)

    for tokenData in data {
      switch tokenData {
      case let .text(text):
        result.append(NSAttributedString(string: text, attributes: self.defaultTextAttributes))

      case let .token(token):
        let isSelected = self.selectedToken == token

        result.append(
          NSMutableAttributedString(
            attachment: TokenTextAttachment(
              token: token,
              buildTokenView: self.buildTokenView,
              isSelected: isSelected,
            ),
            attributes: self.defaultTextAttributes,
          ),
        )
      }
    }

    return result
  }

  func data(from attributedText: NSAttributedString) -> [TokenData<Token>] {
    var result: [TokenData<Token>] = []
    var currentText = ""

    attributedText.enumerateAttribute(
      .attachment,
      in: NSRange(location: 0, length: attributedText.length),
    ) { value, range, _ in
      guard let attachment = value as? TokenTextAttachment<Token> else {
        currentText += attributedText.attributedSubstring(from: range).string
        return
      }

      if !currentText.isEmpty {
        result.append(.text(currentText))
        currentText = ""
      }

      result.append(.token(attachment.token))
    }

    if !currentText.isEmpty {
      result.append(.text(currentText))
    }

    return result
  }

  func convertPendingTextToToken() {
    // If a token is selected, move cursor to end and deselect
    if self.selectedToken != nil {
      self.selectedRange = NSRange(location: self.textStorage.length, length: 0)
      self.selectedToken = nil
      return
    }

    let cursorPosition = self.selectedRange.location

    // Find range of pending text between attachments or boundaries
    let currentTextRange = self.findPendingTextRange(at: cursorPosition)

    guard currentTextRange.length > 0 else {
      // No text to convert, move cursor to end
      self.selectedRange = NSRange(location: self.textStorage.length, length: 0)
      return
    }

    let currentText = self.textStorage.attributedSubstring(from: currentTextRange).string

    // Try to create a token from the pending text
    if let token = self.createToken(currentText) {
      // Convert to token
      self.textStorage.replaceCharacters(
        in: currentTextRange,
        with: self.attributedText(for: [.token(token)]),
      )
      self.dataChanged()
    } else {
      // Not a valid token, move cursor to end of pending text
      self.selectedRange = NSRange(location: NSMaxRange(currentTextRange), length: 0)
    }
  }

  func findPendingTextRange(at position: Int) -> NSRange {
    var rangeStart = 0
    var rangeEnd = self.textStorage.length

    // Find the nearest attachment before the cursor
    self.textStorage.enumerateAttribute(
      .attachment,
      in: NSRange(location: 0, length: position),
      options: .reverse,
    ) { value, range, stop in
      if value is TokenTextAttachment<Token> {
        rangeStart = NSMaxRange(range)
        stop.pointee = true
      }
    }

    // Find the nearest attachment after the cursor
    if position < self.textStorage.length {
      self.textStorage.enumerateAttribute(
        .attachment,
        in: NSRange(location: position, length: self.textStorage.length - position),
      ) { value, range, stop in
        if value is TokenTextAttachment<Token> {
          rangeEnd = range.location
          stop.pointee = true
        }
      }
    }

    return NSRange(location: rangeStart, length: rangeEnd - rangeStart)
  }

  func deleteSelectedToken() {
    guard let selectedToken else {
      return
    }

    self.data.removeAll { data in
      data == .token(selectedToken)
    }

    self.dataChanged()
  }

  func apply(attributedText: NSAttributedString, restoreSelection: Bool = false) {
    guard !self.isApplyingText else {
      return
    }

    self.isApplyingText = true

    let selectedTextRange = self.selectedTextRange
    let formerLength = self.attributedText.length

    self.attributedText = attributedText

    if restoreSelection, formerLength == attributedText.length {
      self.selectedTextRange = selectedTextRange
    }

    self.isApplyingText = false
  }

  func dataChanged() {
    let newData = self.data(from: self.textStorage)
    self._data = newData
    self.onDataChanged?(newData)
  }
}
