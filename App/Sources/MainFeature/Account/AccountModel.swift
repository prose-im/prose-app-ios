//
// This file is part of prose-app-ios.
// Copyright (c) 2025 Prose Foundation
//

import Deps
import Domain
import Foundation

@MainActor @Observable
final class AccountModel {
  @ObservationIgnored @SharedReader var account: Account

  @ObservationIgnored @Dependency(\.accounts) var accountsClient
  @ObservationIgnored @Dependency(\.logger[category: "Main"]) var logger

  init(account: SharedReader<Account>) {
    self._account = account
  }

  func logout() {
    do {
      try self.accountsClient.removeAccount(self.account.id)
    } catch {
      self.logger.error("Failed to log out. Reason: \(error.localizedDescription)")
    }
  }
}
