//
//  MapView.swift
//  Austrian.rocks
//
//  Created by Nicolas Mondollot on 12/11/2022.
//  Copyright © 2022 Nicolas Mondollot. All rights reserved.
//

import SwiftUI
import CoreLocation

import TipKit

struct MapContainerView: View {
    @Environment(\.managedObjectContext) var managedObjectContext
    
    @Environment(AppState.self) private var appState: AppState
    @Environment(MapState.self) private var mapState: MapState
    
    
    // TODO: make this more DRY
    @State private var presentDownloads = false
    @State private var presentDownloadsPlaceholder = false
    @State private var presentAboutAcknowledgements = false

    var body: some View {
        @Bindable var mapState = mapState

        ZStack {
            mapLibre

            if let mapUnavailableMessage = mapState.mapUnavailableMessage {
                MapUnavailableOverlay(message: mapUnavailableMessage) {
                    mapState.requestMapRetry()
                }
                .zIndex(5)
            }

            aboveSheetNavigationButtons
                .opacity(mapState.presentProblemDetails ? 1 : 0)

            fabButtonsContainer
                .zIndex(10)
            
            if mapState.selectedArea == nil {
                searchButtonOverlay
                    .zIndex(20)
            }
            
            AreaToolbarView()
                .frame(maxWidth: 600)
                .zIndex(30)
                .opacity(mapState.selectedArea != nil ? 1 : 0)
        }
        .sheet(isPresented: $mapState.presentSearch) {
            SearchSheetView()
        }
        .modify {
            if #available(iOS 26, *) {
                $0 // Feature card presented via BottomSheetView in ContentView
            } else {
                $0.sheet(isPresented: featureCardPresented) {
                    MapFeatureSheetView()
                        .presentationDetents([.height(MapFeatureSheetView.compactDetentHeight), .medium, .large])
                        .presentationBackgroundInteraction(.enabled(upThrough: .medium))
                        .presentationDragIndicator(.visible)
                }
            }
        }
        .sheet(isPresented: $presentAboutAcknowledgements) {
            NavigationStack {
                AcknowledgementsView()
            }
        }
        .onChange(of: mapState.presentProblemDetails) { oldValue, newValue in
            if !newValue {
                mapState.deselectTopo()
                // Single dismissal path (swipe, close, background tap, sheet
                // replacement) — clears the selected problem dot on the map.
                mapState.clearProblemMapSelection()
            }
        }
        .onChange(of: appState.selectedProblem) { oldValue, newValue in
            if let problem = appState.selectedProblem {
                mapState.selectAndPresentAndCenterOnProblem(problem)
                mapState.presentAreaView = false
            }
        }
        .onChange(of: appState.selectedArea) { oldValue, newValue in
            if let area = appState.selectedArea {
                mapState.selectArea(area)
                mapState.centerOnArea(area)
            }
        }
    }
    
    // The feature card sheet is isPresented-driven (not item-driven) so that
    // tapping a different feature swaps the card content in place instead of
    // cycling a dismiss/present animation. Setting it false (user swipe or
    // close) clears the map selection scoped to the dismissed card's kind.
    private var featureCardPresented: Binding<Bool> {
        Binding(
            get: { mapState.selectedMapFeatureCard != nil },
            set: { if !$0 { mapState.dismissMapFeatureCard() } }
        )
    }

    var mapLibre : some View {
        @Bindable var mapState = mapState
        return MapLibreView(mapState: mapState)
            .modify {
                if #available(iOS 26, *) {
                    $0.edgesIgnoringSafeArea(.vertical)
                }
                else {
                    $0.edgesIgnoringSafeArea(.top)
                }
            }
            .ignoresSafeArea(.keyboard)
            .modify {
                if #available(iOS 26, *) {
                    $0 // Sheet presented via overlay for iOS 26
                }
                else {
                    $0.sheet(isPresented: $mapState.presentProblemDetails) {
                        ProblemDetailsView()
                        .presentationDetents([detent])
                        .presentationBackgroundInteraction(
                            .enabled(upThrough: detent)
                        )
                        .presentationDragIndicator(.visible)
                    }
                }
            }
    }
    
    var detent: PresentationDetent {
        if UIScreen.main.bounds.height <= 667 { // iPhone SE (all generations) & iPhone 8 and earlier
            return .height(420)
        }
        else {
            return .medium
        }
    }
    
    var offsetToBeOnTopOfSheet: CGFloat {
        if UIScreen.main.bounds.height <= 667 { // iPhone SE (all generations) & iPhone 8 and earlier
            if #available(iOS 26, *) {
                return -80
            }
            else {
                return -104
            }
        }
        else {
            if #available(iOS 26, *) {
                return -32
            }
            else {
                return -48
            }
        }
    }
    
    var aboveSheetNavigationButtons : some View {
        VStack {
            HStack {
                Spacer()

                if mapState.presentProblemDetails {
                    fullScreenButton
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom, 16)
        }
        .offset(CGSize(width: 0, height: offsetToBeOnTopOfSheet)) // FIXME: might break in the future (we assume the sheet is exactly half the screen height)
    }

    var fullScreenButton: some View {
        Button(action: {
            mapState.requestTopoFullScreenPresentation()
        }) {
            Image(systemName: "arrow.down.left.and.arrow.up.right")
                .adaptiveCircleButtonIcon()
        }
        .adaptiveCircleButtonStyle()
    }

    var searchButtonOverlay: some View {
        VStack {
            HStack {
                Spacer()
                Button {
                    mapState.presentProblemDetails = false
                    mapState.presentSearch = true
                } label: {
                    HStack {
                        Image(systemName: "magnifyingglass")
                        Text("search.placeholder")
                        Spacer()
                    }
                    .modify {
                        if #available(iOS 26, *) {
                            // Let Liquid Glass vibrancy color the placeholder.
                            $0
                        } else {
                            $0.foregroundColor(Color(.secondaryLabel))
                        }
                    }
                    .frame(maxWidth: 600)
                    .modify {
                        if #available(iOS 26, *) {
                            $0.padding(.vertical, 4)
                        } else {
                            $0
                                .padding(10)
                                .padding(.horizontal, 25)
                        }
                    }
                }
                .modify {
                    if #available(iOS 26, *) {
                        $0.buttonStyle(.glass)
                    } else {
                        $0
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .shadow(color: Color(.secondaryLabel).opacity(0.5), radius: 5)
                    }
                }
                .contentShape(Rectangle())

                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 8)

            Spacer()
        }
    }

    var fabButtonsContainer: some View {
        HStack {
            Spacer()
            
            VStack(alignment: .trailing) {
                Spacer()
                
                if #available(iOS 26.0, *) {
                    GlassEffectContainer {
                        fabButtons
                    }
                } else {
                    fabButtons
                }
            }
            .padding(.trailing)
        }
        .padding(.bottom)
        .ignoresSafeArea(.keyboard)
    }

    var fabButtons: some View {
        Group {
            // Attribution entry point: replaces the hidden MapLibre ornaments,
            // so it must stay one tap from the map. Visually smaller/subdued
            // than the primary download/location actions.
            infoButton

            Group {
                if let cluster = mapState.selectedCluster {
                    DownloadButtonView(cluster: cluster, presentDownloads: $presentDownloads, clusterDownloader: ClusterDownloader(cluster: cluster, mainArea: areaBestGuess(in: cluster) ?? cluster.mainArea))
                }
                else {
                    DownloadButtonPlaceholderView(presentDownloadsPlaceholder: $presentDownloadsPlaceholder)
                    
                }
            }
            .adaptiveFabForeground()
            .adaptiveFabStyle()

            Button {
                print("location")
                mapState.centerOnCurrentLocation()
            } label: {
                Image(systemName: "location")
//                    .frame(width: 22, height: 22)
                    .padding(12)
                    .adaptiveFabForeground()
                    
//                    .offset(x: -1, y: 0)
                //                        .font(.system(size: 20, weight: .regular))
            }
            .adaptiveFabStyle()
        }
    }

    var infoButton: some View {
        Button {
            presentAboutAcknowledgements = true
        } label: {
            Image(systemName: "info.circle")
                .font(.system(size: 15))
                .padding(8)
                .modify {
                    if #available(iOS 26, *) {
                        $0
                    } else {
                        $0.foregroundColor(.secondary)
                    }
                }
        }
        .adaptiveFabStyle()
        .accessibilityLabel(Text("map.info.accessibility"))
    }


    // TODO: remove after October 2024
    private var userDidUseOldOfflineMode: Bool {
        if let data = UserDefaults.standard.data(forKey: "offline-photos/areasIds"),
           let decodedSet = try? JSONDecoder().decode(Set<Int>.self, from: data) {
            return decodedSet.count > 0
        }
        
        return false
    }

    private func areaBestGuess(in cluster: Cluster) -> Area? {
        if let selectedArea = mapState.selectedArea {
            return selectedArea
        }
        
        if let zoom = mapState.zoom, let center = mapState.center {
            if zoom > 12.5 {
                if let area = closestArea(in: cluster, from: CLLocation(latitude: center.latitude, longitude: center.longitude)) {
                    return area
                }
            }
        }
        
        return nil
    }
    
    private func closestArea(in cluster: Cluster, from center: CLLocation) -> Area? {
        cluster.areas.sorted {
            $0.center.distance(from: center) < $1.center.distance(from: center)
        }.first
    }
    
}

//struct MapView_Previews: PreviewProvider {
//    static var previews: some View {
//        MapView()
//    }
//}
