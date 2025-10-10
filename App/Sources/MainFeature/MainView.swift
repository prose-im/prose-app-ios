//
// This file is part of prose-app-ios.
// Copyright (c) 2025 Prose Foundation
//

import SwiftUI

public struct MainView: View {
  @Bindable var model: MainModel

  public init(model: MainModel) {
    self.model = model
  }

  public var body: some View {
    NavigationSplitView {
      VStack(spacing: 0) {
        AccountView(model: self.model.accountModel)
        SidebarView(model: self.model.sidebarModel)
      }
    } detail: {
      Text("No room selected")
    }
  }
}
