//
// This file is part of prose-app-ios.
// Copyright (c) 2025 Prose Foundation
//

import SwiftUI

public struct OfflineBanner: View {
  let action: () -> Void
  let isConnecting: Bool

  public init(isConnecting: Bool, action: @escaping () -> Void) {
    self.isConnecting = isConnecting
    self.action = action
  }

  public var body: some View {
    VStack(spacing: 16) {
      HStack(spacing: 18) {
        Image(systemName: "exclamationmark.triangle.fill")
          .font(.largeTitle)

        VStack(alignment: .leading, spacing: 6) {
          Text("You are offline")
            .fontWeight(.bold)

          Text("New messages will not appear for now.")
            .font(.subheadline)
            .opacity(0.8)
        }

        Spacer()
      }
      .foregroundColor(.white)

      Button(action: self.action) {
        HStack(spacing: 8) {
          if self.isConnecting {
            ProgressView()
              .scaleEffect(0.8)
              .progressViewStyle(CircularProgressViewStyle(tint: .black))
          }

          Text(self.isConnecting ? "Connecting..." : "Reconnect now")
            .padding(.vertical, 6)
            .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity)
      }
      .buttonStyle(.borderedProminent)
      .buttonBorderShape(.roundedRectangle)
      .foregroundStyle(.black)
      .tint(.white)
      .opacity(self.isConnecting ? 0.6 : 1)
      // We're not using disabled so that the button keeps its background
      .allowsHitTesting(!self.isConnecting)
    }
    .padding()
    .background(
      RoundedRectangle(cornerRadius: 16)
        .fill(Color(red: 0.4, green: 0.45, blue: 0.55)),
    )
  }
}

#Preview {
  VStack {
    OfflineBanner(isConnecting: false) {
      print("Click")
    }
    OfflineBanner(isConnecting: true) {
      print("Click")
    }
  }
  .padding(.horizontal)
}
