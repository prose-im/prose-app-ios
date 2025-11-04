//
// This file is part of prose-app-ios.
// Copyright (c) 2025 Prose Foundation
//

import SwiftUI

public enum TokenData<T: Hashable>: Hashable {
  case token(T)
  case text(String)
}

public struct TokenTextField<Token: Hashable, TokenView: View>: UIViewRepresentable {
  @MainActor
  public final class Coordinator {
    var textField: BackingTokenTextField<Token>?
    var isUpdatingBinding = false

    func toggleSelection(for token: Token) {
      self.textField?.toggleSelection(for: token)
    }
  }

  struct DefaultTextAttributes {
    var font = UIFont.preferredFont(forTextStyle: .body)
    var textColor = UIColor.label
    var keyboardType: UIKeyboardType = .default
  }

  @Binding public var data: [TokenData<Token>]
  @ViewBuilder public let buildTokenView: (Token, _ isSelected: Bool) -> TokenView
  public let createToken: (String) -> Token?

  private var attributes = DefaultTextAttributes()

  public init(
    data: Binding<[TokenData<Token>]>,
    @ViewBuilder buildTokenView: @escaping (Token, _ isSelected: Bool) -> TokenView,
    createToken: @escaping (String) -> Token?,
  ) {
    self._data = data
    self.buildTokenView = buildTokenView
    self.createToken = createToken
  }

  public func makeCoordinator() -> Coordinator {
    Coordinator()
  }

  public func makeUIView(context: Context) -> BackingTokenTextField<Token> {
    let textField = BackingTokenTextField(
      buildTokenView: { token, isSelected in
        UIHostingConfiguration {
          self.buildTokenView(token, isSelected)
            .onTapGesture {
              context.coordinator.toggleSelection(for: token)
            }
        }
        .margins(.all, EdgeInsets(top: 0, leading: 2, bottom: 4, trailing: 2))
        .makeContentView()
      },
      createToken: self.createToken,
      defaultTextAttributes: [
        .font: self.attributes.font,
        .foregroundColor: self.attributes.textColor,
      ],
    )
    textField.onDataChanged = { newData in
      context.coordinator.isUpdatingBinding = true
      self.data = newData
      context.coordinator.isUpdatingBinding = false
    }
    textField.keyboardType = self.attributes.keyboardType

    context.coordinator.textField = textField

    return textField
  }

  public func updateUIView(_ textField: BackingTokenTextField<Token>, context: Context) {
    guard !context.coordinator.isUpdatingBinding else { return }
    textField.data = self.data
  }

  public func sizeThatFits(
    _ proposal: ProposedViewSize,
    uiView textField: BackingTokenTextField<Token>,
    context _: Context,
  ) -> CGSize? {
    guard let width = proposal.width else {
      return nil
    }

    let requiredSize = textField.sizeThatFits(CGSize(
      width: width,
      height: .greatestFiniteMagnitude,
    ))
    return CGSize(width: width, height: requiredSize.height)
  }
}

public extension TokenTextField {
  func font(_ font: UIFont) -> Self {
    var view = self
    view.attributes.font = font
    return view
  }

  func textColor(_ color: UIColor) -> Self {
    var view = self
    view.attributes.textColor = color
    return view
  }

  func keyboardType(_ keyboardType: UIKeyboardType) -> Self {
    var view = self
    view.attributes.keyboardType = keyboardType
    return view
  }
}

#Preview {
  @Previewable @State var data: [TokenData<String>] = [
    .token("a@prose.org"),
    .token("b@prose.org"),
    .token("c@prose.org"),
    .token("d@prose.org"),
    .text("text"),
    .text("more text"),
  ]

  TokenTextField(data: $data) { token, isSelected in
    Text(verbatim: token)
      .padding(.vertical, 2)
      .padding(.horizontal, 6)
      .lineLimit(1)
      .foregroundStyle(isSelected ? .blue : .white)
      .background {
        RoundedRectangle(cornerRadius: 4)
          .fill(isSelected ? .white : .blue)
          .stroke(isSelected ? .blue : .clear, lineWidth: 1)
      }
  } createToken: { text in
    text
  }
  .frame(width: 400, height: 300)
}
