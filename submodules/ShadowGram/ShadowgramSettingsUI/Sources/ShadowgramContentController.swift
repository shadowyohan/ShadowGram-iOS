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

private final class ShadowgramContentArguments {
    let context: AccountContext
    let updateSettings: (@escaping (ShadowgramSettings) -> ShadowgramSettings) -> Void

    init(context: AccountContext, updateSettings: @escaping (@escaping (ShadowgramSettings) -> ShadowgramSettings) -> Void) {
        self.context = context
        self.updateSettings = updateSettings
    }
}

private enum ShadowgramContentSection: Int32 {
    case hide
    case channels
    case confirmations
    case warnings
}

private enum ShadowgramContentEntry: ItemListNodeEntry {
    case hideHeader
    case disableAds(Bool)
    case disableStories(Bool)
    case hidePremiumStatuses(Bool)
    case disableCustomBackgrounds(Bool)
    case disableGreetingSticker(Bool)
    case hideFooter

    case channelsHeader
    case collapseSimilar(Bool)
    case hideSimilar(Bool)
    case channelsFooter

    case confirmHeader
    case stickerConfirm(Bool)
    case gifConfirm(Bool)
    case voiceConfirm(Bool)
    case confirmFooter

    case warnHeader
    case disableLinkWarning(Bool)
    case filterZalgo(Bool)
    case warnFooter

    var section: ItemListSectionId {
        switch self {
        case .hideHeader, .disableAds, .disableStories, .hidePremiumStatuses, .disableCustomBackgrounds, .disableGreetingSticker, .hideFooter:
            return ShadowgramContentSection.hide.rawValue
        case .channelsHeader, .collapseSimilar, .hideSimilar, .channelsFooter:
            return ShadowgramContentSection.channels.rawValue
        case .confirmHeader, .stickerConfirm, .gifConfirm, .voiceConfirm, .confirmFooter:
            return ShadowgramContentSection.confirmations.rawValue
        case .warnHeader, .disableLinkWarning, .filterZalgo, .warnFooter:
            return ShadowgramContentSection.warnings.rawValue
        }
    }

    var stableId: Int32 {
        switch self {
        case .hideHeader: return 0
        case .disableAds: return 1
        case .disableStories: return 2
        case .hidePremiumStatuses: return 3
        case .disableCustomBackgrounds: return 4
        case .disableGreetingSticker: return 5
        case .hideFooter: return 6
        case .channelsHeader: return 7
        case .collapseSimilar: return 8
        case .hideSimilar: return 9
        case .channelsFooter: return 10
        case .confirmHeader: return 11
        case .stickerConfirm: return 12
        case .gifConfirm: return 13
        case .voiceConfirm: return 14
        case .confirmFooter: return 15
        case .warnHeader: return 16
        case .disableLinkWarning: return 17
        case .filterZalgo: return 18
        case .warnFooter: return 19
        }
    }

