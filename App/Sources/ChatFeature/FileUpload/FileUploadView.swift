//
// This file is part of prose-app-ios.
// Copyright (c) 2025 Prose Foundation
//

import PhotosUI
import SwiftUI
import UniformTypeIdentifiers

extension View {
  @ViewBuilder
  func fileUpload(model: FileUploadModel) -> some View {
    self.overlay(alignment: .bottom) {
      FileUploadView(model: model)
    }
    .fileImporter(
      isPresented: model.isFileImporterPresented,
      allowedContentTypes: [.item],
      allowsMultipleSelection: true,
    ) { result in
      model.handleFileSelection(result: result)
    }
    .photosPicker(
      isPresented: model.isPhotoPickerPresented,
      selection: model.selectedPhotoItems,
      maxSelectionCount: 3,
      preferredItemEncoding: .compatible,
    )
    .camera(isPresented: model.isCameraPresented) { image in
      model.handleCameraCapture(image: image)
    }
  }
}

private struct FileUploadView: View {
  @Bindable var model: FileUploadModel

  var body: some View {
    switch self.model.state {
    case .preparingUpload:
      ProgressToast(progress: .indeterminate("Preparing…")) {
        self.model.cancelUpload()
      }
    case let .uploading(progress):
      ProgressToast(progress: .determinate(progress)) {
        self.model.cancelUpload()
      }
    case let .error(error):
      ErrorToast(error: error) {
        self.model.cancelUpload()
      }
    case .selectingFile, .pending:
      EmptyView()
    }
  }
}

@MainActor
private extension FileUploadModel {
  var isFileImporterPresented: Binding<Bool> {
    Binding<Bool>(
      get: { self.state.is(\.selectingFile.fileImporter) == true },
      set: { _ in self.didFinishFileSelection() },
    )
  }

  var isPhotoPickerPresented: Binding<Bool> {
    Binding<Bool>(
      get: { self.state.is(\.selectingFile.photoPicker) == true },
      set: { _ in self.didFinishFileSelection() },
    )
  }

  var isCameraPresented: Binding<Bool> {
    Binding<Bool>(
      get: { self.state.is(\.selectingFile.camera) == true },
      set: { _ in self.didFinishFileSelection() },
    )
  }

  var selectedPhotoItems: Binding<[PhotosPickerItem]> {
    Binding<[PhotosPickerItem]>(
      get: { [] },
      set: { self.handlePhotoSelection(items: $0) },
    )
  }
}
