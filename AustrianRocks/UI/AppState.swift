//
//  AppState.swift
//  Austrian.rocks
//
//  Created by Nicolas Mondollot on 16/04/2023.
//  Copyright © 2023 Nicolas Mondollot. All rights reserved.
//

import SwiftUI

@Observable
@MainActor class AppState {
    var tab = Tab.map
    var selectedProblem: Problem?
    var selectedArea: Area?
    /// A pending Discover destination requested from elsewhere (e.g. a map
    /// feature card's "More details" button). `DiscoverView` consumes it,
    /// navigates its stack to the route, and resets it to nil.
    var discoverRoute: DiscoverRoute?

    enum Tab {
        case map
        case discover
        case ticklist
        case contribute
    }
}
