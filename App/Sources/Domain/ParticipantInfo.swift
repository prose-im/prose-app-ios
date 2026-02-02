//
// This file is part of prose-app-ios.
// Copyright (c) 2025 Prose Foundation
//

import ProseSDK

// UniFFI can generate Equatable conformances but not for structs that contain objects.
// See https://github.com/mozilla/uniffi-rs/issues/2409
// In this case avatar is an object.

extension ParticipantInfo: @retroactive Equatable {
  public static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.id == rhs.id &&
      lhs.userId == rhs.userId &&
      lhs.name == rhs.name &&
      lhs.isSelf == rhs.isSelf &&
      lhs.availability == rhs.availability &&
      lhs.affiliation == rhs.affiliation &&
      lhs.avatarBundle == rhs.avatarBundle &&
      lhs.client == rhs.client &&
      lhs.status == rhs.status
  }
}
