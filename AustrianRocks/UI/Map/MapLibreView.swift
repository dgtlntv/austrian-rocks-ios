//
//  MapLibreView.swift
//  Austrian.rocks
//
//  Created by Nicolas Mondollot on 27/10/2022.
//  Copyright © 2022 Nicolas Mondollot. All rights reserved.
//

import SwiftUI
import CoreLocation
import MapLibre
import Combine

// Bridge between SwiftUI-world (driven by MapState) and UIKit-world (MapLibreViewController).
// SwiftUI -> UIKit: MapLibreView.updateUIViewController
// UIKit -> SwiftUI: MapLibreViewDelegate protocol
struct MapLibreView: UIViewControllerRepresentable {
    var mapState: MapState

    func makeUIViewController(context: Context) -> MapLibreViewController {
        let vc = MapLibreViewController()
        vc.delegate = context.coordinator
        context.coordinator.viewController = vc
        return vc
    }

    func updateUIViewController(_ vc: MapLibreViewController, context: Context) {
        vc.retryToken = mapState.mapRetryCount

        // Pass pre-cached topo problem IDs so setProblemAsSelected never hits SQLite.
        if let topoId = mapState.selectedTopo?.id {
            vc.selectedTopoProblemIds = mapState.boulderProblems
                .filter { $0.topoId == topoId }
                .map { String($0.id) }
        } else {
            vc.selectedTopoProblemIds = []
        }

        let selectedId = mapState.selectedProblem?.id ?? 0
        let isTopoMode = mapState.selectedTopo != nil

        if context.coordinator.lastSelectedProblemId != selectedId || context.coordinator.lastIsTopoMode != isTopoMode {
            context.coordinator.lastSelectedProblemId = selectedId
            context.coordinator.lastIsTopoMode = isTopoMode
            if selectedId != 0 {
                vc.setProblemAsSelected(problemFeatureId: String(selectedId))
            }
        }

        if let centerOnProblem = mapState.centerOnProblem {
            let centerOnProblemId = centerOnProblem.id
            if context.coordinator.lastCenterOnProblemId != centerOnProblemId {
                context.coordinator.lastCenterOnProblemId = centerOnProblemId
                vc.centerOnProblem(centerOnProblem)
            }
        }

        if let centerOnArea = mapState.centerOnArea {
            let centerOnAreaId = centerOnArea.id
            if context.coordinator.lastCenterOnAreaId != centerOnAreaId {
                context.coordinator.lastCenterOnAreaId = centerOnAreaId
                vc.centerOnArea(centerOnArea)
            }
        }

        if mapState.currentLocationCount != context.coordinator.lastCurrentLocationCount {
            context.coordinator.lastCurrentLocationCount = mapState.currentLocationCount
            vc.centerOnCurrentLocation()
        }

        if mapState.centerOnBoulderCount != context.coordinator.lastCenterOnBoulderCount {
            context.coordinator.lastCenterOnBoulderCount = mapState.centerOnBoulderCount
            vc.centerOnBoulderCoordinates(mapState.centerOnBoulderCoordinates)
        }

        if mapState.refreshFiltersCount != context.coordinator.lastRefreshFiltersCount {
            context.coordinator.lastRefreshFiltersCount = mapState.refreshFiltersCount
            vc.applyFilters(mapState.filters)
        }

        if mapState.fitMapFeatureBoundsCount != context.coordinator.lastFitMapFeatureBoundsCount {
            context.coordinator.lastFitMapFeatureBoundsCount = mapState.fitMapFeatureBoundsCount
            if let bounds = mapState.fitMapFeatureBounds {
                vc.fitMapFeatureBounds(bounds)
            }
        }

        if mapState.clearFeatureSelectionCount != context.coordinator.lastClearFeatureSelectionCount {
            context.coordinator.lastClearFeatureSelectionCount = mapState.clearFeatureSelectionCount
            if let kind = mapState.clearFeatureSelectionKind {
                vc.clearSelectedMapFeature(ofKind: kind)
            }
        }

        if mapState.clearProblemSelectionCount != context.coordinator.lastClearProblemSelectionCount {
            context.coordinator.lastClearProblemSelectionCount = mapState.clearProblemSelectionCount
            vc.clearSelectedProblem()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: MapLibreViewDelegate {
        var parent: MapLibreView
        var viewController: MapLibreViewController?

        var lastSelectedProblemId: Int = 0
        var lastCenterOnProblemId: Int = 0
        var lastCenterOnAreaId: Int = 0
        var lastCurrentLocationCount: Int = 0
        var lastRefreshFiltersCount: Int = 0
        var lastIsTopoMode: Bool = false
        var lastCenterOnBoulderCount: Int = 0
        var lastFitMapFeatureBoundsCount: Int = 0
        var lastClearFeatureSelectionCount: Int = 0
        var lastClearProblemSelectionCount: Int = 0

        init(_ parent: MapLibreView) {
            self.parent = parent
        }

        func selectProblem(id: Int) {
            if let problem = Problem.load(id: id) {
                parent.mapState.selectProblem(problem, source: .map)
                parent.mapState.presentProblemDetails = true
            }
        }

        func selectArea(id: Int) {
            if let area = Area.load(id: id) {
                parent.mapState.selectArea(area)
            }
        }

        func selectCluster(id: Int) {
            if let cluster = Cluster.load(id: id) {
                parent.mapState.selectCluster(cluster)
            }
        }

        func selectRegion(id: Int) {
            if let region = Region.load(id: id) {
                parent.mapState.selectRegion(region)
            }
        }

        func unselectArea() {
            parent.mapState.unselectArea()
        }

        func unselectCluster() {
            parent.mapState.unselectCluster()
        }

        func selectMapFeatureCard(_ card: MapFeatureCardModel) {
            parent.mapState.selectMapFeatureCard(card)
        }

        func dismissProblemDetails() {
            parent.mapState.presentProblemDetails = false
        }

        func dismissMapFeatureCard() {
            parent.mapState.dismissMapFeatureCardFromMap()
        }

        func cameraChanged(state: MapLibreCameraState) {
            parent.mapState.updateCameraState(center: state.center, zoom: state.zoom)
        }

        func mapBecameAvailable() {
            parent.mapState.markMapAvailable()
        }

        func mapBecameUnavailable(message: String) {
            parent.mapState.markMapUnavailable(message)
        }
    }
}
