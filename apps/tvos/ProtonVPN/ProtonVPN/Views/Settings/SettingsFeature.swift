//
//  Created on 25/04/2024.
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

import ComposableArchitecture
import SwiftUI

@Reducer
struct SettingsFeature {
    @ObservableState
    struct State: Equatable {
        @Shared(.appStorage("username")) var userName: String?

        @Presents var alert: AlertState<Action.Alert>?
    }

    enum Action {
        case alert(PresentationAction<Alert>)
        case contactUs
        case reportAnIssue
        case privacyPolicy
        case signOutSelected

        @CasePathable
        enum Alert {
          case signOut
        }
    }

    static let signOutAlert = AlertState<Action.Alert> {
        TextState("Sign out")
      } actions: {
          ButtonState(action: .signOut) {
              TextState("Sign out")
          }
          ButtonState(role: .cancel) {
              TextState("Cancel")
          }
      } message: {
          TextState("Are you sure you want to sign out of Proton VPN?")
      }

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .contactUs:
                return .none
            case .reportAnIssue:
                return .none
            case .privacyPolicy:
                return .none
            case .signOutSelected:
                state.alert = Self.signOutAlert
                return .none
            case .alert(.presented(.signOut)):
                state.userName = nil
                return .none
            case .alert:
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
    }
}
