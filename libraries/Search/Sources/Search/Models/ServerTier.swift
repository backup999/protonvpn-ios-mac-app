//
//  Created on 16.03.2022.
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

public enum ServerTier {
    case free
    case plus
    case basic
}

extension ServerTier {
    var title: String {
        switch self {
        case .basic:
            return LocalizedString.basicServers
        case .plus:
            return LocalizedString.plusServers
        case .free:
            return LocalizedString.freeServers
        }
    }

    static func sorted(by userTier: UserTier) -> [ServerTier] {
        switch userTier {
        case .free:
            return [.free, .plus, .basic]
        case .basic:
            return [.basic, .plus, .free]
        case .plus, .visionary:
            return [.plus, .basic, .free]
        }
    }
}