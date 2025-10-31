//
// This file is part of prose-app-ios.
// Copyright (c) 2025 Prose Foundation
//

import Foundation
import Sharing

public struct AccountSettings: Codable, Sendable {
  public struct Sidebar: Codable, Sendable {
    public var favoritesExpanded = true
    public var dmsExpanded = true
    public var channelsExpanded = true
  }

  public var sidebar = Sidebar()
}

public extension SharedKey where Self == FileStorageKey<AccountSettings>.Default {
  static func account(userId: UserId) -> Self {
    Self[
      .fileStorage(.documentsDirectory
        .appending(component: "Accounts")
        .appending(component: userId)
        .appending(component: "settings.json")),
      default: .init(),
    ]
  }
}
