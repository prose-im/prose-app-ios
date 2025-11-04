//
// This file is part of prose-app-ios.
// Copyright (c) 2025 Prose Foundation
//

import Deps
import Domain
import Foundation

@MainActor @Observable
public final class AvatarModel {
  @ObservationIgnored @Dependency(\.client) var client
  @ObservationIgnored @Dependency(\.logger[category: "Avatar"]) var logger

  let userId: UserId
  let bundle: AvatarBundle

  private(set) var avatarURL: URL?

  private var loadTask: Task<Void, Never>?

  public init(userId: UserId, bundle: AvatarBundle) {
    self.userId = userId
    self.bundle = bundle
  }
}

extension AvatarModel {
  func task() async {
    self.loadAvatar()

    for await event in self.client.events() {
      if
        case let .avatarChanged(userIds) = event,
        userIds.contains(self.userId)
      {
        self.loadAvatar()
      }
    }
  }
}

private extension AvatarModel {
  func loadAvatar() {
    self.loadTask?.cancel()

    guard let avatar = self.bundle.avatar else {
      return
    }

    self.loadTask = Task { [client, logger, userId, weak self] in
      do {
        self?.avatarURL = try await client.loadAvatar(avatar: avatar)
      } catch {
        logger.error("Failed to load avatar for \(userId). \(error.localizedDescription)")
      }
    }
  }
}
