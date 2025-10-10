//
// This file is part of prose-app-ios.
// Copyright (c) 2025 Prose Foundation
//

import Dependencies
import DependenciesMacros
import Domain
import Foundation

@DependencyClient
public struct AccountBookmarksClient: Sendable {
  public var loadBookmarks: @Sendable () throws -> [AccountBookmark]
  public var addBookmark: @Sendable (UserId) async throws -> Void
  public var removeBookmark: @Sendable (UserId) async throws -> Void
  public var selectBookmark: @Sendable (UserId) async throws -> Void
}

public extension DependencyValues {
  var accountBookmarks: AccountBookmarksClient {
    get { self[AccountBookmarksClient.self] }
    set { self[AccountBookmarksClient.self] = newValue }
  }
}

extension AccountBookmarksClient: TestDependencyKey {
  public static let testValue = Self()
}
