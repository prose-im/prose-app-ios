//
// This file is part of prose-app-ios.
// Copyright (c) 2025 Prose Foundation
//

import Combine
import Dependencies
import Domain
import Foundation
import UIKit

public extension DependencyValues {
  var scenePhase: ScenePhaseEffect {
    get { self[ScenePhaseKey.self] }
    set { self[ScenePhaseKey.self] = newValue }
  }
}

private enum ScenePhaseKey: DependencyKey {
  static let liveValue = ScenePhaseEffect {
    let currentPhase: ScenePhase = switch UIApplication.shared.applicationState {
    case .active:
      .active
    case .inactive:
      .inactive
    case .background:
      .background
    @unknown default:
      .active
    }

    return Publishers.MergeMany(
      NotificationCenter.default
        .publisher(for: UIApplication.didBecomeActiveNotification)
        .map { _ in ScenePhase.active },
      NotificationCenter.default
        .publisher(for: UIApplication.didEnterBackgroundNotification)
        .map { _ in ScenePhase.background },
      NotificationCenter.default
        .publisher(for: UIApplication.willResignActiveNotification)
        .map { _ in ScenePhase.inactive },
    )
    .prepend(currentPhase)
    .removeDuplicates()
    .values
  }

  static let testValue = ScenePhaseEffect {
    reportIssue(#"Unimplemented: @Dependency(\.scenePhase)"#)
    return AsyncStream.never
  }
}

public struct ScenePhaseEffect: Sendable {
  private let handler: @MainActor () -> any AsyncSequence<ScenePhase, Never>

  public init(handler: @escaping @MainActor () -> any AsyncSequence<ScenePhase, Never>) {
    self.handler = handler
  }

  @MainActor
  public func callAsFunction() -> any AsyncSequence<ScenePhase, Never> {
    self.handler()
  }
}
