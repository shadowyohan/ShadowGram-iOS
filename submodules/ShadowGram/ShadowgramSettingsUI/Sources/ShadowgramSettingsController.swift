import Foundation
import UIKit
import Display
import SwiftSignalKit
import TelegramCore
import TelegramPresentationData
import TelegramUIPreferences
import ItemListUI
import PresentationDataUtils
import AccountContext
import ShadowgramSettings

// Root ShadowGram settings screen. This is the entry point pushed from the
// main Settings list. It follows the ItemListController convention used by
// every first-party settings screen (see ArchiveSettingsController /
// IntentsSettingsController) so it renders with the native Telegram iOS UI kit
// and reacts to theme / language changes automatically.
//
// ShadowGram-specific titles are plain string literals (not presentationData.strings.*)
// because adding new keys to lang.strings requires regenerating the strings bindings
// as part of the build; using literals keeps the module self-contained.

private final class ShadowgramSettingsControllerArguments {
    let context: AccountContext
    let updateGhostMode: (Bool) -> Void
    let openGhostMode: () -> Void
    let openMessageHistory: () -> Void
    let openAppearance: () -> Void
    let openPrivacy: () -> Void
    let openContent: () -> Void

    init(
        context: AccountContext,
        updateGhostMode: @escaping (Bool) -> Void,
        openGhostMode: @escaping () -> Void,
        openMessageHistory: @escaping () -> Void,
        openAppearance: @escaping () -> Void,
        openPrivacy: @escaping () -> Void,
        openContent: @escaping () -> Void
    ) {
        self.context = context
        self.updateGhostMode = updateGhostMode
        self.openGhostMode = openGhostMode
        self.openMessageHistory = openMessageHistory
        self.openAppearance = openAppearance
        self.openPrivacy = openPrivacy
        self.openContent = openContent
    }
}

private enum ShadowgramSettingsSection: Int32 {
    case ghost
    case sections
    case info
}

private enum ShadowgramSettingsEntry: ItemListNodeEntry {
    case ghostHeader
    case ghostToggle(Bool)
    case ghostFooter

    case ghostMode
    case messageHistory
    case appearance
    case privacy
    case content

    case info

    var section: ItemListSectionId {
        switch self {
        case .ghostHeader, .ghostToggle, .ghostFooter:
            return ShadowgramSettingsSection.ghost.rawValue
        case .ghostMode, .messageHistory, .appearance, .privacy, .content:
            return ShadowgramSettingsSection.sections.rawValue
        case .info:
            return ShadowgramSettingsSection.info.rawValue
        }
    }

    var stableId: Int32 {
        switch self {
        case .ghostHeader:
            return 0
        case .ghostToggle:
            return 1
        case .ghostFooter:
            return 2
        case .ghostMode:
            return 3
        case .messageHistory:
            return 4
        case .appearance:
            return 5
        case .privacy:
            return 6
        case .content:
            return 7
        case .info:
            return 8
        }
    }

