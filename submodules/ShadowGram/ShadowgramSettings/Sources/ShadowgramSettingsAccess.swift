import Foundation
import TelegramCore
import SwiftSignalKit
import TelegramUIPreferences

// Canonical read / write helpers for ShadowgramSettings, mirroring the
// updateXInteractively convention used across TelegramUIPreferences. The
// settings live in the account manager's shared-data store under the
// centrally-registered ApplicationSpecificSharedDataKeys.shadowgramSettings key.

public extension ShadowgramSettings {
    static func get(accountManager: AccountManager<TelegramAccountManagerTypes>) -> Signal<ShadowgramSettings, NoError> {
        return accountManager.sharedData(keys: [ApplicationSpecificSharedDataKeys.shadowgramSettings])
        |> map { sharedData -> ShadowgramSettings in
            return sharedData.entries[ApplicationSpecificSharedDataKeys.shadowgramSettings]?.get(ShadowgramSettings.self) ?? ShadowgramSettings.defaultSettings
        }
    }
}

public func updateShadowgramSettingsInteractively(accountManager: AccountManager<TelegramAccountManagerTypes>, _ f: @escaping (ShadowgramSettings) -> ShadowgramSettings) -> Signal<Void, NoError> {
    return accountManager.transaction { transaction -> Void in
        transaction.updateSharedData(ApplicationSpecificSharedDataKeys.shadowgramSettings, { entry in
            let currentSettings: ShadowgramSettings
            if let entry = entry?.get(ShadowgramSettings.self) {
                currentSettings = entry
            } else {
                currentSettings = .defaultSettings
            }
            return SharedPreferencesEntry(f(currentSettings))
        })
    }
}
