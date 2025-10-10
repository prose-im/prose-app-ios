//
// This file is part of prose-app-ios.
// Copyright (c) 2025 Prose Foundation
//

import SwiftUI
import SwiftUINavigation

public struct LoginView: View {
  @Bindable var model: LoginModel

  public init(model: LoginModel) {
    self.model = model
  }

  public var body: some View {
    VStack(spacing: 0) {
      Spacer()

      Text("👋")
        .font(.system(size: 80))
        .padding(.bottom, 40)

      Text("Welcome!")
        .font(.largeTitle)
        .fontWeight(.bold)
        .padding(.bottom, 8)

      Text("Sign in to your chat account.")
        .foregroundColor(.secondary)
        .padding(.bottom, 60)

      VStack(spacing: 16) {
        TextField(text: self.$model.userId, prompt: Text("Enter your JID…")) {
          Text("Username")
        }
        .keyboardType(.emailAddress)
        .autocorrectionDisabled(true)
        .textInputAutocapitalization(.never)
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)

        SecureField(text: self.$model.password, prompt: Text("Enter your password…")) {
          Text("Password")
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
      }
      .padding(.horizontal, 24)

      Spacer()

      Button(action: {
        self.model.loginButtonTapped()
      }) {
        Text("Login to account")
          .padding()
          .frame(maxWidth: .infinity)
      }
      .buttonStyle(.borderedProminent)
      .buttonBorderShape(.roundedRectangle)
      .padding(.horizontal, 24)
      .padding(.bottom, 40)
      .disabled(self.model.isLoginButtonDisabled)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .alert(self.$model.alert) { action in
      self.model.alertActionTapped(action: action)
    }
  }
}

#Preview {
  LoginView(model: .init())
}
