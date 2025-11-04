//
// This file is part of prose-app-ios.
// Copyright (c) 2025 Prose Foundation
//

import AvatarFeature
import Domain
import RoomFeature
import RoomPickerFeature
import SharedUI
import SwiftUI
import SwiftUINavigation

struct SidebarView: View {
  @Bindable var model: SidebarModel

  init(model: SidebarModel) {
    self.model = model
  }

  var body: some View {
    VStack {
      List {
        ForEach(self.model.sections) {
          self.section(with: $0)
        }
      }
      .listStyle(.sidebar)
      .skeleton(condition: self.model.isLoading)
      .ignoresSafeArea()
    }
    .task { await self.model.task() }
    .sheet(item: self.$model.route.channelPicker) { model in
      ChannelPickerView(model: model) { action in
        self.model.addChannel(with: action)
      }
    }
    .sheet(item: self.$model.route.contactPicker) { model in
      ContactPickerView(model: model) { userIds in
        self.model.startConversation(with: userIds)
      }
    }
    .alert(self.$model.route.alert) { action in
      self.model.alertActionTapped(action: action)
    }
    .navigationDestination(item: self.$model.route.room) { model in
      RoomView(model: model)
    }
    .navigationDestination(item: self.$model.route.invalidRoom) {
      ContentUnavailableView("Room is gone", systemImage: "binoculars")
    }
    .navigationDestination(for: RoomId.self) { id in
      if let model = self.model.roomModel(for: id) {
        RoomView(model: model)
      } else {
        ContentUnavailableView("Room is gone", systemImage: "binoculars")
      }
    }
  }
}

private extension SidebarView {
  @ViewBuilder
  func section(with section: SidebarModel.Section) -> some View {
    Section(isExpanded: Binding(section.$isExpanded)) {
      ForEach(section.items) { item in
        NavigationLink(value: item.roomId) {
          self.row(with: item)
        }
      }
    } header: {
      HStack {
        switch section.kind {
        case .favorites:
          self.sectionHeader(title: "Favorites")

        case .directMessages:
          self.sectionHeader(title: "Direct Messages") {
            self.model.addContact()
          }

        case .channels:
          self.sectionHeader(title: "Channels") {
            self.model.addChannel()
          }
        }
      }
    }
  }

  @ViewBuilder
  func sectionHeader(title: LocalizedStringKey, action: (() -> Void)? = nil) -> some View {
    Text(title)

    if let action {
      Spacer()
      Button(action: action) {
        Image(systemName: "plus")
          .font(.caption)
          .foregroundColor(Color(.label))
          .padding(4)
          .background(Circle().fill(Color(.secondarySystemFill)))
      }
      .hiddenIfRedacted()
    }
  }

  @ViewBuilder
  func row(with item: SidebarItem) -> some View {
    Row(item: item) {
      Group {
        switch item.type {
        case let .directMessage(userId, _, avatarBundle, _):
          AvatarView(model: self.model.avatarModel(for: userId, bundle: avatarBundle)).size(24)
        case .group:
          Text("@")
        case .privateChannel:
          Image(systemName: "lock")
        case .publicChannel:
          Image(systemName: "circle.grid.2x2")
        case .generic:
          Image(systemName: "bubble")
        }
      }
      .foregroundStyle(.blue)
      .frame(width: 24, height: 24)
    }
    .contextMenu {
      Button {
        self.model.toggleFavorite(item)
      } label: {
        Label("Toggle Favorite", systemImage: "star")
      }

      Divider()

      Button(role: .destructive) {
        self.model.removeItem(item)
      } label: {
        Label("Remove from sidebar", systemImage: "trash")
      }
    }
  }
}

private struct Row<Icon: View>: View {
  let item: SidebarItem
  @ViewBuilder let icon: Icon

  var body: some View {
    HStack {
      self.icon
      Text(verbatim: self.item.name)

      if case let .directMessage(_, availability, _, status) = self.item.type {
        AvailabilityIndicator(availability)
          .size(8)

        if let status {
          HStack(spacing: 2) {
            Text(verbatim: status.emoji)

            if let text = status.status {
              Text(verbatim: text)
                .lineLimit(1)
            }
          }
          .padding(.leading, 4)
          .foregroundStyle(.secondary)
          .font(.footnote)
        }
      }

      Spacer()

      if self.item.hasDraft {
        Image(systemName: "pencil")
          .foregroundStyle(.secondary)
      }

      if self.item.mentionsCount > 0 || self.item.unreadCount > 0 {
        Text("\(self.item.mentionsCount > 0 ? "@" : String(self.item.unreadCount))")
          .font(.caption)
          .fontWeight(.bold)
          .foregroundColor(.white)
          .padding(.horizontal, 4)
          .padding(.vertical, 2)
          .frame(minWidth: 20, minHeight: 20)
          .background(Capsule().fill(.blue))
      }
    }
  }
}
