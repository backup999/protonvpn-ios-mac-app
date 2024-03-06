//
//  Created on 23/01/2024.
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

import Foundation

public enum UserInitiatedVPNChange {
    case connect
    case disconnect(ConnectionDimensions.VPNTrigger)
    case abort
    case settingsChange
    case logout
}

protocol TelemetryTimer {
    func updateConnectionStarted(_ date: Date?)
    func markStartedConnecting()
    func markFinishedConnecting()
    func markConnectionStopped()
    var connectionDuration: TimeInterval { get throws }
    var timeToConnect: TimeInterval { get throws }
    var timeConnecting: TimeInterval { get throws }
}

class TelemetryConnectionStatusReporter {

    public typealias Factory = NetworkingFactory & AppStateManagerFactory & PropertiesManagerFactory & VpnKeychainFactory & TelemetryAPIFactory & TelemetrySettingsFactory

    private let factory: Factory

    private lazy var appStateManager: AppStateManager = factory.makeAppStateManager()
    private lazy var propertiesManager: PropertiesManagerProtocol = factory.makePropertiesManager()
    private lazy var vpnKeychain: VpnKeychainProtocol = factory.makeVpnKeychain()

    var networkType: ConnectionDimensions.NetworkType = .other
    var previousConnectionStatus: ConnectionStatus?

    var userInitiatedVPNChange: UserInitiatedVPNChange?
    
    private lazy var previousConnectionConfiguration: ConnectionConfiguration? = {
        appStateManager.activeConnection()
    }()

    private let timer: TelemetryTimer

    private var telemetryEventScheduler: TelemetryEventScheduler
    private var businessEventScheduler: TelemetryEventScheduler

    init(
        factory: Factory,
        timer: TelemetryTimer = ConnectionTimer(),
        telemetryEventScheduler: TelemetryEventScheduler,
        businessEventScheduler: TelemetryEventScheduler
    ) async {
        self.factory = factory
        self.timer = timer

        self.telemetryEventScheduler = telemetryEventScheduler
        self.businessEventScheduler = businessEventScheduler
    }

    public func vpnGatewayConnectionChanged(_ connectionStatus: ConnectionStatus) async throws {
        // Assume the first status is generated by the system upon app launch
        guard previousConnectionStatus != nil else {
            previousConnectionStatus = connectionStatus
            throw "`previousConnectionStatus` is nil, saving status and ignoring event: \(connectionStatus)"
        }
        defer {
            if [.connected, .disconnected, .connecting].contains(connectionStatus) {
                previousConnectionStatus = connectionStatus
            }
        }
        // appStateManager should be now initiated and should produce a correct connectedDate
        await timer.updateConnectionStarted(appStateManager.connectedDate())
        var eventType: ConnectionEvent.Event
        switch connectionStatus {
        case .connected:
            timer.markFinishedConnecting()
            eventType = try connectionEventType(state: connectionStatus)
        case .connecting:
            timer.markConnectionStopped()
            timer.markStartedConnecting()
            eventType = try connectionEventType(state: connectionStatus)
        case .disconnected:
            timer.markConnectionStopped()
            eventType = try connectionEventType(state: connectionStatus)
        case .disconnecting:
            throw "Ignoring the `disconnecting` status"
        }
        let event = try collectDimensions(outcome: connectionOutcome(connectionStatus),
                                          eventType: eventType)
        await scheduleEvent(event)
    }

    private func scheduleEvent(_ event: ConnectionEvent) async {
        do {
            try await telemetryEventScheduler.report(event: event)
        } catch {
            log.debug("\(error)", category: .telemetry)
        }
        do {
            try await businessEventScheduler.report(event: event)
        } catch {
            log.debug("\(error)", category: .telemetry)
        }
    }

