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
    await self.sidebarItemsDidChange(items: self.client.sidebarItems())

    for await event in self.client.events() {
      switch event {
      case .sidebarChanged:
        await self.sidebarItemsDidChange(items: self.client.sidebarItems())
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
  func sidebarItemsDidChange(items: [SidebarItem]) {
    // Load avatars if needed…
    for item in items {
      guard case let .directMessage(room) = item.room else {
        continue
      }

      if let avatar = room.participants().first?.avatar, avatarTasks[item.id] == nil {
        self.avatarTasks[item.id] = Task { [weak self] in
          let url = try await self?.client.loadAvatar(avatar: avatar)
          self?.avatars[item.id] = url
        }
      }
    }

    self.sections = Section.sectionsByGrouping(items: items)
  }
}
