//
// This file is part of prose-app-ios.
// Copyright (c) 2025 Prose Foundation
//

import AvatarFeature
import CasePaths
import Deps
import Domain
import Foundation
import RoomPickerFeature
import SwiftUINavigation

@MainActor @Observable
final class MembersSectionModel: Identifiable {
  @CasePathable
  enum Route {
    case addMembers(ContactPickerModel)
  }

  enum AlertAction {
    case ok
  }

  @ObservationIgnored @Dependency(\.client) var client
  @ObservationIgnored @Dependency(\.logger[category: "ChatInfo"]) var logger
  @ObservationIgnored @Dependency(\.room) var room

  struct Participant: Identifiable, Equatable {
    var id: ParticipantId
    var avatar: AvatarBundle
    var availability: Availability
    var name: String
  }

  var route: Route?
  var participants = [Participant]()
  var alert: AlertState<AlertAction>?

  var canInviteParticipants: Bool {
    switch self.room.roomType() {
    case .privateChannel, .publicChannel:
      true
    case .directMessage, .generic, .group:
      false
    }
  }

  private var avatarModels = [ParticipantId: AvatarModel]()

  init() {}

  func task() async {
    self.loadData()

    for await event in self.client.events() {
      guard
        case let .roomChanged(room, .participantsChanged) = event,
        room.id == self.room.id()
      else {
        continue
      }

      self.loadData()
    }
  }

  func avatarModel(for participantId: ParticipantId, bundle: AvatarBundle) -> AvatarModel {
    if let model = self.avatarModels[participantId] {
      return model
    }

    let model = withDependencies(from: self) {
      AvatarModel(participantId: participantId, bundle: bundle)
    }
    self.avatarModels[participantId] = model
    return model
  }

  func addMembersButtonTapped() {
    self.route = withDependencies(from: self) {
      .addMembers(.init())
    }
  }

  func addMembers(userIDs: [UserId]) {
    self.route = nil

    guard let room = self.room as? RoomChannelClient else {
      return
    }

    Task {
      do {
        try await room.inviteUsers(users: userIDs)
      } catch {
        self.logger.error("Failed to invite users. \(error.localizedDescription)")
        self.alert = AlertState(
          title: {
            TextState("Could not add members")
          },
          actions: {
            ButtonState(action: .send(.ok)) {
              TextState("Ok")
            }
          },
          message: {
            TextState(verbatim: error.localizedDescription)
          },
        )
      }
    }
  }

  func alertActionTapped(action _: AlertAction?) {}
}

private extension MembersSectionModel {
  func loadData() {
    self.participants = self.room.participants().map { info in
      Participant(
        id: info.id,
        avatar: info.avatarBundle,
        availability: info.availability,
        name: info.name,
      )
    }
  }
}
