//
// This file is part of prose-app-ios.
// Copyright (c) 2025 Prose Foundation
//

import AsyncAlgorithms
import Dependencies
import Domain
import Foundation
import Network

public extension DependencyValues {
  var connectivity: ConnectivityEffect {
    get { self[ConnectivityKey.self] }
    set { self[ConnectivityKey.self] = newValue }
  }
}

private enum ConnectivityKey: DependencyKey {
  static let liveValue = ConnectivityEffect {
    chain(
      [.online].async,
      NWPathMonitor().map { path in
        switch path.status {
        case .satisfied:
          .online
        case .unsatisfied, .requiresConnection:
          .offline
        @unknown default:
          .offline
        }
      },
    )
    .removeDuplicates()
  }

  static let testValue = ConnectivityEffect {
    reportIssue(#"Unimplemented: @Dependency(\.connectivity)"#)
    return AsyncStream.never
  }
}

public struct ConnectivityEffect: Sendable {
  private let handler: @Sendable () -> any AsyncSequence<Connectivity, Never>

  public init(handler: @escaping @Sendable () -> any AsyncSequence<Connectivity, Never>) {
    self.handler = handler
  }

  public func callAsFunction() -> any AsyncSequence<Connectivity, Never> {
    self.handler()
  }
}
