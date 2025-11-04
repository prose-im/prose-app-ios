//
// This file is part of prose-app-ios.
// Copyright (c) 2025 Prose Foundation
//

import AvatarFeature
import Deps
import Domain
import Foundation
import SharedUI

@MainActor @Observable
public final class ContactPickerModel: Identifiable {
  @ObservationIgnored @Dependency(\.client) var client

  var contacts = [Contact]()

  var selectedUserIds: [UserId] {
    self.data.compactMap { data in
      if case let .token(userId) = data {
        return userId
      }
      return nil
    }
  }

  var data: [TokenData<UserId>] = []

  var listSelection: Set<UserId> {
    get { Set(self.selectedUserIds) }
    set {
      let currentUserIds = self.listSelection
      let addedUserIds = newValue.subtracting(currentUserIds)
      let removedUserIds = currentUserIds.subtracting(newValue)

      self.data.removeAll { data in
        if case let .token(userId) = data {
          return removedUserIds.contains(userId)
        }
        return false
      }

      self.data += addedUserIds.map(TokenData.token)
    }
  }

  var isFormValid: Bool {
    !self.data.isEmpty && !self.data.contains(where: { data in
      if case .text = data {
        return true
      }
      return false
    })
  }

  private var avatarModels = [UserId: AvatarModel]()

  public init() {}

  func task() async {
    self.contacts = await (try? self.client.loadContacts()) ?? []
  }

  func avatarModel(for userId: UserId, bundle: AvatarBundle) -> AvatarModel {
    if let model = self.avatarModels[userId] {
      return model
    }

    let model = withDependencies(from: self) {
      AvatarModel(userId: userId, bundle: bundle)
    }
    self.avatarModels[userId] = model
    return model
  }
}
