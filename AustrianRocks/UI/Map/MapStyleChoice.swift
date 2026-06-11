//
//  MapStyleChoice.swift
//  Austrian.rocks
//
//  Copyright © 2026 Austrian.rocks. All rights reserved.
//

import UIKit

enum MapStyleChoice: String, Codable, Equatable {
    case light
    case dark

    init(userInterfaceStyle: UIUserInterfaceStyle) {
        switch userInterfaceStyle {
        case .dark:
            self = .dark
        default:
            self = .light
        }
    }

    var manifestKey: String { rawValue }
}
