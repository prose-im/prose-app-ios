//
// This file is part of prose-app-ios.
// Copyright (c) 2025 Prose Foundation
//

import Deps
import Domain
import Foundation
import SwiftUI

@MainActor @Observable
public final class ChannelPickerModel: Identifiable {
  public enum Action: Equatable {
    case join(MucId)
    case create(name: String, private: Bool)
  }

  @ObservationIgnored @Dependency(\.client) var client

  var text = "" {
    didSet { self.inputDidChange() }
  }

  var createPrivateChannel = false {
    didSet { self.inputDidChange() }
  }

  var action = Action.create(name: "", private: false)
  var selectedRoom: MucId?

  var isFormValid: Bool {
    !self.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }

  var channels = [PublicRoomInfo]()

  public init() {}

  func task() async {
    let channels = await (try? self.client.loadPublicChannels()) ?? []
    self.channels = channels.sorted(using: SortDescriptor(\.name, comparator: .localized))
  }
}

private extension ChannelPickerModel {
  func inputDidChange() {
    if let roomAddress = MucId(self.text) {
      withAnimation {
        self.action = .join(roomAddress)
      }
      return
    }

    let existingRoom: MucId? = if let roomAddress = MucId(self.text) {
      roomAddress
    } else {
      self.channels.first {
        $0.name?.localizedCaseInsensitiveCompare(self.text) == .orderedSame
      }.map(\.id)
    }

    withAnimation {
      self.action = if let existingRoom {
        .join(existingRoom)
      } else {
        .create(name: self.text, private: self.createPrivateChannel)
      }
    }
  }
}

extension ChannelPickerModel.Action {
  var isCreateAction: Bool {
    if case .create = self {
      return true
    }
    return false
  }
}
