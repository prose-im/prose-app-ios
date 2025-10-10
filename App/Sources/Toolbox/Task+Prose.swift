//
// This file is part of prose-app-ios.
// Copyright (c) 2025 Prose Foundation
//

@_exported import class Combine.AnyCancellable
import Foundation

public extension Task {
  func asCancellable() -> AnyCancellable {
    AnyCancellable {
      self.cancel()
    }
  }

  func store(in cancellables: inout Set<AnyCancellable>) {
    self.asCancellable().store(in: &cancellables)
  }
}
