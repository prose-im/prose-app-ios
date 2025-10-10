//
// This file is part of prose-app-ios.
// Copyright (c) 2025 Prose Foundation
//

import Dependencies
import DependenciesMacros
import Domain

@DependencyClient
public struct CredentialsClient: Sendable {
  public var loadCredentials: @Sendable (_ id: UserId) throws -> Credentials?
  public var save: @Sendable (_ credentials: Credentials) throws -> Void
  public var deleteCredentials: @Sendable (_ id: UserId) throws -> Void
}

public extension DependencyValues {
  var credentials: CredentialsClient {
    get { self[CredentialsClient.self] }
    set { self[CredentialsClient.self] = newValue }
  }
}
