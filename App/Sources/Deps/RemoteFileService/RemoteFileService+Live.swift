//
// This file is part of prose-app-ios.
// Copyright (c) 2025 Prose Foundation
//

import Dependencies
import Foundation
import Synchronization

struct InvalidServerResponse: Error {}

extension RemoteFileService {
  static func live(urlSession: URLSession = .shared) -> Self {
    .init(
      getFile: { from, to, progress in
        try await urlSession.prose_download(from: from, to: to, progressHandler: progress)
      },
      putFile: { source, to, contentType, additionalHeaders, progress in
        var request = URLRequest(url: to)
        request.httpMethod = "PUT"

        for (header, value) in additionalHeaders {
          request.setValue(value, forHTTPHeaderField: header)
        }
        request.setValue(contentType.preferredMIMEType, forHTTPHeaderField: "Content-Type")

        let (_, response) = switch source {
        case let .url(url):
          try await urlSession.prose_upload(
            with: request,
            fromFile: url,
            progressHandler: progress,
          )

        case let .data(data):
          try await urlSession.prose_upload(
            with: request,
            data: data,
            progressHandler: progress,
          )
        }

        guard
          let response = response as? HTTPURLResponse,
          (200..<300).contains(response.statusCode)
        else {
          throw InvalidServerResponse()
        }
      },
    )
  }
}

extension RemoteFileService: DependencyKey {
  public static let liveValue: RemoteFileService = .live()
}

extension URLSession {
  func prose_download(
    from url: URL,
    to localURL: URL,
    progressHandler: @escaping ProgressHandler,
  ) async throws {
    // Unfortunately the newer async variant of URLSession.download(from:delegate:) doesn't report
    // progress to the passed in delegate. So we have to resort to the old API…

    let taskMutex = Mutex<URLSessionDownloadTask?>(nil)

    return try await withTaskCancellationHandler {
      try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<
        Void,
        any Error,
      >) in
        let task = self.downloadTask(with: url) { tmpURL, _, error in
          if let error {
            continuation.resume(throwing: error)
            return
          }

          guard let tmpURL else {
            continuation.resume(throwing: URLError(.badServerResponse))
            return
          }

          do {
            let destinationDirectory = localURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(
              at: destinationDirectory,
              withIntermediateDirectories: true,
              attributes: nil,
            )
            try FileManager.default.moveItem(at: tmpURL, to: localURL)
          } catch {
            continuation.resume(throwing: error)
            return
          }

          continuation.resume()
        }

        taskMutex.withLock { $0 = task }

        // Observe progress
        let observation = task.progress.observe(\.fractionCompleted) { progress, _ in
          progressHandler(progress.fractionCompleted)
        }

        // Store observation to keep it alive for the duration of the download
        objc_setAssociatedObject(
          task,
          "progressObservation",
          observation,
          .OBJC_ASSOCIATION_RETAIN,
        )

        task.resume()
      }
    } onCancel: {
      taskMutex.withLock { $0?.cancel() }
    }
  }

  func prose_upload(
    with request: URLRequest,
    data: Data,
    progressHandler: @escaping ProgressHandler,
  ) async throws -> (Data, URLResponse) {
    try await self.prose_upload(
      buildTask: { session, completion in
        session.uploadTask(with: request, from: data, completionHandler: completion)
      },
      progressHandler: progressHandler,
    )
  }

  func prose_upload(
    with request: URLRequest,
    fromFile url: URL,
    progressHandler: @escaping ProgressHandler,
  ) async throws -> (Data, URLResponse) {
    try await self.prose_upload(
      buildTask: { session, completion in
        session.uploadTask(with: request, fromFile: url, completionHandler: completion)
      },
      progressHandler: progressHandler,
    )
  }

  func prose_upload(
    buildTask: (URLSession, @Sendable @escaping (Data?, URLResponse?, Error?) -> Void)
      -> URLSessionUploadTask,
    progressHandler: @escaping ProgressHandler,
  ) async throws -> (Data, URLResponse) {
    let taskMutex = Mutex<URLSessionUploadTask?>(nil)

    return try await withTaskCancellationHandler {
      try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<
        (Data, URLResponse),
        any Error,
      >) in
        let task = buildTask(self) { data, response, error in
          if let error {
            continuation.resume(throwing: error)
            return
          }

          guard let data, let response else {
            continuation.resume(throwing: URLError(.badServerResponse))
            return
          }

          continuation.resume(returning: (data, response))
        }

        taskMutex.withLock { $0 = task }

        let observation = task.progress.observe(\.fractionCompleted) { progress, _ in
          progressHandler(progress.fractionCompleted)
        }

        objc_setAssociatedObject(
          task,
          "progressObservation",
          observation,
          .OBJC_ASSOCIATION_RETAIN,
        )

        task.resume()
      }
    } onCancel: {
      taskMutex.withLock { $0?.cancel() }
    }
  }
}
