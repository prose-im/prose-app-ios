//
// This file is part of prose-app-ios.
// Copyright (c) 2025 Prose Foundation
//

import _PhotosUI_SwiftUI
import AVFoundation
import CasePaths
import CoreTransferable
import Deps
import Domain
import Foundation
import PhotosUI
import Synchronization
import UniformTypeIdentifiers

@MainActor @Observable
final class FileUploadModel: Identifiable {
  @CasePathable
  enum Route {
    case camera
    case photoPicker
    case fileImporter
  }

  @CasePathable
  enum State {
    case pending
    case selectingFile(Route)
    case preparingUpload
    case uploading(progress: Double)
    case error(Error)
  }

  @ObservationIgnored @Dependency(\.client) var client
  @ObservationIgnored @Dependency(\.room) var room
  @ObservationIgnored @Dependency(\.remoteFiles) var remoteFiles
  @ObservationIgnored @Dependency(\.localFiles) var localFiles
  @ObservationIgnored @Dependency(\.thumbnails) var thumbnails
  @ObservationIgnored @Dependency(\.logger[category: "FileUpload"]) var logger

  var state = State.pending

  private var uploadTask: Task<Void, Never>?

  init() {}

  func selectFileForUploading(source: FileUploadModel.Route) {
    self.state = .selectingFile(source)
  }

  func handlePhotoSelection(items: [PhotosPickerItem]) {
    self.uploadTask?.cancel()

    guard !items.isEmpty else {
      return
    }

    self.state = .preparingUpload

    self.uploadTask = Task {
      do {
        let pendingUploads = try await withThrowingTaskGroup(
          of: (Int, PendingUpload?).self,
        ) { @Sendable group in
          for (idx, item) in items.enumerated() {
            group.addTask {
              try await withDependencies(from: self) {
                if let movie = try await item.loadTransferable(type: MovieFile.self) {
                  (idx, .videoFile(movie.url))
                } else if let image = try await item.loadTransferable(type: ImageFile.self) {
                  (idx, .imageFile(image.url))
                } else {
                  (idx, nil)
                }
              }
            }
          }

          let pendingUploads = try await group.reduce(
            into: Array(repeating: nil, count: items.count),
          ) { files, item in
            let (idx, file) = item
            files[idx] = file
          }

          return pendingUploads.compactMap(\.self)
        }

        await self.prepareAndSend(pendingUploads: pendingUploads)
      } catch {
        self.state = .error(error)
      }
    }
  }

  func handleFileSelection(result: Result<[URL], Error>) {
    self.uploadTask?.cancel()

    self.state = .preparingUpload

    self.uploadTask = Task {
      self.state = .preparingUpload

      do {
        let urls = try result.get()

        let pendingUploads = try urls.compactMap { url -> PendingUpload? in
          guard url.startAccessingSecurityScopedResource() else {
            return nil
          }
          defer { url.stopAccessingSecurityScopedResource() }

          let mediaType = UTType(filenameExtension: url.pathExtension) ?? .data
          let localURL = try self.localFiles.importTemporaryFile(from: url)

          return switch mediaType {
          case _ where mediaType.conforms(to: .image):
            PendingUpload.imageFile(localURL)
          case _ where mediaType.conforms(to: .movie):
            PendingUpload.videoFile(localURL)
          default:
            PendingUpload.document(localURL, mediaType)
          }
        }

        await self.prepareAndSend(pendingUploads: pendingUploads)
      } catch {
        self.state = .error(error)
      }
    }
  }

  func handleCameraCapture(image: ImageData) {
    self.uploadTask?.cancel()

    self.state = .preparingUpload

    self.uploadTask = Task {
      let pendingUpload = switch image {
      case let .image(image):
        PendingUpload.image(image)
      case let .file(url):
        PendingUpload.imageFile(url)
      }
      await self.prepareAndSend(pendingUploads: [pendingUpload])
    }
  }

  func cancelUpload() {
    self.uploadTask?.cancel()
    self.state = .pending
  }

  func didFinishFileSelection() {
    guard self.state.is(\.selectingFile) else {
      return
    }
    self.state = .pending
  }
}

private extension FileUploadModel {
  enum PendingUpload: Sendable {
    case image(UIImage)
    case imageFile(URL)
    case videoFile(URL)
    case document(URL, UTType)
  }

