// swift-tools-version: 6.2

import PackageDescription

let package = Package(
  name: "App",
  defaultLocalization: "en",
  platforms: [.iOS(.v18), .macOS(.v13)],
  products: [
    .library(name: "App", targets: ["App"]),
  ],
  dependencies: [
    //    .package(path: "../../prose-core-client/master/bindings/prose-sdk-ffi/ProseSDK"),
    .package(
      url: "https://github.com/prose-im/prose-wrapper-swift.git",
      .upToNextMajor(from: "0.0.15"),
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
  ],
  targets: [
    .feature(
      name: "App",
      dependencies: [
        "LoginFeature",
        "MainFeature",
        .product(name: "CasePaths", package: "swift-case-paths"),
      ],
    ),
    .feature(
      name: "MainFeature",
      dependencies: [
        "RoomFeature",
      ],
    ),
    .feature(
      name: "LoginFeature",
      dependencies: [
        .product(name: "SwiftUINavigation", package: "swift-navigation"),
      ],
    ),
    .feature(
      name: "RoomFeature",
      dependencies: [
        "ChatFeature",
      ],
    ),
    .feature(
      name: "ChatFeature",
      resources: [.copy("Messages/HTML")],
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
      ],
    ),
    .target(name: "Toolbox"),
    .target(name: "SharedUI"),

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
      "Deps",
      "Domain",
      "SharedUI",
      "Toolbox",
    ]

    return target(
      name: name,
      dependencies: commonDependencies + dependencies,
      resources: resources,
    )
  }
}
