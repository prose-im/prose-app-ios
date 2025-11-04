//
// This file is part of prose-app-ios.
// Copyright (c) 2025 Prose Foundation
//

import Dependencies
import Domain
import Foundation

private enum KeychainError: Error {
  case unexpectedPasswordData
  case unhandledError(status: OSStatus)
}

extension CredentialsClient: DependencyKey {
  public static let liveValue = Self.live(service: "org.prose.app")
}

public extension CredentialsClient {
  static func live(service: String) -> CredentialsClient {
    let deleteCredentials = { @Sendable (id: UserId) in
      let query: [CFString: Any] = [
        kSecClass: kSecClassGenericPassword,
        kSecAttrService: service,
        kSecAttrAccount: id,
      ]

      let status = SecItemDelete(query as CFDictionary)
      guard status == errSecSuccess || status == errSecItemNotFound else {
        throw KeychainError.unhandledError(status: status)
      }
    }

    return CredentialsClient(
      loadCredentials: { (id: UserId) in
        let query: [CFString: Any] = [
          kSecClass: kSecClassGenericPassword,
          kSecAttrService: service,
          kSecAttrAccount: id.rawValue,
          kSecMatchLimit: kSecMatchLimitOne,
          kSecReturnAttributes: true,
          kSecReturnData: true,
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        guard status != errSecItemNotFound else {
          return nil
        }

        guard status == errSecSuccess else {
          throw KeychainError.unhandledError(status: status)
        }

        guard let existingItem = item as? [CFString: Any] else {
          throw KeychainError.unexpectedPasswordData
        }

        guard let itemData = existingItem[kSecValueData] as? Data else {
          throw KeychainError.unexpectedPasswordData
        }

        if let password = String(data: itemData, encoding: .utf8) {
          return Credentials(id: id, password: password)
        } else {
          return nil
        }
      },
      save: { (credentials: Credentials) in
        try? deleteCredentials(credentials.id)

        let query: [CFString: Any] = [
          kSecClass: kSecClassGenericPassword,
          kSecAttrService: service,
          kSecAttrAccount: credentials.id,
          kSecValueData: Data(credentials.password.utf8),
          kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlock,
        ]

        let status = SecItemAdd(query as CFDictionary, nil)

        guard status == errSecSuccess else {
          throw KeychainError.unhandledError(status: status)
        }
      },
      deleteCredentials: deleteCredentials,
    )
  }
}
