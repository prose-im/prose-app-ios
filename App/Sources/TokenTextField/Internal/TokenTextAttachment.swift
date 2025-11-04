//
// This file is part of prose-app-ios.
// Copyright (c) 2025 Prose Foundation
//

import UIKit

final class TokenTextAttachment<Token: Hashable>: NSTextAttachment {
  let token: Token
  let buildTokenView: (Token, Bool) -> UIView
  let isSelected: Bool

  init(token: Token, buildTokenView: @escaping (Token, Bool) -> UIView, isSelected: Bool) {
    self.token = token
    self.buildTokenView = buildTokenView
    self.isSelected = isSelected

    super.init(data: nil, ofType: tokenFileType)
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

final class TokenTextAttachmentViewProvider<Token: Hashable>: NSTextAttachmentViewProvider {
  private var token: Token?
  private var buildTokenView: ((Token, Bool) -> UIView)?
  private var isSelected = false

  override init(
    textAttachment: NSTextAttachment,
    parentView: UIView?,
    textLayoutManager: NSTextLayoutManager?,
    location: any NSTextLocation,
  ) {
    super.init(
      textAttachment: textAttachment,
      parentView: parentView,
      textLayoutManager: textLayoutManager,
      location: location,
    )

    guard let textAttachment = textAttachment as? TokenTextAttachment<Token> else {
      return
    }

    self.tracksTextAttachmentViewBounds = true

    self.token = textAttachment.token
    self.buildTokenView = textAttachment.buildTokenView
    self.isSelected = textAttachment.isSelected
  }

  override func loadView() {
    self.view = self.token.flatMap {
      self.buildTokenView?($0, self.isSelected)
    }
  }

  override func attachmentBounds(
    for attributes: [NSAttributedString.Key: Any],
    location: any NSTextLocation,
    textContainer: NSTextContainer?,
    proposedLineFragment: CGRect,
    position: CGPoint,
  ) -> CGRect {
    var bounds = super.attachmentBounds(
      for: attributes,
      location: location,
      textContainer: textContainer,
      proposedLineFragment: proposedLineFragment,
      position: position,
    )

    let font = attributes[.font] as? UIFont ?? UIFont.preferredFont(forTextStyle: .body)
    let offset = (font.capHeight - bounds.height) / 2
    bounds.origin.y = offset

    return bounds
  }
}
