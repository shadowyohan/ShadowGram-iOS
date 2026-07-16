# ShadowGram for iOS

ShadowGram is a Telegram iOS fork that ports the unique features of **AyuGram Desktop**
(a Telegram Desktop / C++ Qt fork) onto the official Telegram iOS sources, using Telegram
iOS's own UI kit (`ItemListUI` / `Display`) and Apple's UIKit.

This document describes what has been added, how it is wired into the app, how to open the
project in Xcode, and the precise integration map for the remaining behavioral hooks.

---

## 1. What was added

A new module group under `submodules/ShadowGram/`:

| Module | Path | Purpose |
|---|---|---|
| `ShadowgramSettings` | `submodules/ShadowGram/ShadowgramSettings` | Persisted settings model + read/update helpers |
| `ShadowgramSettingsUI` | `submodules/ShadowGram/ShadowgramSettingsUI` | Native settings screens (root + 5 sub-screens) |
| `ShadowgramData` | `submodules/ShadowGram/ShadowgramData` | Reserved for the local deleted/edited message DB (see §5) |

Plus small, surgical edits to first-party files to register the settings key, expose a
synchronous accessor, and add the entry point in the Settings list (see §3).

### Settings model — `ShadowgramSettings`

`submodules/ShadowGram/ShadowgramSettings/Sources/ShadowgramSettings.swift` is a
`Codable, Equatable` struct that follows the exact serialization convention used by every
first-party settings struct in `TelegramUIPreferences` (`StringCodingKey`, `Int32`-encoded
bools, `defaultSettings`, explicit `init(from:)` / `encode(to:)`). It carries every
**portable** AyuGram toggle, grouped by feature:

- **Ghost mode**: `ghostModeEnabled`, `sendReadReceipts`, `sendReadStories`, `sendOnlineStatus`,
  `sendUploadProgress`, `sendTyping`, `sendOfflineAfterAction`, `markReadAfterAction`,
  `useScheduledMessages`, `sendWithoutSound`.
- **Message history**: `saveDeletedMessages`, `saveMessagesHistory`, `saveForBots`,
  `showMessageDetails`.
- **Local premium**: `localPremium`.
- **Privacy**: `hideFromBlocked`, `showPeerId`, `showRegistrationDate`, `showMessageSeconds`,
  `shadowBanIds` (+ `isShadowBanned` / `withUpdatedShadowBan`).
- **Content controls**: `disableAds`, `disableStories`, `disableCustomBackgrounds`,
  `hidePremiumStatuses`, `showOnlyAddedEmojisAndStickers`, `collapseSimilarChannels`,
  `hideSimilarChannels`, `disableGreetingSticker`, `disableOpenLinkWarning`, `filterZalgo`,
  `stickerConfirmation`, `gifConfirmation`, `voiceConfirmation`.
- **Appearance**: `deletedMark`, `editedMark`, `simpleQuotesAndReplies`, `recentStickersCount`,
  `showMessageShot`, `wideMultiplier`, context-menu visibility flags.

The settings live in the account manager's shared-data store under a new, centrally-registered
key `ApplicationSpecificSharedDataKeys.shadowgramSettings` (raw value `23`, added in
`submodules/TelegramUIPreferences/Sources/PostboxKeys.swift`).

Read / write helpers are in
`submodules/ShadowGram/ShadowgramSettings/Sources/ShadowgramSettingsAccess.swift`:
- `ShadowgramSettings.get(accountManager:)` → `Signal<ShadowgramSettings, NoError>`
- `updateShadowgramSettingsInteractively(accountManager:_:)` → `Signal<Void, NoError>`

### Settings UI — `ShadowgramSettingsUI`

Six screens, each built with `ItemListController` exactly like `ArchiveSettingsController` /
`IntentsSettingsController`, so they render with the native look and react to theme / language
changes automatically:

- `shadowgramSettingsController` — root screen (master Ghost toggle + navigation to sub-screens)
- `shadowgramGhostModeController` — per-activity ghost toggles + silent-send picker
- `shadowgramMessageHistoryController` — save deleted / edits / bot chats, message details
- `shadowgramAppearanceController` — seconds, simple quotes, Message Shot, deleted mark picker
- `shadowgramPrivacyController` — peer-ID display, registration date, hide-from-blocked
- `shadowgramContentController` — hide ads/stories/premium statuses, similar channels,
  send confirmations, link warning, zalgo filter

> ShadowGram-specific row titles are plain string literals rather than
> `presentationData.strings.*`. Adding new keys to `Telegram/Resources/langs/lang.strings`
> requires regenerating the strings bindings as a build step; literals keep the module
> self-contained. To localize, add `ShadowGram_*` keys to `lang.strings` and swap the literals.

---

## 2. Entry point

The screen is reachable from **Settings → ShadowGram** (in the "advanced" cluster, right after
Appearance). Wiring:

- `submodules/TelegramUI/Components/PeerInfo/PeerInfoScreen/Sources/PeerInfoScreen.swift`
  — added `case shadowGram` to `PeerInfoSettingsSection`.
- `.../PeerInfoSettingsItems.swift` — added the disclosure row (id `7`, icon
  `PresentationResourcesSettings.shadowGram`).
- `.../PeerInfoScreenSettingsActions.swift` — added
  `case .shadowGram: push(shadowgramSettingsController(context:))` + `import ShadowgramSettingsUI`.
- `submodules/TelegramPresentationData/Sources/Resources/PresentationResourcesSettings.swift`
  — added the `shadowGram` settings icon (reuses the bundled Privacy glyph, violet background).

