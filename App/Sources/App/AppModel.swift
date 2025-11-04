//
// This file is part of prose-app-ios.
// Copyright (c) 2025 Prose Foundation
//

import CasePaths
import Deps
import Domain
import Foundation
import LoginFeature
import MainFeature
import Toolbox

@MainActor @Observable
final class AppModel {
  private var accounts = [UserId: AccountModel]()
  private var sessionState: Shared<SessionState>?

  @ObservationIgnored @Dependency(\.accountBookmarks) var bookmarks
  @ObservationIgnored @Dependency(\.credentials) var credentials
  @ObservationIgnored @Dependency(\.accounts) var accountsClient

  var route = Route.noAccounts
  var login: LoginModel? = LoginModel()

  @CasePathable
  @dynamicMemberLookup
  enum Route {
    case main(MainModel)
    case noAccounts
  }

  func task() async {
    Task {
      // Observe accounts changes…
      for try await accounts in self.accountsClient.accounts() {
        self.accountsDidChange(newAccountIds: accounts)
      }
    }
    try? await self.restoreAccounts()
  }
}

private extension AppModel {
  func restoreAccounts() async throws {
    let bookmarks = try self.bookmarks.loadBookmarks()
    var accounts = IdentifiedArrayOf<Account>()
    var selectedAccountId: UserId?

    for bookmark in bookmarks {
      guard let credentials = try? self.credentials.loadCredentials(bookmark.userId) else {
        continue
      }

      try await self.accountsClient.addAccount(bookmark.userId)
      accounts.append(.placeholder(for: credentials.id))

      if bookmark.isSelected {
        selectedAccountId = bookmark.userId
      }
    }

    guard let firstAccount = accounts.first else {
      return
    }

    self._sessionState = Shared(value: SessionState(
      accounts: accounts,
      selectedAccountId: selectedAccountId ?? firstAccount.id,
    ))
  }

  func accountsDidChange(newAccountIds: [UserId]) {
    // If selectedAccountId isn't available in accounts anymore, let's select the first
    // available account.
    if
      let sessionState = self.sessionState,
      let firstAvailableAccountId = newAccountIds.first,
      !newAccountIds.contains(sessionState.wrappedValue.selectedAccountId)
    {
      sessionState.withLock {
        $0.selectedAccountId = firstAvailableAccountId
      }
    }

    for accountId in self.accounts.keys {
      if !newAccountIds.contains(accountId) {
        self.accounts.removeValue(forKey: accountId)
      }
    }

    guard let firstNewAccountId = newAccountIds.first else {
      self.sessionState = nil
      self.route = .noAccounts

      // Set the state conditionally so that controls don't lose focus in case the auth form
      // is visible already.
      if self.login == nil {
        self.login = withDependencies(from: self) {
          LoginModel()
        }
      }

      return
    }

    let sessionState = self.sessionState ??
      Shared(value: SessionState(accounts: [], selectedAccountId: firstNewAccountId))
    self.sessionState = sessionState

    for accountId in newAccountIds where self.accounts[accountId] == nil {
      guard let client = try? self.accountsClient.client(for: accountId) else {
        continue
      }

      _ = sessionState.withLock { $0.accounts.append(Account.placeholder(for: accountId)) }

      self.accounts[accountId] = withDependencies(from: self) {
        $0.client = client
      } operation: {
        AccountModel(
          userId: accountId,
          account: Shared(sessionState.projectedValue.accounts[id: accountId])!,
        )
      }
    }

    self.login = nil
    self.route = withDependencies(from: self) {
      .main(MainModel(sessionState: SharedReader(sessionState)))
    }
  }
}
