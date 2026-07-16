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

private final class ShadowgramAppearanceArguments {
    let context: AccountContext
    let updateSettings: (@escaping (ShadowgramSettings) -> ShadowgramSettings) -> Void
    let selectDeletedMark: () -> Void

    init(context: AccountContext, updateSettings: @escaping (@escaping (ShadowgramSettings) -> ShadowgramSettings) -> Void, selectDeletedMark: @escaping () -> Void) {
        self.context = context
        self.updateSettings = updateSettings
        self.selectDeletedMark = selectDeletedMark
    }
}

private enum ShadowgramAppearanceSection: Int32 {
    case timestamps
    case bubbles
    case marks
}

private enum ShadowgramAppearanceEntry: ItemListNodeEntry {
    case timeHeader
    case showSeconds(Bool)
    case timeFooter

    case bubbleHeader
    case simpleQuotes(Bool)
    case messageShot(Bool)
    case bubbleFooter

    case markHeader
    case deletedMark(String)
    case markFooter

    var section: ItemListSectionId {
        switch self {
        case .timeHeader, .showSeconds, .timeFooter:
            return ShadowgramAppearanceSection.timestamps.rawValue
        case .bubbleHeader, .simpleQuotes, .messageShot, .bubbleFooter:
            return ShadowgramAppearanceSection.bubbles.rawValue
        case .markHeader, .deletedMark, .markFooter:
            return ShadowgramAppearanceSection.marks.rawValue
        }
    }

    var stableId: Int32 {
        switch self {
        case .timeHeader: return 0
        case .showSeconds: return 1
        case .timeFooter: return 2
        case .bubbleHeader: return 3
        case .simpleQuotes: return 4
        case .messageShot: return 5
        case .bubbleFooter: return 6
        case .markHeader: return 7
        case .deletedMark: return 8
        case .markFooter: return 9
        }
    }

    static func <(lhs: ShadowgramAppearanceEntry, rhs: ShadowgramAppearanceEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }

    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let arguments = arguments as! ShadowgramAppearanceArguments
        switch self {
        case .timeHeader:
            return ItemListSectionHeaderItem(presentationData: presentationData, text: "TIMESTAMPS", sectionId: self.section)
        case let .showSeconds(value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: "Show seconds", value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateSettings { s in var s = s; s.showMessageSeconds = value; return s }
            })
        case .timeFooter:
            return ItemListTextItem(presentationData: presentationData, text: .plain("Display seconds in message timestamps."), sectionId: self.section)
        case .bubbleHeader:
            return ItemListSectionHeaderItem(presentationData: presentationData, text: "MESSAGES", sectionId: self.section)
        case let .simpleQuotes(value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: "Simple quotes and replies", value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateSettings { s in var s = s; s.simpleQuotesAndReplies = value; return s }
            })
        case let .messageShot(value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: "Enable Message Shot", value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateSettings { s in var s = s; s.showMessageShot = value; return s }
            })
        case .bubbleFooter:
            return ItemListTextItem(presentationData: presentationData, text: .plain("Message Shot lets you render a message into a shareable image from its action menu."), sectionId: self.section)
        case .markHeader:
            return ItemListSectionHeaderItem(presentationData: presentationData, text: "DELETED MESSAGE MARK", sectionId: self.section)
        case let .deletedMark(value):
            return ItemListDisclosureItem(presentationData: presentationData, systemStyle: .glass, title: "Mark", label: value.isEmpty ? "None" : value, sectionId: self.section, style: .blocks, action: {
                arguments.selectDeletedMark()
            })
        case .markFooter:
            return ItemListTextItem(presentationData: presentationData, text: .plain("Symbol appended to messages that were deleted by their sender."), sectionId: self.section)
        }
    }
}

private func shadowgramAppearanceEntries(presentationData: PresentationData, settings: ShadowgramSettings) -> [ShadowgramAppearanceEntry] {
    var entries: [ShadowgramAppearanceEntry] = []

    entries.append(.timeHeader)
    entries.append(.showSeconds(settings.showMessageSeconds))
    entries.append(.timeFooter)

    entries.append(.bubbleHeader)
    entries.append(.simpleQuotes(settings.simpleQuotesAndReplies))
    entries.append(.messageShot(settings.showMessageShot))
    entries.append(.bubbleFooter)

    entries.append(.markHeader)
    entries.append(.deletedMark(settings.deletedMark))
    entries.append(.markFooter)

    return entries
}

public func shadowgramAppearanceController(context: AccountContext) -> ViewController {
    var presentControllerImpl: ((ViewController) -> Void)?

    let updateSettings: (@escaping (ShadowgramSettings) -> ShadowgramSettings) -> Void = { f in
        let _ = updateShadowgramSettingsInteractively(accountManager: context.sharedContext.accountManager, f).start()
    }

    let arguments = ShadowgramAppearanceArguments(context: context, updateSettings: updateSettings, selectDeletedMark: {
        let presentationData = context.sharedContext.currentPresentationData.with { $0 }
        let controller = ActionSheetController(presentationData: presentationData)
        let dismissAction: () -> Void = { [weak controller] in
            controller?.dismissAnimated()
        }
        let presets: [(String, String)] = [("🧹", "🧹"), ("🗑", "🗑"), ("❌", "❌"), ("None", "")]
        var items: [ActionSheetItem] = []
        for (title, value) in presets {
            items.append(ActionSheetButtonItem(title: title, action: {
                dismissAction()
                updateSettings { s in var s = s; s.deletedMark = value; return s }
            }))
        }
        controller.setItemGroups([
            ActionSheetItemGroup(items: items),
            ActionSheetItemGroup(items: [ActionSheetButtonItem(title: presentationData.strings.Common_Cancel, color: .accent, font: .bold, action: { dismissAction() })])
        ])
        presentControllerImpl?(controller)
    })

    let signal = combineLatest(queue: .mainQueue(),
        context.sharedContext.presentationData,
        ShadowgramSettings.get(accountManager: context.sharedContext.accountManager)
    )
    |> deliverOnMainQueue
    |> map { presentationData, settings -> (ItemListControllerState, (ItemListNodeState, Any)) in
        let controllerState = ItemListControllerState(presentationData: ItemListPresentationData(presentationData), title: .text("Appearance"), leftNavigationButton: nil, rightNavigationButton: nil, backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back))
        let listState = ItemListNodeState(presentationData: ItemListPresentationData(presentationData), entries: shadowgramAppearanceEntries(presentationData: presentationData, settings: settings), style: .blocks, animateChanges: false)
        return (controllerState, (listState, arguments))
    }

    let controller = ItemListController(context: context, state: signal)
    presentControllerImpl = { [weak controller] c in
        controller?.present(c, in: .window(.root))
    }
    return controller
}
