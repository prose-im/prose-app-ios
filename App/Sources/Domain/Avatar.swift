//
// This file is part of prose-app-ios.
// Copyright (c) 2025 Prose Foundation
//

import ProseSDK

extension Avatar: @retroactive Equatable {
  public static func == (lhs: Avatar, rhs: Avatar) -> Bool {
    lhs.id() == rhs.id()
  }
}

extension Avatar: @retroactive Hashable {
  public func hash(into hasher: inout Hasher) {
    hasher.combine(self.id())
  }
}

extension AvatarBundle: @retroactive Equatable {
  public static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.avatar == rhs.avatar && lhs.initials == rhs.initials && lhs.color == rhs.color
  }
}

extension AvatarBundle: @retroactive Hashable {
  public func hash(into hasher: inout Hasher) {
    hasher.combine(self.avatar)
    hasher.combine(self.initials)
    hasher.combine(self.color)
  }
}
