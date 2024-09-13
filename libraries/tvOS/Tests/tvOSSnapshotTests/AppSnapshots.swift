//
//  Created on 07/06/2024.
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

import XCTest
import SnapshotTesting
import ComposableArchitecture
@testable import tvOS
import SwiftUI
@testable import CommonNetworking

class AppFeatureSnapshotTests: XCTestCase {

    func testLightApp() {
        app(trait: .light)
        upsell(trait: .light)
    }

    func testDarkApp() {
        app(trait: .dark)
        upsell(trait: .dark)
    }

    func upsell(trait: UIUserInterfaceStyle) {
        let store = Store(initialState: AppFeature.State(
            userTier: .init(0),
            welcome: .init(destination: .upsell(.loading)),
            networking: .authenticated(.auth(uid: "")))
        ) { AppFeature() }

        let appView = AppView(store: store)
            .frame(.rect(width: 1920, height: 1080))

        assertSnapshot(of: appView, as: .image(traits: trait.collection), testName: "7 Upsell Loading " + trait.name)

        store.send(.upsell(.finishedLoadingProducts(.success(
            [
                PlanIAPTuple(planOption: .init(duration: .oneMonth, price: .init(amount: 2, currency: "USD",locale: .init(identifier: "en_US"))), iap: .freePlan),
                PlanIAPTuple(planOption: .init(duration: .oneYear, price: .init(amount: 12, currency: "USD",locale: .init(identifier: "en_US"))), iap: .freePlan)
            ]
        ))))
        assertSnapshot(of: appView, as: .image(traits: trait.collection), testName: "8 Upsell Loaded " + trait.name)
    }

    func app(trait: UIUserInterfaceStyle) {
        let store = Store(initialState: AppFeature.State(networking: .authenticated(.unauth(uid: "")))) {
            AppFeature()
        } withDependencies: {
            $0.networking = VPNNetworkingMock()
            $0.continuousClock = TestClock()
            $0.paymentsClient = .init(startObserving: unimplemented(),
                                      getOptions: { [ ] },
                                      attemptPurchase: { _ in .purchaseCancelled } )
        }

        let appView = AppView(store: store)
            .frame(.rect(width: 1920, height: 1080))

        assertSnapshot(of: appView, as: .image(traits: trait.collection), testName: "1 Welcome " + trait.name)
        store.send(.welcome(.showCreateAccount))
        assertSnapshot(of: appView, as: .image(traits: trait.collection), testName: "2 CreateAccount " + trait.name)
        store.send(.welcome(.showSignIn))
        assertSnapshot(of: appView, as: .image(traits: trait.collection), testName: "3 SignInRetrievingCode " + trait.name)
        store.send(.welcome(.destination(.presented(.signIn(.codeFetchingFinished(.success(SignInCode(selector: "", userCode: "1234ABCD"))))))))
        assertSnapshot(of: appView, as: .image(traits: trait.collection), testName: "4 SignInWithCode " + trait.name)
        store.send(.welcome(.destination(.presented(.signIn(.signInFinished(.failure(.authenticationAttemptsExhausted)))))))
        assertSnapshot(of: appView, as: .image(traits: trait.collection), testName: "5 CodeExpired " + trait.name)

        store.send(.networking(.startAcquiringSession))
        assertSnapshot(of: appView, as: .image(traits: trait.collection), testName: "6 AcquiringSession " + trait.name)
    }
}
