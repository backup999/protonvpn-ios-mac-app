//
//  Created on 2022-01-11.
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
import XCTest
import Strings

fileprivate let qcButton = Localizable.quickConnect
fileprivate let disconnectButton = Localizable.disconnect
fileprivate let preferencesTitle = Localizable.preferences
fileprivate let menuItemReportAnIssue = Localizable.reportAnIssue
fileprivate let menuItemProfiles = Localizable.overview
fileprivate let statusTitle = Localizable.youAreNotConnected
fileprivate let initializingConnectionTitle = Localizable.initializingConnection
fileprivate let successfullyConnectedTitle = Localizable.successfullyConnected
fileprivate let headerLabelField = "headerLabel"
fileprivate let ipLabelField = "ipLabel"
fileprivate let protocolLabelField = "protocolLabel"

class MainRobot {
    
    func openProfiles() -> ManageProfilesRobot {
        app.tabGroups[Localizable.profiles].forceClick()
        app.buttons[Localizable.createProfile].click()
        return ManageProfilesRobot()
    }
    
    func closeProfilesOverview() -> MainRobot {
        let preferencesWindow = app.windows[Localizable.profilesOverview]
        preferencesWindow.buttons[XCUIIdentifierCloseWindow].click()
        return self
    }
    
    func openAppSettings() -> SettingsRobot {
        window.typeKey(",", modifierFlags: [.command]) // Settings…
        return SettingsRobot()
    }
    
    func quickConnectToAServer() -> MainRobot {
        app.buttons[qcButton].forceClick()
        return self
    }
    
    func isConnected() -> Bool {
        return app.buttons[disconnectButton].waitForExistence(timeout: WaitTimeout.short)
    }
    
    func disconnect() -> MainRobot {
        app.buttons[disconnectButton].firstMatch.forceClick()
        return self
    }
    
    func logOut() -> LoginRobot {
        window.typeKey("w", modifierFlags: [.shift, .command])
        return LoginRobot()
    }
    
    func waitForInitializingConnectionScreenDisappear(_ timeout: Int) -> Bool {
        return app.staticTexts[initializingConnectionTitle].waitForNonExistence(timeout: TimeInterval(timeout))
    }
    
    func waitForSuccessfullyConnectedScreenDisappear(_ timeout: Int) -> Bool {
        return app.staticTexts[successfullyConnectedTitle].waitForNonExistence(timeout: TimeInterval(timeout))
    }
    
    func isConnecting() -> Bool {
        return app.staticTexts[initializingConnectionTitle].exists
    }
    
    func waitForConnected(with connectionProtocol: ConnectionProtocol) -> MainRobot {
        let connectingTimeout = 5
        guard waitForInitializingConnectionScreenDisappear(connectingTimeout) else {
            XCTFail("VPN is not connected using \(connectionProtocol) in \(connectingTimeout) seconds")
            return MainRobot()
        }

        _ = waitForSuccessfullyConnectedScreenDisappear(connectingTimeout)

        if isConnectionTimedOut() {
            XCTFail("Connection timeout while connecting to \(connectionProtocol) protocol")
        }

        return self
    }

    func cancelConnecting() -> MainRobot {
        app.buttons[Localizable.cancel].click()
        return self
    }
    
    func isConnectionTimedOut() -> Bool {
        return app.staticTexts[Localizable.connectionTimedOut].exists
    }
    
    func getHeaderLabelValue() -> String {
        return app.staticTexts[headerLabelField].value as? String ?? ""
    }
    
    func getConnectedCountry() -> String {
        return getHeaderLabelValue().trimServerCode
    }
    
    func getIPLabelValue() -> String {
        return app.staticTexts[ipLabelField].value as? String ?? ""
    }
    
    func getProtocolLabelValue() -> String {
        return app.staticTexts[protocolLabelField].value as? String ?? ""
    }
    
    func isAbleToChangeServer() -> Bool {
        return app.buttons[Localizable.changeServer].exists
    }
    
    func clickChangeServer() -> MainRobot {
        let changeServerButton = app.buttons[Localizable.changeServer]
        if changeServerButton.exists {
            changeServerButton.forceClick()
        } else {
            let changeServerLabel = app.staticTexts[Localizable.changeServer]
            changeServerLabel.forceClick()
        }
        return self
    }

    let verify = Verify()
    
    class Verify {
        
        @discardableResult
        func checkSettingsModalIsClosed() -> MainRobot {
            XCTAssertFalse(app.buttons[preferencesTitle].exists)
            XCTAssertTrue(app.buttons[qcButton].exists)
            return MainRobot()
        }
        
        @discardableResult
        func checkUserIsLoggedIn() -> MainRobot {
            XCTAssert(app.staticTexts[statusTitle].waitForExistence(timeout: WaitTimeout.short))
            XCTAssert(app.buttons[qcButton].waitForExistence(timeout: WaitTimeout.short))
            return MainRobot()
        }
        
        @discardableResult
        func checkVPNConnecting() -> MainRobot {
            XCTAssert(app.staticTexts[initializingConnectionTitle].waitForExistence(timeout: WaitTimeout.normal), "\(initializingConnectionTitle) element not found.")
            return MainRobot()
        }
        
