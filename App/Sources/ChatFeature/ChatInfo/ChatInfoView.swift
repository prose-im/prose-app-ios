//
// This file is part of prose-app-ios.
// Copyright (c) 2025 Prose Foundation
//

import AvatarFeature
import SharedUI
import SwiftUI

struct ChatInfoView: View {
  @Bindable var model: ChatInfoModel

  init(model: ChatInfoModel) {
    self.model = model
  }

  var body: some View {
    ScrollView(.vertical) {
      VStack(alignment: .leading, spacing: 0) {
        InfoSection(model: self.model.infoSectionModel)
          .frame(maxWidth: .infinity, alignment: .leading)

        if let model = model.membersSectionModel {
          MembersSection(model: model)
        }
      }
      .groupBoxStyle(SectionGroupStyle())
      .safeAreaPadding(.top)
    }
    .background(Color(.systemGroupedBackground))
    .task { await self.model.task() }
  }
}

private struct SectionGroupStyle: GroupBoxStyle {
  func makeBody(configuration: Configuration) -> some View {
    VStack(spacing: 8) {
      VStack(alignment: .leading, spacing: 2) {
        configuration.label
          .font(.caption)
          .textCase(.uppercase)
          .foregroundColor(.secondary)
        Divider()
      }
      configuration.content
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    .padding()
  }
}
