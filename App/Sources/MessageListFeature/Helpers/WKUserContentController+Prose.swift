//
// This file is part of prose-app-ios.
// Copyright (c) 2025 Prose Foundation
//

import Foundation
import WebKit

enum WebViewLoadResult: String {
  case ready
  case timeout
}

extension WKUserContentController {
  func addMessageEventHandler<T: Decodable>(
    for event: MessageEvent.Kind,
    handler: @escaping (Result<T, JSEventError>) -> Void,
  ) {
    let (script, handlerName) = MessagingEventScript.on(event)

    let scriptMessageHandler = ScriptMessageHandler<T> { message in
      handler(decodeJSEventPayload(message))
    }

    self.add(scriptMessageHandler, name: handlerName)
    self.addUserScript(
      WKUserScript(source: script, injectionTime: .atDocumentEnd, forMainFrameOnly: true),
    )
  }

  func addDOMReadyHandler(_ handler: @escaping (WebViewLoadResult) -> Void) {
    let script = """
    function waitForMessagingContext() {
      if (window.MessagingContext !== undefined) {
        window.webkit.messageHandlers.domReady.postMessage('ready');
        return;
      }

      // Poll every 50ms for ~10 seconds
      let attempts = 0;
      const maxAttempts = 200;

      const interval = setInterval(() => {
        attempts++;

        if (window.MessagingContext !== undefined) {
          clearInterval(interval);
          window.webkit.messageHandlers.domReady.postMessage('ready');
        } else if (attempts >= maxAttempts) {
          clearInterval(interval);
          window.webkit.messageHandlers.domReady.postMessage('timeout');
        }
      }, 50);
    }

    if (document.readyState === 'complete') {
      waitForMessagingContext();
    } else {
      window.addEventListener('load', function() {
        waitForMessagingContext();
      });
    }
    """

    let scriptMessageHandler = ScriptMessageHandler<WebViewLoadResult> { message in
      let result = (message as? String)
        .flatMap(WebViewLoadResult.init(rawValue:))
        .expect("Received unexpected result from ready handler")

      handler(result)
    }

    self.add(scriptMessageHandler, name: "domReady")
    self.addUserScript(
      WKUserScript(source: script, injectionTime: .atDocumentEnd, forMainFrameOnly: true),
    )
  }
}

private final class ScriptMessageHandler<T>: NSObject, WKScriptMessageHandler {
  let handler: (Any) -> Void

  init(handler: @escaping (Any) -> Void) {
    self.handler = handler
    super.init()
  }

  func userContentController(
    _: WKUserContentController,
    didReceive message: WKScriptMessage,
  ) {
    self.handler(message.body)
  }
}

private enum MessagingEventScript {
  static func on(_ event: MessageEvent.Kind) -> (script: String, handlerName: String) {
    let handlerName = "handler_" + event.rawValue.replacingOccurrences(of: ":", with: "_")

    let script = """
    function \(handlerName)(content) {
      window.webkit.messageHandlers.\(handlerName).postMessage(JSON.stringify(content));
    }
    MessagingEvent.on("\(event.rawValue)", \(handlerName));
    """

    return (script: script, handlerName: handlerName)
  }
}

private func decodeJSEventPayload<T: Decodable>(_ message: Any) -> Result<T, JSEventError> {
  guard
    let bodyString: String = message as? String,
    let bodyData: Data = bodyString.data(using: .utf8)
  else {
    print("JS message body should be serialized as a String")
    return .failure(.badSerialization)
  }

  do {
    let payload = try JSONDecoder().decode(T.self, from: bodyData)
    return .success(payload)
  } catch let error as DecodingError {
    print("JS message body could not be decoded as `Payload`. Content: \(bodyString)")
    return .failure(
      .decodingError(
        "JS message body could not be decoded from \"\(bodyString)\": \(error)",
      ),
    )
  } catch {
    fatalError("`error` should always be a `DecodingError`")
  }
}
