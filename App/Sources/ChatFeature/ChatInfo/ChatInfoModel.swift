//
// This file is part of prose-app-ios.
// Copyright (c) 2025 Prose Foundation
//

import Deps
import Domain
import Foundation

@MainActor @Observable
final class ChatInfoModel: Identifiable {
  @ObservationIgnored @Dependency(\.client) var client
  @ObservationIgnored @Dependency(\.logger[category: "ChatInfo"]) var logger
  @ObservationIgnored @Dependency(\.room) var room

  let infoSectionModel: InfoSectionModel
  let membersSectionModel: MembersSectionModel?

  init() {
    @Dependency(\.room) var room

    self.infoSectionModel = InfoSectionModel()
    self.membersSectionModel = room.roomType() != .directMessage
      ? MembersSectionModel()
      : nil
  }

  func task() async {}
}
