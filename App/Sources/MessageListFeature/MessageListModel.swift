//
// This file is part of prose-app-ios.
// Copyright (c) 2025 Prose Foundation
//

import Deps
import Domain
import Foundation

@MainActor @Observable
public class MessageListModel {
  @ObservationIgnored @SharedReader var messages: IdentifiedArrayOf<Message>

  @ObservationIgnored @Dependency(\.logger[category: "MessageList"]) var logger

  var webViewIsReady = false

  public init(messages: SharedReader<IdentifiedArrayOf<Message>>) {
    self._messages = messages
  }
}
