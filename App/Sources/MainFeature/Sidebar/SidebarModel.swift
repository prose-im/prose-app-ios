//
// This file is part of prose-app-ios.
// Copyright (c) 2025 Prose Foundation
//

import Deps
import Domain
import Foundation
import SwiftUI

@MainActor @Observable
final class SidebarModel {
  struct Section: Identifiable, Equatable {
    var name: String
    var items: [SidebarItem]

    var id: String {
      self.name
    }
  }

  @ObservationIgnored @SharedReader var sessionState: SessionState

  @ObservationIgnored @Dependency(\.accounts) var accounts

  var sections = [Section]()
  var avatarTasks = [RoomId: Task<Void, Error>]()
  var avatars = [RoomId: URL]()

  init(sessionState: SharedReader<SessionState>) {
    self._sessionState = sessionState
  }

  func task() async {
    guard let client = try? self.accounts.client(for: self.sessionState.selectedAccountId) else {
      return
    }

    await self.setSidebarItems(items: client.sidebarItems(), client: client)

    for await event in client.events() {
      switch event {
      case .sidebarChanged:
        await self.setSidebarItems(items: client.sidebarItems(), client: client)
      default:
        continue
      }
    }
  }
}

private extension SidebarModel {
  func setSidebarItems(items: [SidebarItem], client: ProseCoreClient) {
    var favorites = [SidebarItem]()
    var dms = [SidebarItem]()
    var channels = [SidebarItem]()

    for item in items {
      switch item.room {
      case _ where item.isFavorite:
        favorites.append(item)

      case let .directMessage(room):
        if let avatar = room.participants().first?.avatar, avatarTasks[item.id] == nil {
          self.avatarTasks[item.id] = Task { [weak self] in
            let url = try await client.loadAvatar(avatar: avatar)
            self?.avatars[item.id] = url
          }
        }
        dms.append(item)

      case .group:
        dms.append(item)

      case .privateChannel, .publicChannel, .generic:
        channels.append(item)
      }
    }

    favorites.sort()
    dms.sort()
    channels.sort()

    var sections = [Section]()

    if !favorites.isEmpty {
      sections.append(
        Section(
          name: String(localized: "Favorites"),
          items: favorites,
        ),
      )
    }

    sections.append(
      Section(
        name: String(localized: "Direct Messages"),
        items: dms,
      ),
    )
    sections.append(
      Section(
        name: String(localized: "Channels"),
        items: channels,
      ),
    )

    self.sections = sections
  }
}
