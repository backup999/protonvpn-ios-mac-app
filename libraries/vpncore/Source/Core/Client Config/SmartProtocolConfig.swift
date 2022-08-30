//
//  SmartProtocolConfig.swift
//  ProtonVPN - Created on 2020-10-21.
//
//  Copyright (c) 2021 Proton Technologies AG
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

import Foundation

public struct SmartProtocolConfig: Codable, Equatable {
    public let openVPN: Bool
    public let iKEv2: Bool
    public let wireGuard: Bool
    @Default<Bool> public var wireGuardTls: Bool

    enum CodingKeys: String, CodingKey {
        case openVPN
        case iKEv2 = "IKEv2"
        case wireGuard
        case wireGuardTls
    }

    public init(openVPN: Bool, iKEv2: Bool, wireGuard: Bool, wireGuardTls: Bool) {
        self.openVPN = openVPN
        self.iKEv2 = iKEv2
        self.wireGuard = wireGuard
        self.wireGuardTls = wireGuardTls
    }

    public init() {
        self.init(openVPN: true, iKEv2: true, wireGuard: true, wireGuardTls: true)
    }
    
    public func configWithWireGuard(enabled: Bool? = nil, tlsEnabled: Bool? = nil) -> SmartProtocolConfig {
        // If enabled is specified, use that value. Otherwise, use the existing config value in this object.
        let wireGuardEnabled = enabled ?? wireGuard
        var wireGuardTlsEnabled = false
        // If wireGuard has been enabled via the above, set WGTLS' enablement according to the passed value,
        // or, if none was provided, the existing config value in this object.
        if wireGuardEnabled {
            wireGuardTlsEnabled = tlsEnabled ?? wireGuardTls
        }

        return SmartProtocolConfig(openVPN: openVPN,
                                   iKEv2: iKEv2,
                                   wireGuard: wireGuardEnabled,
                                   wireGuardTls: wireGuardTlsEnabled)
    }

    public static func == (lhs: SmartProtocolConfig, rhs: SmartProtocolConfig) -> Bool {
        lhs.openVPN == rhs.openVPN &&
        lhs.iKEv2 == rhs.iKEv2 &&
        lhs.wireGuard == rhs.wireGuard &&
        lhs.wireGuardTls == rhs.wireGuardTls
    }
}
