//
// This file is part of prose-app-ios.
// Copyright (c) 2025 Prose Foundation
//

import SwiftUI

extension View {
  @ViewBuilder
  func filePreview(model: Binding<FilePreviewModel?>) -> some View {
    self.overlay(alignment: .bottom) {
      if let model = model.wrappedValue {
        FilePreviewView(model: model)
      }
    }
    .quickLookPreview(model.downloadedURL)
  }
}

private struct FilePreviewView: View {
  @Bindable var model: FilePreviewModel

  var body: some View {
    Group {
      switch self.model.state {
      case .pending:
        ProgressToast(progress: .determinate(0)) {
          self.model.cancelDownload()
        }
      case let .downloading(progress):
        ProgressToast(progress: .determinate(progress)) {
          self.model.cancelDownload()
        }
      case let .error(error):
        ErrorToast(error: error) {
          self.model.cancelDownload()
        }
      case .finished:
        EmptyView()
      }
    }
    .task {
      await self.model.startDownload()
    }
  }
}

@MainActor
private extension Binding<FilePreviewModel?> {
  var downloadedURL: Binding<URL?> {
    Binding<URL?>(
      get: { self.wrappedValue?.state[case: \.finished] },
      set: { _ in self.wrappedValue?.cancelDownload() },
    )
  }
}
