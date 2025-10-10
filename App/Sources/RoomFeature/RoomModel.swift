//
// This file is part of prose-app-ios.
// Copyright (c) 2025 Prose Foundation
//

import ChatFeature
import Deps
import Domain
import Foundation

@MainActor @Observable
public final class RoomModel {
  @ObservationIgnored @SharedReader var sessionState: SessionState

  @ObservationIgnored @Dependency(\.accounts) var accounts

  let selectedItem: SidebarItem
  var messages = IdentifiedArrayOf<Message>()

  var chatModel: ChatModel {
    ChatModel(sessionState: self.$sessionState, selectedItem: self.selectedItem)
  }

  public init(sessionState: SharedReader<SessionState>, selectedItem: SidebarItem) {
    self._sessionState = sessionState
    self.selectedItem = selectedItem
  }
}
