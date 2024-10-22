//
//  Created on 07/12/2023.
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

import Domain

extension VPNServer {

    /// The server name, split into the name prefix and sequence number (if it exists).
    private var splitName: (serverName: String, sequenceNumber: Int?) {
        let nameArray = logical.name.split(separator: "#")
        guard nameArray.count == 2 else {
            return (logical.name, nil)
        }
        let serverName = String(nameArray[0])
        // some of the server sequence numbers might have the trailing "-TOR" - we strip it
        guard let numberString = nameArray[1].split(separator: "-").first, let number = Int(String(numberString)) else {
            return (serverName, 0)
        }
        return (serverName, number)
    }

    var logicalRecord: Persistence.Logical {
        let (namePrefix, sequenceNumber) = self.splitName

        return .init(
            id: logical.id,
            name: logical.name,
            namePrefix: namePrefix,
            sequenceNumber: sequenceNumber,
            domain: logical.domain,
            entryCountryCode: logical.entryCountryCode,
            exitCountryCode: logical.exitCountryCode,
            tier: logical.tier,
            feature: logical.feature,
            city: logical.city,
            hostCountry: logical.hostCountry,
            translatedCity: logical.translatedCity,
            latitude: logical.latitude,
            longitude: logical.longitude,
            gatewayName: logical.gatewayName
        )
    }

    var logicalStatus: Persistence.LogicalStatus {
        return .init(
            logicalID: logical.id,
            status: logical.status,
            load: logical.load, 
            score: logical.score
        )
    }

    var endpointRecords: [Persistence.Endpoint] {
        return endpoints.map { endpoint in
            .init(
                logicalId: id,
                id: endpoint.id,
                entryIp: endpoint.entryIp,
                exitIp: endpoint.exitIp,
                domain: endpoint.domain,
                status: endpoint.status,
                label: endpoint.label,
                x25519PublicKey: endpoint.x25519PublicKey
            )
        }
    }

    var overrideRecords: [Persistence.EndpointOverrides] {
        return endpoints.compactMap { $0.overrideInfo }
    }
}

extension Domain.Logical {
    init(
        staticInfo: Persistence.Logical,
        dynamicInfo: Persistence.LogicalStatus
    ) {
        self.init(
            id: staticInfo.id,
            name: staticInfo.name,
            domain: staticInfo.domain,
            load: dynamicInfo.load,
            entryCountryCode: staticInfo.entryCountryCode,
            exitCountryCode: staticInfo.exitCountryCode,
            tier: staticInfo.tier,
            score: dynamicInfo.score,
            status: dynamicInfo.status,
            feature: staticInfo.feature,
            city: staticInfo.city,
            hostCountry: staticInfo.hostCountry,
            translatedCity: staticInfo.translatedCity ?? staticInfo.city,
            latitude: staticInfo.latitude,
            longitude: staticInfo.longitude,
            gatewayName: staticInfo.gatewayName
        )
    }

    /// For non-secure core logicals, this is equal to `exitCountryCode`. The access modifier is public while
    /// LegacyCommon code still relies on `entryCountryCode` directly rather than `kind`.
    public var entryCountryCode: String { kind.entryCountryCode ?? exitCountryCode }

    /// Returns nil if this logical is not a gateway. The access modifier is public while LegacyCommon code still relies
    /// on `gatewayName` directly rather than `kind`.
    public var gatewayName: String? { kind.gatewayName }
}

extension ContinuousServerProperties {
    var databaseRecord: LogicalStatus {
        return LogicalStatus(logicalID: serverId, status: status, load: load, score: score)
    }
}

extension Domain.Logical.Kind {
    public var entryCountryCode: String? {
        if case .secureCore(let entryCountryCode) = self {
            return entryCountryCode
        }
        return nil
    }

    public var gatewayName: String? {
        if case .gateway(let name) = self {
            return name
        }
        return nil
    }
}
