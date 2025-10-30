//
// This file is part of prose-app-ios.
// Copyright (c) 2025 Prose Foundation
//

import Deps
import Domain
import Foundation
import RoomFeature
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

  @ObservationIgnored @Dependency(\.client) var client

  var sections = [Section]()
  var avatarTasks = [RoomId: Task<Void, Error>]()
  var avatars = [RoomId: URL]()

  init(sessionState: SharedReader<SessionState>) {
    self._sessionState = sessionState
  }

  func task() async {
    await self.setSidebarItems(items: self.client.sidebarItems())

    for await event in self.client.events() {
      switch event {
      case .sidebarChanged:
        await self.setSidebarItems(items: self.client.sidebarItems())
      default:
        continue
      }
    }
  }

  func roomModel(for item: SidebarItem) -> RoomModel {
    withDependencies(from: self) {
      RoomModel(sessionState: self.$sessionState, selectedItem: item)
    }
  }
}

private extension SidebarModel {
  func setSidebarItems(items: [SidebarItem]) {
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
            let url = try await self?.client.loadAvatar(avatar: avatar)
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