---

## 3. Reading settings from feature code (the integration seam)

A synchronous accessor was added to `SharedAccountContext`, mirroring
`immediateExperimentalUISettings`:

```swift
// AccountContext protocol (submodules/AccountContext/Sources/AccountContext.swift)
var currentShadowgramSettings: Atomic<ShadowgramSettings> { get }
```

It is backed in `submodules/TelegramUI/Sources/SharedAccountContext.swift` by an `Atomic` kept
current via a `sharedData(keys:)` subscription. Any chat / message / rendering code can branch on
a setting with no signal plumbing:

```swift
if context.sharedContext.currentShadowgramSettings.with({ $0 }).disableAds {
    // hide the sponsored message
}
```

For reactive UI, `combineLatest` in
`context.sharedContext.accountManager.sharedData(keys: [ApplicationSpecificSharedDataKeys.shadowgramSettings])`
and pull `entries[key]?.get(ShadowgramSettings.self) ?? .defaultSettings`.

---

## 4. Building / opening in Xcode

> **Toolchain requirement (hard):** `versions.json` pins **Xcode 26.2** and **Bazel 8.4.2**.
> Telegram iOS's Xcode project is *generated* by Bazel + `rules_xcodeproj`; there is no static
> `.xcodeproj` to open. `Make.py` downloads the correct Bazel automatically, but the Xcode
> version must match (an older Xcode will fail project generation / indexing).

Generate the Xcode project (this includes the ShadowGram modules automatically, since they are in
the `//submodules/TelegramUI` dependency graph):

```sh
python3 build-system/Make/Make.py \
  --cacheDir="$HOME/telegram-bazel-cache" \
  generateProject \
  --configurationPath=build-system/appstore-configuration.json \
  --codesigningInformationPath=<path-to-your-signing-repo> \
  --disableExtensions
```

`--disableExtensions` is recommended so Xcode indexes the source cleanly. The generated
`Telegram.xcodeproj` opens in Xcode; build the `Telegram` scheme.

For a headless full build (no Xcode UI), use the `build` subcommand documented in `CLAUDE.md`.

### Why the project can't be generated in every environment
Generation shells out to Bazel and `rules_xcodeproj`, which require the pinned Xcode. On a
machine with a different Xcode (e.g. 15.x), run `xcode-select` to a 26.2 install first, or use the
`remote-build` path. The ShadowGram wiring itself is toolchain-independent — it is plain Swift +
Bazel `BUILD` files already merged into the graph.

---

## 5. Remaining behavioral integration map

The settings model, UI, entry point, and read-seam are complete. Making each toggle change
runtime behavior means editing the corresponding first-party site to read
`currentShadowgramSettings`. These edits are intentionally **not** applied blindly (they touch hot
paths and must be compiled/tested against the pinned toolchain). Precise hook points:

| Feature | Setting | Hook site (iOS) |
|---|---|---|
| Hide sponsored messages | `disableAds` | Ad item construction in `ChatHistoryListNode` / `ChatControllerNode` where `adMessages` are inserted — skip when set. |
| Ghost: skip read receipts | `sendReadReceipts` | The history-read path already has `ExperimentalUISettings.skipReadHistory`; gate the same `installedStickerPacks`/`applyMaxReadIndex` calls (`TelegramCore` `applyMaxReadIndexInteractively`) additionally on this flag. |
| Ghost: online status | `sendOnlineStatus` | `AccountStateManager` / `updateAccountPeerPresence` — suppress the periodic online update. |
| Ghost: typing | `sendTyping` | `ChatControllerNode` typing activity → don't send `.typingText` `setTypingActivity`. |
| Ghost: upload progress | `sendUploadProgress` | Upload activity reporting in the media upload pipeline. |
| Ghost: story views | `sendReadStories` | Story view reporting (`markStoryAsSeen`). |
| Save deleted / edited | `saveDeletedMessages`, `saveMessagesHistory` | Subscribe to message deletions/edits (postbox `MessageHistory` updates) and persist snapshots into `ShadowgramData` (SQLite/GRDB). Present via a "Deleted messages" chat-like screen. |
| Show peer ID | `showPeerId` | `PeerInfoScreen` info items — append an ID row (Bot-API vs raw form). |
| Registration date | `showRegistrationDate` | `PeerInfoScreen` — estimate from peer id ranges and show a row. |
| Message seconds | `showMessageSeconds` | Timestamp formatting in `ChatMessageDateAndStatusNode` — include seconds. |
| Hide premium statuses | `hidePremiumStatuses` | Emoji-status badge rendering next to names in chat list / message headers. |
| Hide stories | `disableStories` | Stories strip in `ChatListController` — hide when set. |
| Send confirmations | `stickerConfirmation` / `gifConfirmation` / `voiceConfirmation` | Present a confirm alert in the sticker/GIF/voice send paths. |
| Skip link warning | `disableOpenLinkWarning` | External-link open confirmation in `openExternalUrl`. |
| Zalgo filter | `filterZalgo` | Incoming text rendering — strip excess combining marks before layout. |
| Message Shot | `showMessageShot` | Add a message action-menu item that renders the bubble to a `UIImage` and shares it. |

Desktop-only AyuGram features intentionally excluded on iOS: Streamer Mode (window
screen-capture exclusion), tray toggles, Material switches, mono-font picker, message-field
hover popups, and desktop maintenance actions. Taptic engine maps to `UIFeedbackGenerator`;
the online-status worker maps to a background task.
