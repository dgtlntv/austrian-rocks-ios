//
//  ProblemCircleView.swift
//  Austrian.rocks
//
//  Created by Nicolas Mondollot on 05/11/2020.
//  Copyright © 2020 Nicolas Mondollot. All rights reserved.
//

import SwiftUI

struct ProblemCircleView: View {
    var problem: Problem
    var isDisplayedOnPhoto = false

    var body: some View {
        CircleView(number: "",
                   color: UIColor(Color.appBrandColor),
                   showStroke: !isDisplayedOnPhoto,
                   showShadow: isDisplayedOnPhoto,
                   scaleEffect: scaleEffect
        )
    }

    var scaleEffect: CGFloat {
        0.7
    }
}
//
//struct ProblemCircleView_Previews: PreviewProvider {
//    static var previews: some View {
//        ProblemCircleView(problem: DataStore().problems.first!)
//    }
//}
