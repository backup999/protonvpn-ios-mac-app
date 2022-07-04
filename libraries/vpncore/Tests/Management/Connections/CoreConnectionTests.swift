//
//  Created on 2022-06-27.
//
//  Copyright (c) 2022 Proton AG
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

import Foundation
import XCTest
import NetworkExtension
import Crypto_VPN

@testable import vpncore

class CoreConnectionTests: XCTestCase {
    let expectationTimeout: TimeInterval = 10

    var mockProviderState: (
        shouldRefresh: Bool,
        needNewSession: Bool
    ) = (true, false)

    var didRequestCertRefresh: (() -> ())?

    fileprivate let testData = TestData()
    fileprivate var container: Container!

    private var apiServerList: [ServerModel] = []
    private var apiCredentials: VpnCredentials?

    private lazy var responseEncoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .capitalizeFirstLetter
        return encoder
    }()

    override func setUp() {
        container = Container()
        container.networking.requestCallback = handleMockNetworkingRequest

        apiServerList = [testData.server1]
        container.serverStorage.servers = apiServerList

        container.neTunnelProviderFactory.tunnelProvidersInPreferences.removeAll()
        container.neTunnelProviderFactory.tunnelProviderPreferencesData.removeAll()
    }

    override func tearDown() {
        apiCredentials = nil
    }

    func callOnTunnelProviderStateChange(closure: @escaping (NEVPNManagerMock, NEVPNConnectionMock, NEVPNStatus) -> Void) {
        container.neTunnelProviderFactory.newManagerCreated = { manager in
            manager.connectionWasCreated = { connection in
                guard let tunnelConnection = connection as? NETunnelProviderSessionMock else {
                    XCTFail("Incorrect connection type for object")
                    return
                }

                tunnelConnection.providerMessageSent = {
                    self.handleProviderMessage(messageData: $0)
                }

                tunnelConnection.tunnelStateDidChange = { status in
                    closure(manager, tunnelConnection, status)
                }
            }
        }
    }

    func callOnManagerStateChange(closure: @escaping (NEVPNManagerMock, NEVPNConnectionMock, NEVPNStatus) -> Void) {
        container.neVpnManagerConnectionStateChangeCallback = { (connection, status) in
            closure(self.container.neVpnManager, connection, status)
        }
    }

    func handleMockNetworkingRequest(_ request: URLRequest) -> Result<Data, Error> {
        switch request.url?.path {
        case "/vpn":
            // for fetching client credentials
            guard let apiCredentials = apiCredentials else {
                return .failure(ApiError(httpStatusCode: 400, code: 2000))
            }

            let data = try! JSONSerialization.data(withJSONObject: apiCredentials.asDict)
            return .success(data)
        case "/vpn_status":
            // for checking p2p state
            return .success(Data())
        case "/vpn/location":
            // for checking IP state
            let response = testData.vpnLocation
            let data = try! responseEncoder.encode(response)
            return .success(data)
        case "/vpn/logicals":
            // for fetching server list
            let servers = self.apiServerList.map { $0.asDict }
            let data = try! JSONSerialization.data(withJSONObject: [
                "LogicalServers": servers
            ])

            return .success(data)
        case "/vpn/streamingservices":
            // for fetching list of streaming services & icons
            let response = VPNStreamingResponse(code: 1000,
                                                resourceBaseURL: "https://protonvpn.com/resources",
                                                streamingServices: ["IT": [
                                                    "1": [.init(name: "Rai", icon: "rai.jpg")],
                                                    "2": [.init(name: "Netflix", icon: "netflix.jpg")]
                                                ]])
            let data = try! responseEncoder.encode(response)
            return .success(data)
        case "/vpn/v2/clientconfig":
            let response = ClientConfigResponse(clientConfig: testData.defaultClientConfig)
            let data = try! responseEncoder.encode(response)
            return .success(data)
        default:
            XCTFail("Shouldn't do anything")
            return .failure(POSIXError(.EPROCUNAVAIL))
        }
    }

    func makeNewCertificate() -> VpnCertificate {
        let refreshTime = Date().addingTimeInterval(.hours(6))
        let expiryTime = refreshTime.addingTimeInterval(.hours(6))
        let certDict: [String: Any] = ["Certificate": "abcd1234",
                                       "ExpirationTime": Int(expiryTime.timeIntervalSince1970),
                                       "RefreshTime": Int(refreshTime.timeIntervalSince1970)]
        return try! VpnCertificate(dict: certDict.mapValues({ $0 as AnyObject }))
    }

    func handleProviderMessage(messageData: Data) -> Data? {
        let request = try? WireguardProviderRequest.decode(data: messageData)

        switch request {
        case .refreshCertificate(let features):
            guard !mockProviderState.needNewSession else {
                return WireguardProviderRequest.Response.errorSessionExpired.asData
            }

            guard mockProviderState.shouldRefresh else {
                break
            }

            let certAndFeatures = VpnCertificateWithFeatures(certificate: makeNewCertificate(),
                                                             features: features)
            container.vpnAuthenticationStorage.store(certificate: certAndFeatures)

            mockProviderState.shouldRefresh = false
            didRequestCertRefresh?()
        case .setApiSelector:
            mockProviderState.needNewSession = false
        case .cancelRefreshes, .restartRefreshes:
            break
        case nil:
            XCTFail("Decoding failed for data: \(messageData)")
            return nil
        default:
            XCTFail("Case not handled: \(request!)")
            return nil
        }

        return WireguardProviderRequest.Response.ok(data: nil).asData
    }

    func testFirstTimeConnectionWithSmartProtocol() {
        let expectations = (
            initialConnection: XCTestExpectation(description: "initial connection"),
            connectedDate: XCTestExpectation(description: "connected date"),
            certRefresh: XCTestExpectation(description: "request cert refresh")
        )

        var currentConnection: NEVPNConnectionWrapper?
        var currentManager: NEVPNManagerWrapper?

        let request = ConnectionRequest(serverType: .standard,
                                        connectionType: .country("CH", .fastest),
                                        connectionProtocol: .smartProtocol,
                                        netShieldType: .level1,
                                        natType: .moderateNAT,
                                        safeMode: true,
                                        profileId: nil)

        callOnTunnelProviderStateChange { vpnManager, vpnConnection, vpnStatus in
            (currentManager, currentConnection) = (vpnManager, vpnConnection)

            if vpnStatus == .connected {
                expectations.initialConnection.fulfill()
            }
        }

        didRequestCertRefresh = {
            expectations.certRefresh.fulfill()
        }

        container.vpnGateway.connect(with: request)

        wait(for: [expectations.initialConnection, expectations.certRefresh], timeout: expectationTimeout)

        // smart protocol should favor wireguard
        XCTAssertEqual((currentManager?.protocolConfiguration as? NETunnelProviderProtocol)?.providerBundleIdentifier, Container.wireguardProviderBundleId)

        XCTAssertNotNil(currentManager?.protocolConfiguration?.serverAddress)
        XCTAssertEqual(currentManager?.protocolConfiguration?.serverAddress, testData.server1.ips.first?.entryIp)
        XCTAssertEqual(container.alertService.alerts.count, 1)
        XCTAssert(container.alertService.alerts.first is FirstTimeConnectingAlert)

        container.vpnManager.connectedDate { date in
            XCTAssertEqual(date, currentConnection?.connectedDate)
            expectations.connectedDate.fulfill()
        }
        wait(for: [expectations.connectedDate], timeout: expectationTimeout)
    }

    /// This test uses two servers and manipulates their properties and protocol availabilities to see how vpncore reacts.
    ///
    /// With two servers in the server storage, the app should pick the one with the lower score. Then, using a mocked
    /// availability checker which fakes the wireguard protocol being unavailable for that server, we should see the code
    /// decide to fall back on openvpn instead. Then we make openvpn unavailable and reconnect, at which point the code
    /// should fall back onto IKEv2. Finally, we disconnect, which should exercise the API to fetch the server list and user
    /// IP. This updated server list has placed the server we just connected to under maintenance. On the next reconnect,
    /// we go ahead and make all protocols available again, and check to see that the server chosen is not the one we were
    /// just connected to (i.e., the one with the higher score).
    func testFastestConnectionAndSmartProtocolFallbackAndDisconnectApiUsage() {
        container.availabilityCheckerResolverFactory.checkers[.wireGuard]?.availabilityCallback = { serverIp in
            // Force server2 wireguard server to be unavailable
            if serverIp == self.testData.server2.ips.first {
                return .unavailable
            }

            XCTFail("Shouldn't be checking availability for server1")
            return .available(ports: [15213, 15410])
        }

        container.serverStorage.servers.append(testData.server2)

        let expectations = (
            initialConnection: XCTestExpectation(description: "initial connection"),
            connectedDate: XCTestExpectation(description: "connected date"),
            reconnection: XCTestExpectation(description: "reconnection"),
            reconnectionAppStateChange: XCTestExpectation(description: "reconnect app state change"),
            disconnect: XCTestExpectation(description: "disconnect"),
            disconnectAppStateChange: XCTestExpectation(description: "disconnect app state change"),
            serverListFetch: XCTestExpectation(description: "fetch and store new servers"),
            reconnectionAfterServerInfoFetch: XCTestExpectation(description: "reconnect after manual disconnect + server info fetch"),
            wireguardCertRefresh: XCTestExpectation(description: "should refresh certificate with wireguard protocol"),
            finalConnection: XCTestExpectation(description: "final app state transition to connected")
        )

        var currentStatus: NEVPNStatus?
        var currentConnection: NEVPNConnectionWrapper?
        var currentManager: NEVPNManagerWrapper?

        let request = ConnectionRequest(serverType: .standard,
                                        connectionType: .country("CH", .fastest),
                                        connectionProtocol: .smartProtocol,
                                        netShieldType: .level1,
                                        natType: .moderateNAT,
                                        safeMode: true,
                                        profileId: nil)

        var tunnelProviderExpectation = expectations.initialConnection
        callOnTunnelProviderStateChange { vpnManager, vpnConnection, vpnStatus in
            (currentManager, currentConnection, currentStatus) = (vpnManager, vpnConnection, vpnStatus)

            if vpnStatus == .connected {
                tunnelProviderExpectation.fulfill()
            }
        }

        didRequestCertRefresh = {
            XCTFail("Should not request to refresh certificate for non-certificate-authenticated protocol")
        }

        container.propertiesManager.hasConnected = true // check that we don't display FirstTimeConnectingAlert
        container.vpnGateway.connect(with: request)

        wait(for: [tunnelProviderExpectation], timeout: expectationTimeout)

        XCTAssert(container.appStateManager.state.isConnected)
        // wireguard was made unavailable above. protocol should fallback to openvpn
        XCTAssertEqual((currentManager?.protocolConfiguration as? NETunnelProviderProtocol)?.providerBundleIdentifier, Container.openvpnProviderBundleId)

        // server2 has a lower score, so it should connect instead of server1
        XCTAssertNotNil(currentManager?.protocolConfiguration?.serverAddress)
        XCTAssertEqual(currentManager?.protocolConfiguration?.serverAddress, testData.server2.ips.first?.entryIp)
        XCTAssert(container.alertService.alerts.isEmpty)

        container.vpnManager.connectedDate { date in
            XCTAssertEqual(date, currentConnection?.connectedDate)
            expectations.connectedDate.fulfill()
        }
        wait(for: [expectations.connectedDate], timeout: expectationTimeout)

        // now also force openvpn to be unavailable
        let unavailableCallback = container.availabilityCheckerResolverFactory.checkers[.wireGuard]!.availabilityCallback
        container.availabilityCheckerResolverFactory.checkers[.openVpn(.tcp)]?.availabilityCallback = unavailableCallback
        container.availabilityCheckerResolverFactory.checkers[.openVpn(.udp)]?.availabilityCallback = unavailableCallback

        callOnManagerStateChange { manager, connection, vpnStatus in
            (currentManager, currentConnection, currentStatus) = (manager, connection, vpnStatus)
            expectations.reconnection.fulfill()
        }

        var observedState: AppState?
        var hasReconnected = false
        let stateChangeNotification = AppStateManagerNotification.stateChange
        let observer = NotificationCenter.default.addObserver(forName: stateChangeNotification, object: nil, queue: nil) { notification in
            guard let appState = notification.object as? AppState else {
                XCTFail("Did not send app state as part of notification")
                return
            }

            if observedState?.isDisconnected == false, appState.isDisconnected {
                expectations.disconnectAppStateChange.fulfill()
            } else if observedState?.isConnected == false, appState.isConnected {
                if !hasReconnected {
                    expectations.reconnectionAppStateChange.fulfill()
                    hasReconnected = true
                } else {
                    expectations.finalConnection.fulfill()
                }
            }
            observedState = appState
        }
        defer { NotificationCenter.default.removeObserver(observer, name: stateChangeNotification, object: nil) }

        // reconnect with netshield settings change
        container.vpnGateway.reconnect(with: NATType.strictNAT)

        wait(for: [expectations.reconnection, expectations.reconnectionAppStateChange], timeout: expectationTimeout)

        XCTAssertEqual(currentManager?.protocolConfiguration?.serverAddress, testData.server2.ips.first?.entryIp)
        XCTAssert(container.appStateManager.state.isConnected)

        apiServerList = [testData.server1, testData.server2UnderMaintenance]

        var storedServers: [ServerModel] = []
        container.serverStorage.didStoreNewServers = { newServers in
            storedServers = newServers
            expectations.serverListFetch.fulfill()
        }

        container.vpnGateway.disconnect {
            expectations.disconnect.fulfill()
        }

        // After disconnect, check that the results fetched from the API match the local server storage
        wait(for: [expectations.disconnect,
                   expectations.disconnectAppStateChange,
                   expectations.serverListFetch], timeout: expectationTimeout)

        XCTAssertEqual(currentStatus, .disconnected, "VPN status should be disconnected")

        XCTAssertEqual(container.serverStorage.servers.count, 2)
        let fetchedServer1 = storedServers.first(where: { $0.name == testData.server1.name })
        let fetchedServer2 = storedServers.first(where: { $0.name == testData.server2.name })

        XCTAssertEqual(fetchedServer1?.id, testData.server1.id)
        XCTAssertEqual(fetchedServer1?.status, testData.server1.status)
        XCTAssertEqual(fetchedServer2?.id, testData.server2.id)
        XCTAssertEqual(fetchedServer2?.status, testData.server2UnderMaintenance.status)

        // now we make all protocols available on all servers, so wireguard should connect now.
        container.availabilityCheckerResolverFactory.checkers[.wireGuard]?.availabilityCallback = nil
        container.availabilityCheckerResolverFactory.checkers[.openVpn(.tcp)]?.availabilityCallback = nil
        container.availabilityCheckerResolverFactory.checkers[.openVpn(.udp)]?.availabilityCallback = nil

        didRequestCertRefresh = {
            expectations.wireguardCertRefresh.fulfill()
        }

        tunnelProviderExpectation = expectations.reconnectionAfterServerInfoFetch
        container.vpnGateway.connect(with: request)

        wait(for: [tunnelProviderExpectation,
                   expectations.wireguardCertRefresh,
                   expectations.finalConnection], timeout: expectationTimeout)

        // wireguard protocol now available for smart protocol to pick
        XCTAssertEqual((currentManager?.protocolConfiguration as? NETunnelProviderProtocol)?.providerBundleIdentifier, Container.wireguardProviderBundleId)

        // server2 has a lower score, but has been marked as going under maintenance, so server1 should be used
        XCTAssertNotNil(currentManager?.protocolConfiguration?.serverAddress)
        XCTAssertEqual(currentManager?.protocolConfiguration?.serverAddress, testData.server1.ips.first?.entryIp)
        XCTAssert(container.alertService.alerts.isEmpty)
    }

    /// Tests user connected to a plus server. Then the plan gets downgraded to free. Supposing the user then realizes
    /// the error of their ways and upgrades back to plus, the test will then exercise the app in the case where that
    /// same user then becomes delinquent on their plan payment.
    func testUserPlanChangingThenBecomingDelinquentWithWireGuard() {
        container.serverStorage.servers = [testData.server1, testData.server3]
        container.vpnKeychain.setVpnCredentials(with: .plus, maxTier: CoreAppConstants.VpnTiers.plus)
        container.propertiesManager.vpnProtocol = .wireGuard
        container.propertiesManager.hasConnected = true

        let (totalConnections, totalDisconnections) = (4, 3)
        let expectations = (
            connections: (1...totalConnections).map { XCTestExpectation(description: "connection \($0)") },
            appStateConnectedTransitions: (1...totalConnections).map { XCTestExpectation(description: "app state transition -> connected \($0)") },
            disconnections: (1...totalDisconnections).map { XCTestExpectation(description: "disconnection \($0)") },
            downgradeAlert: XCTestExpectation(description: "downgraded alert"),
            delinquentAlert: XCTestExpectation(description: "delinquent alert"),
            upgradeNotification: XCTestExpectation(description: "notify upgrade state")
        )

        var downgradedAlert: UserPlanDowngradedAlert?
        var delinquentAlert: UserBecameDelinquentAlert?

        container.alertService.alertAdded = { alert in
            if let downgraded = alert as? UserPlanDowngradedAlert {
                downgradedAlert = downgraded
                expectations.downgradeAlert.fulfill()
            } else if let delinquent = alert as? UserBecameDelinquentAlert {
                delinquentAlert = delinquent
                expectations.delinquentAlert.fulfill()
            } else {
                XCTFail("Unexpected alert.")
            }
        }

        container.localAgentConnectionFactory.connectionWasCreated = { connection in
            let consts = LocalAgentConstants()!
            DispatchQueue.main.async {
                connection.client.onState(consts.stateConnecting)
            }
            DispatchQueue.main.async {
                connection.client.onState(consts.stateConnected)
            }
        }

        let request = ConnectionRequest(serverType: .standard,
                                        connectionType: .country("CH", .fastest),
                                        connectionProtocol: .vpnProtocol(.wireGuard),
                                        netShieldType: .level1,
                                        natType: .moderateNAT,
                                        safeMode: true,
                                        profileId: nil)

        var (nConnections,
             nDisconnections,
             nAppStateConnectTransitions) = (0, 0, 0)

        let stateChangeNotification = AppStateManagerNotification.stateChange
        var observedStates: [AppState] = []
        let observer = NotificationCenter.default.addObserver(forName: stateChangeNotification, object: nil, queue: nil) { notification in
            guard let appState = notification.object as? AppState else { return }
            defer { observedStates.append(appState) }
            // debounce multiple "connected" notifications... we should probably fix that
            if case .connected = appState {
                if case .connected = observedStates.last { return }

                guard nAppStateConnectTransitions < totalConnections else {
                    XCTFail("Didn't expect that many (\(nAppStateConnectTransitions + 1)) connection transitions - " +
                            "previous observed states \(observedStates.map { $0.description })")
                    return
                }

                expectations.appStateConnectedTransitions[nAppStateConnectTransitions].fulfill()
                nAppStateConnectTransitions += 1
            }
        }
        defer { NotificationCenter.default.removeObserver(observer, name: stateChangeNotification, object: nil) }

        var observedStatuses: [NEVPNStatus] = []
        var currentManager: NEVPNManagerMock?
        callOnTunnelProviderStateChange { vpnManager, _, vpnStatus in
            currentManager = vpnManager
            defer { observedStatuses.append(vpnStatus) }

            switch vpnStatus {
            case .connected:
                defer { nConnections += 1 }
                guard nConnections < totalConnections else {
                    XCTFail("Didn't expect that many (\(nConnections + 1)) connection transitions - " +
                            "previous statuses \(observedStatuses.map { $0.description })")
                    return
                }
                expectations.connections[nConnections].fulfill()
            case .disconnected:
                defer { nDisconnections += 1 }
                guard nDisconnections < totalDisconnections else {
                    XCTFail("Didn't expect that many (\(nDisconnections + 1)) disconnection transitions - " +
                            "previous statuses \(observedStatuses.map { $0.description })")
                    return
                }
                expectations.disconnections[nDisconnections].fulfill()
            default:
                break
            }

        }
        container.vpnGateway.connect(with: request)
        wait(for: [expectations.connections[0],
                   expectations.appStateConnectedTransitions[0]], timeout: expectationTimeout)
        XCTAssertEqual(nConnections, 1)

        // should be connected to plus server
        XCTAssertNotNil(currentManager?.protocolConfiguration?.serverAddress)
        XCTAssertEqual(currentManager?.protocolConfiguration?.serverAddress, testData.server3.ips.first?.entryIp)

        let plusCreds = try! container.vpnKeychain.fetch()
        XCTAssertEqual(plusCreds.accountPlan, .plus)
        XCTAssertEqual(plusCreds.maxTier, CoreAppConstants.VpnTiers.plus)

        let freeCreds = VpnKeychainMock.vpnCredentials(accountPlan: .free,
                                                       maxTier: CoreAppConstants.VpnTiers.free)
        apiCredentials = freeCreds

        let downgrade: VpnDowngradeInfo = (plusCreds, freeCreds)
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: VpnKeychainMock.vpnPlanChanged, object: downgrade)
            self.container.vpnKeychain.credentials = freeCreds
            NotificationCenter.default.post(name: VpnKeychainMock.vpnCredentialsChanged, object: freeCreds)
        }

        wait(for: [expectations.disconnections[0],
                   expectations.downgradeAlert], timeout: expectationTimeout)
        XCTAssertEqual(nDisconnections, 1)
        container.alertService.alerts.removeAll()

        guard let downgradedAlert = downgradedAlert, let reconnectInfo = downgradedAlert.reconnectInfo else {
            XCTFail("Downgraded alert not found or reconnect info not found in downgraded alert")
            return
        }

        XCTAssertEqual(reconnectInfo.fromServer.name, testData.server3.name)
        XCTAssertEqual(reconnectInfo.toServer.name, testData.server1.name)

        wait(for: [expectations.connections[1],
                   expectations.appStateConnectedTransitions[1]], timeout: expectationTimeout)
        XCTAssertEqual(nConnections, 2)

        // Should have reconnected to server1 now that the user tier has changed
        XCTAssertNotNil(currentManager?.protocolConfiguration?.serverAddress)
        XCTAssertEqual(currentManager?.protocolConfiguration?.serverAddress, testData.server1.ips.first?.entryIp)

        // Even if it's an upgrade, it's still called "VpnDowngradeInfo" *shrug*
        let upgrade: VpnDowngradeInfo = (freeCreds, plusCreds)
        apiCredentials = plusCreds

        DispatchQueue.main.async {
            NotificationCenter.default.post(name: VpnKeychainMock.vpnPlanChanged, object: upgrade)
            self.container.vpnKeychain.credentials = plusCreds
            NotificationCenter.default.post(name: VpnKeychainMock.vpnCredentialsChanged, object: plusCreds)
            expectations.upgradeNotification.fulfill()
        }

        wait(for: [expectations.upgradeNotification], timeout: expectationTimeout)

        container.vpnGateway.disconnect()
        wait(for: [expectations.disconnections[1]], timeout: expectationTimeout)
        XCTAssertEqual(nDisconnections, 2)

        container.vpnGateway.connect(with: request)
        wait(for: [expectations.connections[2],
                   expectations.appStateConnectedTransitions[2]], timeout: expectationTimeout)
        XCTAssertEqual(nConnections, 3)

        // Should have reconnected to server3 now that the user is again eligible
        XCTAssertNotNil(currentManager?.protocolConfiguration?.serverAddress)
        XCTAssertEqual(currentManager?.protocolConfiguration?.serverAddress, testData.server3.ips.first?.entryIp)

        DispatchQueue.main.async {
            NotificationCenter.default.post(name: VpnKeychainMock.vpnUserDelinquent, object: downgrade)
            self.container.vpnKeychain.credentials = freeCreds
            NotificationCenter.default.post(name: VpnKeychainMock.vpnCredentialsChanged, object: freeCreds)
        }

        wait(for: [expectations.disconnections[2],
                   expectations.delinquentAlert], timeout: expectationTimeout)
        XCTAssertEqual(nDisconnections, 3)
        // and should have received an alert stating which server the app reconnected to
        XCTAssertEqual(delinquentAlert?.reconnectInfo?.fromServer.name, testData.server3.name)
        XCTAssertEqual(delinquentAlert?.reconnectInfo?.toServer.name, testData.server1.name)

        wait(for: [expectations.connections[3],
                   expectations.appStateConnectedTransitions[3]], timeout: expectationTimeout)
        XCTAssertEqual(nConnections, 4)

        // Should have reconnected to server1 now that user is delinquent
        XCTAssertNotNil(currentManager?.protocolConfiguration?.serverAddress)
        XCTAssertEqual(currentManager?.protocolConfiguration?.serverAddress, testData.server1.ips.first?.entryIp)
    }

    func testLocalAgentErrorHandling() {
        guard let consts = LocalAgentConstants() else {
            XCTFail("Could not initialize local agent constants")
            return
        }

        let (totalConnections, totalDisconnections) = (3, 3)

        let expectations = (
            vpnConnection: (1...totalConnections).map { XCTestExpectation(description: "vpn tunnel start \($0)") },
            newLAConnection: (1...totalConnections).map { XCTestExpectation(description: "new client for connection \($0)") },
            vpnDisconnection: (1...totalDisconnections).map { XCTestExpectation(description: "vpn tunnel stop \($0)") }
        )

        var localAgentConnection: LocalAgentConnectionMock?
        let (laState, laError) = ({ (state: String?) in
            DispatchQueue.main.async {
                localAgentConnection?.client.onState(state)
            }
        }, { (code: Int, description: String?) in
            DispatchQueue.main.async {
                localAgentConnection?.client.onError(code, description: description)
            }
        })

        var nLAConnections = 0
        container.localAgentConnectionFactory.connectionWasCreated = { connection in
            localAgentConnection = connection

            guard nLAConnections < totalConnections else {
                XCTFail("Didn't expect this number of connections")
                return
            }

            expectations.newLAConnection[nLAConnections].fulfill()
            nLAConnections += 1
        }

        callOnTunnelProviderStateChange { manager, connection, status in
            if status == .connected {
                expectations.vpnConnection[0].fulfill()
            }
            if status == .disconnected {
                expectations.vpnDisconnection[0].fulfill()
            }
        }

        let request = ConnectionRequest(serverType: .standard,
                                        connectionType: .country("CH", .fastest),
                                        connectionProtocol: .vpnProtocol(.wireGuard),
                                        netShieldType: .level1,
                                        natType: .moderateNAT,
                                        safeMode: true,
                                        profileId: nil)
        container.vpnGateway.connect(with: request)

        wait(for: [expectations.newLAConnection[0], expectations.vpnConnection[0]], timeout: expectationTimeout)
        laState(consts.stateConnecting)
        laState(consts.stateConnected)

        laError(consts.errorCodeUserBadBehavior, "bad user, bad")
        wait(for: [expectations.vpnDisconnection[0]], timeout: expectationTimeout)
    }
}

