//
// This file is part of prose-app-ios.
// Copyright (c) 2025 Prose Foundation
//

import Dependencies
import DependenciesMacros
import UIKit

@DependencyClient
public struct ThumbnailService: Sendable {
  public struct ImageFile: Sendable {
    public let url: URL
    public let type: UTType
    public let dimensions: CGSize
  }

  public struct VideoFile: Sendable {
    public let url: URL
    public let type: UTType
    public let duration: UInt64?
  }

  public var createThumbnailFromImage: @Sendable (_ source: UIImage) async throws -> ImageFile
  public var createThumbnailFromImageFile: @Sendable (_ source: URL) async throws -> ImageFile
  public var createThumbnailFromVideoFile: @Sendable (_ source: URL) async throws -> ImageFile

  public var downsampleImage: @Sendable (_ source: UIImage) async throws -> ImageFile
  public var downsampleImageFile: @Sendable (_ source: URL) async throws -> ImageFile
  public var downsampleVideoFile: @Sendable (_ source: URL) async throws -> VideoFile
}

public extension DependencyValues {
  var thumbnails: ThumbnailService {
    get { self[ThumbnailService.self] }
    set { self[ThumbnailService.self] = newValue }
  }
}

extension ThumbnailService: TestDependencyKey {
  public static let testValue = Self()
}