    static func <(lhs: ShadowgramSettingsEntry, rhs: ShadowgramSettingsEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }

    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let arguments = arguments as! ShadowgramSettingsControllerArguments
        switch self {
        case .ghostHeader:
            return ItemListSectionHeaderItem(presentationData: presentationData, text: "GHOST MODE", sectionId: self.section)
        case let .ghostToggle(value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: "Ghost Mode", value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateGhostMode(value)
            })
        case .ghostFooter:
            return ItemListTextItem(presentationData: presentationData, text: .plain("When enabled, your read receipts, online status, typing and upload activity are not sent to other users."), sectionId: self.section)
        case .ghostMode:
            return ItemListDisclosureItem(presentationData: presentationData, systemStyle: .glass, title: "Ghost Mode Settings", label: "", sectionId: self.section, style: .blocks, action: {
                arguments.openGhostMode()
            })
        case .messageHistory:
            return ItemListDisclosureItem(presentationData: presentationData, systemStyle: .glass, title: "Message History", label: "", sectionId: self.section, style: .blocks, action: {
                arguments.openMessageHistory()
            })
        case .appearance:
            return ItemListDisclosureItem(presentationData: presentationData, systemStyle: .glass, title: "Appearance", label: "", sectionId: self.section, style: .blocks, action: {
                arguments.openAppearance()
            })
        case .privacy:
            return ItemListDisclosureItem(presentationData: presentationData, systemStyle: .glass, title: "Privacy", label: "", sectionId: self.section, style: .blocks, action: {
                arguments.openPrivacy()
            })
        case .content:
            return ItemListDisclosureItem(presentationData: presentationData, systemStyle: .glass, title: "Content", label: "", sectionId: self.section, style: .blocks, action: {
                arguments.openContent()
            })
        case .info:
            return ItemListTextItem(presentationData: presentationData, text: .plain("ShadowGram — AyuGram features ported to Telegram iOS."), sectionId: self.section)
        }
    }
}

private func shadowgramSettingsEntries(presentationData: PresentationData, settings: ShadowgramSettings) -> [ShadowgramSettingsEntry] {
    var entries: [ShadowgramSettingsEntry] = []

    entries.append(.ghostHeader)
    entries.append(.ghostToggle(settings.ghostModeEnabled))
    entries.append(.ghostFooter)

    entries.append(.ghostMode)
    entries.append(.messageHistory)
    entries.append(.appearance)
    entries.append(.privacy)
    entries.append(.content)

    entries.append(.info)

    return entries
}

public func shadowgramSettingsController(context: AccountContext) -> ViewController {
    var pushControllerImpl: ((ViewController) -> Void)?

    let arguments = ShadowgramSettingsControllerArguments(
        context: context,
        updateGhostMode: { value in
            let _ = updateShadowgramSettingsInteractively(accountManager: context.sharedContext.accountManager, { settings in
                var settings = settings
                settings.ghostModeEnabled = value
                if value {
                    settings.sendReadReceipts = false
                    settings.sendOnlineStatus = false
                    settings.sendTyping = false
                    settings.sendUploadProgress = false
                    settings.sendReadStories = false
                } else {
                    settings.sendReadReceipts = true
                    settings.sendOnlineStatus = true
                    settings.sendTyping = true
                    settings.sendUploadProgress = true
                    settings.sendReadStories = true
                }
                return settings
            }).start()
        },
        openGhostMode: {
            pushControllerImpl?(shadowgramGhostModeController(context: context))
        },
        openMessageHistory: {
            pushControllerImpl?(shadowgramMessageHistoryController(context: context))
        },
        openAppearance: {
            pushControllerImpl?(shadowgramAppearanceController(context: context))
        },
        openPrivacy: {
            pushControllerImpl?(shadowgramPrivacyController(context: context))
        },
        openContent: {
            pushControllerImpl?(shadowgramContentController(context: context))
        }
    )

    let signal = combineLatest(queue: .mainQueue(),
        context.sharedContext.presentationData,
        ShadowgramSettings.get(accountManager: context.sharedContext.accountManager)
    )
    |> deliverOnMainQueue
    |> map { presentationData, settings -> (ItemListControllerState, (ItemListNodeState, Any)) in
        let controllerState = ItemListControllerState(presentationData: ItemListPresentationData(presentationData), title: .text("ShadowGram"), leftNavigationButton: nil, rightNavigationButton: nil, backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back))
        let listState = ItemListNodeState(presentationData: ItemListPresentationData(presentationData), entries: shadowgramSettingsEntries(presentationData: presentationData, settings: settings), style: .blocks, animateChanges: false)
        return (controllerState, (listState, arguments))
    }

    let controller = ItemListController(context: context, state: signal)
    pushControllerImpl = { [weak controller] c in
        (controller?.navigationController as? NavigationController)?.pushViewController(c)
    }
    return controller
}
