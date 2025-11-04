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
      Color(self.model.bundle.color)
        .overlay(
          Text(verbatim: self.model.bundle.initials)
            .font(.system(size: self.style.resolvedFontSize))
            .fontWeight(.bold)
            .foregroundColor(.white),
        )
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