    static func <(lhs: ShadowgramContentEntry, rhs: ShadowgramContentEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }

    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let arguments = arguments as! ShadowgramContentArguments
        switch self {
        case .hideHeader:
            return ItemListSectionHeaderItem(presentationData: presentationData, text: "HIDE CONTENT", sectionId: self.section)
        case let .disableAds(value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: "Hide sponsored messages", value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateSettings { s in var s = s; s.disableAds = value; return s }
            })
        case let .disableStories(value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: "Hide stories", value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateSettings { s in var s = s; s.disableStories = value; return s }
            })
        case let .hidePremiumStatuses(value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: "Hide premium statuses", value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateSettings { s in var s = s; s.hidePremiumStatuses = value; return s }
            })
        case let .disableCustomBackgrounds(value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: "Ignore custom backgrounds", value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateSettings { s in var s = s; s.disableCustomBackgrounds = value; return s }
            })
        case let .disableGreetingSticker(value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: "Hide greeting sticker", value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateSettings { s in var s = s; s.disableGreetingSticker = value; return s }
            })
        case .hideFooter:
            return ItemListTextItem(presentationData: presentationData, text: .plain("Remove clutter from your feed. Some options take effect after a restart."), sectionId: self.section)
        case .channelsHeader:
            return ItemListSectionHeaderItem(presentationData: presentationData, text: "SIMILAR CHANNELS", sectionId: self.section)
        case let .collapseSimilar(value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: "Collapse similar channels", value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateSettings { s in var s = s; s.collapseSimilarChannels = value; return s }
            })
        case let .hideSimilar(value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: "Hide similar channels", value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateSettings { s in var s = s; s.hideSimilarChannels = value; return s }
            })
        case .channelsFooter:
            return ItemListTextItem(presentationData: presentationData, text: .plain("Control the \"similar channels\" strip shown when opening a channel."), sectionId: self.section)
        case .confirmHeader:
            return ItemListSectionHeaderItem(presentationData: presentationData, text: "SEND CONFIRMATIONS", sectionId: self.section)
        case let .stickerConfirm(value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: "Confirm before sending stickers", value: value, maximumNumberOfLines: 2, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateSettings { s in var s = s; s.stickerConfirmation = value; return s }
            })
        case let .gifConfirm(value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: "Confirm before sending GIFs", value: value, maximumNumberOfLines: 2, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateSettings { s in var s = s; s.gifConfirmation = value; return s }
            })
        case let .voiceConfirm(value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: "Confirm before sending voice", value: value, maximumNumberOfLines: 2, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateSettings { s in var s = s; s.voiceConfirmation = value; return s }
            })
        case .confirmFooter:
            return ItemListTextItem(presentationData: presentationData, text: .plain("Ask for confirmation before sending these media types."), sectionId: self.section)
        case .warnHeader:
            return ItemListSectionHeaderItem(presentationData: presentationData, text: "TEXT & LINKS", sectionId: self.section)
        case let .disableLinkWarning(value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: "Skip open-link warning", value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateSettings { s in var s = s; s.disableOpenLinkWarning = value; return s }
            })
        case let .filterZalgo(value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: "Filter zalgo text", value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateSettings { s in var s = s; s.filterZalgo = value; return s }
            })
        case .warnFooter:
            return ItemListTextItem(presentationData: presentationData, text: .plain("Zalgo filtering strips excessive combining diacritics from incoming text."), sectionId: self.section)
        }
    }
}

private func shadowgramContentEntries(presentationData: PresentationData, settings: ShadowgramSettings) -> [ShadowgramContentEntry] {
    var entries: [ShadowgramContentEntry] = []

    entries.append(.hideHeader)
    entries.append(.disableAds(settings.disableAds))
    entries.append(.disableStories(settings.disableStories))
    entries.append(.hidePremiumStatuses(settings.hidePremiumStatuses))
    entries.append(.disableCustomBackgrounds(settings.disableCustomBackgrounds))
    entries.append(.disableGreetingSticker(settings.disableGreetingSticker))
    entries.append(.hideFooter)

    entries.append(.channelsHeader)
    entries.append(.collapseSimilar(settings.collapseSimilarChannels))
    entries.append(.hideSimilar(settings.hideSimilarChannels))
    entries.append(.channelsFooter)

    entries.append(.confirmHeader)
    entries.append(.stickerConfirm(settings.stickerConfirmation))
    entries.append(.gifConfirm(settings.gifConfirmation))
    entries.append(.voiceConfirm(settings.voiceConfirmation))
    entries.append(.confirmFooter)

    entries.append(.warnHeader)
    entries.append(.disableLinkWarning(settings.disableOpenLinkWarning))
    entries.append(.filterZalgo(settings.filterZalgo))
    entries.append(.warnFooter)

    return entries
}

public func shadowgramContentController(context: AccountContext) -> ViewController {
    let updateSettings: (@escaping (ShadowgramSettings) -> ShadowgramSettings) -> Void = { f in
        let _ = updateShadowgramSettingsInteractively(accountManager: context.sharedContext.accountManager, f).start()
    }

    let arguments = ShadowgramContentArguments(context: context, updateSettings: updateSettings)

    let signal = combineLatest(queue: .mainQueue(),
        context.sharedContext.presentationData,
        ShadowgramSettings.get(accountManager: context.sharedContext.accountManager)
    )
    |> deliverOnMainQueue
    |> map { presentationData, settings -> (ItemListControllerState, (ItemListNodeState, Any)) in
        let controllerState = ItemListControllerState(presentationData: ItemListPresentationData(presentationData), title: .text("Content"), leftNavigationButton: nil, rightNavigationButton: nil, backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back))
        let listState = ItemListNodeState(presentationData: ItemListPresentationData(presentationData), entries: shadowgramContentEntries(presentationData: presentationData, settings: settings), style: .blocks, animateChanges: false)
        return (controllerState, (listState, arguments))
    }

    let controller = ItemListController(context: context, state: signal)
    return controller
}
