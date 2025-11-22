//
// This file is part of prose-app-ios.
// Copyright (c) 2025 Prose Foundation
//

import AVFoundation
import Dependencies
import UIKit

private extension ThumbnailService {
  static let maximumImagePixelSize = 4096
  static let maximumThumbnailPixelSize = 512
  static let maximumCompressionQuality = Float(0.8)
  static let maximumVideoQuality = AVAssetExportPresetMediumQuality
}

extension ThumbnailService {
  static let live: Self = .init(
    createThumbnailFromImage: { image in
      try await Deps.downsampleImage(
        image,
        maxPixelSize: ThumbnailService.maximumThumbnailPixelSize,
      )
    },
    createThumbnailFromImageFile: { url in
      try await Deps.downsampleImage(
        url: url,
        maxPixelSize: ThumbnailService.maximumThumbnailPixelSize,
      )
    },
    createThumbnailFromVideoFile: { url in
      let asset = AVURLAsset(url: url)
      let imageGenerator = AVAssetImageGenerator(asset: asset)
      imageGenerator.appliesPreferredTrackTransform = true
      let (image, _) = try await imageGenerator.image(at: .zero)

      return try await Deps.downsampleImage(
        image,
        maxPixelSize: ThumbnailService.maximumThumbnailPixelSize,
      )
    },
    downsampleImage: { image in
      try await Deps.downsampleImage(
        image,
        maxPixelSize: ThumbnailService.maximumImagePixelSize,
      )
    },
    downsampleImageFile: { url in
      try await Deps.downsampleImage(
        url: url,
        maxPixelSize: ThumbnailService.maximumImagePixelSize,
      )
    },
    downsampleVideoFile: { url in
      let targetURL = try targetURL(for: url, targetMediaType: .mpeg4Movie)
      let duration = try await downsampleVideo(sourceURL: url, targetURL: targetURL)

      return .init(
        url: targetURL,
        type: .mpeg4Movie,
        duration: duration,
      )
    },
  )
}

extension ThumbnailService: DependencyKey {
  public static let liveValue: ThumbnailService = .live
}

private enum DownsamplingError: Error {
  case couldNotConvertToCGImage
  case couldNotCreateExportSession
  case couldNotReadImageData
  case couldNotDownsampleImage
  case couldNotCreateImageDestination
  case invalidInputImage
  case couldNotFinalizeImage
  case couldNotGenerateJPEGData
}

private func targetURL(for sourceURL: URL?, targetMediaType: UTType) throws -> URL {
  let directory = FileManager.default
    .temporaryDirectory
    .appending(path: "PendingUploads")

  try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

  let targetURL = directory
    .appending(component: sourceURL?.lastPathComponent ?? UUID().uuidString)
    .appendingPathExtension(targetMediaType.preferredFilenameExtension ?? "bin")

  try? FileManager.default.removeItem(at: targetURL)

  return targetURL
}

@concurrent
private func downsampleImage(
  _ image: CGImage,
  maxPixelSize: Int,
) async throws -> ThumbnailService.ImageFile {
  let targetURL = try targetURL(for: nil, targetMediaType: .jpeg)
  let resizedImage = try image.prose_downsampled(maxPixelSize: maxPixelSize)

  guard let thumbnail = resizedImage.prose_jpegData(
    compressionQuality: ThumbnailService.maximumCompressionQuality,
  ) else {
    throw DownsamplingError.couldNotGenerateJPEGData
  }
  try thumbnail.write(to: targetURL)

  return .init(
    url: targetURL,
    type: .jpeg,
    dimensions: CGSize(width: resizedImage.width, height: resizedImage.height),
  )
}

@concurrent
private func downsampleImage(
  _ image: UIImage,
  maxPixelSize: Int,
) async throws -> ThumbnailService.ImageFile {
  let targetURL = try targetURL(for: nil, targetMediaType: .jpeg)
  let resizedImage = try image.prose_downsampled(maxPixelSize: maxPixelSize)

  guard let thumbnail = resizedImage.jpegData(
    compressionQuality: CGFloat(ThumbnailService.maximumCompressionQuality),
  ) else {
    throw DownsamplingError.couldNotGenerateJPEGData
  }
  try thumbnail.write(to: targetURL)

  return .init(
    url: targetURL,
    type: .jpeg,
    dimensions: CGSize(width: resizedImage.size.width, height: resizedImage.size.height),
  )
}

@concurrent
private func downsampleImage(
  url: URL,
  maxPixelSize: Int,
) async throws -> ThumbnailService.ImageFile {
  let targetURL = try targetURL(for: nil, targetMediaType: .jpeg)

  let dimensions = try downsampleImage(
    sourceURL: url,
    targetURL: targetURL,
    maxPixelSize: maxPixelSize,
    compressionRatio: ThumbnailService.maximumCompressionQuality,
  )

  return .init(
    url: targetURL,
    type: .jpeg,
    dimensions: dimensions,
  )
}

