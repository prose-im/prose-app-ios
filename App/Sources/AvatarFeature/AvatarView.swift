//
// This file is part of prose-app-ios.
// Copyright (c) 2025 Prose Foundation
//

import Domain
import SwiftUI

public struct AvatarView: View {
  struct Style {
    var size: CGFloat = 24
    var cornerRadius: CGFloat?
    var fontSize: CGFloat?
  }

  @Bindable var model: AvatarModel

  var style = Style()

  public init(model: AvatarModel) {
    self.model = model
  }

  public var body: some View {
    AsyncImage(url: self.model.avatarURL) { image in
      image
        .resizable()
        .aspectRatio(contentMode: .fill)
    } placeholder: {
      if let bundle = self.model.bundle {
        Color(bundle.color)
          .overlay(
            Text(verbatim: bundle.initials)
              .font(.system(size: self.style.resolvedFontSize))
              .fontWeight(.bold)
              .foregroundColor(.white),
          )
      } else {
        Color.gray.opacity(0.3)
          .overlay(
            Image(systemName: "person.fill")
              .font(.title2)
              .foregroundColor(.gray),
          )
      }
    }
    .frame(width: self.style.size, height: self.style.size)
    .clipShape(RoundedRectangle(cornerRadius: self.style.resolvedCornerRadius))
    .task {
      await self.model.task()
    }
  }

  public func size(_ size: CGFloat) -> Self {
    var view = self
    view.style.size = size
    return view
  }

  public func cornerRadius(_ radius: CGFloat) -> Self {
    var view = self
    view.style.cornerRadius = radius
    return view
  }
}

extension AvatarView.Style {
  var resolvedCornerRadius: CGFloat {
    self.cornerRadius ?? (self.size * 0.25)
  }

  var resolvedFontSize: CGFloat {
    self.size * 0.5
  }
}
