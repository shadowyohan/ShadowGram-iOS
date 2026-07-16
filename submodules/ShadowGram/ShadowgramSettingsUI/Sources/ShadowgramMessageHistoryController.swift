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

private final class ShadowgramMessageHistoryArguments {
    let context: AccountContext
    let updateSettings: (@escaping (ShadowgramSettings) -> ShadowgramSettings) -> Void

    init(context: AccountContext, updateSettings: @escaping (@escaping (ShadowgramSettings) -> ShadowgramSettings) -> Void) {
        self.context = context
        self.updateSettings = updateSettings
    }
}

private enum ShadowgramMessageHistorySection: Int32 {
    case save
    case marks
}

private enum ShadowgramMessageHistoryEntry: ItemListNodeEntry {
    case saveHeader
    case saveDeleted(Bool)
    case saveEdits(Bool)
    case saveForBots(Bool)
    case saveFooter

    case marksHeader
    case showMessageDetails(Bool)
    case marksFooter

    var section: ItemListSectionId {
        switch self {
        case .saveHeader, .saveDeleted, .saveEdits, .saveForBots, .saveFooter:
            return ShadowgramMessageHistorySection.save.rawValue
        case .marksHeader, .showMessageDetails, .marksFooter:
            return ShadowgramMessageHistorySection.marks.rawValue
        }
    }

    var stableId: Int32 {
        switch self {
        case .saveHeader: return 0
        case .saveDeleted: return 1
        case .saveEdits: return 2
        case .saveForBots: return 3
        case .saveFooter: return 4
        case .marksHeader: return 5
        case .showMessageDetails: return 6
        case .marksFooter: return 7
        }
    }

    static func <(lhs: ShadowgramMessageHistoryEntry, rhs: ShadowgramMessageHistoryEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }

    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let arguments = arguments as! ShadowgramMessageHistoryArguments
        switch self {
        case .saveHeader:
            return ItemListSectionHeaderItem(presentationData: presentationData, text: "SAVE HISTORY", sectionId: self.section)
        case let .saveDeleted(value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: "Save deleted messages", value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateSettings { s in var s = s; s.saveDeletedMessages = value; return s }
            })
        case let .saveEdits(value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: "Save edit history", value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateSettings { s in var s = s; s.saveMessagesHistory = value; return s }
            })
        case let .saveForBots(value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: "Also save in bot chats", value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateSettings { s in var s = s; s.saveForBots = value; return s }
            })
        case .saveFooter:
            return ItemListTextItem(presentationData: presentationData, text: .plain("Deleted messages and every edit revision are kept in a local database so you can view them later. Nothing leaves your device."), sectionId: self.section)
        case .marksHeader:
            return ItemListSectionHeaderItem(presentationData: presentationData, text: "MESSAGE DETAILS", sectionId: self.section)
        case let .showMessageDetails(value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: "Show message details", value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateSettings { s in var s = s; s.showMessageDetails = value; return s }
            })
        case .marksFooter:
            return ItemListTextItem(presentationData: presentationData, text: .plain("Adds a \"Details\" action showing message ID, dates, file size, resolution and datacenter."), sectionId: self.section)
        }
    }
}

private func shadowgramMessageHistoryEntries(presentationData: PresentationData, settings: ShadowgramSettings) -> [ShadowgramMessageHistoryEntry] {
    var entries: [ShadowgramMessageHistoryEntry] = []

    entries.append(.saveHeader)
    entries.append(.saveDeleted(settings.saveDeletedMessages))
    entries.append(.saveEdits(settings.saveMessagesHistory))
    entries.append(.saveForBots(settings.saveForBots))
    entries.append(.saveFooter)

    entries.append(.marksHeader)
    entries.append(.showMessageDetails(settings.showMessageDetails))
    entries.append(.marksFooter)

    return entries
}

public func shadowgramMessageHistoryController(context: AccountContext) -> ViewController {
    let updateSettings: (@escaping (ShadowgramSettings) -> ShadowgramSettings) -> Void = { f in
        let _ = updateShadowgramSettingsInteractively(accountManager: context.sharedContext.accountManager, f).start()
    }

    let arguments = ShadowgramMessageHistoryArguments(context: context, updateSettings: updateSettings)

    let signal = combineLatest(queue: .mainQueue(),
        context.sharedContext.presentationData,
        ShadowgramSettings.get(accountManager: context.sharedContext.accountManager)
    )
    |> deliverOnMainQueue
    |> map { presentationData, settings -> (ItemListControllerState, (ItemListNodeState, Any)) in
        let controllerState = ItemListControllerState(presentationData: ItemListPresentationData(presentationData), title: .text("Message History"), leftNavigationButton: nil, rightNavigationButton: nil, backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back))
        let listState = ItemListNodeState(presentationData: ItemListPresentationData(presentationData), entries: shadowgramMessageHistoryEntries(presentationData: presentationData, settings: settings), style: .blocks, animateChanges: false)
        return (controllerState, (listState, arguments))
    }

    let controller = ItemListController(context: context, state: signal)
    return controller
}
