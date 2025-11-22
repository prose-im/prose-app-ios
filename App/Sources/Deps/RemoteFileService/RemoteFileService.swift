//
// This file is part of prose-app-ios.
// Copyright (c) 2025 Prose Foundation
//

import Dependencies
import DependenciesMacros
import Foundation
import UniformTypeIdentifiers

public typealias ProgressHandler = @Sendable (Double) -> Void

public enum FileSource {
  case data(Data)
  case url(URL)
}

@DependencyClient
public struct RemoteFileService: Sendable {
  public var getFile: @Sendable (
    _ from: URL,
    _ to: URL,
    _ progress: @escaping ProgressHandler,
  ) async throws -> Void

  public var putFile: @Sendable (
    _ source: FileSource,
    _ to: URL,
    _ contentType: UTType,
    _ additionalHeaders: [String: String],
    _ progress: @escaping ProgressHandler,
  ) async throws -> Void
}

public extension DependencyValues {
  var remoteFiles: RemoteFileService {
    get { self[RemoteFileService.self] }
    set { self[RemoteFileService.self] = newValue }
  }
}

extension RemoteFileService: TestDependencyKey {
  public static let testValue = Self()
}