fileprivate class Container {
    static let appGroup = "test"
    static let wireguardProviderBundleId = "ch.protonvpn.test.wireguard"
    static let openvpnProviderBundleId = "ch.protonvpn.test.openvpn"
    
    var neVpnManagerConnectionStateChangeCallback: ((NEVPNConnectionMock, NEVPNStatus) -> Void)?

    lazy var neVpnManager = NEVPNManagerMock()
    lazy var neTunnelProviderFactory = NETunnelProviderManagerFactoryMock()

    lazy var networking = NetworkingMock()
    lazy var alertService = CoreAlertServiceMock()
    lazy var timerFactory = TimerFactoryMock()
    lazy var propertiesManager = PropertiesManagerMock()
    lazy var vpnKeychain = VpnKeychainMock()
    lazy var dohVpn = DoHVPN(apiHost: "unit-test.protonvpn.ch", verifyHost: "", alternativeRouting: true, appState: .disconnected)

    lazy var natProvider = NATTypePropertyProviderMock()
    lazy var netShieldProvider = NetShieldPropertyProviderMock()
    lazy var safeModeProvider = SafeModePropertyProviderMock()

    lazy var ikeFactory = IkeProtocolFactory(factory: self)
    lazy var openVpnFactory = OpenVpnProtocolFactory(bundleId: Self.openvpnProviderBundleId,
                                                     appGroup: Self.appGroup,
                                                     propertiesManager: propertiesManager,
                                                     vpnManagerFactory: self)
    lazy var wireguardFactory = WireguardProtocolFactory(bundleId: Self.wireguardProviderBundleId,
                                                         appGroup: Self.appGroup,
                                                         propertiesManager: propertiesManager,
                                                         vpnManagerFactory: self)

    lazy var vpnApiService = VpnApiService(networking: networking)

    let sessionService = SessionServiceMock()
    let vpnAuthenticationStorage = MockVpnAuthenticationStorage()

    lazy var vpnAuthentication = VpnAuthenticationRemoteClient(sessionService: sessionService,
                                                               authenticationStorage: vpnAuthenticationStorage,
                                                               safeModePropertyProvider: safeModeProvider)

    lazy var stateConfiguration = VpnStateConfigurationManager(ikeProtocolFactory: ikeFactory,
                                                               openVpnProtocolFactory: openVpnFactory,
                                                               wireguardProtocolFactory: wireguardFactory,
                                                               propertiesManager: propertiesManager,
                                                               appGroup: Self.appGroup)

    let localAgentConnectionFactory = LocalAgentConnectionMockFactory()

    lazy var vpnManager = VpnManager(ikeFactory: ikeFactory,
                                     openVpnFactory: openVpnFactory,
                                     wireguardProtocolFactory: wireguardFactory,
                                     appGroup: Self.appGroup,
                                     vpnAuthentication: vpnAuthentication,
                                     vpnKeychain: vpnKeychain,
                                     propertiesManager: propertiesManager,
                                     vpnStateConfiguration: stateConfiguration,
                                     alertService: alertService,
                                     vpnCredentialsConfiguratorFactory: self,
                                     localAgentConnectionFactory: localAgentConnectionFactory,
                                     natTypePropertyProvider: natProvider,
                                     netShieldPropertyProvider: netShieldProvider,
                                     safeModePropertyProvider: safeModeProvider)

    lazy var vpnManagerConfigurationPreparer = VpnManagerConfigurationPreparer(vpnKeychain: vpnKeychain,
                                                                               alertService: alertService,
                                                                               propertiesManager: propertiesManager)

    lazy var serverStorage = ServerStorageMock(servers: [])

    lazy var appStateManager = AppStateManagerImplementation(vpnApiService: vpnApiService,
                                                             vpnManager: vpnManager,
                                                             networking: networking,
                                                             alertService: alertService,
                                                             timerFactory: timerFactory,
                                                             propertiesManager: propertiesManager,
                                                             vpnKeychain: vpnKeychain,
                                                             configurationPreparer: vpnManagerConfigurationPreparer,
                                                             vpnAuthentication: vpnAuthentication,
                                                             doh: dohVpn,
                                                             serverStorage: serverStorage,
                                                             natTypePropertyProvider: natProvider,
                                                             netShieldPropertyProvider: netShieldProvider,
                                                             safeModePropertyProvider: safeModeProvider)

    lazy var profileManager = ProfileManager(serverStorage: serverStorage, propertiesManager: propertiesManager)

    lazy var checkers = [
        AvailabilityCheckerMock(vpnProtocol: .ike, availablePorts: [500]),
        AvailabilityCheckerMock(vpnProtocol: .openVpn(.tcp), availablePorts: [9000, 12345]),
        AvailabilityCheckerMock(vpnProtocol: .openVpn(.udp), availablePorts: [9090, 8080, 9091, 8081]),
        AvailabilityCheckerMock(vpnProtocol: .wireGuard, availablePorts: [15213, 15410, 15210])
    ].reduce(into: [:], { $0[$1.vpnProtocol] = $1 })

    lazy var availabilityCheckerResolverFactory = AvailabilityCheckerResolverFactoryMock(checkers: checkers)

    lazy var authKeychain = MockAuthKeychain(context: .mainApp)

    lazy var vpnGateway = VpnGateway(vpnApiService: vpnApiService,
                                     appStateManager: appStateManager,
                                     alertService: alertService,
                                     vpnKeychain: vpnKeychain,
                                     authKeychain: authKeychain,
                                     netShieldPropertyProvider: netShieldProvider,
                                     natTypePropertyProvider: natProvider,
                                     safeModePropertyProvider: safeModeProvider,
                                     propertiesManager: propertiesManager,
                                     profileManager: profileManager,
                                     availabilityCheckerResolverFactory: availabilityCheckerResolverFactory,
                                     serverStorage: serverStorage)
}