        @discardableResult
        func checkConnectionCardIsConnected(with expectedProtocol: ConnectionProtocol,
                                            to connectedCountry: String? = nil,
                                            userType: UserType? = nil) -> MainRobot {
            // verify Disconnect button appears
            XCTAssert(app.buttons[Localizable.disconnect].waitForExistence(timeout: WaitTimeout.normal), "Connection card is not connected. '\(Localizable.disconnect)' button not found.")
            
            // verify correct connected protocol appears
            let actualProtocol = MainRobot().getProtocolLabelValue()
            
            if case .Smart = expectedProtocol {
                XCTAssertTrue(!actualProtocol.isEmpty, "Connection protocol for Smart protocol should not be empty")
            } else {
                XCTAssertEqual(expectedProtocol.rawValue, actualProtocol, "Invalid protocol shown, expected: \(expectedProtocol), actual: \(actualProtocol)")
            }
            
            // verify IP Address label appears
            let actualIPAddress = MainRobot().getIPLabelValue()
            XCTAssertTrue(validateIPAddress(from: actualIPAddress), "IP label \(actualIPAddress) does not contain valid IP address")
            
            // verify header label contain country code
            validateHeaderLabel(value: connectedCountry)
            
            if case .Free = userType {
                let predicate = NSPredicate(format: "value CONTAINS[c] %@", Localizable.changeServer)
                let changeServerButton = app.buttons[Localizable.changeServer]
                let changeServerTextField = app.staticTexts.matching(predicate).firstMatch
                
                
                XCTAssertTrue(changeServerButton.exists || changeServerTextField.exists, "'\(Localizable.changeServer)' button is not visible when it shoudl be")
                // verify header label contain "FREE" text
                validateHeaderLabel(value: "FREE")
            }
            
            return MainRobot()
        }
        
        func checkConnectedServerContain(label: String) -> MainRobot {
            // verify header label contain label
            validateHeaderLabel(value: label)
            return MainRobot()
        }
        
        @discardableResult
        func checkConnectionCardIsDisconnected() -> MainRobot {
            // verify "Quick Connect" button is visible
            XCTAssert(app.buttons[Localizable.quickConnect].waitForExistence(timeout: WaitTimeout.short), "'\(Localizable.quickConnect)' button not found.")
            
            // verify "You are not connected" label if visible
            validateHeaderLabel(value: Localizable.youAreNotConnected)
            
            // verify IP adddress label is displayed and not empty
            let actualIPAddress = MainRobot().getIPLabelValue()
            XCTAssertTrue(validateIPAddress(from: actualIPAddress), "IP label \(actualIPAddress) does not contain valid IP address")
            return MainRobot()
        }

        @discardableResult
        func checkIfLocalNetworkingReachable(to defaultGatewayAddress: String) throws -> MainRobot {
            let success = try NetworkUtils.isIpAddressAccessible(ipAddress: defaultGatewayAddress)
            if !success {
                XCTFail("Local letwork is not accessbile by ip addess: \(defaultGatewayAddress)")
            }

            return MainRobot()
        }
        
        func checkConnectedServerChanged(connectedServer: String) -> MainRobot {
            let actualConnectedServer = MainRobot().getConnectedCountry()
            
            XCTAssertNotEqual(connectedServer, actualConnectedServer, "Connected server is not changed")
            
            return MainRobot()
        }
        
        func checkIpAddressChanged(previousIpAddress: String) async throws -> String {
            let currentIpAddress = try await NetworkUtils.getIpAddress()
            XCTAssertTrue(currentIpAddress != previousIpAddress, "IP address is not changed. Previous ip address: \(previousIpAddress), current IP address: \(currentIpAddress)")
            return currentIpAddress
        }
        
        func checkIpAddressUnchanged(previousIpAddress: String) async throws {
            let currentIpAddress = try await NetworkUtils.getIpAddress()
            XCTAssertEqual(currentIpAddress, previousIpAddress, "IP address has been changed. Previous ip address: \(previousIpAddress), current IP address: \(currentIpAddress)")
        }

        // MARK: private methods
        
        private func validateIPAddress(from string: String) -> Bool {
            let prefix = "IP: "
            guard string.hasPrefix(prefix) else {
                return false
            }
            
            let ipAddress = String(string.dropFirst(prefix.count))
            return ipAddress.isValidIPv4Address
        }
        
        private func validateHeaderLabel(value: String? = nil) {
            // validate "headerLabel" exist
            XCTAssert(app.staticTexts[headerLabelField].waitForExistence(timeout: WaitTimeout.short),
                      "headerLabel textfield was not found.")
            let actualHeaderLabelValue = MainRobot().getHeaderLabelValue()
            
            if let expectedValue = value {
                // validate headerLabel has exact value
                XCTAssertTrue(actualHeaderLabelValue.contains(expectedValue),
                               "headerLabel textfield does not contain expected value: \(expectedValue), actual value: \(actualHeaderLabelValue)")
            } else {
                // validate headerLabel is not empty
                XCTAssertTrue(!actualHeaderLabelValue.isEmpty, "headerLabel textfield shold not be empty")
            }
        }
    }
}
