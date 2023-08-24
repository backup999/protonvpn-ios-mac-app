//
//  CountryItemViewModelTests.swift
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

import XCTest
import LegacyCommon
import ProtonCoreUIFoundations
import TimerMock
import VPNShared
import VPNSharedTesting
import Dependencies
import VPNAppCore

@testable import ProtonVPN

class CountryItemViewModelTests: XCTestCase {

    func testUnderMaintenanceLogic() {
        withDependencies {
            $0.featureFlagProvider = .constant(flags: .allDisabled)
        } operation: {
            XCTAssertFalse(self.viewModel(withServers: [
                serverModel(withStatus: 5),
                serverModel(withStatus: 1),
                serverModel(withStatus: 25),
            ]).connectIcon! == IconProvider.wrench, "UnderMaintenance returned true while no server is under maintenance")

            XCTAssertFalse(self.viewModel(withServers: [
                serverModel(withStatus: 5),
                serverModel(withStatus: 1),
                serverModel(withStatus: 0),
            ]).connectIcon! == IconProvider.wrench, "UnderMaintenance returned true while at least one server is not under maintenance")

            XCTAssertTrue(self.viewModel(withServers: [
                serverModel(withStatus: 0),
                serverModel(withStatus: 0),
                serverModel(withStatus: 0),
            ]).connectIcon! == IconProvider.wrench, "UnderMaintenance returned false while all servers are under maintenance")
        }
    }

    // MARK: Mocks
    // FUTUREFIX: Make/find a factory for creating mocks
    
    private func viewModel(withServers servers: [ServerModel]) -> CountryItemViewModel {
        let country = CountryModel(serverModel: self.serverModel(withStatus: 22))
        let group: ServerGroup = ServerGroup(kind: .country(country), servers: servers)
        let vpnKeychain = VpnKeychainMock()
        let networking = CoreNetworking(delegate: iOSNetworkingDelegate(alertingService: CoreAlertServiceDummy()), appInfo: AppInfoImplementation(), doh: .mock, authKeychain: MockAuthKeychain(), unauthKeychain: UnauthKeychainMock())
        let vpnApiService = VpnApiService(networking: networking, vpnKeychain: vpnKeychain, countryCodeProvider: CountryCodeProviderImplementation(), authKeychain: MockAuthKeychain())
        let configurationPreparer = VpnManagerConfigurationPreparer(
            vpnKeychain: vpnKeychain,
            alertService: AlertServiceEmptyStub(),
            propertiesManager: PropertiesManagerMock())
        
        let appStateManager = AppStateManagerImplementation(
            vpnApiService: vpnApiService,
            vpnManager: VpnManagerMock(),
            networking: networking,
            alertService: AlertServiceEmptyStub(),
            timerFactory: TimerFactoryMock(),
            propertiesManager: PropertiesManagerMock(),
            vpnKeychain: vpnKeychain,
            configurationPreparer: configurationPreparer,
            vpnAuthentication: VpnAuthenticationMock(),
            doh: .mock,
            serverStorage: ServerStorageMock(),
            natTypePropertyProvider: NATTypePropertyProviderMock(),
            netShieldPropertyProvider: NetShieldPropertyProviderMock(),
            safeModePropertyProvider: SafeModePropertyProviderMock()
        )

        let viewModel = CountryItemViewModel(
            serversGroup: group,
            servers: group.servers,
            serverType: ServerType.standard,
            appStateManager: appStateManager,
            vpnGateway: VpnGatewayMock(userTier: 1),
            alertService: AlertServiceEmptyStub(),
            connectionStatusService: ConnectionStatusServiceMock(),
            propertiesManager: PropertiesManagerMock(),
            planService: PlanServiceMock(),
            serversFilter: { _ in true },
            showCountryConnectButton: true,
            showFeatureIcons: true
        )

        return viewModel
    }
    
    private func serverModel(withStatus status: Int) -> ServerModel {
        return ServerModel(
            id: "",
            name: "1",
            domain: "1",
            load: 1,
            entryCountryCode: "LT",
            exitCountryCode: "US",
            tier: 1,
            feature: ServerFeature.zero,
            city: nil,
            ips: [ServerIp(id: "", entryIp: "10.0.0.1", exitIp: "", domain: "", status: status)],
            score: 11,
            status: status,
            location: ServerLocation(lat: 1, long: 2),
            hostCountry: nil,
            translatedCity: nil,
            gatewayName: nil
        )
    }
    
}
