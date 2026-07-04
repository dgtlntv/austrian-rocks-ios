//
//  ClusterViewWithActionsheet.swift
//  Austrian.rocks
//
//  Created by Nicolas Mondollot on 26/07/2024.
//  Copyright © 2024 Nicolas Mondollot. All rights reserved.
//

import SwiftUI

struct ClusterViewWithActionsheet: View {
    let clusterDownloader: ClusterDownloader

    var body: some View {
        ClusterView(clusterDownloader: clusterDownloader)
    }
}

//#Preview {
//    ClusterViewWithActionsheet()
//}
