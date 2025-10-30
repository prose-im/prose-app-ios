//
// This file is part of prose-app-ios.
// Copyright (c) 2025 Prose Foundation
//

@preconcurrency import Combine
import Domain
import Foundation
import Synchronization
import UIKit

extension ProseCoreClient {
  static func live(userId: UserId) async throws -> Self {
    @Dependency(\.logger[category: "Client"]) var logger

    let connectionStatus = CurrentValueSubject<ConnectionStatus, Never>(.disconnected)
    let events = PassthroughSubject<ClientEvent, Never>()

    let client = try await Client(
      cacheDir: .temporaryDirectory
        .appending(component: "Accounts")
        .appending(component: userId),
      delegate: ProseClientDelegate(subject: events),
      config: .init(
        clientName: "Prose iOS",
        clientVersion: "beta",
        clientOs: UIDevice.current.systemName,
      ),
    )

    if ProcessInfo.processInfo.environment["PROSE_CORE_LOG_ENABLED"] == "1" {
      client.enableLogging(
        minLevel: ProcessInfo.processInfo.environment["PROSE_CORE_LOG_LEVEL"] ?? "error",
      )
    }

    @Sendable func connectWithBackoff(
      credentials: Credentials,
      backoff: Duration = .seconds(3),
      numberOfRetries: Int = 3,
    ) async throws {
      guard
        connectionStatus.value != .connected,
        connectionStatus.value != .connecting
      else {
        return
      }

      connectionStatus.value = .connecting

      do {
        logger.info("Connecting \(credentials.id)…")
        try await client.connect(userId: credentials.id, password: credentials.password)
        connectionStatus.value = .connected
        logger.info("Connected \(credentials.id).")
      } catch {
        logger.info("Connection failed for \(credentials.id).")
        if numberOfRetries < 1 {
          connectionStatus.value = .disconnected
          throw error
        }

        try await Task.sleep(for: backoff)
        try await connectWithBackoff(
          credentials: credentials,
          backoff: backoff * 2,
          numberOfRetries: numberOfRetries - 1,
        )
      }
    }

    return .init(
      connectionStatus: {
        connectionStatus
          .removeDuplicates()
          .buffer(size: 10, prefetch: .byRequest, whenFull: .dropOldest)
          .values
      },
      events: {
        events
          // Buffer events or they might get lost in the AsyncSequence
          // See: https://stackoverflow.com/questions/75776172/passthroughsubjects-asyncpublisher-values-property-not-producing-all-values
          .buffer(size: 10, prefetch: .byRequest, whenFull: .dropOldest)
          .values
      },
      connect: { credentials, retry in
        try await connectWithBackoff(
          credentials: credentials,
          numberOfRetries: retry ? 3 : 0,
        )
      },
      disconnect: {
        logger.info("Disconnecting…")
        connectionStatus.value = .disconnected
        try await client.disconnect()
        logger.info("Disconnected.")
      },
      startObservingRooms: {
        try await client.startObservingRooms()
      },
      sidebarItems: {
        await client.sidebarItems().map(SidebarItem.init(sdkSidebarItem:))
      },
      loadAccountInfo: {
        try await client.loadAccountInfo()
      },
      changePassword: { newPassword in
        try await client.changePassword(newPassword: newPassword)
      },
      setUserActivity: { status in
        try await client.setUserActivity(status: status)
      },
      setAvailability: { availability in
        try await client.setAvailability(availability: availability)
      },
      loadWorkspaceInfo: {
        try await client.loadWorkspaceInfo()
      },
      loadWorkspaceIcon: { icon in
        try await client.loadWorkspaceIcon(icon: icon)
      },
      loadAvatar: { avatar in
        try await client.loadAvatar(avatar: avatar)
      },
      saveAvatar: { imagePath in
        try await client.saveAvatar(imagePath: imagePath)
      },
      loadProfile: { userId in
        try await client.loadProfile(from: userId)
      },
      saveProfile: { profile in
        try await client.saveProfile(profile: profile)
      },
      loadUserMetadata: { userId in
        try await client.loadUserMetadata(userId: userId)
      },
      addContact: { userId in
        try await client.addContact(userId: userId)
      },
      removeContact: { userId in
        try await client.removeContact(userId: userId)
      },
      loadContacts: {
        try await client.loadContacts()
      },
      requestPresenceSubscription: { userId in
        try await client.requestPresenceSub(userId: userId)
      },
      loadPresenceSubscriptionRequests: {
        try await client.loadPresenceSubRequests()
      },
      approvePresenceSubscriptionRequest: { id in
        try await client.approvePresenceSubRequest(id: id)
      },
      denyPresenceSubscriptionRequest: { id in
        try await client.denyPresenceSubRequest(id: id)
      },
      blockUser: { userId in
        try await client.blockUser(userId: userId)
      },
      unblockUser: { userId in
        try await client.unblockUser(userId: userId)
      },
      loadBlockList: {
        try await client.loadBlockList()
      },
      clearBlockList: {
        try await client.clearBlockList()
      },
      loadPublicChannels: {
        try await client.loadPublicChannels()
      },
      findPublicChannelByName: { name in
        try await client.findPublicChannelByName(name: name)
      },
      startConversation: { participants in
        try await client.startConversation(participants: participants)
      },
      createGroup: { participants in
        try await client.createGroup(participants: participants)
      },
      createPublicChannel: { name in
        try await client.createPublicChannel(channelName: name)
      },
      createPrivateChannel: { name in
        try await client.createPrivateChannel(channelName: name)
      },
      joinRoom: { roomId, password in
        try await client.joinRoom(roomId: roomId, password: password)
      },
      destroyRoom: { roomId in
        try await client.destroyRoom(roomId: roomId)
      },
      requestUploadSlot: { fileName, fileSize, mediaType in
        try await client.requestUploadSlot(
          fileName: fileName,
          fileSize: UInt64(fileSize),
          mediaType: mediaType,
        )
      },
      previewMarkdown: { markdown in
        async let preview = client.previewMarkdown(markdown: markdown)
        return await preview
      },
      deleteCachedData: {
        try await client.deleteCachedData()
      },
    )
  }
}

private final class ProseClientDelegate: ClientDelegate {
  private let subject: PassthroughSubject<ClientEvent, Never>

  init(subject: PassthroughSubject<ClientEvent, Never>) {
    self.subject = subject
  }

  func handleEvent(event: ClientEvent) {
    self.subject.send(event)
  }
}
