//
// This file is part of prose-app-ios.
// Copyright (c) 2025 Prose Foundation
//

import ElegantEmojiPicker
import QuickLook
import SharedUI
import SwiftUI
import SwiftUINavigation

public struct ChatView: View {
  @Bindable var model: ChatModel

  public init(model: ChatModel) {
    self.model = model
  }

  public var body: some View {
    self.content
      .sheet(item: self.$model.route.emojiPicker) { model in
        ElegantEmojiPickerRepresentable(
          isPresented: .constant(true),
          selectedEmoji: model.emoji,
          configuration: .init(
            showRandom: false,
            showReset: false,
            showClose: false,
            supportsPreview: false,
          ),
          localization: .init(),
        )
        .presentationDetents([.medium, .large])
        .ignoresSafeArea(.container, edges: .bottom)
      }
      .sheet(item: self.$model.route.messageMenu) { model in
        MessageMenu(model: model)
          .ignoresSafeArea()
          .fittedPresentationDetent()
      }
      .alert(
        item: self.$model.route.deleteMessageConfirmation,
        title: { _ in Text("Are you sure you want to remove this message?") },
        actions: { messageId in
          Button("Remove Message", role: .destructive) {
            self.model.messageDeletionConfirmed(messageId: messageId)
          }
          Button("Cancel", role: .cancel) {
            self.model.messageDeletionCancelled()
          }
        },
        message: { _ in
          Text(
            "The message will disappear from your inbox. We will also try to remove it on your recipient end, although removal is not guaranteed.",
          )
        },
      )
      .sheet(item: self.$model.route.editMessage) { model in
        EditMessageView(model: model)
      }
      .safariWebView(self.$model.route.safariView)
      .task { await self.model.task() }
  }

  @ViewBuilder
  var content: some View {
    if let error = self.model.error {
      ErrorView(error: error)
    } else {
      VStack {
        ZStack(alignment: .bottom) {
          MessagesView(model: self.model)
            .onShowReactions { messageId, _ in
              self.model.showEmojiPicker(for: messageId)
            }
            .onShowMessageMenu { messageId in
              self.model.showMessageMenu(for: messageId)
            }
            .onToggleEmoji { messageId, emoji in
              self.model.toggleReaction(for: messageId, reaction: emoji)
            }
            .onOpenLink { _, url in
              self.model.openURL(url: url)
            }
            .onViewFile { messageId, url in
              self.model.previewFile(messageId: messageId, url: url)
            }
            .onDownloadFile { messageId, url in
              self.model.previewFile(messageId: messageId, url: url)
            }
            .ignoresSafeArea()

          Color.clear
            .fileUpload(model: self.model.fileUploadModel)
            .filePreview(model: self.$model.route.filePreview)
            .padding(.bottom)
        }

        MessageInputView(model: self.model.messageInputModel) {
          Button(action: { self.model.fileUploadModel.selectFileForUploading(source: .camera) }) {
            Label("Take Photo", systemImage: "camera")
          }
          Button(action: { self.model.fileUploadModel.selectFileForUploading(source: .photoPicker)
          }) {
            Label("Choose Photo or Video", systemImage: "photo.on.rectangle")
          }
          Button(action: { self.model.fileUploadModel.selectFileForUploading(source: .fileImporter)
          }) {
            Label("Choose File", systemImage: "doc")
          }
        }.fixedSize(horizontal: false, vertical: true)
      }
    }
  }
}
