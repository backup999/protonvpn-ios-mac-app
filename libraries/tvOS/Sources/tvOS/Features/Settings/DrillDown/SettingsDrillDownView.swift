//
//  Created on 08/05/2024.
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

import SwiftUI
import ComposableArchitecture

struct SettingsDrillDownView: View {
    private static let maximumContentWidth: CGFloat = 1420

    var store: StoreOf<SettingsDrillDownFeature>

    var body: some View {
        viewBody
            .frame(width: Self.maximumContentWidth)
            .onExitCommand { store.send(.onExitCommand) }
    }
    
    @ViewBuilder var viewBody: some View {
        switch store.state {
        case .eula:
            EULAView()
        case .dynamic(let destination):
            DynamicDrillDownView(model: destination.model)
                .focusable()
        }
    }
}

struct DynamicDrillDownView: View {
    let model: DynamicDrillDownModel
    
    var body: some View {
        HStack(spacing: .themeSpacing120) {
            VStack(alignment: .leading, spacing: .themeSpacing24) {
                Text(model.title)
                    .font(.title)
                    .fontWeight(.bold)
                Text(model.description)
                    .font(.title3)
                    .foregroundStyle(Color(.text, .weak)) +
                Text(verbatim: model.displayURL)
                    .font(.title3)
                    .foregroundStyle(Color(.text, .interactive))
                    .fontWeight(.bold)
            }
            if let url = model.url {
                QRCodeView(string: url)
            } else {
                Spacer()
                    .frame(width: QRCodeView.size)
            }
        }
    }
}
