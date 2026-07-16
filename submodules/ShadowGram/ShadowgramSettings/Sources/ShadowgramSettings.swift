import Foundation
import TelegramCore
import SwiftSignalKit

// ShadowGram — a Telegram iOS fork that ports the unique features of AyuGram Desktop.
// This is the master persisted settings model. It follows the exact serialization
// convention used across TelegramUIPreferences (StringCodingKey + Int32-encoded bools),
// so it round-trips through the account manager's shared-data store like any other
// first-party settings struct.

public enum ShadowgramPeerIdDisplay: Int32, Codable {
    case hidden = 0
    case telegramApi = 1
    case botApi = 2
}

public enum ShadowgramSendWithoutSoundOption: Int32, Codable {
    case never = 0
    case inGhostMode = 1
    case always = 2
}

public enum ShadowgramContextMenuVisibility: Int32, Codable {
    case hidden = 0
    case visible = 1
    case visibleWithModifier = 2
}

public struct ShadowgramSettings: Codable, Equatable {
    // Ghost mode — do not leak activity to peers.
    public var ghostModeEnabled: Bool
    public var sendReadReceipts: Bool
    public var sendReadStories: Bool
    public var sendOnlineStatus: Bool
    public var sendUploadProgress: Bool
    public var sendTyping: Bool
    public var sendOfflineAfterAction: Bool
    public var markReadAfterAction: Bool
    public var useScheduledMessages: Bool
    public var sendWithoutSound: ShadowgramSendWithoutSoundOption

    // Message history — anti-delete / anti-edit local archive.
    public var saveDeletedMessages: Bool
    public var saveMessagesHistory: Bool
    public var saveForBots: Bool

    // Local premium / spoofing.
    public var localPremium: Bool

    // Privacy.
    public var hideFromBlocked: Bool
    public var showPeerId: ShadowgramPeerIdDisplay
    public var showRegistrationDate: Bool
    public var showMessageSeconds: Bool
    public var showMessageDetails: Bool

    // Content controls.
    public var disableAds: Bool
    public var disableStories: Bool
    public var disableCustomBackgrounds: Bool
    public var hidePremiumStatuses: Bool
    public var showOnlyAddedEmojisAndStickers: Bool
    public var collapseSimilarChannels: Bool
    public var hideSimilarChannels: Bool
    public var disableGreetingSticker: Bool
    public var disableOpenLinkWarning: Bool
    public var filterZalgo: Bool
    public var stickerConfirmation: Bool
    public var gifConfirmation: Bool
    public var voiceConfirmation: Bool

    // Appearance.
    public var deletedMark: String
    public var editedMark: String
    public var simpleQuotesAndReplies: Bool
    public var recentStickersCount: Int32
    public var showMessageShot: Bool
    public var wideMultiplier: Double

    // Context menu extras.
    public var showMessageDetailsInContextMenu: ShadowgramContextMenuVisibility
    public var showRepeatInContextMenu: ShadowgramContextMenuVisibility

    // Shadow-banned peer ids (messages from these are hidden locally).
    public var shadowBanIds: [Int64]

    public static var defaultSettings: ShadowgramSettings {
        return ShadowgramSettings(
            ghostModeEnabled: false,
            sendReadReceipts: true,
            sendReadStories: true,
            sendOnlineStatus: true,
            sendUploadProgress: true,
            sendTyping: true,
            sendOfflineAfterAction: false,
            markReadAfterAction: true,
            useScheduledMessages: false,
            sendWithoutSound: .never,
            saveDeletedMessages: true,
            saveMessagesHistory: true,
            saveForBots: false,
            localPremium: false,
            hideFromBlocked: false,
            showPeerId: .botApi,
            showRegistrationDate: true,
            showMessageSeconds: false,
            showMessageDetails: true,
            disableAds: true,
            disableStories: false,
            disableCustomBackgrounds: false,
            hidePremiumStatuses: false,
            showOnlyAddedEmojisAndStickers: false,
            collapseSimilarChannels: true,
            hideSimilarChannels: false,
            disableGreetingSticker: false,
            disableOpenLinkWarning: false,
            filterZalgo: false,
            stickerConfirmation: false,
            gifConfirmation: false,
            voiceConfirmation: false,
            deletedMark: "🧹",
            editedMark: "",
            simpleQuotesAndReplies: false,
            recentStickersCount: 100,
            showMessageShot: true,
            wideMultiplier: 1.0,
            showMessageDetailsInContextMenu: .visibleWithModifier,
            showRepeatInContextMenu: .hidden,
            shadowBanIds: []
        )
    }

