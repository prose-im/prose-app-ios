//
// This file is part of prose-app-ios.
// Copyright (c) 2025 Prose Foundation
//

import AvatarFeature
import CasePaths
import Deps
import Domain
import Foundation
import RoomFeature
import RoomPickerFeature
import SwiftUI
import SwiftUINavigation

@MainActor @Observable
final class SidebarModel {
  @CasePathable
  enum Route {
    case alert(AlertState<AlertAction>)
    case channelPicker(ChannelPickerModel)
    case contactPicker(ContactPickerModel)
    case room(RoomModel)
    case invalidRoom
  }

  enum AlertAction {
    case ok
  }

  @ObservationIgnored @SharedReader var sessionState: SessionState
  @ObservationIgnored @Shared var settings: AccountSettings.Sidebar

  @ObservationIgnored @Dependency(\.client) var client
  @ObservationIgnored @Dependency(\.logger[category: "Sidebar"]) var logger

  var route: Route?

  private(set) var isLoading = true
  private(set) var sections: [Section] = Section.placeholderData

  private var avatarModels = [UserId: AvatarModel]()
  private var needsRefresh = false

  init(sessionState: SharedReader<SessionState>) {
    self._sessionState = sessionState
    self._settings = (Shared<AccountSettings>(
      .account(userId: sessionState.wrappedValue.selectedAccountId)).sidebar)
  }

  func task() async {
    if self.needsRefresh {
      self.needsRefresh = false

      // Do not try to reload if we're not connected. Once we're connected we'll receive
      // a new event and will load automatically.
      if self.sessionState.selectedAccount.connectionStatus == .connected {
        await self.sidebarItemsDidChange(items: self.client.sidebarItems())
      }
    }

    for await event in self.client.events() {
      switch event {
      case .sidebarChanged:
        await self.sidebarItemsDidChange(items: self.client.sidebarItems())
      case .connectionStatusChanged(event: .connect):
        self.didReconnect()
      default:
        continue
      }
    }

    // If we're cancelled because our view was dismissed make sure that we reload the data after
    // becoming visible again since it might have changed…
    self.needsRefresh = true
  }

  func navigateToRoom(roomId: RoomId) {
    // self.route = .invalidRoom

    let room = try? self.client.getConnectedRoom(roomId: roomId)
    let model = self.roomModel(with: .live(id: roomId, room: room))
    self.route = .room(model)
  }

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

  func addChannel() {
    self.route = withDependencies(from: self) {
      .channelPicker(.init())
    }
  }

  func addContact() {
    self.route = withDependencies(from: self) {
      .contactPicker(.init())
    }
  }

  func avatarModel(for userId: UserId, bundle: AvatarBundle) -> AvatarModel {
    if let model = self.avatarModels[userId] {
      return model
    }

    let model = withDependencies(from: self) {
      AvatarModel(userId: userId, bundle: bundle)
    }
    self.avatarModels[userId] = model
    return model
  }

  func startConversation(with userIds: [UserId]) {
    Task {
      do {
        let roomId = try await self.client.startConversation(participants: userIds)
        self.navigateToRoom(roomId: roomId)
      } catch {
        self.route = .alert(AlertState {
          TextState("Failed to start conversation")
        } actions: {
          ButtonState(action: .send(.ok)) {
            TextState("Ok")
          }
        } message: {
          TextState(verbatim: error.localizedDescription)
        })
      }
    }
  }

  func addChannel(with action: ChannelPickerModel.Action) {
    Task {
      do {
        let roomId = switch action {
        case let .join(roomId):
          try await self.client.joinRoom(roomId: roomId, password: nil)

        case let .create(name, private: true):
          try await self.client.createPrivateChannel(name: name)

        case let .create(name, private: false):
          try await self.client.createPublicChannel(name: name)
        }
        self.navigateToRoom(roomId: roomId)
      } catch {
        self.route = .alert(AlertState {
          TextState("Failed to add channel")
        } actions: {
          ButtonState(action: .send(.ok)) {
            TextState("Ok")
          }
        } message: {
          TextState(verbatim: error.localizedDescription)
        })
      }
    }
  }

  func alertActionTapped(action _: AlertAction?) {}
}

private extension SidebarModel {
  func roomModel(with roomClient: RoomClient) -> RoomModel {
    withDependencies {
      $0.client = self.client
      $0.room = roomClient
    } operation: {
      RoomModel(account: self.$sessionState.selectedAccount)
    }
  }

  func sidebarItemsDidChange(items: [SidebarItem]) {
    self.isLoading = false
    self.sections = Section.sectionsByGrouping(items: items, settings: self.$settings)
  }

  func didReconnect() {
    guard case let .room(roomModel) = self.route else {
      return
    }

    guard let room = try? self.client.getConnectedRoom(roomId: roomModel.roomId()) else {
      self.route = .invalidRoom
      return
    }

    self.route = .room(self.roomModel(with: .live(id: room.id, room: room)))
  }
}