fileprivate struct TestData {
    struct VPNLocationResponse: Codable, Equatable {
        let ip: String
        let country: String
        let isp: String

        enum CodingKeys: String, CodingKey {
            case ip = "IP"
            case country = "Country"
            case isp = "ISP"
        }
    }

    var vpnLocation = VPNLocationResponse(ip: "123.123.123.123", country: "USA", isp: "GreedyCorp, Inc.")

    /// free server with relatively high latency score and not under maintenance.
    var server1 = ServerModel(id: "abcd",
                              name: "free server",
                              domain: "swiss.protonvpn.ch",
                              load: 15,
                              entryCountryCode: "CH",
                              exitCountryCode: "CH",
                              tier: CoreAppConstants.VpnTiers.free,
                              feature: .zero,
                              city: "Palézieux",
                              ips: [.init(id: "abcd", entryIp: "10.0.0.1", exitIp: "10.0.0.2",
                                          domain: "swiss.protonvpn.ch", status: 1,
                                          x25519PublicKey: "this is a public key".data(using: .utf8)!.base64EncodedString())],
                              score: 50,
                              status: 1, // 0 == under maintenance
                              location: ServerLocation(lat: 46.33, long: 6.5),
                              hostCountry: "Switzerland",
                              translatedCity: "Not The Eyes")

    /// free server with relatively low latency score and not under maintenance.
    var server2 = ServerModel(id: "efgh",
                              name: "other free server",
                              domain: "swiss2.protonvpn.ch",
                              load: 80,
                              entryCountryCode: "CH",
                              exitCountryCode: "CH",
                              tier: CoreAppConstants.VpnTiers.free,
                              feature: .zero,
                              city: "Gland",
                              ips: [.init(id: "efgh", entryIp: "10.0.0.3", exitIp: "10.0.0.4",
                                          domain: "swiss2.protonvpn.ch", status: 1,
                                          x25519PublicKey: "this is another public key".data(using: .utf8)!.base64EncodedString())],
                              score: 15,
                              status: 1,
                              location: ServerLocation(lat: 46.25, long: 6.16),
                              hostCountry: "Switzerland",
                              translatedCity: "Anatomy")

    /// same server as server 2, but placed under maintenance.
    var server2UnderMaintenance = ServerModel(
                              id: "efgh",
                              name: "other free server",
                              domain: "swiss2.protonvpn.ch",
                              load: 80,
                              entryCountryCode: "CH",
                              exitCountryCode: "CH",
                              tier: CoreAppConstants.VpnTiers.free,
                              feature: .zero,
                              city: "Gland",
                              ips: [.init(id: "efgh", entryIp: "10.0.0.3", exitIp: "10.0.0.4",
                                          domain: "swiss2.protonvpn.ch", status: 0,
                                          x25519PublicKey: "this is another public key".data(using: .utf8)!.base64EncodedString())],
                              score: 15,
                              status: 0, // under maintenance
                              location: ServerLocation(lat: 46.25, long: 6.16),
                              hostCountry: "Switzerland",
                              translatedCity: "Anatomy")

    /// plus server with low latency score and p2p feature. not under maintenance.
    var server3 = ServerModel(id: "ijkl",
                              name: "plus server",
                              domain: "swissplus.protonvpn.ch",
                              load: 42,
                              entryCountryCode: "CH",
                              exitCountryCode: "CH",
                              tier: CoreAppConstants.VpnTiers.plus,
                              feature: .zero,
                              city: "Zurich",
                              ips: [.init(id: "ijkl", entryIp: "10.0.0.5", exitIp: "10.0.0.6",
                                          domain: "swissplus.protonvpn.ch", status: 1,
                                          x25519PublicKey: "plus public key".data(using: .utf8)!.base64EncodedString())],
                              score: 10,
                              status: 1,
                              location: .init(lat: 47.22, long: 8.32),
                              hostCountry: "Switzerland",
                              translatedCity: nil)

    var defaultClientConfig = ClientConfig(openVPNConfig: .init(defaultTcpPorts: [1234, 5678],
                                                                defaultUdpPorts: [2345, 6789]),
                                           featureFlags: .init(smartReconnect: true,
                                                               vpnAccelerator: true,
                                                               netShield: true,
                                                               streamingServicesLogos: true,
                                                               portForwarding: true,
                                                               moderateNAT: true,
                                                               pollNotificationAPI: true,
                                                               serverRefresh: true,
                                                               guestHoles: true,
                                                               safeMode: true,
                                                               promoCode: true),
                                           serverRefreshInterval: 2 * 60,
                                           wireGuardConfig: .init(defaultPorts: [12345, 65432]),
                                           smartProtocolConfig: .init(openVPN: true, iKEv2: true, wireGuard: true),
                                           ratingSettings: .init())
}

