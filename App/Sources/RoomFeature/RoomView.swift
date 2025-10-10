//
// This file is part of prose-app-ios.
// Copyright (c) 2025 Prose Foundation
//

import ChatFeature
import Domain
import IdentifiedCollections
import SwiftUI

public struct RoomView: View {
  @Bindable var model: RoomModel

  public init(model: RoomModel) {
    self.model = model
  }

  public var body: some View {
    ChatView(model: self.model.chatModel)
      .navigationBarTitle(Text(self.model.selectedItem.name))
      .navigationBarTitleDisplayMode(.inline)
  }
}
