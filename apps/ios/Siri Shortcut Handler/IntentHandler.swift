//
//  IntentHandler.swift
//  ProtonVPN - Created on 01.07.19.
//
//  Copyright (c) 2019 Proton Technologies AG
//
//  This file is part of ProtonVPN.
//
//  ProtonVPN is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonVPN is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonVPN.  If not, see <https://www.gnu.org/licenses/>.
//

import Intents
import vpncore

@available(iOSApplicationExtension 12.0, *)
class IntentHandler: INExtension, QuickConnectIntentHandling, DisconnectIntentHandling, GetConnectionStatusIntentHandling {
    
    let siriHandlerViewModel: SiriHandlerViewModel
    
    override init() {
        let appInfoFactory = SiriIntentHandlerAppInfoFactory()
        let doh = DoHVPN(apiHost: "", verifyHost: "", alternativeRouting: false, appState: .disconnected)
        let networking = CoreNetworking(delegate: iOSNetworkingDelegate(alertingService: CoreAlertServiceMock()),
                                        appInfo: appInfoFactory.makeAppInfo(context: .siriIntentHandler),
                                        doh: doh)
        let openVpnExtensionBundleIdentifier = AppConstants.NetworkExtensions.openVpn
        let wireguardVpnExtensionBundleIdentifier = AppConstants.NetworkExtensions.wireguard
        let appGroup = AppConstants.AppGroups.main
        let storage = Storage()
        let propertiesManager = PropertiesManager(storage: storage)
        let vpnKeychain = VpnKeychain()
        let appIdentifierPrefix = Bundle.main.infoDictionary!["AppIdentifierPrefix"] as! String
        let vpnAuthKeychain = VpnAuthenticationKeychain(accessGroup: "\(appIdentifierPrefix)prt.ProtonVPN", storage: storage)
        let userTierProvider = UserTierProviderImplementation(UserTierProviderFactory(vpnKeychainProtocol: vpnKeychain))
        let paidFeaturePropertyProviderFactory = PaidFeaturePropertyProviderFactory(propertiesManager: propertiesManager, userTierProvider: userTierProvider)
        let netShieldPropertyProvider = NetShieldPropertyProviderImplementation(paidFeaturePropertyProviderFactory, storage: storage, userInfoProvider: AuthKeychain())
        let natTypePropertyProvider = NATTypePropertyProviderImplementation(paidFeaturePropertyProviderFactory, storage: storage, userInfoProvider: AuthKeychain())
        let safeModePropertyProvider = SafeModePropertyProviderImplementation(paidFeaturePropertyProviderFactory, storage: storage, userInfoProvider: AuthKeychain())
        let ikeFactory = IkeProtocolFactory()
        let openVpnFactory = OpenVpnProtocolFactory(bundleId: openVpnExtensionBundleIdentifier, appGroup: appGroup, propertiesManager: propertiesManager)
        let wireguardVpnFactory = WireguardProtocolFactory(bundleId: wireguardVpnExtensionBundleIdentifier, appGroup: appGroup, propertiesManager: propertiesManager)
        let vpnStateConfiguration = VpnStateConfigurationManager(ikeProtocolFactory: ikeFactory, openVpnProtocolFactory: openVpnFactory, wireguardProtocolFactory: wireguardVpnFactory, propertiesManager: propertiesManager, appGroup: appGroup)
        let sessionService = SessionServiceImplementation(appInfoFactory: appInfoFactory, networking: networking, doh: doh)
        let vpnManager = VpnManager(ikeFactory: ikeFactory,
                                    openVpnFactory: openVpnFactory,
                                    wireguardProtocolFactory: wireguardVpnFactory,
                                    appGroup: appGroup,
                                    vpnAuthentication: VpnAuthenticationRemoteClient(sessionService: sessionService,
                                                                                     authenticationStorage: vpnAuthKeychain,
                                                                                     safeModePropertyProvider: safeModePropertyProvider),
                                    vpnKeychain: vpnKeychain,
                                    propertiesManager: propertiesManager,
                                    vpnStateConfiguration: vpnStateConfiguration,
                                    vpnCredentialsConfiguratorFactory: IOSVpnCredentialsConfiguratorFactory(propertiesManager: propertiesManager),
                                    natTypePropertyProvider: natTypePropertyProvider,
                                    netShieldPropertyProvider: netShieldPropertyProvider,
                                    safeModePropertyProvider: safeModePropertyProvider)
        
        siriHandlerViewModel = SiriHandlerViewModel(networking: networking,
                                                    vpnApiService: VpnApiService(networking: networking),
                                                    vpnManager: vpnManager,
                                                    vpnKeychain: vpnKeychain,
                                                    propertiesManager: propertiesManager,
                                                    sessionService: sessionService,
                                                    netShieldPropertyProvider: netShieldPropertyProvider,
                                                    natTypePropertyProvider: natTypePropertyProvider,
                                                    safeModePropertyProvider: safeModePropertyProvider,
                                                    profileManager: ProfileManager(serverStorage: ServerStorageConcrete(), propertiesManager: propertiesManager),
                                                    doh: doh)
        
        super.init()
    }
    
    func handle(intent: QuickConnectIntent, completion: @escaping (QuickConnectIntentResponse) -> Void) {
        siriHandlerViewModel.connect(completion)
    }
    
    func handle(intent: DisconnectIntent, completion: @escaping (DisconnectIntentResponse) -> Void) {
        siriHandlerViewModel.disconnect(completion)
    }
    
    func handle(intent: GetConnectionStatusIntent, completion: @escaping (GetConnectionStatusIntentResponse) -> Void) {
        siriHandlerViewModel.getConnectionStatus(completion)
    }
    
    override func handler(for intent: INIntent) -> Any {
        // This is the default implementation.  If you want different objects to handle different intents,
        // you can override this and return the handler you want for that particular intent.
        
        return self
    }
    
}

fileprivate class PaidFeaturePropertyProviderFactory: PaidFeaturePropertyProvider.Factory {
    private let propertiesManager: PropertiesManagerProtocol
    private let userTierProvider: UserTierProvider
    
    init(propertiesManager: PropertiesManagerProtocol, userTierProvider: UserTierProvider) {
        self.propertiesManager = propertiesManager
        self.userTierProvider = userTierProvider
    }
    
    func makePropertiesManager() -> PropertiesManagerProtocol {
        return propertiesManager
    }
    
    func makeUserTierProvider() -> UserTierProvider {
        return userTierProvider
    }
}

fileprivate class UserTierProviderFactory: UserTierProviderImplementation.Factory {
    
    private let vpnKeychainProtocol: VpnKeychainProtocol
    
    public init(vpnKeychainProtocol: VpnKeychainProtocol) {
        self.vpnKeychainProtocol = vpnKeychainProtocol
    }
    
    func makeVpnKeychain() -> VpnKeychainProtocol {
        return vpnKeychainProtocol
    }
}

fileprivate class SiriIntentHandlerAppInfoFactory: AppInfoFactory {
    func makeAppInfo(context: AppContext) -> AppInfo {
        AppInfoImplementation(context: context)
    }
}
