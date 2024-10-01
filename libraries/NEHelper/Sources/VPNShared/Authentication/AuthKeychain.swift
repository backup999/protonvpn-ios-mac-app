//
//  AuthKeychain.swift
//  vpncore - Created on 26.06.19.
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

import Foundation
import KeychainAccess
import Dependencies
import Ergonomics
import Domain

public protocol AuthKeychainHandle {
    var username: String? { get }
    var userId: String? { get }
    /// Whenever we try storing credentials or fetching them from keychain
    /// We also save them to memory as a quick cache that would save us
    /// a lot of trips to the keychain.
    func saveToCache(_ credentials: AuthCredentials?)
    func fetch(forContext: AppContext?) -> AuthCredentials?
    func fetch(forContext: AppContext?) throws -> AuthCredentials
    func store(_ credentials: AuthCredentials, forContext: AppContext?) throws
    func clear()
}

public extension AuthKeychainHandle {
    func fetch() -> AuthCredentials? {
        let credentials: AuthCredentials? = fetch(forContext: nil)
        saveToCache(credentials)
        return credentials
    }

    func fetch() throws -> AuthCredentials {
        let credentials: AuthCredentials = try fetch(forContext: nil)
        saveToCache(credentials)
        return credentials
    }

    func store(_ credentials: AuthCredentials) throws {
        saveToCache(credentials)
        try store(credentials, forContext: nil)
    }
}

public protocol AuthKeychainHandleFactory {
    func makeAuthKeychainHandle() -> AuthKeychainHandle
}

public struct AuthKeychainHandleDependencyKey: DependencyKey {
    public static var liveValue: AuthKeychainHandle {
        AuthKeychain.default
    }

    #if DEBUG
    public static var testValue = liveValue
    #endif
}

extension DependencyValues {
    public var authKeychain: AuthKeychainHandle {
        get { self[AuthKeychainHandleDependencyKey.self] }
        set { self[AuthKeychainHandleDependencyKey.self] = newValue }
    }
}

public final class AuthKeychain {
    public static let clearNotification = Notification.Name("AuthKeychain.clear")

    private struct StorageKey {
        static let authCredentials = "authCredentials"

        static let contextKeys: [AppContext: String] = [
            .mainApp: authCredentials,
            .wireGuardExtension: "\(authCredentials)_\(AppContext.wireGuardExtension)"
        ]
    }

    public static let `default`: AuthKeychainHandle = AuthKeychain()

    static let dispatchQueue = DispatchQueue(label: "ch.protonvpn.VPNShared.AuthKeychain",
                                             attributes: .concurrent)
    @ConcurrentlyReadable(queue: AuthKeychain.dispatchQueue)
    public var username: String? = nil

    @ConcurrentlyReadable(queue: AuthKeychain.dispatchQueue)
    public var userId: String? = nil

    public static func fetch() -> AuthCredentials? {
        `default`.fetch()
    }

    public static func store(_ credentials: AuthCredentials) throws {
        try `default`.store(credentials)
    }

    public static func clear() {
        `default`.clear()
    }
    private let keychain = KeychainActor()

    @Dependency(\.appContext) private var context
}

extension AuthKeychain: AuthKeychainHandle {
    public func saveToCache(_ credentials: AuthCredentials?) {
        AuthKeychain.dispatchQueue.sync(flags: .barrier) {
            self._username.unsafeUpdateNoSync { $0 = credentials?.username }
            self._userId.unsafeUpdateNoSync { $0 = credentials?.userId }
        }
    }
    
    private var defaultStorageKey: String {
        storageKey(forContext: context) ?? StorageKey.authCredentials
    }

    private func storageKey(forContext context: AppContext) -> String? {
        StorageKey.contextKeys[context]
    }

    public func fetch(forContext context: AppContext?) -> AuthCredentials? {
        do {
            // Explicitly state type as AuthCredentials to resolve ambiguity between throwing and non throwing functions
            let credentials: AuthCredentials = try fetch(forContext: context)
            return credentials
        } catch {
            if let keychainError = error as? KeychainError, case .credentialsMissing(let key) = keychainError {
                log.debug("Credentials missing from auth keychain", metadata: ["storageKey": "\(key)"])
                return nil
            }
            log.error("Failed to fetch auth credentials", category: .keychain, metadata: ["error": "\(error)"])
            return nil
        }
    }

    public func fetch(forContext context: AppContext?) throws -> AuthCredentials {
        NSKeyedUnarchiver.setClass(AuthCredentials.self, forClassName: "ProtonVPN.AuthCredentials")
        let key: String = context.flatMap { storageKey(forContext: $0) } ?? defaultStorageKey
        guard let data = try keychain.getData(key) else {
            throw KeychainError.credentialsMissing(key)
        }

        do {
            return try JSONDecoder().decode(AuthCredentials.self, from: data)
        } catch {
            do {
                /// We tried decoding with JSON and failed, let's try to decode from NSKeyedUnarchiver,
                /// but first let's remove the stored data in case the NSKeyedUnarchiver crashes.
                /// Next time user launches the app, the credentials will be lost, but at least
                /// we won't start a crash cycle from which the user can't recover.
                try? keychain.remove(key)
                log.info("Removed AuthKeychain storage for \(key) key before attempting to unarchive with NSKeyedUnarchiver", category: .keychain)
                let rootClasses = [AuthCredentials.self, NSString.self, NSData.self]
                let unarchivedObject = try NSKeyedUnarchiver.unarchivedObject(ofClasses: rootClasses, from: data)
                guard let authCredentials = unarchivedObject as? AuthCredentials else {
                    throw KeychainError.migration(.invalidObjectType(type(of: unarchivedObject)))
                }
                    try? store(authCredentials, forContext: context) // store in JSON
                    log.info("AuthKeychain storage for \(key) migration successful!", category: .keychain)
                    return authCredentials

            } catch let unarchivingError {
                throw KeychainError.migration(.unarchivingFailure(unarchivingError))
            }
        }
    }

    public func store(_ credentials: AuthCredentials, forContext context: AppContext?) throws {
        var key = defaultStorageKey
        if let context = context, let contextKey = storageKey(forContext: context) {
            key = contextKey
        }

        do {
            let data = try JSONEncoder().encode(credentials)
            try keychain.set(data, key: key)
        } catch let error {
            log.error("Keychain (auth) write error: \(error). Will clean and retry.", category: .keychain, metadata: ["error": "\(error)"])
            do { // In case of error try to clean keychain and retry with storing data
                clear()
                let data = try JSONEncoder().encode(credentials)
                try keychain.set(data, key: key)
            } catch let error2 {
                #if os(macOS)
                    log.error("Keychain (auth) write error: \(error2). Will lock keychain to try to recover from this error.", category: .keychain, metadata: ["error": "\(error2)"])
                    do { // Last chance. Locking/unlocking keychain sometimes helps.
                        SecKeychainLock(nil)
                        let data = try JSONEncoder().encode(credentials)
                        try keychain.set(data, key: key)
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

    public func clear() {
        keychain.clear(contextValues: Array<String>(StorageKey.contextKeys.values))
        saveToCache(nil)
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: Self.clearNotification, object: nil, userInfo: nil)
        }
    }
}

public enum KeychainError: Error {
    case credentialsMissing(String)
    case migration(LegacyMigrationError)

    public enum LegacyMigrationError: Error {
        case invalidObjectType(Any.Type)
        case unarchivingFailure(Error)
    }
}
