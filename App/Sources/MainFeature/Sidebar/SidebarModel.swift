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
  struct Section: Identifiable {
    var name: String
    var items: [SidebarItem]

    @Shared var isExpanded: Bool

    var id: String {
      self.name
    }
  }

  @ObservationIgnored @SharedReader var sessionState: SessionState
  @ObservationIgnored @Shared var settings: AccountSettings.Sidebar

  @ObservationIgnored @Dependency(\.client) var client
  @ObservationIgnored @Dependency(\.logger[category: "Sidebar"]) var logger

  var sections = [Section]()
  var avatarTasks = [RoomId: Task<Void, Error>]()
  var avatars = [RoomId: URL]()

  init(sessionState: SharedReader<SessionState>) {
    self._sessionState = sessionState
    self._settings = (Shared<AccountSettings>(
      .account(userId: sessionState.wrappedValue.selectedAccountId)).sidebar)
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

  func removeItem(_ item: SidebarItem) {
    Task {
      do {
        try await self.client.removeItemFromSidebar(roomId: item.roomId)
      } catch {
        self.logger.error("Failed to remove sidebar item. \(error.localizedDescription)")
      }
    }
  }

  func toggleFavorite(_ item: SidebarItem) {
    Task {
      do {
        try await self.client.toggleSidebarFavorite(roomId: item.roomId)
      } catch {
        self.logger.error("Failed to toggle favorite. \(error.localizedDescription)")
      }
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

      if let avatar = room.participants().first?.avatar, avatarTasks[item.roomId] == nil {
        self.avatarTasks[item.roomId] = Task { [weak self] in
          let url = try await self?.client.loadAvatar(avatar: avatar)
          self?.avatars[item.roomId] = url
        }
      }
    }

    self.sections = Section.sectionsByGrouping(items: items, settings: self.$settings)
  }
}
