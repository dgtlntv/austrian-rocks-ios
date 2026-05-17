//
//  AreaLevelsBarView.swift
//  Austrian.rocks
//
//  Created by Nicolas Mondollot on 11/01/2023.
//  Copyright © 2023 Nicolas Mondollot. All rights reserved.
//

import SwiftUI

struct AreaLevelsBarView: View {
    let area: Area

    var body: some View {
        HStack(spacing: 2) {
            ForEach(area.levels) { level in
                Text(String(level.name))
                    .frame(width: 20, height: 20)
                    .foregroundColor(style(for: level.count).foreground)
                    .background(style(for: level.count).background)
                    .cornerRadius(4)
            }
        }
    }

    // Light → dark scale tuned for Austrian areas. Text colour flips between
    // dark-green and white so every tier stays above WCAG AA (4.5:1). Colours
    // from the Tailwind emerald palette.
    private func style(for count: Int) -> (background: Color, foreground: Color) {
        let darkText = Color(red: 6/255, green: 78/255, blue: 59/255) // emerald-900
        switch count {
        case 0:
            return (Color.gray.opacity(0.3), .secondary)
        case 1...4:
            return (Color(red: 209/255, green: 250/255, blue: 229/255), darkText) // emerald-100, ~14:1
        case 5...14:
            return (Color(red: 110/255, green: 231/255, blue: 183/255), darkText) // emerald-300, ~10:1
        default:
            return (Color(red:   4/255, green: 120/255, blue:  87/255), .white)   // emerald-700, ~6.4:1
        }
    }
}

struct AreaLevelsBarView_Previews: PreviewProvider {
    static var previews: some View {
        AreaLevelsBarView(area: Area.load(id: 1)!)
    }
}
