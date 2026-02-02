// swift-tools-version: 6.2

import PackageDescription

let package = Package(
  name: "App",
  defaultLocalization: "en",
  platforms: [.iOS(.v18), .macOS(.v13)],
  products: [
    .library(name: "App", targets: ["App"]),
    .library(name: "TokenTextField", targets: ["TokenTextField"]),
  ],
  dependencies: [
    //    .package(path: "../../prose-core-client/master/bindings/prose-sdk-ffi/ProseSDK"),
    .package(
      url: "https://github.com/prose-im/prose-wrapper-swift.git",
      .upToNextMajor(from: "0.0.18"),
    ),
    .package(
      url: "https://github.com/pointfreeco/swift-dependencies.git",
      .upToNextMajor(from: "1.10.0"),
    ),
    .package(
      url: "https://github.com/pointfreeco/swift-navigation.git",
      .upToNextMajor(from: "2.6.0"),
    ),
    .package(
      url: "https://github.com/pointfreeco/swift-identified-collections.git",
      .upToNextMajor(from: "1.1.1"),
    ),
    .package(
      url: "https://github.com/pointfreeco/swift-case-paths.git",
      .upToNextMajor(from: "1.7.2"),
    ),
    .package(
      url: "https://github.com/pointfreeco/swift-sharing.git",
      .upToNextMajor(from: "2.7.4"),
    ),
    .package(
      url: "https://github.com/apple/swift-async-algorithms.git",
      .upToNextMajor(from: "1.0.4"),
    ),
    .package(
      url: "https://github.com/prose-im/Elegant-Emoji-Picker.git",
      revision: "96d27fa06c3fd72870895b2b4c521a3129efc16e",
    ),
  ],
  targets: [
    .feature(
      name: "App",
      dependencies: [
        "LoginFeature",
        "MainFeature",
      ],
    ),
    .feature(
      name: "MainFeature",
      dependencies: [
        "RoomFeature",
        "RoomPickerFeature",
      ],
    ),
    .feature(
      name: "LoginFeature",
    ),
    .feature(
      name: "RoomFeature",
      dependencies: [
        "ChatFeature",
      ],
    ),
    .feature(
      name: "ChatFeature",
      dependencies: [
        "MessageListFeature",
        "RoomPickerFeature",
        .product(name: "ElegantEmojiPicker", package: "Elegant-Emoji-Picker"),
      ],
      resources: [
        .process("Assets.xcassets"),
      ],
    ),
    .feature(
      name: "MessageListFeature",
      resources: [
        .copy("HTML"),
      ],
    ),
    .feature(
      name: "RoomPickerFeature",
    ),

    .target(
      name: "AvatarFeature",
      dependencies: [
        "Deps",
        "Domain",
      ],
    ),
    .target(
      name: "Domain",
      dependencies: [
        "Toolbox",
//        .product(name: "ProseSDK", package: "ProseSDK"),
        .product(name: "ProseSDK", package: "prose-wrapper-swift"),
        .product(name: "IdentifiedCollections", package: "swift-identified-collections"),
        .product(name: "Sharing", package: "swift-sharing"),
      ],
      linkerSettings: [
        .linkedLibrary("sqlite3.0"),
      ],
    ),
    .target(
      name: "Deps",
      dependencies: [
        "Domain",
        "Toolbox",
        .product(name: "Dependencies", package: "swift-dependencies"),
        .product(name: "DependenciesMacros", package: "swift-dependencies"),
        .product(name: "AsyncAlgorithms", package: "swift-async-algorithms"),
      ],
    ),
    .target(name: "Toolbox"),
    .target(name: "TokenTextField"),
    .target(
      name: "SharedUI",
      dependencies: [
        "Domain",
        "TokenTextField",
      ],
    ),

    .testTarget(
      name: "DepsTests",
      dependencies: ["Deps"],
    ),
  ],
)

extension Target {
  static func feature(
    name: String,
    dependencies: [PackageDescription.Target.Dependency] = [],
    resources: [PackageDescription.Resource]? = nil,
  ) -> PackageDescription.Target {
    let commonDependencies: [Target.Dependency] = [
      "AvatarFeature",
      "Deps",
      "Domain",
      "SharedUI",
      "Toolbox",
      .product(name: "CasePaths", package: "swift-case-paths"),
      .product(name: "SwiftUINavigation", package: "swift-navigation"),
    ]

    return target(
      name: name,
      dependencies: commonDependencies + dependencies,
      resources: resources,
    )
  }
}
