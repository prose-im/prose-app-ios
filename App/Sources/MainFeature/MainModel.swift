//
// This file is part of prose-app-ios.
// Copyright (c) 2025 Prose Foundation
//

import Deps
import Domain
import Foundation

@MainActor @Observable
public final class MainModel {
  @ObservationIgnored @SharedReader var sessionState: SessionState

  @ObservationIgnored let accountModel: AccountModel
  @ObservationIgnored let sidebarModel: SidebarModel

  public init(sessionState: SharedReader<SessionState>) {
    self._sessionState = sessionState
    self.accountModel = AccountModel(account: sessionState.selectedAccount)
    self.sidebarModel = SidebarModel(sessionState: sessionState)
  }
}
