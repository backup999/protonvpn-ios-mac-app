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

/// Classes that confirm to this protocol can refresh data from API into the app
public protocol AppSessionRefresher: AnyObject {
    var lastDataRefresh: Date? { get }
    var lastServerLoadsRefresh: Date? { get }
    var lastAccountRefresh: Date? { get }
    var lastStreamingInfoRefresh: Date? { get }
    var lastPartnersInfoRefresh: Date? { get }

    func refreshData()
    func refreshServerLoads()
    func refreshAccount()
    func refreshStreamingServices()
    func refreshPartners(ifUnknownPartnerLogicalExistsIn serverModels: [ServerModel]?) async
}

extension AppSessionRefresher {
    public func refreshPartners() async {
        await refreshPartners(ifUnknownPartnerLogicalExistsIn: nil)
    }

    public func refreshPartners(
        ifUnknownPartnerLogicalExistsIn serverModels: [ServerModel]? = nil,
        completion: @escaping (() -> Void)
    ) {
        Task { [weak self] in
            await self?.refreshPartners(ifUnknownPartnerLogicalExistsIn: serverModels)
            completion()
        }
    }
}

public protocol AppSessionRefresherFactory {
    func makeAppSessionRefresher() -> AppSessionRefresher
}

open class AppSessionRefresherImplementation: AppSessionRefresher {
    public var lastDataRefresh: Date?
    public var lastServerLoadsRefresh: Date?
    public var lastAccountRefresh: Date?
    public var lastStreamingInfoRefresh: Date?
    public var lastPartnersInfoRefresh: Date?
    
    public var loggedIn = false
    
    public var vpnApiService: VpnApiService
    public var vpnKeychain: VpnKeychainProtocol
    public var propertiesManager: PropertiesManagerProtocol
    public var serverStorage: ServerStorage
    public var alertService: CoreAlertService

    public typealias Factory = VpnApiServiceFactory & VpnKeychainFactory & PropertiesManagerFactory & ServerStorageFactory & CoreAlertServiceFactory
        
    public init(factory: Factory) {
        vpnApiService = factory.makeVpnApiService()
        vpnKeychain = factory.makeVpnKeychain()
        propertiesManager = factory.makePropertiesManager()
        serverStorage = factory.makeServerStorage()
        alertService = factory.makeCoreAlertService()
    }
    
    @objc public func refreshData() {
        lastDataRefresh = Date()
        attemptSilentLogIn { result in
            switch result {
            case .success:
                break
            case let .failure(error):
                log.error("Failed to refresh vpn credentials", category: .app, metadata: ["error": "\(error)"])

                let error = error as NSError
                switch error.code {
                case ApiErrorCode.apiVersionBad, ApiErrorCode.appVersionBad:
                    self.alertService.push(alert: AppUpdateRequiredAlert(error as! ApiError))
                default:
                    break // ignore failures
                }
            }
        }
    }
    
    @objc public func refreshServerLoads() {
        guard loggedIn else { return }
        lastServerLoadsRefresh = Date()
        
        vpnApiService.loads(lastKnownIp: propertiesManager.userLocation?.ip) { result in
            switch result {
            case let .success(properties):
                self.serverStorage.update(continuousServerProperties: properties)
            case let .failure(error):
                log.error("RefreshServerLoads error", category: .app, metadata: ["error": "\(error)"])
            }
        }
    }
    
    @objc public func refreshAccount() {
        lastAccountRefresh = Date()        
        
        self.vpnApiService.clientCredentials { result in
            switch result {
            case let .success(credentials):
                self.vpnKeychain.store(vpnCredentials: credentials)
            case let .failure(error):
                log.error("RefreshAccount error", category: .app, metadata: ["error": "\(error)"])
            }
        }
    }

    @objc public func refreshStreamingServices() {
        guard loggedIn else { return }

        lastStreamingInfoRefresh = Date()
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

    public func refreshPartners(ifUnknownPartnerLogicalExistsIn serverModels: [ServerModel]?) async {
        guard loggedIn else { return }

        if let serverModels {
            let knownPartnerLogicals = Set(propertiesManager.partnerTypes.flatMap { type in
                type.partners.flatMap { partner in partner.logicalIDs }
            })
            let shouldRefreshPartners = serverModels.contains { logical in
                logical.feature.contains(.partner) && !knownPartnerLogicals.contains(logical.id)
            }

            guard shouldRefreshPartners else { return }
        }

        lastPartnersInfoRefresh = Date()
        do {
            guard let partnerServices = try await vpnApiService.partnersServices() else { return }
            propertiesManager.partnerTypes = partnerServices.partnerTypes
        } catch {
            log.error("RefreshPartners error", category: .app, metadata: ["error": "\(error)"])
        }

    }

    // MARK: - Override
    
    open func attemptSilentLogIn(completion: @escaping (Result<(), Error>) -> Void) {
        fatalError("This method should be overridden, but it is not")
    }
}