    private func collectDimensions(outcome: ConnectionDimensions.Outcome, eventType: ConnectionEvent.Event?) throws -> ConnectionEvent {
        guard let eventType else {
            throw "Can't determine eventType"
        }
        guard let connection = connection(eventType: eventType) else {
            throw "No active connection"
        }
        guard let port = connection.ports.first else {
            throw "No port detected"
        }
        let dimensions = ConnectionDimensions(
            outcome: outcome,
            userTier: userTier(),
            vpnStatus: previousConnectionStatus == .connected ? .on : .off,
            vpnTrigger: vpnTrigger(eventType: eventType),
            networkType: networkType,
            serverFeatures: connection.server.feature,
            vpnCountry: connection.server.countryCode,
            userCountry: propertiesManager.userLocation?.country ?? "",
            protocol: connection.vpnProtocol,
            server: connection.server.name,
            port: String(port),
            isp: propertiesManager.userLocation?.isp ?? "",
            isServerFree: connection.server.isFree
        )
        if case .settingsChange = userInitiatedVPNChange,
           case .vpnDisconnection = eventType {
            // don't reset the `userInitiatedVPNChange` on disconnect, we'll need it in just a moment for the connection event
        } else {
            userInitiatedVPNChange = nil
            // reset the `userInitiatedVPNChange` so that consequent events that are not explicitly generated by the user are not overriden by this (now) stale value
        }
        previousConnectionConfiguration = appStateManager.activeConnection()
        return ConnectionEvent(event: eventType, dimensions: dimensions)
    }

    private func userTier() -> ConnectionDimensions.UserTier {
        let cached = try? vpnKeychain.fetchCached()
        switch cached?.maxTier ?? 0 {
        case CoreAppConstants.VpnTiers.free:
            return .free
        case CoreAppConstants.VpnTiers.basic:
            return .paid
        case CoreAppConstants.VpnTiers.plus:
            return .paid
        case CoreAppConstants.VpnTiers.internal:
            return .internal
        default:
            return .internal
        }
    }

    private func connection(eventType: ConnectionEvent.Event) -> ConnectionConfiguration? {
        switch eventType {
        case .vpnConnection:
            return appStateManager.activeConnection()
        case .vpnDisconnection:
            return previousConnectionConfiguration
        }
    }

    private func connectionEventType(state: ConnectionStatus) throws -> ConnectionEvent.Event {
        switch state {
        case .connected:
            let timeInterval = try timer.timeToConnect
            return .vpnConnection(timeToConnection: timeInterval)
        case .disconnected:
            if previousConnectionStatus == .connected {
                return .vpnDisconnection(sessionLength: try timer.connectionDuration)
            } else if previousConnectionStatus == .connecting {
                return .vpnConnection(timeToConnection: try timer.timeConnecting)
            }
            throw "Ignoring disconnected event, was previously disconnected"
        case .connecting:
            if previousConnectionStatus == .connected {
                return .vpnDisconnection(sessionLength: try timer.connectionDuration)
            }
            throw "Ignoring connecting event, wasn't connected before"
        case .disconnecting:
            throw "Ignoring disconnecting state"
        }
    }

    private func connectionOutcome(_ state: ConnectionStatus) -> ConnectionDimensions.Outcome {
        switch state {
        case .disconnected:
            if [.connected, .connecting].contains(previousConnectionStatus) {
                guard let userInitiatedVPNChange else {
                    return .failure
                }
                switch userInitiatedVPNChange {
                case .connect, .disconnect:
                    return .success
                case .abort:
                    return .aborted
                case .settingsChange, .logout:
                    return .success
                }
            }
            return .success
        case .connected:
            return .success
        case .connecting:
            if previousConnectionStatus == .connected {
                return .success
            }
            return .failure
        case .disconnecting:
            return .failure
        }
    }

    private func vpnTrigger(eventType: ConnectionEvent.Event) -> ConnectionDimensions.VPNTrigger {
        let lastConnectionTrigger = propertiesManager.lastConnectionRequest?.trigger

        let newConnection: () -> ConnectionDimensions.VPNTrigger = { [weak self] in
            if self?.previousConnectionStatus == .connected,
               case .vpnDisconnection = eventType {
                return .newConnection
            }
            return lastConnectionTrigger ?? .auto
        }

        guard let userInitiatedVPNChange else {
            return newConnection()
        }
        switch userInitiatedVPNChange {
        case .connect:
            return newConnection()
        case .disconnect(let trigger):
            return trigger
        case .abort:
            return .auto
        case .settingsChange, .logout:
            return .auto
        }
    }
}
