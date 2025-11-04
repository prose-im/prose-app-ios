//
// This file is part of prose-app-ios.
// Copyright (c) 2025 Prose Foundation
//

import Foundation
import IdentifiedCollections
import ProseSDK
import Sharing
import Toolbox

public struct SessionState: Sendable {
  public var accounts = IdentifiedArrayOf<Account>()
  public var selectedAccountId: UserId

  public var selectedAccount: Account {
    self.accounts[id: self.selectedAccountId]
      .expect("SessionState was misconfigured. No selected account.")
  }

  public init(
    accounts: IdentifiedArrayOf<Account>,
    selectedAccountId: UserId,
  ) {
    self.accounts = accounts
    self.selectedAccountId = selectedAccountId
  }
}

#if DEBUG
  public extension SessionState {
    static func mock(
      accounts: [Account] = [.placeholder(for: UserId("bot@prose.org")!)],
      selectedAccountId: UserId = UserId("bot@prose.org")!,
    ) -> Self {
      .init(accounts: .init(uniqueElements: accounts), selectedAccountId: selectedAccountId)
    }
  }
#endif
