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

  let selectedItem: SidebarItem
  let chatModel: ChatModel

  var messages = IdentifiedArrayOf<Message>()

  public init(sessionState: SharedReader<SessionState>, selectedItem: SidebarItem) {
    self._sessionState = sessionState
    self.selectedItem = selectedItem
    self.chatModel = ChatModel(sessionState: sessionState, selectedItem: selectedItem)
  }
}
