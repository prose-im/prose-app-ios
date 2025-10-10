//
// This file is part of prose-app-ios.
// Copyright (c) 2025 Prose Foundation
//

@preconcurrency import Combine
import Dependencies
import Domain
import Foundation
import Synchronization

enum AccountError: Error {
  case unknownAccount
  case alreadyLoggedIn
}

extension AccountsClient {
  static func live(
    clientProvider: @Sendable @escaping (UserId) async throws -> ProseCoreClient = ProseCoreClient
      .live,
  ) -> Self {
    struct State {
      let accounts = CurrentValueSubject<[UserId: ProseCoreClient], Never>([:])
      var pendingAccounts = [UserId: Task<Void, Error>]()
      var ephemeralAccounts = [UserId: ProseCoreClient]()
      var pendingEphemeralAccounts = [UserId: Task<Void, Error>]()
    }

    final class StateWrapper: Sendable {
      let state = Mutex<State>(.init())

      func withLock<T>(_ body: (inout State) throws -> sending T) rethrows -> T {
        try self.state.withLock(body)
      }
    }

    let state = StateWrapper()

    return .init(
      accounts: {
        AsyncStream(state.withLock { $0.accounts.map { Array($0.keys) }.removeDuplicates().values })
      },
      addAccount: { userId in
        let task = state.withLock { unlockedState -> Task<Void, Error>? in
          guard unlockedState.accounts.value[userId] == nil else {
            return nil
          }

          if let task = unlockedState.pendingAccounts[userId] {
            return task
          }

          let task = Task {
            let client = try await clientProvider(userId)
            state.withLock {
              $0.pendingAccounts.removeValue(forKey: userId)
              $0.accounts.value[userId] = client
            }
          }
          unlockedState.pendingAccounts[userId] = task
          return task
        }

        _ = try await task?.value
      },
      removeAccount: { userId in
        let task = state.withLock { state -> Task<Void, Error>? in
          if let client = state.accounts.value.removeValue(forKey: userId) {
            return Task { try await client.disconnect() }
          }
          return state.pendingAccounts.removeValue(forKey: userId)
        }
        Task { try await task?.value }
      },
      client: { userId in
        guard let client = state.withLock({ $0.accounts.value[userId] }) else {
          throw AccountError.unknownAccount
        }
        return client
      },
      addEphemeralAccount: { userId in
        let task = try state.withLock { unlockedState -> Task<Void, Error>? in
          guard unlockedState.accounts.value[userId] == nil else {
            throw AccountError.alreadyLoggedIn
          }

          guard unlockedState.ephemeralAccounts[userId] == nil else {
            return nil
          }

          return unlockedState.pendingEphemeralAccounts[userId, default: Task {
            let client = try await clientProvider(userId)
            state.withLock {
              $0.pendingEphemeralAccounts.removeValue(forKey: userId)
              $0.ephemeralAccounts[userId] = client
            }
          }]
        }

        _ = try await task?.value
      },
      removeEphemeralAccount: { userId in
        let task = state.withLock { state -> Task<Void, Error>? in
          if let client = state.ephemeralAccounts.removeValue(forKey: userId) {
            return Task { try await client.disconnect() }
          }
          return state.pendingEphemeralAccounts.removeValue(forKey: userId)
        }
        Task { try await task?.value }
      },
      promoteEphemeralAccount: { userId in
        try state.withLock {
          guard let client = $0.ephemeralAccounts.removeValue(forKey: userId) else {
            return
          }
          guard $0.accounts.value[userId] == nil else {
            throw AccountError.alreadyLoggedIn
          }
          $0.accounts.value[userId] = client
        }
      },
      ephemeralClient: { userId in
        guard let client = state.withLock({ $0.ephemeralAccounts[userId] }) else {
          throw AccountError.unknownAccount
        }
        return client
      },
    )
  }
}

extension AccountsClient: DependencyKey {
  public static let liveValue = AccountsClient.live()
}
