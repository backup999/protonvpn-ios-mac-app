//
//  Created on 9/6/24.
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
import Dependencies
import NetShield

public struct NetShieldStatsProvider: TestDependencyKey {
    var stats: @Sendable () -> NetShieldModel

    public static let testValue = NetShieldStatsProvider(stats: { .init(trackersCount: 34, adsCount: 75, dataSaved: 2945, enabled: true)})
}

extension DependencyValues {
    public var netShieldStatsProvider: NetShieldStatsProvider {
        get { self[NetShieldStatsProvider.self] }
        set { self[NetShieldStatsProvider.self] = newValue }
    }
}
