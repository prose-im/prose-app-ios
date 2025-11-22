//
// This file is part of prose-app-ios.
// Copyright (c) 2025 Prose Foundation
//

import CryptoKit
import Dependencies
import Foundation

extension LocalFileService {
  static let live: Self = .init(
    temporaryPathForRemoteFile: { url, type, roomId in
      let fileExtension =
        type?.preferredFilenameExtension ??
        url.nonEmptyPathExtension ??
        "bin"

      var fileURL = FileManager.default.temporaryDirectory

      switch roomId {
      case let .user(userId):
        fileURL.append(path: userId.rawValue)
      case let .muc(mucId):
        fileURL.append(path: mucId.rawValue)
      case .none:
        break
      }

      fileURL.append(component: url.fileHash)
      fileURL.appendPathExtension(fileExtension)

      return fileURL
    },
    importTemporaryFile: { sourceURL in
      var importDirectory = FileManager.default.temporaryDirectory
        .appending(path: "Import")

      try FileManager.default.createDirectory(
        at: importDirectory,
        withIntermediateDirectories: true,
      )

      let targetURL = importDirectory.appendingPathComponent(sourceURL.lastPathComponent)
      try? FileManager.default.removeItem(at: targetURL)
      try FileManager.default.copyItem(at: sourceURL, to: targetURL)

      return targetURL
    },
    fileExists: { url in
      FileManager.default.fileExists(atPath: url.path)
    },
    fileSize: { url in
      try (FileManager.default.attributesOfItem(atPath: url.path)[.size] as? NSNumber)?
        .uint64Value ?? 0
    },
    removeFile: { url in
      try FileManager.default.removeItem(at: url)
    },
  )
}

extension LocalFileService: DependencyKey {
  public static let liveValue: LocalFileService = .live
}

private extension URL {
  var fileHash: String {
    SHA256.hash(data: Data(self.absoluteString.utf8))
      .prefix(8)
      .map { String(format: "%02x", $0) }
      .joined()
  }

  var nonEmptyPathExtension: String? {
    let pathExtension = self.pathExtension
    if pathExtension.isEmpty {
      return nil
    }
    return pathExtension
  }
}
