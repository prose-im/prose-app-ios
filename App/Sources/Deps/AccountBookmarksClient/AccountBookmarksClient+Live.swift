//
// This file is part of prose-app-ios.
// Copyright (c) 2025 Prose Foundation
//

import Dependencies
import Domain
import Foundation

extension AccountBookmarksClient {
  static func live(
    bookmarksURL: URL = .documentsDirectory.appending(component: "accounts.json"),
  ) -> Self {
    print("Bookmarks URL: \(bookmarksURL.absoluteString)")
    let client = Domain.AccountBookmarksClient(bookmarksPath: bookmarksURL)

    return .init(
      loadBookmarks: {
        try client.loadBookmarks()
      },
      addBookmark: { id in
        try await Task {
          try client.addBookmark(userId: id, selectBookmark: true)
        }.result.get()
      },
      removeBookmark: { id in
        try await Task {
          try client.removeBookmark(userId: id)
        }.result.get()
      },
      selectBookmark: { id in
        try await Task {
          try client.selectBookmark(userId: id)
        }.result.get()
      },
    )
  }
}

extension AccountBookmarksClient: DependencyKey {
  public static let liveValue: AccountBookmarksClient = .live()
}
