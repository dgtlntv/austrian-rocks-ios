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
    @State private var featureCardCompactHeight = MapFeatureSheetView.compactDetentHeight
    @State private var featureCardDetent: PresentationDetent = .height(MapFeatureSheetView.compactDetentHeight)
    @State private var featureCardCanExpand = false
    @State private var infoCardCompactHeight = MapFeatureSheetView.compactDetentHeight
    @State private var infoCardDetent: PresentationDetent = .height(MapFeatureSheetView.compactDetentHeight)
    @State private var infoCardCanExpand = false
    @State private var problemSheetDetent: PresentationDetent = .medium

    private var featureCardCompactDetent: PresentationDetent {
        .height(featureCardCompactHeight)
    }

    private var featureCardDetents: Set<PresentationDetent> {
        featureCardCanExpand ? [featureCardCompactDetent, .large] : [featureCardCompactDetent]
    }

    private var infoCardCompactDetent: PresentationDetent {
        .height(infoCardCompactHeight)
    }

    private var infoCardDetents: Set<PresentationDetent> {
        infoCardCanExpand ? [infoCardCompactDetent, .large] : [infoCardCompactDetent]
    }

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
        .sheet(isPresented: $mapState.presentSearch, onDismiss: {
            mapState.completeSearchDismissal()
        }) {
            SearchSheetView()
        }
        .sheet(isPresented: featureCardPresented) {
            MapFeatureSheetView(
                isExpanded: featureCardDetent == .large,
                onContentHeightChange: updateFeatureCardCompactHeight
            )
            .presentationDetents(featureCardDetents, selection: $featureCardDetent)
            .presentationContentInteraction(.resizes)
            .presentationBackground(.clear)
            .presentationBackgroundInteraction(.enabled(upThrough: featureCardCompactDetent))
            .presentationDragIndicator(.visible)
            .id("\(featureCardCompactHeight)-\(featureCardCanExpand)")
        }
        .sheet(isPresented: $presentAboutAcknowledgements) {
            AcknowledgementsCardView(
                isExpanded: infoCardDetent == .large,
                onContentHeightChange: updateInfoCardCompactHeight
            )
            .presentationDetents(infoCardDetents, selection: $infoCardDetent)
            .presentationContentInteraction(.resizes)
            .presentationBackground(.clear)
            .presentationBackgroundInteraction(.enabled(upThrough: infoCardCompactDetent))
            .presentationDragIndicator(.visible)
            .id("\(infoCardCompactHeight)-\(infoCardCanExpand)")
        }
        .onChange(of: mapState.presentProblemDetails) { oldValue, newValue in
            if newValue {
                problemSheetDetent = problemCompactDetent
            } else {
                mapState.deselectTopo()
                // Single dismissal path (swipe, close, background tap, sheet
                // replacement) — clears the selected problem dot on the map.
                mapState.clearProblemMapSelection()
            }
        }
        .onChange(of: mapState.selectedMapFeatureCard) { oldValue, newValue in
            if newValue != nil, oldValue != newValue {
                featureCardCompactHeight = MapFeatureSheetView.compactDetentHeight
                featureCardCanExpand = allowsExpansionWithoutOverflow(newValue)
                featureCardDetent = featureCardCompactDetent
            }
        }
        .onChange(of: presentAboutAcknowledgements) { _, newValue in
            if newValue {
                infoCardCompactHeight = MapFeatureSheetView.compactDetentHeight
                infoCardCanExpand = false
                infoCardDetent = infoCardCompactDetent
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
            .sheet(isPresented: $mapState.presentProblemDetails) {
                ProblemDetailsView(isExpanded: problemSheetDetent == .large)
                    .presentationDetents([problemCompactDetent, .large], selection: $problemSheetDetent)
                    .presentationContentInteraction(.resizes)
                    .presentationBackgroundInteraction(
                        .enabled(upThrough: problemCompactDetent)
                    )
                    .presentationDragIndicator(.visible)
            }
    }
    
    private func updateFeatureCardCompactHeight(_ contentHeight: CGFloat) {
        updateCompactSheetHeight(
            contentHeight,
            compactHeight: $featureCardCompactHeight,
            canExpand: $featureCardCanExpand,
            detent: $featureCardDetent,
            alwaysAllowExpansion: allowsExpansionWithoutOverflow(mapState.selectedMapFeatureCard)
        )
    }

    private func updateInfoCardCompactHeight(_ contentHeight: CGFloat) {
        updateCompactSheetHeight(
            contentHeight,
            compactHeight: $infoCardCompactHeight,
            canExpand: $infoCardCanExpand,
            detent: $infoCardDetent
        )
    }

    private func updateCompactSheetHeight(
        _ contentHeight: CGFloat,
        compactHeight: Binding<CGFloat>,
        canExpand: Binding<Bool>,
        detent: Binding<PresentationDetent>,
        alwaysAllowExpansion: Bool = false
    ) {
        guard contentHeight > 0 else { return }

        let measuredHeight = contentHeight + MapFeatureSheetView.compactContentChromePadding
        let clampedHeight = min(
            max(measuredHeight, MapFeatureSheetView.compactMinDetentHeight),
            MapFeatureSheetView.compactMaxDetentHeight
        )

        let measuredCanExpand = measuredHeight > clampedHeight + 8
        let effectiveCanExpand = measuredCanExpand || alwaysAllowExpansion

        guard abs(compactHeight.wrappedValue - clampedHeight) > 1 || canExpand.wrappedValue != effectiveCanExpand else { return }

        withAnimation(.snappy) {
            compactHeight.wrappedValue = clampedHeight
            canExpand.wrappedValue = effectiveCanExpand
            if detent.wrappedValue != .large || !effectiveCanExpand {
                detent.wrappedValue = .height(clampedHeight)
            }
        }
    }

    private func allowsExpansionWithoutOverflow(_ card: MapFeatureCardModel?) -> Bool {
        guard let card else { return false }

        switch card.kind {
        case .region, .cluster, .area:
            return true
        case .poi:
            return false
        }
    }

    var problemCompactDetent: PresentationDetent {
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