  struct PendingAttachment: Sendable {
    struct Document: Sendable {
      let url: URL
      let type: UTType
    }

    typealias Image = ThumbnailService.ImageFile
    typealias Video = ThumbnailService.VideoFile

    enum File {
      case image(Image)
      case video(Video)
      case document(Document)
    }

    let file: File
    let thumbnail: Image?
  }

  struct MovieFile: Transferable, Sendable {
    let url: URL

    static var transferRepresentation: some TransferRepresentation {
      FileRepresentation(contentType: .movie) { movie in
        SentTransferredFile(movie.url)
      } importing: { received in
        @Dependency(\.localFiles) var localFiles
        let url = try localFiles.importTemporaryFile(from: received.file)
        return Self(url: url)
      }
    }
  }

  struct ImageFile: Transferable, Sendable {
    let url: URL

    static var transferRepresentation: some TransferRepresentation {
      FileRepresentation(contentType: .image) { image in
        SentTransferredFile(image.url)
      } importing: { received in
        @Dependency(\.localFiles) var localFiles
        let url = try localFiles.importTemporaryFile(from: received.file)
        return Self(url: url)
      }
    }
  }
}

extension FileUploadModel.PendingAttachment.File {
  var url: URL {
    switch self {
    case let .image(image):
      image.url
    case let .video(video):
      video.url
    case let .document(document):
      document.url
    }
  }
}

private extension FileUploadModel {
  func prepareAndSend(pendingUploads: [PendingUpload]) async {
    do {
      let pendingAttachments = try await Self.prepare(
        pendingUploads: pendingUploads,
        thumbnailService: self.thumbnails,
      )

      self.state = .uploading(progress: 0)

      let attachments = try await Self.upload(
        pendingAttachments: pendingAttachments,
        client: self.client,
        localFileService: self.localFiles,
        remoteFileService: self.remoteFiles,
      ) { [weak self] progress in
        Task { @MainActor in
          self?.state.modify(\.uploading) { value in
            value = progress
          }
        }
      }

      try await self.room.baseRoom.sendMessage(request: .init(
        body: .init(text: "Shared \(attachments.count) file(s)"),
        attachments: attachments,
      ))

      self.state = .pending
    } catch {
      self.state = .error(error)
    }
  }

  static func prepare(
    pendingUploads: [PendingUpload],
    thumbnailService: ThumbnailService,
  ) async throws -> [PendingAttachment] {
    try await withThrowingTaskGroup(
      of: (Int, PendingAttachment).self,
    ) { @Sendable group in
      for (idx, pendingUpload) in pendingUploads.enumerated() {
        group.addTask {
          let file: PendingAttachment.File
          let thumbnail: PendingAttachment.Image?

          switch pendingUpload {
          case let .image(image):
            async let imageTask = thumbnailService.downsampleImage(source: image)
            async let thumbnailTask = thumbnailService.createThumbnailFromImage(image)
            let (imageFile, imageThumbnail) = try await (imageTask, thumbnailTask)
            file = .image(imageFile)
            thumbnail = imageThumbnail

          case let .imageFile(url):
            async let imageTask = thumbnailService.downsampleImageFile(source: url)
            async let thumbnailTask = thumbnailService.createThumbnailFromImageFile(source: url)
            let (imageFile, imageThumbnail) = try await (imageTask, thumbnailTask)
            file = .image(imageFile)
            thumbnail = imageThumbnail

          case let .videoFile(url):
            async let videoTask = thumbnailService.downsampleVideoFile(source: url)
            async let thumbnailTask = thumbnailService.createThumbnailFromVideoFile(source: url)
            let (videoFile, videoThumbnail) = try await (videoTask, thumbnailTask)
            file = .video(videoFile)
            thumbnail = videoThumbnail

          case let .document(url, type):
            file = .document(.init(url: url, type: type))
            thumbnail = nil
          }

          return (idx, .init(file: file, thumbnail: thumbnail))
        }
      }

      return try await group
        .reduce(into: Array(repeating: nil, count: pendingUploads.count)) { files, item in
          let (idx, file) = item
          files[idx] = file
        }
        .compactMap(\.self)
    }
  }