private func downsampleVideo(sourceURL: URL, targetURL: URL) async throws -> UInt64 {
  precondition(sourceURL != targetURL)

  let asset = AVURLAsset(url: sourceURL)

  guard let exportSession = AVAssetExportSession(
    asset: asset,
    presetName: ThumbnailService.maximumVideoQuality,
  ) else {
    throw DownsamplingError.couldNotCreateExportSession
  }

  exportSession.shouldOptimizeForNetworkUse = true
  try await exportSession.export(to: targetURL, as: .mp4)

  let duration = try await asset.load(.duration)
  return UInt64(duration.seconds)
}

private func downsampleImage(
  sourceURL: URL,
  targetURL: URL,
  maxPixelSize: Int,
  compressionRatio: Float,
) throws -> CGSize {
  let sourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary

  guard let imageSource = CGImageSourceCreateWithURL(sourceURL as CFURL, sourceOptions) else {
    throw DownsamplingError.couldNotReadImageData
  }

  return try imageSource.prose_downsample(
    to: targetURL,
    maxPixelSize: maxPixelSize,
    compressionRatio: compressionRatio,
  )
}

private extension CGImageSource {
  func prose_downsample(
    to targetURL: URL,
    maxPixelSize: Int,
    compressionRatio: Float,
  ) throws -> CGSize {
    let downsampleOptions = [
      kCGImageSourceCreateThumbnailFromImageAlways: true,
      kCGImageSourceCreateThumbnailWithTransform: true,
      kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
      kCGImageSourceShouldCacheImmediately: true,
    ] as CFDictionary

    guard let thumbnail = CGImageSourceCreateThumbnailAtIndex(self, 0, downsampleOptions) else {
      throw DownsamplingError.couldNotDownsampleImage
    }

    guard let imageDestination =
      CGImageDestinationCreateWithURL(
        targetURL as CFURL,
        UTType.jpeg.identifier as CFString,
        1,
        nil,
      )
    else {
      throw DownsamplingError.couldNotCreateImageDestination
    }

    let destinationProperties = [
      kCGImageDestinationLossyCompressionQuality: compressionRatio,
    ] as CFDictionary

    CGImageDestinationAddImage(imageDestination, thumbnail, destinationProperties)
    CGImageDestinationFinalize(imageDestination)

    return CGSize(width: thumbnail.width, height: thumbnail.height)
  }
}

private extension UIImage {
  func prose_downsampled(maxPixelSize: Int) throws -> UIImage {
    let imageSize = self.size

    guard Int(max(imageSize.width, imageSize.height)) > maxPixelSize else {
      return self
    }

    let widthRatio = CGFloat(maxPixelSize) / imageSize.width
    let heightRatio = CGFloat(maxPixelSize) / imageSize.height
    let scaleFactor = min(widthRatio, heightRatio)
    let newSize = CGSize(
      width: imageSize.width * scaleFactor,
      height: imageSize.height * scaleFactor,
    )

    let renderer = UIGraphicsImageRenderer(size: newSize)
    let image = renderer.image { _ in
      self.draw(in: CGRect(origin: .zero, size: newSize))
    }

    return image
  }
}

private extension CGImage {
  func prose_downsampled(maxPixelSize: Int) throws -> CGImage {
    let imageSize = CGSize(
      width: self.width,
      height: self.height,
    )

    guard Int(max(imageSize.width, imageSize.height)) > maxPixelSize else {
      return self
    }

    let widthRatio = CGFloat(maxPixelSize) / imageSize.width
    let heightRatio = CGFloat(maxPixelSize) / imageSize.height
    // Scale to fit
    let scaleFactor = min(widthRatio, heightRatio)
    let newSize = CGSize(
      width: imageSize.width * scaleFactor,
      height: imageSize.height * scaleFactor,
    )

    guard let colorSpace = self.colorSpace else {
      throw DownsamplingError.invalidInputImage
    }

    guard let context = CGContext(
      data: nil,
      width: Int(newSize.width),
      height: Int(newSize.height),
      bitsPerComponent: self.bitsPerComponent,
      bytesPerRow: self.bytesPerRow,
      space: colorSpace,
      bitmapInfo: self.alphaInfo.rawValue,
    ) else {
      throw DownsamplingError.couldNotCreateImageDestination
    }

    context.interpolationQuality = .high
    context.draw(self, in: CGRect(origin: .zero, size: newSize))

    guard let image = context.makeImage() else {
      throw DownsamplingError.couldNotFinalizeImage
    }

    return image
  }

  func prose_jpegData(compressionQuality: Float) -> Data? {
    guard let buffer = CFDataCreateMutable(nil, 0) else {
      return nil
    }

    guard let imageDestination =
      CGImageDestinationCreateWithData(buffer, UTType.jpeg.identifier as CFString, 1, nil)
    else {
      return nil
    }

    let destinationProperties = [
      kCGImageDestinationLossyCompressionQuality: compressionQuality,
    ] as CFDictionary

    CGImageDestinationAddImage(imageDestination, self, destinationProperties)
    CGImageDestinationFinalize(imageDestination)

    return buffer as Data
  }
}
