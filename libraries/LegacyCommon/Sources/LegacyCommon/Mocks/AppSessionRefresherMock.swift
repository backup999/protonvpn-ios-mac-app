//
//  Created on 12.07.23.
//
//  Copyright (c) 2023 Proton AG
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

import Dependencies

import Domain

/// This exists because the `attemptSilentLogIn()` function needs to be overridden.
class AppSessionRefresherMock: AppSessionRefresherImplementation {
    var didAttemptLogin: (() -> Void)?
    var loginError: Error?

    override func attemptSilentLogIn(completion: @escaping (Result<(), Error>) -> Void) {
        defer { didAttemptLogin?() }

        if let loginError = loginError {
            completion(.failure(loginError))
            return
        }

        let isFreeTier: Bool
        do {
            isFreeTier = try vpnKeychain.fetchCached().maxTier.isFreeTier
        } catch {
            completion(.failure(error))
            return
        }

        // The completion handler of vpnApiService.refreshServerInfo is escaping, so it's necessary to manually
        // propagate dependencies here
        withEscapedDependencies { dependencies in
            vpnApiService.refreshServerInfo(freeTier: isFreeTier) { result in
                // Inside this closure, dependencies defined on this object are now not guaranteed to be what we expect
                dependencies.yield {
                    // Access correct dependencies (e.g. those applied with withDependencies inside tests)
                    switch result {
                    case let .success(properties):
                        guard let properties else {
                            completion(.success)
                            return
                        }
                        if let userLocation = properties.location {
                            self.propertiesManager.userLocation = userLocation
                        }
                        if let services = properties.streamingServices {
                            self.propertiesManager.streamingServices = services.streamingServices
                        }
                        @Dependency(\.serverManager) var serverManager
                        if case .modified(let modifiedAt, let servers, let isFreeTier) = properties.serverInfo {
                            serverManager.update(
                                servers: servers.map { VPNServer(legacyModel: $0) },
                                freeServersOnly: isFreeTier,
                                lastModifiedAt: modifiedAt
                            )
                        }
                        completion(.success)
                    case let .failure(error):
                        completion(.failure(error))
                    }
                }
            }
        }
    }
}
