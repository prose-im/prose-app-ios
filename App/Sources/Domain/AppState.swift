//
// This file is part of prose-app-ios.
// Copyright (c) 2025 Prose Foundation
//

import Sharing

public enum Connectivity: Equatable, Sendable {
  case online
  case offline
}

public enum ScenePhase: Equatable, Sendable {
  case active
  case inactive
  case background
}

public struct AppState: Sendable {
  public var connectivity: Connectivity
  public var scenePhase: ScenePhase

  public init(connectivity: Connectivity = .online, scenePhase: ScenePhase = .active) {
    self.connectivity = connectivity
    self.scenePhase = scenePhase
  }
}

public extension SharedKey where Self == InMemoryKey<AppState> {
  static var app: Self {
    inMemory("app")
  }
}
