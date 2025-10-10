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
  @Shared var account: Account

  let client: ProseCoreClient
  @Dependency(\.credentials) var credentials

  private var cancellables = Set<AnyCancellable>()

  init(userId: UserId, account: Shared<Account>, client: ProseCoreClient) {
    self.userId = userId
    self._account = account
    self.client = client

    Task {
      if let credentials = try? self.credentials.loadCredentials(self.userId) {
        try? await self.client.connect(credentials, true)
      }

      try await self.client.startObservingRooms()
      await self.loadAccountData()
    }.store(in: &self.cancellables)
  }
}

private extension AccountModel {
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
}