    public init(
        ghostModeEnabled: Bool,
        sendReadReceipts: Bool,
        sendReadStories: Bool,
        sendOnlineStatus: Bool,
        sendUploadProgress: Bool,
        sendTyping: Bool,
        sendOfflineAfterAction: Bool,
        markReadAfterAction: Bool,
        useScheduledMessages: Bool,
        sendWithoutSound: ShadowgramSendWithoutSoundOption,
        saveDeletedMessages: Bool,
        saveMessagesHistory: Bool,
        saveForBots: Bool,
        localPremium: Bool,
        hideFromBlocked: Bool,
        showPeerId: ShadowgramPeerIdDisplay,
        showRegistrationDate: Bool,
        showMessageSeconds: Bool,
        showMessageDetails: Bool,
        disableAds: Bool,
        disableStories: Bool,
        disableCustomBackgrounds: Bool,
        hidePremiumStatuses: Bool,
        showOnlyAddedEmojisAndStickers: Bool,
        collapseSimilarChannels: Bool,
        hideSimilarChannels: Bool,
        disableGreetingSticker: Bool,
        disableOpenLinkWarning: Bool,
        filterZalgo: Bool,
        stickerConfirmation: Bool,
        gifConfirmation: Bool,
        voiceConfirmation: Bool,
        deletedMark: String,
        editedMark: String,
        simpleQuotesAndReplies: Bool,
        recentStickersCount: Int32,
        showMessageShot: Bool,
        wideMultiplier: Double,
        showMessageDetailsInContextMenu: ShadowgramContextMenuVisibility,
        showRepeatInContextMenu: ShadowgramContextMenuVisibility,
        shadowBanIds: [Int64]
    ) {
        self.ghostModeEnabled = ghostModeEnabled
        self.sendReadReceipts = sendReadReceipts
        self.sendReadStories = sendReadStories
        self.sendOnlineStatus = sendOnlineStatus
        self.sendUploadProgress = sendUploadProgress
        self.sendTyping = sendTyping
        self.sendOfflineAfterAction = sendOfflineAfterAction
        self.markReadAfterAction = markReadAfterAction
        self.useScheduledMessages = useScheduledMessages
        self.sendWithoutSound = sendWithoutSound
        self.saveDeletedMessages = saveDeletedMessages
        self.saveMessagesHistory = saveMessagesHistory
        self.saveForBots = saveForBots
        self.localPremium = localPremium
        self.hideFromBlocked = hideFromBlocked
        self.showPeerId = showPeerId
        self.showRegistrationDate = showRegistrationDate
        self.showMessageSeconds = showMessageSeconds
        self.showMessageDetails = showMessageDetails
        self.disableAds = disableAds
        self.disableStories = disableStories
        self.disableCustomBackgrounds = disableCustomBackgrounds
        self.hidePremiumStatuses = hidePremiumStatuses
        self.showOnlyAddedEmojisAndStickers = showOnlyAddedEmojisAndStickers
        self.collapseSimilarChannels = collapseSimilarChannels
        self.hideSimilarChannels = hideSimilarChannels
        self.disableGreetingSticker = disableGreetingSticker
        self.disableOpenLinkWarning = disableOpenLinkWarning
        self.filterZalgo = filterZalgo
        self.stickerConfirmation = stickerConfirmation
        self.gifConfirmation = gifConfirmation
        self.voiceConfirmation = voiceConfirmation
        self.deletedMark = deletedMark
        self.editedMark = editedMark
        self.simpleQuotesAndReplies = simpleQuotesAndReplies
        self.recentStickersCount = recentStickersCount
        self.showMessageShot = showMessageShot
        self.wideMultiplier = wideMultiplier
        self.showMessageDetailsInContextMenu = showMessageDetailsInContextMenu
        self.showRepeatInContextMenu = showRepeatInContextMenu
        self.shadowBanIds = shadowBanIds
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        let d = ShadowgramSettings.defaultSettings

        func boolValue(_ key: String, _ fallback: Bool) -> Bool {
            if let raw = try? container.decodeIfPresent(Int32.self, forKey: StringCodingKey(key)), let raw {
                return raw != 0
            }
            return fallback
        }
        func enumValue<T: RawRepresentable>(_ key: String, _ fallback: T) -> T where T.RawValue == Int32 {
            if let raw = try? container.decodeIfPresent(Int32.self, forKey: StringCodingKey(key)), let raw, let value = T(rawValue: raw) {
                return value
            }
            return fallback
        }

        self.ghostModeEnabled = boolValue("ghostModeEnabled", d.ghostModeEnabled)
        self.sendReadReceipts = boolValue("sendReadReceipts", d.sendReadReceipts)
        self.sendReadStories = boolValue("sendReadStories", d.sendReadStories)
        self.sendOnlineStatus = boolValue("sendOnlineStatus", d.sendOnlineStatus)
        self.sendUploadProgress = boolValue("sendUploadProgress", d.sendUploadProgress)
        self.sendTyping = boolValue("sendTyping", d.sendTyping)
        self.sendOfflineAfterAction = boolValue("sendOfflineAfterAction", d.sendOfflineAfterAction)
        self.markReadAfterAction = boolValue("markReadAfterAction", d.markReadAfterAction)
        self.useScheduledMessages = boolValue("useScheduledMessages", d.useScheduledMessages)
        self.sendWithoutSound = enumValue("sendWithoutSound", d.sendWithoutSound)
        self.saveDeletedMessages = boolValue("saveDeletedMessages", d.saveDeletedMessages)
        self.saveMessagesHistory = boolValue("saveMessagesHistory", d.saveMessagesHistory)
        self.saveForBots = boolValue("saveForBots", d.saveForBots)
        self.localPremium = boolValue("localPremium", d.localPremium)
        self.hideFromBlocked = boolValue("hideFromBlocked", d.hideFromBlocked)
        self.showPeerId = enumValue("showPeerId", d.showPeerId)
        self.showRegistrationDate = boolValue("showRegistrationDate", d.showRegistrationDate)
        self.showMessageSeconds = boolValue("showMessageSeconds", d.showMessageSeconds)
        self.showMessageDetails = boolValue("showMessageDetails", d.showMessageDetails)
        self.disableAds = boolValue("disableAds", d.disableAds)
        self.disableStories = boolValue("disableStories", d.disableStories)
        self.disableCustomBackgrounds = boolValue("disableCustomBackgrounds", d.disableCustomBackgrounds)
        self.hidePremiumStatuses = boolValue("hidePremiumStatuses", d.hidePremiumStatuses)
        self.showOnlyAddedEmojisAndStickers = boolValue("showOnlyAddedEmojisAndStickers", d.showOnlyAddedEmojisAndStickers)
        self.collapseSimilarChannels = boolValue("collapseSimilarChannels", d.collapseSimilarChannels)
        self.hideSimilarChannels = boolValue("hideSimilarChannels", d.hideSimilarChannels)
        self.disableGreetingSticker = boolValue("disableGreetingSticker", d.disableGreetingSticker)
        self.disableOpenLinkWarning = boolValue("disableOpenLinkWarning", d.disableOpenLinkWarning)
        self.filterZalgo = boolValue("filterZalgo", d.filterZalgo)
        self.stickerConfirmation = boolValue("stickerConfirmation", d.stickerConfirmation)
        self.gifConfirmation = boolValue("gifConfirmation", d.gifConfirmation)
        self.voiceConfirmation = boolValue("voiceConfirmation", d.voiceConfirmation)
        self.deletedMark = (try? container.decodeIfPresent(String.self, forKey: "deletedMark")) ?? d.deletedMark
        self.editedMark = (try? container.decodeIfPresent(String.self, forKey: "editedMark")) ?? d.editedMark
        self.simpleQuotesAndReplies = boolValue("simpleQuotesAndReplies", d.simpleQuotesAndReplies)
        self.recentStickersCount = (try? container.decodeIfPresent(Int32.self, forKey: "recentStickersCount")) ?? d.recentStickersCount
        self.showMessageShot = boolValue("showMessageShot", d.showMessageShot)
        self.wideMultiplier = (try? container.decodeIfPresent(Double.self, forKey: "wideMultiplier")) ?? d.wideMultiplier
        self.showMessageDetailsInContextMenu = enumValue("showMessageDetailsInContextMenu", d.showMessageDetailsInContextMenu)
        self.showRepeatInContextMenu = enumValue("showRepeatInContextMenu", d.showRepeatInContextMenu)
        self.shadowBanIds = (try? container.decodeIfPresent([Int64].self, forKey: "shadowBanIds")) ?? d.shadowBanIds
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)

