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

private final class ShadowgramGhostModeArguments {
    let context: AccountContext
    let updateSettings: (@escaping (ShadowgramSettings) -> ShadowgramSettings) -> Void
    let selectSendWithoutSound: () -> Void

    init(
        context: AccountContext,
        updateSettings: @escaping (@escaping (ShadowgramSettings) -> ShadowgramSettings) -> Void,
        selectSendWithoutSound: @escaping () -> Void
    ) {
        self.context = context
        self.updateSettings = updateSettings
        self.selectSendWithoutSound = selectSendWithoutSound
    }
}

private enum ShadowgramGhostModeSection: Int32 {
    case activity
    case behavior
    case sound
}

private enum ShadowgramGhostModeEntry: ItemListNodeEntry {
    case activityHeader
    case readReceipts(Bool)
    case onlineStatus(Bool)
    case typing(Bool)
    case uploadProgress(Bool)
    case readStories(Bool)
    case activityFooter

    case behaviorHeader
    case markReadAfterAction(Bool)
    case offlineAfterAction(Bool)
    case behaviorFooter

    case soundHeader
    case sendWithoutSound(String)
    case soundFooter

    var section: ItemListSectionId {
        switch self {
        case .activityHeader, .readReceipts, .onlineStatus, .typing, .uploadProgress, .readStories, .activityFooter:
            return ShadowgramGhostModeSection.activity.rawValue
        case .behaviorHeader, .markReadAfterAction, .offlineAfterAction, .behaviorFooter:
            return ShadowgramGhostModeSection.behavior.rawValue
        case .soundHeader, .sendWithoutSound, .soundFooter:
            return ShadowgramGhostModeSection.sound.rawValue
        }
    }

    var stableId: Int32 {
        switch self {
        case .activityHeader: return 0
        case .readReceipts: return 1
        case .onlineStatus: return 2
        case .typing: return 3
        case .uploadProgress: return 4
        case .readStories: return 5
        case .activityFooter: return 6
        case .behaviorHeader: return 7
        case .markReadAfterAction: return 8
        case .offlineAfterAction: return 9
        case .behaviorFooter: return 10
        case .soundHeader: return 11
        case .sendWithoutSound: return 12
        case .soundFooter: return 13
        }
    }

    static func <(lhs: ShadowgramGhostModeEntry, rhs: ShadowgramGhostModeEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }

    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let arguments = arguments as! ShadowgramGhostModeArguments
        switch self {
        case .activityHeader:
            return ItemListSectionHeaderItem(presentationData: presentationData, text: "SENT ACTIVITY", sectionId: self.section)
        case let .readReceipts(value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: "Send read receipts", value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateSettings { s in var s = s; s.sendReadReceipts = value; return s }
            })
        case let .onlineStatus(value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: "Send online status", value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateSettings { s in var s = s; s.sendOnlineStatus = value; return s }
            })
        case let .typing(value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: "Send typing status", value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateSettings { s in var s = s; s.sendTyping = value; return s }
            })
        case let .uploadProgress(value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: "Send upload progress", value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateSettings { s in var s = s; s.sendUploadProgress = value; return s }
            })
        case let .readStories(value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: "Send story views", value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateSettings { s in var s = s; s.sendReadStories = value; return s }
            })
        case .activityFooter:
            return ItemListTextItem(presentationData: presentationData, text: .plain("Turn any of these off to stop leaking that activity to other users. The master Ghost Mode toggle flips all of them at once."), sectionId: self.section)
        case .behaviorHeader:
            return ItemListSectionHeaderItem(presentationData: presentationData, text: "BEHAVIOR", sectionId: self.section)
        case let .markReadAfterAction(value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: "Mark read after replying", value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateSettings { s in var s = s; s.markReadAfterAction = value; return s }
            })
        case let .offlineAfterAction(value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: "Go offline after acting", value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateSettings { s in var s = s; s.sendOfflineAfterAction = value; return s }
            })
        case .behaviorFooter:
            return ItemListTextItem(presentationData: presentationData, text: .plain("Optionally mark a chat read when you reply in it, and push an offline status right after any online blip."), sectionId: self.section)
        case .soundHeader:
            return ItemListSectionHeaderItem(presentationData: presentationData, text: "SILENT SENDING", sectionId: self.section)
        case let .sendWithoutSound(value):
            return ItemListDisclosureItem(presentationData: presentationData, systemStyle: .glass, title: "Send without sound", label: value, sectionId: self.section, style: .blocks, action: {
                arguments.selectSendWithoutSound()
            })
        case .soundFooter:
            return ItemListTextItem(presentationData: presentationData, text: .plain("Choose when outgoing messages are sent silently."), sectionId: self.section)
        }
    }
}