  static func upload(
    pendingAttachments: [PendingAttachment],
    client: ProseCoreClient,
    localFileService: LocalFileService,
    remoteFileService: RemoteFileService,
    progress progressHandler: @escaping @Sendable (Double) -> Void,
  ) async throws -> [Attachment] {
    try await withThrowingTaskGroup(
      of: (Int, Attachment).self,
    ) { @Sendable group in
      let fileSizes = try Dictionary(
        pendingAttachments.flatMap { pendingAttachment in
          var fileSizes = try [(
            pendingAttachment.file.url,
            localFileService.fileSize(at: pendingAttachment.file.url),
          )]

          if let thumbnail = pendingAttachment.thumbnail {
            try fileSizes.append((
              thumbnail.url,
              localFileService.fileSize(at: thumbnail.url),
            ))
          }

          return fileSizes
        },
        uniquingKeysWith: { (_, last: UInt64) in last },
      )

      let totalNumberOfBytes = Int64(fileSizes.values.reduce(0, +))
      let numberOfBytesUploaded = Mutex(Int64(0))

      @Sendable func addUploadedBytes(bytes: Int64) {
        let progress = numberOfBytesUploaded.withLock { value in
          value += bytes
          return Double(min(totalNumberOfBytes, value)) / Double(totalNumberOfBytes)
        }
        progressHandler(progress)
      }

      for (idx, pendingAttachment) in pendingAttachments.enumerated() {
        group.addTask { @Sendable in
          let url: URL
          let mediaType: UTType

          switch pendingAttachment.file {
          case let .image(image):
            url = image.url
            mediaType = image.type

          case let .video(video):
            url = video.url
            mediaType = video.type

          case let .document(document):
            url = document.url
            mediaType = document.type
          }

          let fileSlot = try await client.requestUploadSlot(
            fileName: url.lastPathComponent,
            fileSize: fileSizes[url] ?? 0,
            mediaType: mediaType.preferredMIMEType ?? "application/octet-stream",
          )

          try await remoteFileService.putFile(
            source: .url(url),
            to: fileSlot.uploadUrl,
            contentType: mediaType,
            additionalHeaders: Dictionary(
              fileSlot.uploadHeaders.map { ($0.name, $0.value) },
              uniquingKeysWith: { _, last in last },
            ),
          ) { progress in
            addUploadedBytes(bytes: Int64(progress * Double(fileSlot.fileSize)))
          }

          var attachmentThumbnail: Thumbnail? = nil

          if let thumbnail = pendingAttachment.thumbnail {
            let thumbnailSlot = try await client.requestUploadSlot(
              fileName: thumbnail.url.lastPathComponent,
              fileSize: fileSizes[thumbnail.url] ?? 0,
              mediaType: thumbnail.type.preferredMIMEType ?? "application/octet-stream",
            )

            try await remoteFileService.putFile(
              source: .url(thumbnail.url),
              to: thumbnailSlot.uploadUrl,
              contentType: thumbnail.type,
              additionalHeaders: Dictionary(
                thumbnailSlot.uploadHeaders.map { ($0.name, $0.value) },
                uniquingKeysWith: { _, last in last },
              ),
            ) { progress in
              addUploadedBytes(bytes: Int64(progress * Double(fileSlot.fileSize)))
            }

            attachmentThumbnail = .init(
              url: thumbnailSlot.downloadUrl,
              mediaType: thumbnailSlot.mediaType,
              width: UInt32(thumbnail.dimensions.width),
              height: UInt32(thumbnail.dimensions.height),
            )
          }

          let attachmentType: AttachmentType = switch pendingAttachment.file {
          case .image:
            .image(thumbnail: attachmentThumbnail)
          case let .video(video):
            .video(duration: video.duration, thumbnail: attachmentThumbnail)
          case .document:
            .file
          }

          let attachment = Attachment(
            type: attachmentType,
            url: fileSlot.downloadUrl,
            mediaType: fileSlot.mediaType,
            fileName: fileSlot.fileName,
            fileSize: fileSlot.fileSize,
          )

          return (idx, attachment)
        }
      }

      return try await group
        .reduce(into: Array(repeating: nil, count: pendingAttachments.count)) { attachments, item in
          let (idx, attachment) = item
          attachments[idx] = attachment
        }
        .compactMap(\.self)
    }
  }
}
