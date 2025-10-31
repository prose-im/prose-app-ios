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
      switch item.room {
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
