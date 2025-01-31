//
//  Created on 2023-02-03.
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
import SwiftOTP

public enum GenerateTwoFaCode {
    
    public static func generateCodeFor2FAUser(_ key: String) async -> String {
        let expiryInterval: TimeInterval = 5
        let totp = TOTP(secret: base32DecodeToData(key)!)

        guard let res = totp?.generate(time: Date()) else {
            return ""
        }

        // If the 2fa code is expiring in the next 5 seconds, wait for it to roll over and return the new value.
        if let futureRes = totp?.generate(time: Date().addingTimeInterval(expiryInterval)), futureRes != res {
            try? await Task.sleep(nanoseconds: UInt64(expiryInterval * 1_000_000_000))
            return futureRes
        }

        return res
    }
}
