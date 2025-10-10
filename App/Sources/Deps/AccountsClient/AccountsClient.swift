//
// This file is part of prose-app-ios.
// Copyright (c) 2025 Prose Foundation
//

import Dependencies
import DependenciesMacros
import Domain
import Foundation

@DependencyClient
public struct AccountsClient: Sendable {
  /// Returns all added accounts
  public var accounts: @Sendable () -> AsyncStream<[UserId]> = { .never }

  /// Instantiates a `ProseCoreClient` adds the UserId to `availableAccounts`.
  public var addAccount: @Sendable (UserId) async throws -> Void

  /// Disconnects the account with the given UserId and removes it from `availableAccounts`.
  public var removeAccount: @Sendable (UserId) throws -> Void

  /// Returns a `ProseCoreClient` for the given UserId or throws if the UserId wasn't added
  /// using `addAccount`.
  public var client: @Sendable (_ for: UserId) throws -> ProseCoreClient

  /// Adds an ephemeral account for which a `ProseCoreClient` can be requested via
  /// `ephemeralClient`. Ephemeral accounts are not included in `accounts` unless promoted
  /// via `promoteEphemeralAccount`. Throws if a non-ephemeral account was added already.
  ///
  /// Ephemeral accounts are used for verifying and modifying an account before it can be displayed
  /// and used as a regular account in the app.
  public var addEphemeralAccount: @Sendable (UserId) async throws -> Void

  /// Disconnects and removes the ephemeral account with the given UserId. Does nothing if no
  /// ephemeral with the UserId was added.
  public var removeEphemeralAccount: @Sendable (UserId) throws -> Void

  /// Promotes an ephemeral account to `accounts`.
  public var promoteEphemeralAccount: @Sendable (UserId) throws -> Void

  /// Returns a `ProseCoreClient` for the given UserId or throws if the UserId wasn't added
  /// using `addEphemeralAccount`.
  public var ephemeralClient: @Sendable (UserId) throws -> ProseCoreClient
}

public extension DependencyValues {
  var accounts: AccountsClient {
    get { self[AccountsClient.self] }
    set { self[AccountsClient.self] = newValue }
  }
}

extension AccountsClient: TestDependencyKey {
  public static let testValue = Self()
}
