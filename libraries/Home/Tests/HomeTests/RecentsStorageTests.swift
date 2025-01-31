//
//  Created on 17/10/2024.
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
@testable import Home
import Domain
import Dependencies
import OrderedCollections

final class RecentsStorageTests: XCTestCase {

    func testPiningASpecMovesTheCorrespondingRecentToTheTopOfTheListsAndMarksItAsPinned() {
        let now = Date()
        var defaultFastest = RecentConnection(pinnedDate: nil, underMaintenance: false, connectionDate: now, connection: .defaultFastest)
        let specificCity = RecentConnection(pinnedDate: nil, underMaintenance: false, connectionDate: now + 1, connection: .specificCity)
        let specificCountry = RecentConnection(pinnedDate: nil, underMaintenance: false, connectionDate: now, connection: .specificCountry)
        var recents: OrderedSet<RecentConnection> = [specificCity, defaultFastest, specificCountry]
        recents.pin(recent: defaultFastest, pinnedDate: now)
        defaultFastest.pinnedDate = now
        XCTAssertEqual(recents, [defaultFastest, specificCity, specificCountry])
    }

    func testUnpiningASpecMovesTheCorrespondingRecentBelowThePinnedAndMarksItAsUnpinned() {
        let now = Date()
        var defaultFastest = RecentConnection(pinnedDate: now, underMaintenance: false, connectionDate: now, connection: .defaultFastest)
        let specificCity = RecentConnection(pinnedDate: nil, underMaintenance: false, connectionDate: now + 2, connection: .specificCity)
        let specificCountry = RecentConnection(pinnedDate: nil, underMaintenance: false, connectionDate: now + 1, connection: .specificCountry)
        var recents: OrderedSet<RecentConnection> = [defaultFastest, specificCity, specificCountry]
        recents.unpin(recent: defaultFastest)
        defaultFastest.pinnedDate = nil
        XCTAssertEqual(recents, [specificCity, specificCountry, defaultFastest])
    }

    func testRemovingASpecRemovesTheCorrespondingRecent() {
        let now = Date()
        let defaultFastest = RecentConnection(pinnedDate: now, underMaintenance: false, connectionDate: now, connection: .defaultFastest)
        let specificCity = RecentConnection(pinnedDate: nil, underMaintenance: false, connectionDate: now + 2, connection: .specificCity)
        let specificCountry = RecentConnection(pinnedDate: nil, underMaintenance: false, connectionDate: now + 1, connection: .specificCountry)
        var recents: OrderedSet<RecentConnection> = [defaultFastest, specificCity, specificCountry]
        recents.remove(defaultFastest)
        XCTAssertEqual(recents, [specificCity, specificCountry])
    }

    func testInsertingANewRecentIsReflectedInTheCollectionAndItsNotPinned() {
        withDependencies {
            $0.date = .constant(.now)
        } operation: {
            var recents: OrderedSet<RecentConnection> = []
            recents.updateList(with: .defaultFastest)
            XCTAssertFalse(recents.first!.pinned)
        }
    }

    func testInsertingANewConnectionAndPinningItMovesTheCorrespondingRecentAboveUnpinnedConnections() {
        let now = Date()
        withDependencies {
            $0.date = .constant(now)
        } operation: {
            let one = RecentConnection(pinnedDate: nil,
                                       underMaintenance: false,
                                       connectionDate: now,
                                       connection: .init(location: .region(code: "1"), features: []))
            let two = RecentConnection(pinnedDate: now + 1,
                                       underMaintenance: false,
                                       connectionDate: now,
                                       connection: .init(location: .region(code: "2"), features: []))
            var recents: OrderedSet<RecentConnection> = [one, two]

            XCTAssertEqual(recents.sanitized(), [two, one])

            let threeSpec = ConnectionSpec(location: .region(code: "3"), features: [])
            var three = RecentConnection(pinnedDate: nil,
                                         underMaintenance: false,
                                         connectionDate: now,
                                         connection: threeSpec)
            recents.updateList(with: threeSpec)
            recents.pin(recent: three, pinnedDate: now)
            three.pinnedDate = now
            XCTAssertEqual(recents, [three, two, one])
        }
    }

    func testInitializingRecentsListWithMoreThanAllowedNumberOfConnectionsTrimsTheRecentList() {
        let now = Date()
        let array = (0...9).map { element in
            RecentConnection(pinnedDate: nil,
                             underMaintenance: false,
                             connectionDate: now,
                             connection: .init(location: .region(code: "\(element)"), features: []))
        }
        XCTAssertEqual(array.count, 10)
        let recents = OrderedSet(array)
        XCTAssertEqual(recents.sanitized().count, 8)
    }
}
