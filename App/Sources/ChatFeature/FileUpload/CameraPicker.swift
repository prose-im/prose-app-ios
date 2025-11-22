//
// This file is part of prose-app-ios.
// Copyright (c) 2025 Prose Foundation
//

import SwiftUI

enum ImageData {
  case image(UIImage)
  case file(URL)
}

extension View {
  func camera(
    isPresented: Binding<Bool>,
    onCapture: @escaping (ImageData) -> Void,
  ) -> some View {
    self.fullScreenCover(isPresented: isPresented) {
      CameraPicker(onCapture: onCapture)
        .ignoresSafeArea()
    }
  }
}

private struct CameraPicker: UIViewControllerRepresentable {
  let onCapture: (ImageData) -> Void
  @Environment(\.dismiss) private var dismiss

  func makeUIViewController(context: Context) -> UIImagePickerController {
    let ctrl = UIImagePickerController()
    ctrl.sourceType = .camera
    ctrl.cameraCaptureMode = .photo
    ctrl.delegate = context.coordinator
    return ctrl
  }

  func updateUIViewController(_: UIImagePickerController, context _: Context) {}

  func makeCoordinator() -> Coordinator {
    Coordinator(onCapture: self.onCapture, dismiss: self.dismiss)
  }

  final class Coordinator: NSObject, UIImagePickerControllerDelegate,
    UINavigationControllerDelegate
  {
    let onCapture: (ImageData) -> Void
    let dismiss: DismissAction

    init(onCapture: @escaping (ImageData) -> Void, dismiss: DismissAction) {
      self.onCapture = onCapture
      self.dismiss = dismiss
    }

    func imagePickerController(
      _: UIImagePickerController,
      didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any],
    ) {
      if let image = info[.editedImage] as? UIImage {
        self.onCapture(.image(image))
        return
      }

      if let url = info[.imageURL] as? URL {
        self.onCapture(.file(url))
        return
      }

      if let image = info[.originalImage] as? UIImage {
        self.onCapture(.image(image))
        return
      }

      self.dismiss()
    }

    func imagePickerControllerDidCancel(_: UIImagePickerController) {
      self.dismiss()
    }
  }
}
