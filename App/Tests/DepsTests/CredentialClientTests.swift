//
// This file is part of prose-app-ios.
// Copyright (c) 2025 Prose Foundation
//

import Deps
import Domain
import Testing

@Test func savesUpdatesAndDeletesCredentials() throws {
  let client = CredentialsClient.live(service: "org.prose.app.tests")

  let userId: UserId = "tests@prose.org"

  try #expect(client.loadCredentials(userId) == nil)

  let initialCredentials = Credentials(id: userId, password: "initial-password")

  try client.save(initialCredentials)

  try #expect(client.loadCredentials(userId) == initialCredentials)

  let updatedCredentials = Credentials(id: userId, password: "updated-password")

  try client.save(updatedCredentials)

  try #expect(client.loadCredentials(userId) == updatedCredentials)

  try client.deleteCredentials(userId)

  try #expect(client.loadCredentials(userId) == nil)
}
