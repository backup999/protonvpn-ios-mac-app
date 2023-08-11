//
//  Created on 13/12/2022.
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

import XCTest
import fusion
import ProtonCoreTestingToolkitUITestsLogin
import ProtonCoreQuarkCommands
import ProtonCoreEnvironment

final class ExternalAccountsTests: ProtonVPNUITests {
    
    override func setUp() {
        super.setUp()
        logoutIfNeeded()
        changeEnvToBlackIfNeeded()
        useAndContinueTap()
    }

    lazy var environment: Environment = {
        guard let host = dynamicHost else {
            return .black
        }

        return .custom(host)
    }()

    let signInTimeout: TimeInterval = 90
    let signUpTimeout: TimeInterval = 180
    
//    Sign-in:
//    Sign-in with internal account works
//    Sign-in with external account works
//    Sign-in with username account works (no conversion to internal, so no address or keys generation)

    @MainActor
    func testSignInWithInternalAccountWorks() async throws {
        let randomUsername = StringUtils().randomAlphanumericString(length: 8)
        let randomPassword = StringUtils().randomAlphanumericString(length: 8)

        try await QuarkCommands.createAsync(account: .freeWithAddressAndKeys(username: randomUsername, password: randomPassword),
                                            currentlyUsedHostUrl: environment.doh.getCurrentlyUsedHostUrl())

        _ = MainRobot()
            .showLogin()
        
        _ = SigninExternalAccountsCapability()
            .signInWithAccount(
                userName: randomUsername,
                password: randomPassword,
                loginRobot: ProtonCoreTestingToolkitUITestsLogin.LoginRobot(),
                retRobot: MainRobot.self
            )
        
        correctUserIsLoggedIn(.init(username: randomUsername, password: randomPassword, plan: "Proton VPN Free"))
    }

    @MainActor
    func testSignInWithExternalAccountWorks() async throws {
        let randomEmail = "\(StringUtils().randomAlphanumericString(length: 8))@proton.uitests"
        let randomPassword = StringUtils().randomAlphanumericString(length: 8)

        try await QuarkCommands.createAsync(account: .external(email: randomEmail, password: randomPassword),
                                            currentlyUsedHostUrl: environment.doh.getCurrentlyUsedHostUrl())
        
        _ = MainRobot()
            .showLogin()
        
        _ = SigninExternalAccountsCapability()
            .signInWithAccount(
                userName: randomEmail,
                password: randomPassword,
                loginRobot: ProtonCoreTestingToolkitUITestsLogin.LoginRobot(),
                retRobot: MainRobot.self
            )
        
        correctUserIsLoggedIn(.init(username: randomEmail, password: randomPassword, plan: "Proton VPN Free"))
    }

    @MainActor
    func testSignInWithUsernameAccountWorks() async throws {
        let randomUsername = StringUtils().randomAlphanumericString(length: 8)
        let randomPassword = StringUtils().randomAlphanumericString(length: 8)

        try await QuarkCommands.createAsync(account: .freeNoAddressNoKeys(username: randomUsername, password: randomPassword),
                                            currentlyUsedHostUrl: environment.doh.getCurrentlyUsedHostUrl())

        _ = MainRobot()
            .showLogin()

        _ = SigninExternalAccountsCapability()
            .signInWithAccount(
                userName: randomUsername,
                password: randomPassword,
                loginRobot: ProtonCoreTestingToolkitUITestsLogin.LoginRobot(),
                retRobot: MainRobot.self
            )

        correctUserIsLoggedIn(.init(username: randomUsername, password: randomPassword, plan: "Proton VPN Free"))
    }
    
//    Sign-up:
//    Sign-up with internal account works
//    Sign-up with external account works
//    The UI for sign-up with username account is not available

    @MainActor
    func testSignUpWithInternalAccountWorks() async throws {
        try await QuarkCommands.unbanAsync(currentlyUsedHostUrl: environment.doh.getCurrentlyUsedHostUrl())

        let randomUsername = StringUtils().randomAlphanumericString(length: 8)
        let randomEmail = "\(StringUtils().randomAlphanumericString(length: 8))@proton.uitests"
        let randomPassword = StringUtils().randomAlphanumericString(length: 8)

        _ = MainRobot()
            .showSignup()

        SignupExternalAccountsCapability()
            .signUpWithInternalAccount(
                signupRobot: ProtonCoreTestingToolkitUITestsLogin.SignupRobot().otherAccountButtonTap(),
                username: randomUsername,
                password: randomPassword,
                userEmail: randomEmail,
                verificationCode: "666666",
                retRobot: CreatingAccountRobot.self)
            .verify.creatingAccountScreenIsShown()
            .verify.summaryScreenIsShown(time: signUpTimeout)

        _ = skipOnboarding()

        MainRobot()
            .goToSettingsTab()
            .verify.userIsCreated(randomUsername, "Proton VPN Free")

    }

    @MainActor
    func testSignUpWithExternalAccountWorks() async throws {
        try await QuarkCommands.unbanAsync(currentlyUsedHostUrl: environment.doh.getCurrentlyUsedHostUrl())

        let randomEmail = "\(StringUtils().randomAlphanumericString(length: 8))@proton.uitests"
        let randomPassword = StringUtils().randomAlphanumericString(length: 8)

        _ = MainRobot()
            .showSignup()

        SignupExternalAccountsCapability()
            .signUpWithExternalAccount(
                signupRobot: ProtonCoreTestingToolkitUITestsLogin.SignupRobot(),
                userEmail: randomEmail,
                password: randomPassword,
                verificationCode: "666666",
                retRobot: CreatingAccountRobot.self
            )
            .verify.creatingAccountScreenIsShown()
            .verify.summaryScreenIsShown(time: signUpTimeout)

        _ = skipOnboarding()

        MainRobot()
            .goToSettingsTab()
            .verify.userIsCreated(randomEmail, "Proton VPN Free")
    }

    @MainActor
    func testSignUpWithUsernameAccountIsNotAvailable() async throws {
        _ = MainRobot()
            .showSignup()

        ProtonCoreTestingToolkitUITestsLogin.SignupRobot()
            .otherAccountButtonTap()
            .verify.domainsButtonIsShown()
    }
}

private let domainsButtonId = "SignupViewController.domainsButton"

extension ProtonCoreTestingToolkitUITestsLogin.SignupRobot.Verify {
    @discardableResult
    func domainsButtonIsNotShown() -> ProtonCoreTestingToolkitUITestsLogin.SignupRobot {
        button(domainsButtonId).checkDoesNotExist()
        return ProtonCoreTestingToolkitUITestsLogin.SignupRobot()
    }
}

extension ProtonCoreTestingToolkitUITestsLogin.RecoveryRobot {
    public func nextButtonTap<T: CoreElements>(robot: T.Type) -> T {
        _ = nextButtonTap()
        return T()
    }
}
