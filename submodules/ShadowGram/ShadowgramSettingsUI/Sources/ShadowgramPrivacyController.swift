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

private final class ShadowgramPrivacyArguments {
    let context: AccountContext
    let updateSettings: (@escaping (ShadowgramSettings) -> ShadowgramSettings) -> Void
    let selectPeerIdDisplay: () -> Void

    init(context: AccountContext, updateSettings: @escaping (@escaping (ShadowgramSettings) -> ShadowgramSettings) -> Void, selectPeerIdDisplay: @escaping () -> Void) {
        self.context = context
        self.updateSettings = updateSettings
        self.selectPeerIdDisplay = selectPeerIdDisplay
    }
}

private enum ShadowgramPrivacySection: Int32 {
    case profile
    case blocked
}

private enum ShadowgramPrivacyEntry: ItemListNodeEntry {
    case profileHeader
    case peerIdDisplay(String)
    case registrationDate(Bool)
    case profileFooter

    case blockedHeader
    case hideFromBlocked(Bool)
    case blockedFooter

    var section: ItemListSectionId {
        switch self {
        case .profileHeader, .peerIdDisplay, .registrationDate, .profileFooter:
            return ShadowgramPrivacySection.profile.rawValue
        case .blockedHeader, .hideFromBlocked, .blockedFooter:
            return ShadowgramPrivacySection.blocked.rawValue
        }
    }

    var stableId: Int32 {
        switch self {
        case .profileHeader: return 0
        case .peerIdDisplay: return 1
        case .registrationDate: return 2
        case .profileFooter: return 3
        case .blockedHeader: return 4
        case .hideFromBlocked: return 5
        case .blockedFooter: return 6
        }
    }

    static func <(lhs: ShadowgramPrivacyEntry, rhs: ShadowgramPrivacyEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }

    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let arguments = arguments as! ShadowgramPrivacyArguments
        switch self {
        case .profileHeader:
            return ItemListSectionHeaderItem(presentationData: presentationData, text: "PROFILE INFO", sectionId: self.section)
        case let .peerIdDisplay(value):
            return ItemListDisclosureItem(presentationData: presentationData, systemStyle: .glass, title: "Show ID", label: value, sectionId: self.section, style: .blocks, action: {
                arguments.selectPeerIdDisplay()
            })
        case let .registrationDate(value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: "Show registration date", value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateSettings { s in var s = s; s.showRegistrationDate = value; return s }
            })
        case .profileFooter:
            return ItemListTextItem(presentationData: presentationData, text: .plain("Adds the peer ID and estimated account registration date to profile pages."), sectionId: self.section)
        case .blockedHeader:
            return ItemListSectionHeaderItem(presentationData: presentationData, text: "BLOCKED USERS", sectionId: self.section)
        case let .hideFromBlocked(value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: "Hide messages from users who blocked me", value: value, maximumNumberOfLines: 2, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateSettings { s in var s = s; s.hideFromBlocked = value; return s }
            })
        case .blockedFooter:
            return ItemListTextItem(presentationData: presentationData, text: .plain("Locally hides messages sent by users who have blocked you."), sectionId: self.section)
        }
    }
}

private func peerIdDisplayTitle(_ display: ShadowgramPeerIdDisplay) -> String {
    switch display {
    case .hidden:
        return "Hidden"
    case .telegramApi:
        return "Telegram API"
    case .botApi:
        return "Bot API"
    }
}

private func shadowgramPrivacyEntries(presentationData: PresentationData, settings: ShadowgramSettings) -> [ShadowgramPrivacyEntry] {
    var entries: [ShadowgramPrivacyEntry] = []

    entries.append(.profileHeader)
    entries.append(.peerIdDisplay(peerIdDisplayTitle(settings.showPeerId)))
    entries.append(.registrationDate(settings.showRegistrationDate))
    entries.append(.profileFooter)

    entries.append(.blockedHeader)
    entries.append(.hideFromBlocked(settings.hideFromBlocked))
    entries.append(.blockedFooter)

    return entries
}

public func shadowgramPrivacyController(context: AccountContext) -> ViewController {
    var presentControllerImpl: ((ViewController) -> Void)?

    let updateSettings: (@escaping (ShadowgramSettings) -> ShadowgramSettings) -> Void = { f in
        let _ = updateShadowgramSettingsInteractively(accountManager: context.sharedContext.accountManager, f).start()
    }

    let arguments = ShadowgramPrivacyArguments(context: context, updateSettings: updateSettings, selectPeerIdDisplay: {
        let presentationData = context.sharedContext.currentPresentationData.with { $0 }
        let controller = ActionSheetController(presentationData: presentationData)
        let dismissAction: () -> Void = { [weak controller] in
            controller?.dismissAnimated()
        }
        let options: [ShadowgramPeerIdDisplay] = [.hidden, .telegramApi, .botApi]
        var items: [ActionSheetItem] = []
        for option in options {
            items.append(ActionSheetButtonItem(title: peerIdDisplayTitle(option), action: {
                dismissAction()
                updateSettings { s in var s = s; s.showPeerId = option; return s }
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
        let controllerState = ItemListControllerState(presentationData: ItemListPresentationData(presentationData), title: .text("Privacy"), leftNavigationButton: nil, rightNavigationButton: nil, backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back))
        let listState = ItemListNodeState(presentationData: ItemListPresentationData(presentationData), entries: shadowgramPrivacyEntries(presentationData: presentationData, settings: settings), style: .blocks, animateChanges: false)
        return (controllerState, (listState, arguments))
    }

    let controller = ItemListController(context: context, state: signal)
    presentControllerImpl = { [weak controller] c in
        controller?.present(c, in: .window(.root))
    }
    return controller
}