private func sendWithoutSoundTitle(_ option: ShadowgramSendWithoutSoundOption) -> String {
    switch option {
    case .never:
        return "Never"
    case .inGhostMode:
        return "In Ghost Mode"
    case .always:
        return "Always"
    }
}

private func shadowgramGhostModeEntries(presentationData: PresentationData, settings: ShadowgramSettings) -> [ShadowgramGhostModeEntry] {
    var entries: [ShadowgramGhostModeEntry] = []

    entries.append(.activityHeader)
    entries.append(.readReceipts(settings.sendReadReceipts))
    entries.append(.onlineStatus(settings.sendOnlineStatus))
    entries.append(.typing(settings.sendTyping))
    entries.append(.uploadProgress(settings.sendUploadProgress))
    entries.append(.readStories(settings.sendReadStories))
    entries.append(.activityFooter)

    entries.append(.behaviorHeader)
    entries.append(.markReadAfterAction(settings.markReadAfterAction))
    entries.append(.offlineAfterAction(settings.sendOfflineAfterAction))
    entries.append(.behaviorFooter)

    entries.append(.soundHeader)
    entries.append(.sendWithoutSound(sendWithoutSoundTitle(settings.sendWithoutSound)))
    entries.append(.soundFooter)

    return entries
}

public func shadowgramGhostModeController(context: AccountContext) -> ViewController {
    var presentControllerImpl: ((ViewController) -> Void)?

    let updateSettings: (@escaping (ShadowgramSettings) -> ShadowgramSettings) -> Void = { f in
        let _ = updateShadowgramSettingsInteractively(accountManager: context.sharedContext.accountManager, f).start()
    }

    let arguments = ShadowgramGhostModeArguments(
        context: context,
        updateSettings: updateSettings,
        selectSendWithoutSound: {
            let presentationData = context.sharedContext.currentPresentationData.with { $0 }
            let controller = ActionSheetController(presentationData: presentationData)
            let dismissAction: () -> Void = { [weak controller] in
                controller?.dismissAnimated()
            }
            let options: [ShadowgramSendWithoutSoundOption] = [.never, .inGhostMode, .always]
            var items: [ActionSheetItem] = []
            for option in options {
                items.append(ActionSheetButtonItem(title: sendWithoutSoundTitle(option), action: {
                    dismissAction()
                    updateSettings { s in var s = s; s.sendWithoutSound = option; return s }
                }))
            }
            controller.setItemGroups([
                ActionSheetItemGroup(items: items),
                ActionSheetItemGroup(items: [ActionSheetButtonItem(title: presentationData.strings.Common_Cancel, color: .accent, font: .bold, action: { dismissAction() })])
            ])
            presentControllerImpl?(controller)
        }
    )

    let signal = combineLatest(queue: .mainQueue(),
        context.sharedContext.presentationData,
        ShadowgramSettings.get(accountManager: context.sharedContext.accountManager)
    )
    |> deliverOnMainQueue
    |> map { presentationData, settings -> (ItemListControllerState, (ItemListNodeState, Any)) in
        let controllerState = ItemListControllerState(presentationData: ItemListPresentationData(presentationData), title: .text("Ghost Mode"), leftNavigationButton: nil, rightNavigationButton: nil, backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back))
        let listState = ItemListNodeState(presentationData: ItemListPresentationData(presentationData), entries: shadowgramGhostModeEntries(presentationData: presentationData, settings: settings), style: .blocks, animateChanges: false)
        return (controllerState, (listState, arguments))
    }

    let controller = ItemListController(context: context, state: signal)
    presentControllerImpl = { [weak controller] c in
        controller?.present(c, in: .window(.root))
    }
    return controller
}
