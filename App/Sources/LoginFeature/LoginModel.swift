//
// This file is part of prose-app-ios.
// Copyright (c) 2025 Prose Foundation
//

import Deps
import Domain
import Foundation
import SharedUI
import SwiftUINavigation

@MainActor @Observable
public final class LoginModel: Identifiable {
  @ObservationIgnored @Dependency(\.accountBookmarks) var bookmarks
  @ObservationIgnored @Dependency(\.credentials) var credentials
  @ObservationIgnored @Dependency(\.accounts) var accounts

  enum AlertAction {
    case ok
  }

  var alert: AlertState<AlertAction>?
  var userId: String = "" { didSet { self.validate() } }
  var password: String = "" { didSet { self.validate() } }

  private(set) var isLoggingIn = false
  private(set) var isFormValid = false

  var isLoginButtonDisabled: Bool {
    self.isLoggingIn || !self.isFormValid
  }

  public init() {}
}

extension LoginModel {
  func loginButtonTapped() {
    Task {
      do {
        try await self.performLogin()
      } catch {
        self.alert = AlertState {
          TextState("Login failed")
        } actions: {
          ButtonState(action: .send(.ok)) {
            TextState("Ok")
          }
        } message: {
          TextState(verbatim: error.localizedDescription)
        }
      }
    }
  }

  func alertActionTapped(action _: AlertAction?) {}
}

private extension LoginModel {
  func performLogin() async throws {
    self.isLoggingIn = true
    defer { self.isLoggingIn = false }

    let credentials = Credentials(id: self.userId, password: self.password)

    do {
      try await self.accounts.addEphemeralAccount(credentials.id)
      let client = try self.accounts.ephemeralClient(credentials.id)

      try await client.connect(credentials, false)

      // While it wouldn't be great if we couldn't save the credentials and bookmark, the app
      // would still be usable thus try?.
      try? self.credentials.save(credentials)
      try? await self.bookmarks.addBookmark(credentials.id)
      try self.accounts.promoteEphemeralAccount(credentials.id)
    } catch {
      try? self.accounts.removeEphemeralAccount(credentials.id)
      throw error
    }
  }
}

private extension LoginModel {
  func validate() {
    self.isFormValid =
      self.userId.contains("@") && self.userId.contains(".") && !self.password.isEmpty
  }
}
