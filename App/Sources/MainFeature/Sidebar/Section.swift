//
// This file is part of prose-app-ios.
// Copyright (c) 2025 Prose Foundation
//

import Domain

extension SidebarModel.Section {
  static func sectionsByGrouping(
    items: [SidebarItem],
    settings: Shared<AccountSettings.Sidebar>,
  ) -> [Self] {
    var favorites = [SidebarItem]()
    var dms = [SidebarItem]()
    var channels = [SidebarItem]()

    for item in items {
      switch item.type {
      case _ where item.isFavorite:
        favorites.append(item)

      case .directMessage, .group:
        dms.append(item)

      case .privateChannel, .publicChannel, .generic:
        channels.append(item)
      }
    }

    favorites.sort()
    dms.sort()
    channels.sort()

    var sections = [Self]()

    if !favorites.isEmpty {
      sections.append(
        .init(
          name: String(localized: "Favorites"),
          items: favorites,
          isExpanded: settings.favoritesExpanded,
        ),
      )
    }

    sections.append(
      .init(
        name: String(localized: "Direct Messages"),
        items: dms,
        isExpanded: settings.dmsExpanded,
      ),
    )
    sections.append(
      .init(
        name: String(localized: "Channels"),
        items: channels,
        isExpanded: settings.channelsExpanded,
      ),
    )

    return sections
  }
}

extension SidebarModel.Section {
  @MainActor static let placeholderData: [Self] = .init(
    repeating: .init(
      name: String(repeating: "X", count: 14),
      items: (0..<8).map { _ in
        .init(
          name: String(repeating: "X", count: Int.random(in: 7...22)),
          roomId: .muc("id"),
          type: .directMessage(
            availability: .unavailable,
            initials: "",
            color: .lightGray,
            avatar: nil,
            status: nil,
          ),
          roomState: .connected,
          isFavorite: false,
          hasDraft: false,
          unreadCount: 0,
          mentionsCount: 0,
        )
      },
      isExpanded: Shared(value: true),
    ),
    count: 3,
  )
}
