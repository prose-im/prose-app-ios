//
// This file is part of prose-app-ios.
// Copyright (c) 2025 Prose Foundation
//

import Domain
import IdentifiedCollections
import SwiftUI
import Toolbox
import WebKit

typealias ShowReactionsHandler = (MessageId, EventOrigin) -> Void
typealias ShowMessageMenuHandler = (MessageId) -> Void
typealias ToggleEmojiHandler = (MessageId, Emoji) -> Void
typealias OpenLinkHandler = (MessageId, URL) -> Void
typealias DownloadFileHandler = (MessageId, URL) -> Void
typealias ViewFileHandler = (MessageId, URL) -> Void

struct MessagesView: UIViewRepresentable {
  struct Callbacks {
    var showReactions: ShowReactionsHandler?
    var showMessageMenu: ShowMessageMenuHandler?
    var toggleEmoji: ToggleEmojiHandler?
    var openLink: OpenLinkHandler?
    var downloadFile: DownloadFileHandler?
    var viewFile: ViewFileHandler?
  }

  var callbacks = Callbacks()

  @MainActor
  final class Coordinator: NSObject {
    /// This is the state of messages stored in the web view. It's used for diffing purposes.
    let model: ChatModel
    var lastMessages = IdentifiedArrayOf<Message>()
    var ffi: FFI!

    init(model: ChatModel) {
      self.model = model
    }
  }

  @Environment(\.colorScheme) private var colorScheme

  let model: ChatModel

  init(model: ChatModel) {
    self.model = model
  }

  func makeCoordinator() -> Coordinator {
    Coordinator(model: self.model)
  }

  func makeUIView(context: Context) -> WKWebView {
    let logger = context.coordinator.model.logger
    let contentController = WKUserContentController()

    contentController.addDOMReadyHandler { result in
      switch result {
      case .ready:
        logger.info("DOM ready.")
      case .timeout:
        logger.error("DOM timed out.")
      }
      context.coordinator.model.webViewIsReady = true
    }

    // Allow right clicking messages
    contentController.addMessageEventHandler(for: .showMenu) { [callbacks] (result: Result<
      MessageMenuHandlerPayload,
      JSEventError,
    >) in
      guard case let .success(payload) = result else {
        return
      }
      callbacks.showMessageMenu?(payload.id)
    }

    // Allow toggling reactions
    contentController
      .addMessageEventHandler(for: .toggleReaction) { [callbacks] (result: Result<
        ToggleReactionHandlerPayload,
        JSEventError,
      >) in
        guard case let .success(payload) = result else {
          return
        }
        callbacks.toggleEmoji?(payload.id, payload.reaction)
      }

    contentController.addMessageEventHandler(for: .showReactions) { [callbacks] (result: Result<
      ShowReactionsHandlerPayload,
      JSEventError,
    >) in
      guard case let .success(payload) = result else {
        return
      }
      callbacks.showReactions?(payload.id, payload.origin)
    }

    contentController.addMessageEventHandler(for: .openLink) { [callbacks] (result: Result<
      OpenLinkPayload,
      JSEventError,
    >) in
      guard case let .success(payload) = result else {
        return
      }
      callbacks.openLink?(payload.id, payload.link.url)
    }

    contentController.addMessageEventHandler(for: .viewFile) { [callbacks] (result: Result<
      ViewFilePayload,
      JSEventError,
    >) in
      guard case let .success(payload) = result else {
        return
      }

      switch payload.action {
      case .expand:
        callbacks.viewFile?(payload.id, payload.file.url)
      case .download:
        callbacks.downloadFile?(payload.id, payload.file.url)
      }
    }

    let configuration = WKWebViewConfiguration()
    configuration.userContentController = contentController
    configuration.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")

    let htmlURL = Bundle.module.url(forResource: "HTML/messaging", withExtension: "html")
      .expect("Failed to read MessagesView template.")

    let webView = WKWebView(frame: .zero, configuration: configuration)
    webView.isOpaque = false
    webView.backgroundColor = UIColor.clear

    #if DEBUG
      webView.isInspectable = true
    #endif

    webView.loadFileURL(htmlURL, allowingReadAccessTo: htmlURL.deletingLastPathComponent())

    context.coordinator.ffi = FFI { [weak webView] jsString, completion in
      webView?.evaluateJavaScript(jsString) { res, error in
        // Take the JS method name
        let domain: () -> String = { String(jsString.prefix(while: { $0 != "(" })) }

        if let error = error as? NSError {
          logger
            .error(
              "[\(domain())] Error evaluating JavaScript: \(error.prose_javaScriptExceptionMessage)",
            )
        }
        completion(res, error)
      }
    }

    return webView
  }

  func updateUIView(_ webView: WKWebView, context: Context) {
    guard context.coordinator.model.webViewIsReady else {
      return
    }

    let styleTheme: StyleTheme? = {
      switch self.colorScheme {
      case .light:
        return .light
      case .dark:
        return .dark
      @unknown default:
        return nil
      }
    }()
    context.coordinator.ffi.messagingContext.setStyleTheme(styleTheme)

    self.updateMessages(webView, coordinator: context.coordinator)
  }
}

extension MessagesView {
  func onShowReactions(_ handler: @escaping ShowReactionsHandler) -> Self {
    var view = self
    view.callbacks.showReactions = handler
    return view
  }

  func onShowMessageMenu(_ handler: @escaping ShowMessageMenuHandler) -> Self {
    var view = self
    view.callbacks.showMessageMenu = handler
    return view
  }

  func onToggleEmoji(_ handler: @escaping ToggleEmojiHandler) -> Self {
    var view = self
    view.callbacks.toggleEmoji = handler
    return view
  }

  func onOpenLink(_ handler: @escaping OpenLinkHandler) -> Self {
    var view = self
    view.callbacks.openLink = handler
    return view
  }

  func onDownloadFile(_ handler: @escaping DownloadFileHandler) -> Self {
    var view = self
    view.callbacks.downloadFile = handler
    return view
  }

  func onViewFile(_ handler: @escaping ViewFileHandler) -> Self {
    var view = self
    view.callbacks.viewFile = handler
    return view
  }
}

private extension MessagesView {
  func updateMessages(_: WKWebView, coordinator: Coordinator) {
    guard coordinator.model.webViewIsReady else {
      return
    }

    defer { coordinator.lastMessages = coordinator.model.messages }

    let logger = coordinator.model.logger
    logger.info("Loading messages into WebView…")

    coordinator.ffi.messagingStore.updateMessages(
      to: coordinator.model.messages.elements,
      oldMessages: &coordinator.lastMessages,
    )
  }
}
