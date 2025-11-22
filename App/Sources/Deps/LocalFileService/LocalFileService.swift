//
// This file is part of prose-app-ios.
// Copyright (c) 2025 Prose Foundation
//

import Dependencies
import DependenciesMacros
import Domain
import Foundation
@_exported import UniformTypeIdentifiers.UTType

@DependencyClient
public struct LocalFileService: Sendable {
  public var temporaryPathForRemoteFile: @Sendable (
    _ at: URL,
    _ type: UTType?,
    _ room: RoomId?,
  ) -> URL = { _, _, _ in URL(string: "/")! }

  public var importTemporaryFile: @Sendable (_ from: URL) throws -> URL = { _ in URL(string: "/")! }

  public var fileExists: @Sendable (_ at: URL) -> Bool = { _ in false }
  public var fileSize: @Sendable (_ at: URL) throws -> UInt64
  public var removeFile: @Sendable (_ at: URL) throws -> Void
}

public extension DependencyValues {
  var localFiles: LocalFileService {
    get { self[LocalFileService.self] }
    set { self[LocalFileService.self] = newValue }
  }
}

extension LocalFileService: TestDependencyKey {
  public static let testValue = Self()
}
