//
// This file is part of prose-app-ios.
// Copyright (c) 2025 Prose Foundation
//

import Domain
import LoginFeature
import MainFeature
import SwiftUI

public struct AppView: View {
  @Bindable var model: AppModel

  public init() {
    self.model = AppModel()
  }

  public var body: some View {
    self.mainContent
      .fullScreenCover(item: self.$model.login) { model in
        NavigationStack {
          LoginView(model: model)
        }
      }
      // Prevent presentation animation of LoginView
      .transaction { transaction in
        if self.model.login != nil {
          transaction.disablesAnimations = true
        }
      }
      .task { await self.model.task() }
  }

  @ViewBuilder
  private var mainContent: some View {
    switch self.model.route {
    case let .main(model):
      MainView(model: model)
    case .noAccounts:
      ContentUnavailableView("No account", systemImage: "person.crop.circle")
    }
  }
}

#Preview {
  AppView()
}
