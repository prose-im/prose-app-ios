//
// This file is part of prose-app-ios.
// Copyright (c) 2025 Prose Foundation
//

import ChatFeature
import Domain
import IdentifiedCollections
import SharedUI
import SwiftUI

public struct RoomView: View {
  @State var model: RoomModel

  public init(model: RoomModel) {
    self.model = model
  }

  public var body: some View {
    ZStack(alignment: .top) {
      ChatView(model: self.model.chatModel)
        .navigationBarTitle(Text(self.model.name))
        .navigationBarTitleDisplayMode(.inline)

      if self.model.account.connectionStatus != .connected {
        OfflineBanner(isConnecting: self.model.account.connectionStatus == .connecting) {
          self.model.reconnect()
        }.padding(.horizontal)
      }
    }.task {
      await self.model.task()
    }
  }
}
