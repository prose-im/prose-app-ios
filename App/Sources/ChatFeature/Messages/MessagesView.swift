//
// This file is part of prose-app-ios.
// Copyright (c) 2025 Prose Foundation
//

import Domain
import IdentifiedCollections
import SwiftUI
import Toolbox
import WebKit

struct MessagesView: UIViewRepresentable {
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
    let contentController = WKUserContentController()

    contentController.addDOMReadyHandler {
      context.coordinator.model.webViewIsReady = true
    }

//    // Allow right clicking messages
//    contentController.addMessageEventHandler(for: .showMenu) { result in
//      actions.send(.messageEvent(MessageEvent.showMenu, from: result))
//    }
//    // Allow toggling reactions
//    contentController.addMessageEventHandler(for: .toggleReaction) { result in
//      actions.send(.messageEvent(MessageEvent.toggleReaction, from: result))
//    }
//    // Enable reactions picker shortcut
//    contentController.addMessageEventHandler(for: .showReactions) { result in
//      actions.send(.messageEvent(MessageEvent.showReactions, from: result))
//    }
//    // Our user either scroll to the beginning or the end of the message list
//    contentController.addMessageEventHandler(for: .reachedEndOfList) { result in
//      actions.send(.messageEvent(MessageEvent.reachedEndOfList, from: result))
//    }

    let configuration = WKWebViewConfiguration()
    configuration.userContentController = contentController
    configuration.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")

    let htmlURL = Bundle.module.url(forResource: "HTML/messaging", withExtension: "html")
      .expect("Failed to read MessagesView template.")

    let webView = WKWebView(frame: .zero, configuration: configuration)
    webView.isInspectable = true
    webView.loadFileURL(htmlURL, allowingReadAccessTo: htmlURL.deletingLastPathComponent())

    context.coordinator.ffi = FFI { [
      weak webView,
      logger = context.coordinator.model.logger,
    ] jsString, completion in
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

  func updateMessages(_: WKWebView, coordinator: Coordinator) {
    guard coordinator.model.webViewIsReady else {
      return
    }

    defer { coordinator.lastMessages = coordinator.model.messages }

    coordinator.ffi.messagingStore.updateMessages(
      to: coordinator.model.messages.elements,
      oldMessages: &coordinator.lastMessages,
    )
  }
}
