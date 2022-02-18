//
//  AuthKeychain.swift
//  vpncore - Created on 26.06.19.
//
//  Copyright (c) 2019 Proton Technologies AG
//
//  This file is part of vpncore.
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
//  along with vpncore.  If not, see <https://www.gnu.org/licenses/>.

import Foundation
import KeychainAccess

public class AuthKeychain {
    
    public static let clearNotification = Notification.Name("AuthKeychain.clear")
    
    private struct StorageKey {
        static let authCredentials = "authCredentials"
    }
    
    private static let appKeychain = KeychainAccess.Keychain(service: KeychainConstants.appKeychain).accessibility(.afterFirstUnlockThisDeviceOnly)
    
    public static func fetch() -> AuthCredentials? {
        NSKeyedUnarchiver.setClass(AuthCredentials.self, forClassName: "ProtonVPN.AuthCredentials")

        do {
            if let data = try appKeychain.getData(StorageKey.authCredentials) {
                if let authCredentials = NSKeyedUnarchiver.unarchiveObject(with: data) as? AuthCredentials {
                    return authCredentials
                }
            }
        } catch let error {
            log.error("Keychain (auth) read error: \(error)", category: .keychain)
        }
        
        return nil
    }
    
    public static func store(_ credentials: AuthCredentials) throws {
        NSKeyedArchiver.setClassName("ProtonVPN.AuthCredentials", for: AuthCredentials.self)

        do {
            try appKeychain.set(NSKeyedArchiver.archivedData(withRootObject: credentials), key: StorageKey.authCredentials)
        } catch let error {
            log.error("Keychain (auth) write error: \(error). Will clean and retry.", category: .keychain, metadata: ["error": "\(error)"])
            do { // In case of error try to clean keychain and retry with storing data
                clear()
                try appKeychain.set(NSKeyedArchiver.archivedData(withRootObject: credentials), key: StorageKey.authCredentials)
            } catch let error2 {
                #if os(macOS)
                    log.error("Keychain (auth) write error: \(error2). Will lock keychain to try to recover from this error.", category: .keychain, metadata: ["error": "\(error2)"])
                    do { // Last chance. Locking/unlocking keychain sometimes helps.
                        SecKeychainLock(nil) 
                        try appKeychain.set(NSKeyedArchiver.archivedData(withRootObject: credentials), key: StorageKey.authCredentials)
                    } catch let error3 {
                        log.error("Keychain (auth) write error. Giving up.", category: .keychain, metadata: ["error": "\(error3)"])
                        throw error3
                    }
                #else
                log.error("Keychain (auth) write error. Giving up.", category: .keychain, metadata: ["error": "\(error2)"])
                    throw error2
                #endif
            }
        }
    }
    
    public static func clear() {
        appKeychain[data: StorageKey.authCredentials] = nil
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: clearNotification, object: nil, userInfo: nil)
        }
    }

    public init() { }
}
