//
//  Created on 21/08/2023.
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

import SwiftUI
import SharedViews
import Strings
import Theme
import Ergonomics

final class WhatsNewViewController: NSHostingController<WhatsNewView> {
    required init?(coder: NSCoder) {
        super.init(coder: coder, rootView: WhatsNewView())
    }

    convenience init() {
        self.init(rootView: WhatsNewView())
    }

    override init(rootView: WhatsNewView) {
        super.init(rootView: rootView)
        self.rootView.dismiss = dismiss
        title =  "Proton VPN"
        view.window?.titlebarAppearsTransparent = true
        view.wantsLayer = true
        DarkAppearance {
            view.layer?.backgroundColor = Color(.background).cgColor
        }
    }

    func dismiss() {
        dismiss(nil)
    }
}

// This view exceptionally contains string literals because it is not used anywhere,
// and may be redesigned soon.
struct WhatsNewView: View {

    public var dismiss: () -> Void = { }

    var body: some View {
        VStack(spacing: .themeSpacing32) {
            Asset.welcomeToProtonVpn.swiftUIImage

            Text(Localizable.modalsWhatsNew)
                .themeFont(.title1(emphasised: true))
            VStack(alignment: .leading, spacing: .themeSpacing4) {
                HStack {
                    Text("New Free countries")
                        .themeFont(.headline(emphasised: true))
                    Spacer(minLength: 0)
                }
                HStack {
                    Text("There are now Free servers in Poland and Romania.")
                        .themeFont(.body())
                        .foregroundColor(Color(.text, .weak))
                    Spacer(minLength: 0)
                }
            }
            VStack(alignment: .leading, spacing: .themeSpacing4) {
                HStack {
                    Text("Changes to server selection")
                        .themeFont(.headline(emphasised: true))
                    Spacer(minLength: 0)
                }
                HStack {
                    Text("""
                    To prevent server crowding and ensure that everyone has access to fast and secure browsing, we removed manual country selection and made major improvements to automatic server selection.
                    """)
                        .themeFont(.body())
                        .fixedSize(horizontal: false, vertical: true) // allow multiline
                        .foregroundColor(Color(.text, .weak))
                    Spacer(minLength: 0)
                }
            }
            Button {
                
                dismiss()
            } label: {
                Text(Localizable.gotIt)
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .frame(width: 400)
        .padding(.themeSpacing64)
        .preferredColorScheme(.dark)
        .presentedWindowStyle(.hiddenTitleBar)
    }
}

@available(macOS 12.0, *)
struct WhatsNewView_Previews: PreviewProvider {
    static var previews: some View {
        WhatsNewView()
            .previewLayout(.sizeThatFits)
    }
}
