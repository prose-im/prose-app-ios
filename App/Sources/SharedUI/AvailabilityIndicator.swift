//
// This file is part of prose-app-ios.
// Copyright (c) 2025 Prose Foundation
//

import Domain
import SwiftUI

public struct AvailabilityIndicator: View {
  struct Style {
    struct Border {
      var width: CGFloat
      var color: Color
    }

    var isOwnStatus = false
    var size: CGFloat?
    var border: Border?
  }

  var availability: Availability
  var style = Style()

  public init(_ availability: Availability) {
    self.availability = availability
  }

  public var body: some View {
    Group {
      if let border = self.style.border {
        self.indicator
          .overlay(
            Circle().stroke(border.color, lineWidth: border.width),
          )
      } else {
        self.indicator
      }
    }
    .frame(width: self.style.size, height: self.style.size)
  }

  public func isOwnStatus(_ isOwnStatus: Bool) -> Self {
    var view = self
    view.style.isOwnStatus = isOwnStatus
    return view
  }

  public func size(_ size: CGFloat) -> Self {
    var view = self
    view.style.size = size
    return view
  }

  public func border(width: CGFloat, color: Color) -> Self {
    var view = self
    view.style.border = .init(width: width, color: color)
    return view
  }
}

private extension AvailabilityIndicator {
  @ViewBuilder
  var indicator: some View {
    switch self.availability {
    case .available:
      Circle().fill(Color.green)
    case .doNotDisturb:
      Circle().fill(Color.red)
    case .away:
      Circle().fill(Color.orange)
    case
      .invisible where self.style.isOwnStatus,
      .unavailable where self.style.isOwnStatus:
      Circle().fill(Color.gray)
    case .invisible, .unavailable:
      EmptyView()
    }
  }
}
