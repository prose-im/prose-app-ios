//
// This file is part of prose-app-ios.
// Copyright (c) 2025 Prose Foundation
//

import Domain
import RoomFeature
import SharedUI
import SwiftUI

struct SidebarView: View {
  @Bindable var model: SidebarModel

  init(model: SidebarModel) {
    self.model = model
  }

  var body: some View {
    VStack {
      if self.model.sections.isEmpty {
        Text("Loading…")
      } else {
        List {
          ForEach(self.model.sections) { section in
            Section {
              ForEach(section.items) { item in
                NavigationLink {
                  RoomView(model: self.model.roomModel(for: item))
                } label: {
                  Row(item: item, avatar: self.model.avatars[item.id])
                }
              }
            } header: {
              Text(verbatim: section.name)
            }
          }
        }.listStyle(.sidebar)
      }
    }
    .task { await self.model.task() }
  }
}

private struct Row: View {
  let item: SidebarItem
  let avatar: URL?

  var body: some View {
    HStack {
      self.icon
      Text(verbatim: self.item.name)

      if let availability = self.item.availability {
        AvailabilityIndicator(availability)
          .size(8)
      }
    }
  }

  var icon: some View {
    AsyncImage(url: self.avatar) { image in
      image
        .resizable()
        .aspectRatio(contentMode: .fill)
    } placeholder: {
      Color.gray.opacity(0.2)
        .overlay(
          Image(systemName: "bubble.fill")
            .font(.caption)
            .foregroundColor(.gray.opacity(0.7)),
        )
    }
    .frame(width: 24, height: 24)
    .clipShape(RoundedRectangle(cornerRadius: 6))
  }
}
