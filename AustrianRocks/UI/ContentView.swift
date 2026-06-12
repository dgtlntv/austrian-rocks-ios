//
//  ContentView.swift
//  Austrian.rocks
//
//  Created by Nicolas Mondollot on 28/10/2022.
//  Copyright © 2022 Nicolas Mondollot. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    @State private var appState = AppState()
    @State private var mapState = MapState()
    
    var body: some View {
        ZStack {
            TabView(selection: $appState.tab) {
                
                MapContainerView()
                    .tabItem {
                        Label("tabs.map", systemImage: "map")
                    }
                    .tag(AppState.Tab.map)
                
                DiscoverView()
                    .tabItem {
                        Label("tabs.discover", systemImage: "sparkles")
                    }
                    .tag(AppState.Tab.discover)
                
                TickList()
                    .tabItem {
                        Label("tabs.ticklist", systemImage: "bookmark")
                    }
                    .tag(AppState.Tab.ticklist)
            }
            
            if #available(iOS 26, *) {
                BottomSheetView(
                    isPresented: $mapState.presentProblemDetails,
                    onSwipeUp: {
                        mapState.requestTopoFullScreenPresentation()
                    }
                ) {
                    ProblemDetailsView()
                }

                // Map feature card (region/cluster/area/POI): compact card
                // with the map visible behind, expandable via swipe up.
                BottomSheetView(
                    isPresented: featureCardPresented,
                    compactHeight: MapFeatureSheetView.compactDetentHeight,
                    expandable: true
                ) {
                    MapFeatureSheetView()
                }
            }
        }
        .environment(appState)
        .environment(mapState)
    }

    // isPresented-driven so a tap on a different feature swaps the card
    // content in place; setting false (user swipe) clears the map selection
    // scoped to the dismissed card's kind.
    private var featureCardPresented: Binding<Bool> {
        Binding(
            get: { mapState.selectedMapFeatureCard != nil },
            set: { if !$0 { mapState.dismissMapFeatureCard() } }
        )
    }
}

//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        ContentView()
//    }
//}
