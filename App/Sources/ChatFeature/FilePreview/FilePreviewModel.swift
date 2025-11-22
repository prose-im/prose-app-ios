//
// This file is part of prose-app-ios.
// Copyright (c) 2025 Prose Foundation
//

import CasePaths
import Deps
import Domain
import Foundation
import Toolbox

@MainActor @Observable
final class FilePreviewModel: Identifiable {
  @CasePathable
  enum State {
    case pending
    case downloading(progress: Double)
    case error(Error)
    case finished(URL)
  }

  @ObservationIgnored @Dependency(\.remoteFiles) var remoteFiles
  @ObservationIgnored @Dependency(\.localFiles) var localFiles

  let url: URL

  private let mimeType: Mime?
  private let roomId: RoomId
  private let onDismiss: () -> Void

  private(set) var state = State.pending
  private var downloadTask: Task<Void, Never>?

  init(url: URL, mimeType: Mime?, roomId: RoomId, onDismiss: @escaping () -> Void) {
    self.url = url
    self.mimeType = mimeType
    self.roomId = roomId
    self.onDismiss = onDismiss
  }

  func startDownload() async {
    if self.state.isDownloading || self.state.isFinished {
      return
    }

    self.state = .downloading(progress: 0)

    self.downloadTask = Task {
      do {
        let localURL = self.localFiles.temporaryPathForRemoteFile(
          at: self.url,
          type: self.mimeType.flatMap { UTType(mimeType: $0) },
          room: self.roomId,
        )

        if self.localFiles.fileExists(at: localURL) {
          self.state = .finished(localURL)
          return
        }

        try await self.remoteFiles
          .getFile(from: self.url, to: localURL) { [weak self] progress in
            Task { @MainActor in
              self?.state.modify(\.downloading) { value in
                value = progress
              }
            }
          }

        self.state = .finished(localURL)
      } catch is CancellationError {
        self.state = .pending
      } catch {
        self.state = .error(error)
      }
    }

    await self.downloadTask?.value
  }

  func cancelDownload() {
    self.downloadTask?.cancel()
    self.onDismiss()
  }
}

extension FilePreviewModel.State {
  var isFinished: Bool {
    if case .finished = self {
      return true
    }
    return false
  }

  var isDownloading: Bool {
    if case .downloading = self {
      return true
    }
    return false
  }
}
