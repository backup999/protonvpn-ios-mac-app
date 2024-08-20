//
//  AppSessionRefresher.swift
//  vpncore - Created on 2020-09-01.
//
//  Copyright (c) 2019 Proton Technologies AG
//
//  This file is part of LegacyCommon.
//
//  vpncore is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  vpncore is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with LegacyCommon.  If not, see <https://www.gnu.org/licenses/>.
//

import Foundation

import Dependencies

import Ergonomics
import Persistence

/// Classes that confirm to this protocol can refresh data from API into the app
public protocol AppSessionRefresher: AnyObject {
    func refreshData()
    func refreshServerLoads()
    func refreshAccount()
    func refreshStreamingServices()
}

public protocol AppSessionRefresherFactory {
    func makeAppSessionRefresher() -> AppSessionRefresher
}

open class AppSessionRefresherImplementation: AppSessionRefresher {
    @Dependency(\.serverManager) public var serverManager
    public var loggedIn = false
    public var successfulConsecutiveSessionRefreshes = CounterActor()

    /// When true, and the user is on a free tier, requests to v1/logicals should only request free logicals
    public var shouldRefreshServersAccordingToUserTier: Bool {
        get async {
            // Every n times, fully refresh the server list, including the paid ones.
            // Add 1 to the value of `successfulConsecutiveSessionRefreshes` so that on
            // startup we always do a full refresh.
            let n = 10
            let shouldPerformFullRefresh = (await successfulConsecutiveSessionRefreshes.value % n) == 0
            return !shouldPerformFullRefresh
        }
    }

    public var vpnApiService: VpnApiService
    public var vpnKeychain: VpnKeychainProtocol
    public var propertiesManager: PropertiesManagerProtocol
    public var alertService: CoreAlertService
    public var coreApiService: CoreApiService

    private var notificationCenter: NotificationCenter = .default

    private var observation: NotificationToken?

    public typealias Factory = VpnApiServiceFactory & VpnKeychainFactory & PropertiesManagerFactory & CoreAlertServiceFactory & CoreApiServiceFactory

    public init(factory: Factory) {
        vpnApiService = factory.makeVpnApiService()
        vpnKeychain = factory.makeVpnKeychain()
        propertiesManager = factory.makePropertiesManager()
        alertService = factory.makeCoreAlertService()
        coreApiService = factory.makeCoreApiService()

        observation = notificationCenter.addObserver(
            for: type(of: vpnKeychain).vpnPlanChanged,
            object: nil,
            handler: { [weak self] in
                self?.userPlanChanged($0)
            }
        )
    }
    
    @objc public func refreshData() {
        attemptSilentLogIn { [weak self] result in
            switch result {
            case .success:
                Task { [weak self] in
                    await self?.successfulConsecutiveSessionRefreshes.increment()
                    do {
                        self?.propertiesManager.userSettings = try await self?.coreApiService.getUserSettings()
                    } catch {
                        log.error("UserSettings error", category: .app, metadata: ["error": "\(error)"])
                    }
                }
                break
            case let .failure(error):
                log.error("Failed to refresh vpn credentials", category: .app, metadata: ["error": "\(error)"])

                switch error.responseCode {
                case ApiErrorCode.apiVersionBad, ApiErrorCode.appVersionBad:
                    self?.alertService.push(alert: AppUpdateRequiredAlert(error))
                default:
                    break // ignore failures
                }
                Task { [weak self] in
                    await self?.successfulConsecutiveSessionRefreshes.reset()
                }
            }
        }
    }
    
    @objc public func refreshServerLoads() {
        guard loggedIn else { return }

        let lastKnownIp = (propertiesManager.userLocation?.ip).flatMap { TruncatedIp(ip: $0) }
        vpnApiService.loads(lastKnownIp: lastKnownIp) { result in
            switch result {
            case let .success(properties):
                let loads = properties.map { $0.value }
                @Dependency(\.serverRepository) var serverRepository
                serverRepository.upsert(loads: loads)
            case let .failure(error):
                log.error("RefreshServerLoads error", category: .app, metadata: ["error": "\(error)"])
            }
        }
    }
    
    @objc public func refreshAccount() {
        Task { @MainActor in
            do {
                let credentials = try await self.vpnApiService.clientCredentials()
                self.vpnKeychain.storeAndDetectDowngrade(vpnCredentials: credentials)
            } catch {
                log.error("RefreshAccount error", category: .app, metadata: ["error": "\(error)"])
            }
        }
    }

    @objc public func refreshStreamingServices() {
        guard loggedIn else { return }

        Task { [weak self] in
            do {
                guard let streamingResponse = try await self?.vpnApiService.virtualServices() else { return }
                self?.propertiesManager.streamingServices = streamingResponse.streamingServices
                self?.propertiesManager.streamingResourcesUrl = streamingResponse.resourceBaseURL
            } catch {
                log.error("RefreshStreamingInfo error", category: .app, metadata: ["error": "\(error)"])
            }
        }
    }

    /// After user plan changes, feature flags may also change, so we have to reload them
    open func userPlanChanged(_ notification: Notification) {
        refreshData()
        presentWelcomeScreen(notification)
    }

    private func presentWelcomeScreen(_ notification: Notification) {
        guard let info = notification.object as? VpnDowngradeInfo else { return }
        if let plan = WelcomeScreenAlert.Plan(info: info) {
            alertService.push(alert: WelcomeScreenAlert(plan: plan))
        }
    }

    // MARK: - Override
    
    open func attemptSilentLogIn(completion: @escaping (Result<(), Error>) -> Void) {
        fatalError("This method should be overridden, but it is not")
    }
}
