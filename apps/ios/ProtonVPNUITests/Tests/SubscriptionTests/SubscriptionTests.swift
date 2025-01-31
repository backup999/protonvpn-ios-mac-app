//
//  Created on 31/10/2023.
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

import XCTest
import fusion
import ProtonCoreTestingToolkitUITestsPaymentsUI
import ProtonCoreQuarkCommands
import StoreKitTest

final class SubscriptionTests: ProtonVPNUITests {

    private var session: SKTestSession!

    override func setUp() {
        super.setUp()
        setupAtlasEnvironment()
        homeRobot
            .showLogin()
            .verify.loginScreenIsShown()
    }

    override func setUpWithError() throws {
        session = try SKTestSession(configurationFileNamed: "Proton VPN: Fast & Secure")
        session.disableDialogs = true
        session.clearTransactions()
    }

    func testUpgradeAccountFromFreeToUnlimited() throws {
         try createUserVerifySubscription(plan: .unlimited)
    }

    func testUpgradeAccountFromFreeToVPN2022() throws {
         try createUserVerifySubscription(plan: .vpn2022)
    }

    private func createUserVerifySubscription(plan: PaymentsPlan) throws {
        let user = User(name: StringUtils.randomAlphanumericString(length: 10), password: "12l3")
        try quarkCommands.userCreate(user: user)

        _ = LoginRobot()
            .enterCredentials(user)
            .signIn(robot: HomeRobot.self)
            .verify.isLoggedIn()
            .goToSettingsTab()
            .goToAccountDetail()
            .tapSubscription()
            .expandPlan(plan: plan)
            .planButtonTap(plan: plan)
        _ = PaymentsUIRobot()
            .verifyCurrentPlan(plan: plan)
    }
}
