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

@Reducer
struct MainFeature {

    enum Tab { case home, search, settings }

    @ObservableState
    struct State: Equatable {
        var currentTab: Tab = .home
        var countryList = CountryListFeature.State()
        var settings = SettingsFeature.State()
        var connect = ConnectFeature.State()
    }

    enum Action {
        case selectTab(Tab)
        case countryList(CountryListFeature.Action)
        case settings(SettingsFeature.Action)
        case connect(ConnectFeature.Action)
    }

    var body: some Reducer<State, Action> {
        Scope(state: \.connect, action: \.connect) {
            ConnectFeature()
        }
        Scope(state: \.countryList, action: \.countryList) {
            CountryListFeature()
        }
        Scope(state: \.settings, action: \.settings) {
            SettingsFeature()
        }
        Reduce { state, action in
            switch action {
            case .selectTab(let tab):
                state.currentTab = tab
                return .none
            case .settings:
                return .none
            case .countryList(.selectItem(let item)):
                return .run { send in
                    await send(.connect(.userClickedConnect(item)))
                }
            case .connect:
                return .none
            case .countryList:
                return .none
            }
        }
    }
}