extension Container: NEVPNManagerWrapperFactory {
    func makeNEVPNManagerWrapper() -> NEVPNManagerWrapper {
        neVpnManager.connectionWasCreated = { connection in
            connection.tunnelStateDidChange = { status in
                self.neVpnManagerConnectionStateChangeCallback?(connection, status)
            }
        }

        return neVpnManager
    }
}

extension Container: NETunnelProviderManagerWrapperFactory {
    func makeNewManager() -> NETunnelProviderManagerWrapper {
        neTunnelProviderFactory.makeNewManager()
    }

    func loadManagersFromPreferences(completionHandler: @escaping ([NETunnelProviderManagerWrapper]?, Error?) -> Void) {
        neTunnelProviderFactory.loadManagersFromPreferences(completionHandler: completionHandler)
    }
}

extension Container: VpnCredentialsConfiguratorFactory {
    func getCredentialsConfigurator(for `protocol`: VpnProtocol) -> VpnCredentialsConfigurator {
        return VpnCredentialsConfiguratorMock(vpnProtocol: `protocol`)
    }
}

private extension JSONEncoder.KeyEncodingStrategy {
    static let capitalizeFirstLetter = Self.custom { path in
        let original: String = path.last!.stringValue
        let capitalized = original.prefix(1).uppercased() + original.dropFirst()
        return JSONKey(stringValue: capitalized) ?? path.last!
    }

    private struct JSONKey: CodingKey {
        var stringValue: String
        var intValue: Int?

        init?(stringValue: String) {
            self.stringValue = stringValue
            self.intValue = nil
        }

        init?(intValue: Int) {
            self.stringValue = "\(intValue)"
            self.intValue = intValue
        }
    }
}
