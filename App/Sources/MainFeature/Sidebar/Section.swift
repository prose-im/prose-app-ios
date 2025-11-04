//
// This file is part of prose-app-ios.
// Copyright (c) 2025 Prose Foundation
//

import Domain

extension SidebarModel {
  struct Section: Identifiable {
    var kind: Kind
    var items: [SidebarItem]

    @Shared var isExpanded: Bool

    var id: Kind {
      self.kind
    }
  }
}

extension SidebarModel.Section {
  enum Kind {
    case favorites
    case directMessages
    case channels
  }

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
          kind: .favorites,
          items: favorites,
          isExpanded: settings.favoritesExpanded,
        ),
      )
    }

    sections.append(
      .init(
        kind: .directMessages,
        items: dms,
        isExpanded: settings.dmsExpanded,
      ),
    )
    sections.append(
      .init(
        kind: .channels,
        items: channels,
        isExpanded: settings.channelsExpanded,
      ),
    )

    return sections
  }
}

extension SidebarModel.Section {
  @MainActor static let placeholderData: [Self] = .init(
    [Kind.directMessages, Kind.channels].map { kind in
      .init(
        kind: kind,
        items: (0..<8).map { _ in
          .init(
            name: String(repeating: "X", count: Int.random(in: 7...22)),
            roomId: .muc(MucId("room@prose.org")!),
            type: .directMessage(
              userId: UserId("user@prose.org")!,
              availability: .unavailable,
              avatarBundle: .init(
                avatar: nil,
                initials: "",
                color: .lightGray,
              ),
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
      )
    },
  )
}
