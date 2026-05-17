//
//  DiscoverRouter.swift
//  Austrian.rocks
//
//  Copyright © 2026 Austrian.rocks. All rights reserved.
//

import SwiftUI

enum DiscoverRoute: Hashable {
    case region(Int)
    case cluster(Int)
    case area(Int)
    case topAreasLevel
    case topAreasDryFast
    case topAreasBeginner
    case settings
}

@Observable
final class DiscoverRouter {
    var path: [DiscoverRoute] = []

    func navigate(to route: DiscoverRoute) {
        if let idx = path.lastIndex(of: route) {
            path = Array(path.prefix(idx + 1))
        } else {
            path.append(route)
        }
    }
}

private struct DiscoverRouterKey: EnvironmentKey {
    static let defaultValue: DiscoverRouter? = nil
}

extension EnvironmentValues {
    var discoverRouter: DiscoverRouter? {
        get { self[DiscoverRouterKey.self] }
        set { self[DiscoverRouterKey.self] = newValue }
    }
}
