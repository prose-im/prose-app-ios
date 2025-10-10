//
// This file is part of prose-app-ios.
// Copyright (c) 2025 Prose Foundation
//

import RoomFeature
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
                  RoomView(model: RoomModel(
                    sessionState: self.model.$sessionState,
                    selectedItem: item,
                  ))
                } label: {
                  HStack {
                    AsyncImage(url: self.model.avatars[item.id]) { image in
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

                    Text(verbatim: item.name)
                  }
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
