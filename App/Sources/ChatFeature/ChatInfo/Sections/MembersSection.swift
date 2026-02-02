//
// This file is part of prose-app-ios.
// Copyright (c) 2025 Prose Foundation
//

import AvatarFeature
import RoomPickerFeature
import SharedUI
import SwiftUI

struct MembersSection: View {
  @Bindable var model: MembersSectionModel

  init(model: MembersSectionModel) {
    self.model = model
  }

  var body: some View {
    GroupBox("Members") {
      LazyVStack(alignment: .leading) {
        ForEach(self.model.participants) { participant in
          HStack {
            AvatarView(model: self.model.avatarModel(
              for: participant.id,
              bundle: participant.avatar,
            )).size(24)
            Text(verbatim: participant.name)
            AvailabilityIndicator(participant.availability)
              .size(8)
          }
        }

        if self.model.canInviteParticipants {
          Button {
            self.model.addMembersButtonTapped()
          } label: {
            HStack {
              Image(systemName: "plus.square.fill")
              Text("Add members")
                .foregroundStyle(.primary)
                .fontWeight(.medium)
            }
            .padding(.top, 4)
          }
        }
      }
    }
    .sheet(item: self.$model.route.addMembers) { model in
      ContactPickerView(model: model) { userIds in
        self.model.addMembers(userIDs: userIds)
      }
    }
    .alert(self.$model.alert) { action in
      self.model.alertActionTapped(action: action)
    }
    .task { await self.model.task() }
  }
}
