//
// This file is part of prose-app-ios.
// Copyright (c) 2025 Prose Foundation
//

import SafariServices
import SwiftUI

public extension View {
  func safariWebView(_ url: Binding<URL?>) -> some View {
    let binding = Binding<IdentifiableURL?>(
      get: { url.wrappedValue.map(IdentifiableURL.init(id:)) },
      set: { url.wrappedValue = $0?.id },
    )
    return self.fullScreenCover(item: binding) { url in
      SafariWebView(url: url.id)
    }
  }
}

private struct SafariWebView: UIViewControllerRepresentable {
  let url: URL

  func makeUIViewController(context _: Context) -> SFSafariViewController {
    SFSafariViewController(url: self.url)
  }

  func updateUIViewController(_: SFSafariViewController, context _: Context) {}
}

private struct IdentifiableURL: Identifiable {
  var id: URL
}