        try container.encode((self.ghostModeEnabled ? 1 : 0) as Int32, forKey: "ghostModeEnabled")
        try container.encode((self.sendReadReceipts ? 1 : 0) as Int32, forKey: "sendReadReceipts")
        try container.encode((self.sendReadStories ? 1 : 0) as Int32, forKey: "sendReadStories")
        try container.encode((self.sendOnlineStatus ? 1 : 0) as Int32, forKey: "sendOnlineStatus")
        try container.encode((self.sendUploadProgress ? 1 : 0) as Int32, forKey: "sendUploadProgress")
        try container.encode((self.sendTyping ? 1 : 0) as Int32, forKey: "sendTyping")
        try container.encode((self.sendOfflineAfterAction ? 1 : 0) as Int32, forKey: "sendOfflineAfterAction")
        try container.encode((self.markReadAfterAction ? 1 : 0) as Int32, forKey: "markReadAfterAction")
        try container.encode((self.useScheduledMessages ? 1 : 0) as Int32, forKey: "useScheduledMessages")
        try container.encode(self.sendWithoutSound.rawValue, forKey: "sendWithoutSound")
        try container.encode((self.saveDeletedMessages ? 1 : 0) as Int32, forKey: "saveDeletedMessages")
        try container.encode((self.saveMessagesHistory ? 1 : 0) as Int32, forKey: "saveMessagesHistory")
        try container.encode((self.saveForBots ? 1 : 0) as Int32, forKey: "saveForBots")
        try container.encode((self.localPremium ? 1 : 0) as Int32, forKey: "localPremium")
        try container.encode((self.hideFromBlocked ? 1 : 0) as Int32, forKey: "hideFromBlocked")
        try container.encode(self.showPeerId.rawValue, forKey: "showPeerId")
        try container.encode((self.showRegistrationDate ? 1 : 0) as Int32, forKey: "showRegistrationDate")
        try container.encode((self.showMessageSeconds ? 1 : 0) as Int32, forKey: "showMessageSeconds")
        try container.encode((self.showMessageDetails ? 1 : 0) as Int32, forKey: "showMessageDetails")
        try container.encode((self.disableAds ? 1 : 0) as Int32, forKey: "disableAds")
        try container.encode((self.disableStories ? 1 : 0) as Int32, forKey: "disableStories")
        try container.encode((self.disableCustomBackgrounds ? 1 : 0) as Int32, forKey: "disableCustomBackgrounds")
        try container.encode((self.hidePremiumStatuses ? 1 : 0) as Int32, forKey: "hidePremiumStatuses")
        try container.encode((self.showOnlyAddedEmojisAndStickers ? 1 : 0) as Int32, forKey: "showOnlyAddedEmojisAndStickers")
        try container.encode((self.collapseSimilarChannels ? 1 : 0) as Int32, forKey: "collapseSimilarChannels")
        try container.encode((self.hideSimilarChannels ? 1 : 0) as Int32, forKey: "hideSimilarChannels")
        try container.encode((self.disableGreetingSticker ? 1 : 0) as Int32, forKey: "disableGreetingSticker")
        try container.encode((self.disableOpenLinkWarning ? 1 : 0) as Int32, forKey: "disableOpenLinkWarning")
        try container.encode((self.filterZalgo ? 1 : 0) as Int32, forKey: "filterZalgo")
        try container.encode((self.stickerConfirmation ? 1 : 0) as Int32, forKey: "stickerConfirmation")
        try container.encode((self.gifConfirmation ? 1 : 0) as Int32, forKey: "gifConfirmation")
        try container.encode((self.voiceConfirmation ? 1 : 0) as Int32, forKey: "voiceConfirmation")
        try container.encode(self.deletedMark, forKey: "deletedMark")
        try container.encode(self.editedMark, forKey: "editedMark")
        try container.encode((self.simpleQuotesAndReplies ? 1 : 0) as Int32, forKey: "simpleQuotesAndReplies")
        try container.encode(self.recentStickersCount, forKey: "recentStickersCount")
        try container.encode((self.showMessageShot ? 1 : 0) as Int32, forKey: "showMessageShot")
        try container.encode(self.wideMultiplier, forKey: "wideMultiplier")
        try container.encode(self.showMessageDetailsInContextMenu.rawValue, forKey: "showMessageDetailsInContextMenu")
        try container.encode(self.showRepeatInContextMenu.rawValue, forKey: "showRepeatInContextMenu")
        try container.encode(self.shadowBanIds, forKey: "shadowBanIds")
    }

    public func isShadowBanned(_ id: Int64) -> Bool {
        return self.shadowBanIds.contains(id)
    }

    public func withUpdatedShadowBan(_ id: Int64, banned: Bool) -> ShadowgramSettings {
        var updated = self
        if banned {
            if !updated.shadowBanIds.contains(id) {
                updated.shadowBanIds.append(id)
            }
        } else {
            updated.shadowBanIds.removeAll(where: { $0 == id })
        }
        return updated
    }
}
