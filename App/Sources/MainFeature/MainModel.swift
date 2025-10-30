//
// This file is part of prose-app-ios.
// Copyright (c) 2025 Prose Foundation
//

import Deps
import Domain
import Foundation
import Toolbox

@MainActor @Observable
public final class MainModel {
  @ObservationIgnored @SharedReader var sessionState: SessionState

  @ObservationIgnored let accountModel: AccountModel
  @ObservationIgnored let sidebarModel: SidebarModel

  public init(sessionState: SharedReader<SessionState>) {
    @Dependency(\.accounts) var accounts

    self._sessionState = sessionState

    self.accountModel = AccountModel(account: sessionState.selectedAccount)

    let client = (try? accounts.client(for: sessionState.wrappedValue.selectedAccountId))
      .expect("No client registered for selected account ID.")

    let sidebarModel = withDependencies {
      $0.client = client
    } operation: {
      SidebarModel(sessionState: sessionState)
    }

    self.sidebarModel = sidebarModel
  }
}
