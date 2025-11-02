//
// This file is part of prose-app-ios.
// Copyright (c) 2025 Prose Foundation
//

import Dependencies
import DependenciesMacros
import Domain
import Foundation

@DependencyClient
public struct ProseCoreClient: Sendable {
  public var connectionStatus: @Sendable ()
    -> any AsyncSequence<ConnectionStatus, Never> = { AsyncStream.never }

  public var events: @Sendable () -> any AsyncSequence<ClientEvent, Never> = { AsyncStream.never }

  public var connect: @Sendable (Credentials, _ retry: Bool) async throws -> Void
  public var disconnect: @Sendable () async throws -> Void

  public var startObservingRooms: @Sendable () async throws -> Void
  public var sidebarItems: @Sendable () async -> [SidebarItem] = { [] }

  public var loadAccountInfo: @Sendable () async throws -> AccountInfo
  public var changePassword: @Sendable (_ newPassword: String) async throws -> Void
  public var setUserActivity: @Sendable (_ status: UserStatus?) async throws -> Void
  public var setAvailability: @Sendable (_ availability: Availability) async throws -> Void

  public var loadWorkspaceInfo: @Sendable () async throws -> WorkspaceInfo?
  public var loadWorkspaceIcon: @Sendable (_ icon: WorkspaceIcon) async throws -> URL?

  public var loadAvatar: @Sendable (_ avatar: Avatar) async throws -> URL?
  public var saveAvatar: @Sendable (_ imagePath: URL) async throws -> Void

  public var loadProfile: @Sendable (_ userId: UserId) async throws -> UserProfile?
  public var saveProfile: @Sendable (_ profile: UserProfile) async throws -> Void

  public var loadUserMetadata: @Sendable (_ userId: UserId) async throws -> UserMetadata?

  public var addContact: @Sendable (_ userId: UserId) async throws -> Void
  public var removeContact: @Sendable (_ userId: UserId) async throws -> Void
  public var loadContacts: @Sendable () async throws -> [Contact]

  public var requestPresenceSubscription: @Sendable (_ userId: UserId) async throws -> Void
  public var loadPresenceSubscriptionRequests: @Sendable () async throws -> [PresenceSubRequest]
  public var approvePresenceSubscriptionRequest: @Sendable (
    _ id: PresenceSubRequestId,
  ) async throws -> Void
  public var denyPresenceSubscriptionRequest: @Sendable (
    _ id: PresenceSubRequestId,
  ) async throws -> Void

  public var blockUser: @Sendable (_ userId: UserId) async throws -> Void
  public var unblockUser: @Sendable (_ userId: UserId) async throws -> Void
  public var loadBlockList: @Sendable () async throws -> [UserBasicInfo]
  public var clearBlockList: @Sendable () async throws -> Void

  public var loadPublicChannels: @Sendable () async throws -> [PublicRoomInfo]
  public var findPublicChannelByName: @Sendable (_ name: String) async throws -> RoomId?

  public var startConversation: @Sendable (_ participants: [UserId]) async throws -> RoomId
  public var createGroup: @Sendable (_ participants: [UserId]) async throws -> RoomId
  public var createPublicChannel: @Sendable (_ name: String) async throws -> RoomId
  public var createPrivateChannel: @Sendable (_ name: String) async throws -> RoomId
  public var joinRoom: @Sendable (_ roomId: MucId, _ password: String?) async throws -> RoomId
  public var destroyRoom: @Sendable (_ roomId: MucId) async throws -> Void

  public var toggleSidebarFavorite: @Sendable (_ roomId: RoomId) async throws -> Void
  public var removeItemFromSidebar: @Sendable (_ roomId: RoomId) async throws -> Void

  public var requestUploadSlot: @Sendable (
    _ fileName: String,
    _ fileSize: Int64,
    _ mediaType: Mime,
  ) async throws -> UploadSlot

  public var previewMarkdown: @Sendable (String) async -> String = { $0 }

  public var deleteCachedData: @Sendable () async throws -> Void
}

public extension DependencyValues {
  var client: ProseCoreClient {
    get { self[ProseCoreClient.self] }
    set { self[ProseCoreClient.self] = newValue }
  }
}

extension ProseCoreClient: TestDependencyKey {
  public static let testValue = Self()
}
