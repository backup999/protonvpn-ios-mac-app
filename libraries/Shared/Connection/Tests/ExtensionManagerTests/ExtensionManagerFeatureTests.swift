//
//  Created on 06/06/2024.
//
//  Copyright (c) 2024 Proton AG
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

#if targetEnvironment(simulator) // `MockTunnelManager` is only built for the simulator
import Foundation
import XCTest

import ComposableArchitecture

import Ergonomics
import Domain
import DomainTestSupport
import struct ConnectionFoundations.LogicalServerInfo
@testable import ExtensionManager

final class ExtensionManagerFeatureTests: XCTestCase {

    @MainActor
    func testRequestsTunnelStart() async {
        let mockManager = MockTunnelManager()
        let mockClock = TestClock()

        let server = Server.ca // Canadian server mock
        let features = VPNConnectionFeatures.mock
        let logicalServerInfo = LogicalServerInfo(logicalID: server.logical.id, serverID: server.endpoint.id)
        let intent = ServerConnectionIntent(server: server, transport: .udp, features: features)

        mockManager.connection = VPNSessionMock(
            status: .disconnected,
            connectedDate: nil,
            lastDisconnectError: nil
        )
        mockManager.connection.startupDuration = .milliseconds(250)
        mockManager.connection.connectionDuration = .milliseconds(500)

        let disconnected = ExtensionFeature.State.disconnected(nil)
        let store = TestStore(initialState: disconnected) {
            ExtensionFeature()
        } withDependencies: {
            $0.continuousClock = mockClock
            $0.tunnelManager = mockManager
            $0.date = .constant(.now)
        }

        await store.send(.startObservingStateChanges)
        await store.receive(\.tunnelStatusChanged.disconnected)

        await store.send(.connect(intent)) {
            $0 = .preparingConnection(logicalServerInfo)
        }

        await store.receive(\.tunnelStartRequestFinished.success)
        await mockClock.advance(by: .milliseconds(250))
        await store.receive(\.tunnelStatusChanged.connecting) {
            $0 = .connecting(logicalServerInfo)
        }

        await mockClock.advance(by: .milliseconds(500))
        await store.receive(\.tunnelStatusChanged.connected)
        await store.receive(\.connectionFinished.success) {
            $0 = .connected(logicalServerInfo)
        }

        await store.send(.stopObservingStateChanges)
    }

    @MainActor
    func testStateSetToConnectedIfExistingTunnelIsConencted() async {
        let mockManager = MockTunnelManager()
        mockManager.connection = VPNSessionMock(
            status: .connected,
            connectedDate: nil,
            lastDisconnectError: nil
        )
        let previouslyConnectedServer = LogicalServerInfo(logicalID: "logical", serverID: "server")
        mockManager.connection.connectedServer = previouslyConnectedServer

        let disconnected = ExtensionFeature.State.disconnected(nil)
        let store = TestStore(initialState: disconnected) {
            ExtensionFeature()
        } withDependencies: {
            $0.tunnelManager = mockManager
        }

        await store.send(.startObservingStateChanges)
        await store.receive(\.tunnelStatusChanged.connected) {
            $0 = .connecting(nil)
        }
        await store.receive(\.connectionFinished.success) {
            $0 = .connected(previouslyConnectedServer)
        }

        await store.send(.stopObservingStateChanges)
    }

    @MainActor func testDisconnectsWhenVPNConfigurationPermissionDenied() async {
        let mockClock = TestClock()
        let mockManager = MockTunnelManager()
        mockManager.connection = VPNSessionMock(
            status: .invalid,
            connectedDate: nil,
            lastDisconnectError: nil
        )

        let disconnected = ExtensionFeature.State.disconnected(nil)
        let store = TestStore(initialState: disconnected) {
            ExtensionFeature()
        } withDependencies: {
            $0.continuousClock = mockClock
            $0.tunnelManager = mockManager
        }

        let server = Server.mock
        let features = VPNConnectionFeatures.mock
        let logicalServerInfo = LogicalServerInfo(logicalID: server.logical.id, serverID: server.endpoint.id)
        let intent = ServerConnectionIntent(server: server, transport: .udp, features: features)

        await store.send(.startObservingStateChanges)
        await store.receive(\.tunnelStatusChanged.invalid)

        let permissionDenied: Error = "NEVPNErrorDomain Code=5 permission denied" as GenericError
        mockManager.tunnelStartErrorToThrow = permissionDenied

        await store.send(.connect(intent)) {
            $0 = .preparingConnection(logicalServerInfo)
        }
        await store.receive(\.tunnelStartRequestFinished.failure) {
            $0 = .disconnected(.tunnelStartFailed(permissionDenied))
        }

        await store.send(.stopObservingStateChanges)
    }
}
#endif
