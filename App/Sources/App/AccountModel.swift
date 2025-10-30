//
// This file is part of prose-app-ios.
// Copyright (c) 2025 Prose Foundation
//

import Deps
import Domain
import Foundation
import Toolbox

@MainActor
final class AccountModel {
  private let userId: UserId

  @Shared(.app) var appState = AppState()
  @Shared var account: Account

  let client: ProseCoreClient

  @Dependency(\.credentials) var credentials
  @Dependency(\.connectivity) var connectivity
  @Dependency(\.scenePhase) var scenePhase

  private var cancellables = Set<AnyCancellable>()

  init(userId: UserId, account: Shared<Account>, client: ProseCoreClient) {
    self.userId = userId
    self._account = account
    self.client = client

    Task {
      await self.connectClient()

      self.observeConnectivityAndScenePhase()
      try await self.client.startObservingRooms()

      await self.loadAccountData()
    }.store(in: &self.cancellables)
  }
}

private extension AccountModel {
  func connectClient() async {
    if let credentials = try? self.credentials.loadCredentials(self.userId) {
      try? await self.client.connect(credentials, true)
    }
  }

  func loadAccountData() async {
    do {
      async let accountInfoTask = self.client.loadAccountInfo()
      async let profileTask = self.client.loadProfile(self.userId)
      async let contactsTask = self.client.loadContacts()

      let (accountInfo, profile, contacts) = try await (
        accountInfoTask,
        profileTask,
        contactsTask,
      )

      self.$account.withLock {
        $0.name = accountInfo.name
        $0.availability = accountInfo.availability
        $0.status = accountInfo.status
        $0.profile = profile
        $0.contacts = .init(
          zip(contacts.map(\.id), contacts),
          uniquingKeysWith: { _, last in last },
        )
      }

      if let avatarId = accountInfo.avatar {
        let avatar = try await self.client.loadAvatar(avatarId)
        self.$account.withLock {
          $0.avatar = avatar
        }
      }
    } catch {
      print("Failed to load account data.", error)
    }
  }

  func observeConnectivityAndScenePhase() {
    Task { [weak self, connectivity, appState = self.$appState] in
      for await status in connectivity() {
        appState.withLock { $0.connectivity = status }
        self?.appStateDidChange()
      }
    }.store(in: &self.cancellables)

    Task { [weak self, scenePhase, appState = self.$appState] in
      for await phase in scenePhase() {
        appState.withLock { $0.scenePhase = phase }
        self?.appStateDidChange()
      }
    }.store(in: &self.cancellables)
  }

  func connectivityDidChange() {
    guard self.appState.connectivity == .online else {
      return
    }
    Task { await self.connectClient() }
  }

  func appStateDidChange() {
    Task {
      switch self.appState.scenePhase {
      case .active, .inactive:
        await self.connectClient()

      case .background:
        try await self.client.disconnect()
      }
    }
  }
}
