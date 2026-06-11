//
//  MapLibreViewController.swift
//  Austrian.rocks
//
//  Created by Nicolas Mondollot on 27/10/2022.
//  Copyright © 2022 Nicolas Mondollot. All rights reserved.
//

import UIKit
import MapLibre
import CoreLocation
import CoreData

struct MapLibreCameraState {
    let center: CLLocationCoordinate2D
    let zoom: CGFloat
}

class MapLibreViewController: UIViewController, MLNMapViewDelegate {
    var mapView: MLNMapView!
    var delegate: MapLibreViewDelegate?
    var selectedTopoProblemIds: [String] = []

    var retryToken: Int = 0 {
        didSet {
            guard retryToken != oldValue, isViewLoaded else { return }
            loadStyleFromManifestOrCache()
        }
    }

    private let styleLoader: MapStyleLoadCoordinator
    private var selectionController: MapSelectionController?
    private var currentFilters: Filters?
    private var styleLoadTask: Task<Void, Never>?
    private var lastCameraDelegateUpdate = Date.distantPast
    private var flyinToSomething = false
    private let flyinDuration = 0.5
    private let safePadding = UIEdgeInsets(top: 180, left: 20, bottom: 180, right: 20)
    private let safePaddingYForAreaDetector: CGFloat = 30
    private var safePaddingForBottomSheet: UIEdgeInsets {
        UIEdgeInsets(top: 100, left: 0, bottom: view.bounds.height / 2 + 40, right: 0)
    }
    private var safePaddingForBoulder: UIEdgeInsets {
        UIEdgeInsets(top: 100, left: 20, bottom: view.bounds.height / 2 + 40, right: 20)
    }

    init(
        manifestClient: MapTileManifestClient = MapTileManifestClient(),
        styleCache: MapTileStyleCache = MapTileStyleCache()
    ) {
        self.styleLoader = MapStyleLoadCoordinator(
            fetchManifest: { url in try await manifestClient.fetchManifest(from: url) },
            recordSuccess: { manifest, choice, styleURL in try styleCache.recordSuccess(manifest: manifest, choice: choice, styleURL: styleURL) },
            lastKnownStyle: { choice in styleCache.lastKnownStyle(for: choice) }
        )
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        let manifestClient = MapTileManifestClient()
        let styleCache = MapTileStyleCache()
        self.styleLoader = MapStyleLoadCoordinator(
            fetchManifest: { url in try await manifestClient.fetchManifest(from: url) },
            recordSuccess: { manifest, choice, styleURL in try styleCache.recordSuccess(manifest: manifest, choice: choice, styleURL: styleURL) },
            lastKnownStyle: { choice in styleCache.lastKnownStyle(for: choice) }
        )
        super.init(coder: coder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        mapView = MLNMapView(frame: view.bounds)
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapView.delegate = self
        mapView.centerCoordinate = CLLocationCoordinate2D(latitude: 47.7, longitude: 13.5)
        mapView.zoomLevel = 7.0
        mapView.allowsTilting = false
        mapView.allowsRotating = false
        mapView.showsUserLocation = true
        mapView.showsScale = false
        mapView.logoView.alpha = 0.5
        mapView.attributionButton.alpha = 0.35

        selectionController = MapSelectionController(mapView: mapView)

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        tap.cancelsTouchesInView = false
        mapView.addGestureRecognizer(tap)

        view.addSubview(mapView)
        loadStyleFromManifestOrCache()
    }

    deinit {
        styleLoadTask?.cancel()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle else { return }
        loadStyleFromManifestOrCache()
    }

    private func loadStyleFromManifestOrCache() {
        styleLoadTask?.cancel()
        let choice = MapStyleChoice(userInterfaceStyle: traitCollection.userInterfaceStyle)
        let unavailableMessage = String(localized: "map.unavailable.message")

        styleLoadTask = Task { [weak self] in
            guard let self else { return }
            let action = await styleLoader.loadStyle(for: choice, unavailableMessage: unavailableMessage)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                guard !Task.isCancelled else { return }
                self.handleStyleLoadAction(action)
            }
        }
    }

    @MainActor
    private func handleStyleLoadAction(_ action: MapStyleLoadCoordinator.LoadAction) {
        switch action {
        case .install(let url, let forceReload):
            installStyle(url: url, forceReload: forceReload)
        case .available:
            delegate?.mapBecameAvailable()
            selectionController?.styleDidLoad()
            if let filters = currentFilters {
                applyFilters(filters)
            }
        case .unavailable(let message):
            delegate?.mapBecameUnavailable(message: message)
        case .none:
            break
        }
    }

    @MainActor
    private func installStyle(url: URL, forceReload: Bool) {
        if forceReload, mapView.styleURL == url {
            mapView.styleURL = nil
        }
        mapView.styleURL = url
    }

    func mapView(_ mapView: MLNMapView, didFinishLoading style: MLNStyle) {
        handleStyleLoadAction(styleLoader.styleDidLoad(url: mapView.styleURL))
    }

    func mapView(_ mapView: MLNMapView, didFailLoadingMapWithError error: Error) {
        handleStyleLoadAction(styleLoader.styleDidFail(url: mapView.styleURL, message: error.localizedDescription))
    }

    func mapViewRegionIsChanging(_ mapView: MLNMapView) {
        guard !flyinToSomething else { return }
        guard Date().timeIntervalSince(lastCameraDelegateUpdate) > 0.1 else { return }
        lastCameraDelegateUpdate = Date()
        triggerMapDetectors(immediate: true)
        delegate?.cameraChanged(state: MapLibreCameraState(center: mapView.centerCoordinate, zoom: mapView.zoomLevel))
    }

    func mapView(_ mapView: MLNMapView, regionDidChangeAnimated animated: Bool) {
        guard !flyinToSomething else { return }
        triggerMapDetectors(immediate: true)
        delegate?.cameraChanged(state: MapLibreCameraState(center: mapView.centerCoordinate, zoom: mapView.zoomLevel))
    }

    @objc private func handleTap(_ recognizer: UITapGestureRecognizer) {
        guard recognizer.state == .ended else { return }
        findFeatures(tapPoint: recognizer.location(in: mapView))
    }

    func findFeatures(tapPoint: CGPoint) {
        if selectProblem(at: tapPoint) { return }
        if selectPoi(at: tapPoint) { return }
        if selectArea(at: tapPoint) { return }
        if selectCluster(at: tapPoint) { return }
        if selectRegion(at: tapPoint) { return }
        if zoomTowardBoulder(at: tapPoint) { return }

        if visibleFeatures(at: tapPoint, layers: interactiveLayerIds()).isEmpty {
            selectionController?.clear()
            delegate?.dismissProblemDetails()
        }
    }

    func applyFilters(_ filters: Filters) {
        currentFilters = filters
        guard mapView?.style != nil else { return }

        // iOS intentionally keeps popular/project/ticked filters in addition
        // to Rails' grade filter; all predicates use shared PMTiles properties.
        let predicate = problemFilterPredicate(filters)
        vectorLayer(MapLayerContract.Layers.problems)?.predicate = predicate
        selectionController?.setSupplementalPredicate(predicate, for: .problem)
    }

    func centerOnProblem(_ problem: Problem) {
        setCenter(problem.coordinate, zoom: 20, padding: safePaddingForBottomSheet)
    }

    func centerOnArea(_ area: Area) {
        let coords = [
            CLLocationCoordinate2D(latitude: area.southWestLat, longitude: area.southWestLon),
            CLLocationCoordinate2D(latitude: area.northEastLat, longitude: area.northEastLon)
        ]
        fit(coords, minZoom: 15, padding: safePadding)
    }

    func centerOnCurrentLocation() {
        guard let coordinate = mapView.userLocation?.coordinate else { return }

        let austriaFallbackBounds = MLNCoordinateBounds(
            sw: CLLocationCoordinate2D(latitude: 46.372276, longitude: 9.530748),
            ne: CLLocationCoordinate2D(latitude: 49.020530, longitude: 17.160776)
        )

        if coordinateIsInside(coordinate, bounds: austriaFallbackBounds) {
            setCenter(coordinate, zoom: max(mapView.zoomLevel, 17), padding: safePadding)
        } else {
            fit([austriaFallbackBounds.sw, austriaFallbackBounds.ne, coordinate], minZoom: nil, padding: safePadding)
        }
    }

    func centerOnBoulderCoordinates(_ coordinates: [CLLocationCoordinate2D]) {
        guard !coordinates.isEmpty else { return }

        let paddedRect = CGRect(
            x: safePaddingForBoulder.left,
            y: safePaddingForBoulder.top,
            width: view.bounds.width - safePaddingForBoulder.left - safePaddingForBoulder.right,
            height: view.bounds.height - safePaddingForBoulder.top - safePaddingForBoulder.bottom
        )
        let allVisible = coordinates.allSatisfy { coordinate in
            paddedRect.contains(mapView.convert(coordinate, toPointTo: mapView))
        }
        guard !allVisible else { return }

        fit(coordinates, minZoom: nil, maxZoom: mapView.zoomLevel, padding: safePaddingForBoulder)
    }

    func setProblemAsSelected(problemFeatureId: String) {
        guard let id = Int(problemFeatureId) else { return }
        let topoIds = selectedTopoProblemIds.compactMap(Int.init)
        selectionController?.select(.problem, id: id, additionalIds: topoIds)
    }

    func unselectPreviousProblem() {
        selectionController?.clear()
    }

    func triggerMapDetectors() {
        triggerMapDetectors(immediate: false)
    }

    private func selectProblem(at tapPoint: CGPoint) -> Bool {
        guard mapView.zoomLevel >= 15 else { return false }
        let rect = CGRect(x: tapPoint.x - 16, y: tapPoint.y - 16, width: 32, height: 32)
        let features = visibleFeatures(in: rect, layers: [MapLayerContract.Layers.problems, MapLayerContract.SelectedLayers.problems])
        let sortedProblemIds = sortedByDistance(from: tapPoint, features: features)
            .compactMap { $0.attributes.intValue(for: MapLayerContract.Properties.problemId) }

        guard let problemId = sortedProblemIds.first else { return false }
        delegate?.selectProblem(id: problemId)
        setProblemAsSelected(problemFeatureId: String(problemId))

        if tapPoint.y >= (mapView.bounds.height / 2 - 40),
           let feature = features.first(where: { $0.attributes.intValue(for: MapLayerContract.Properties.problemId) == problemId }) {
            easeToCenter(feature.coordinate, padding: safePaddingForBottomSheet)
        }
        return true
    }

    private func selectPoi(at tapPoint: CGPoint) -> Bool {
        guard mapView.zoomLevel >= 12,
              let feature = visibleFeatures(at: tapPoint, layers: [MapLayerContract.Layers.pois, MapLayerContract.SelectedLayers.pois]).first,
              let id = feature.attributes.intValue(for: MapLayerContract.Properties.poiId) else { return false }

        selectionController?.select(.poi, id: id)
        delegate?.dismissProblemDetails()
        let name = feature.attributes.stringValue(for: "name") ?? ""
        delegate?.selectPoi(name: name, location: feature.coordinate, googleUrl: feature.attributes.stringValue(for: "googleUrl"))
        return true
    }

    private func selectArea(at tapPoint: CGPoint) -> Bool {
        guard mapView.zoomLevel < 16,
              let feature = visibleFeatures(at: tapPoint, layers: [MapLayerContract.Layers.areas, MapLayerContract.SelectedLayers.areas, MapLayerContract.Layers.areaHulls]).first,
              let id = feature.attributes.intValue(for: MapLayerContract.Properties.areaId) else { return false }

        selectionController?.select(.area, id: id)
        delegate?.dismissProblemDetails()
        delegate?.selectArea(id: id)
        return true
    }

    private func selectCluster(at tapPoint: CGPoint) -> Bool {
        guard mapView.zoomLevel <= 12,
              let feature = visibleFeatures(at: tapPoint, layers: [MapLayerContract.Layers.clusters, MapLayerContract.SelectedLayers.clusters, MapLayerContract.Layers.clusterHulls]).first,
              let id = feature.attributes.intValue(for: MapLayerContract.Properties.clusterId) else { return false }

        selectionController?.select(.cluster, id: id)
        delegate?.dismissProblemDetails()
        delegate?.selectCluster(id: id)
        return true
    }

    private func selectRegion(at tapPoint: CGPoint) -> Bool {
        guard mapView.zoomLevel <= 10,
              let feature = visibleFeatures(at: tapPoint, layers: [MapLayerContract.Layers.regions, MapLayerContract.SelectedLayers.regions, MapLayerContract.Layers.regionHulls]).first,
              let id = feature.attributes.intValue(for: MapLayerContract.Properties.regionId) else { return false }

        selectionController?.select(.region, id: id)
        delegate?.dismissProblemDetails()
        delegate?.selectRegion(id: id)
        return true
    }

    private func zoomTowardBoulder(at tapPoint: CGPoint) -> Bool {
        guard mapView.zoomLevel >= 15, mapView.zoomLevel < 19 else { return false }
        let rect = CGRect(x: tapPoint.x - 16, y: tapPoint.y - 16, width: 32, height: 32)
        guard !visibleFeatures(in: rect, layers: [MapLayerContract.Layers.boulders]).isEmpty else { return false }
        setCenter(mapView.convert(tapPoint, toCoordinateFrom: mapView), zoom: 19, padding: safePadding)
        return true
    }

    private func inferAreaFromMap() {
        if mapView.zoomLevel < 14.5 {
            delegate?.unselectArea()
            return
        }

        let width = mapView.frame.width / 4
        let rect = CGRect(x: mapView.bounds.midX - width / 2, y: mapView.bounds.midY - width / 2 + safePaddingYForAreaDetector, width: width, height: width)
        guard let feature = visibleFeatures(in: rect, layers: [MapLayerContract.Layers.areaHulls]).first,
              let id = feature.attributes.intValue(for: MapLayerContract.Properties.areaId) else { return }
        delegate?.selectArea(id: id)
    }

    private func inferClusterFromMap() {
        if mapView.zoomLevel < 11 {
            delegate?.unselectCluster()
            return
        }
        guard mapView.zoomLevel >= 12 else { return }

        let width = mapView.frame.width / 4
        let rect = CGRect(x: mapView.bounds.midX - width / 2, y: mapView.bounds.midY - width / 2 + safePaddingYForAreaDetector, width: width, height: width)
        guard let feature = visibleFeatures(in: rect, layers: [MapLayerContract.Layers.clusterHulls]).first,
              let id = feature.attributes.intValue(for: MapLayerContract.Properties.clusterId) else { return }
        delegate?.selectCluster(id: id)
    }

    private func triggerMapDetectors(immediate: Bool) {
        let work = { [weak self] in
            guard let self, !self.flyinToSomething else { return }
            self.inferAreaFromMap()
            self.inferClusterFromMap()
        }
        if immediate {
            work()
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: work)
        }
    }

    private func problemFilterPredicate(_ filters: Filters) -> NSPredicate? {
        var predicates: [NSPredicate] = []

        let gradeMin = filters.gradeRange?.min ?? Grade.min
        let gradeMax = filters.gradeRange?.max ?? Grade.max
        let grades = (gradeMin...gradeMax).map { $0.string }
        predicates.append(NSPredicate(format: "%K IN %@", "grade", grades))

        if filters.popular {
            predicates.append(NSPredicate(format: "%K == %@", "featured", NSNumber(value: true)))
        }
        if filters.favorite {
            predicates.append(NSPredicate(format: "%K IN %@", MapLayerContract.Properties.problemId, favoritesNotTicked.map { NSNumber(value: $0) }))
        }
        if filters.ticked {
            predicates.append(NSPredicate(format: "%K IN %@", MapLayerContract.Properties.problemId, ticks.map { NSNumber(value: Int($0.problemId)) }))
        }

        return predicates.count == 1 ? predicates[0] : NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }

    private var favorites: [Favorite] {
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        do {
            let fetchRequest: NSFetchRequest<Favorite> = Favorite.fetchRequest()
            return try context.fetch(fetchRequest)
        } catch {
            return []
        }
    }

    private var ticks: [Tick] {
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        do {
            let fetchRequest: NSFetchRequest<Tick> = Tick.fetchRequest()
            return try context.fetch(fetchRequest)
        } catch {
            return []
        }
    }

    private var favoritesNotTicked: Set<Int> {
        Set(favorites.map { Int($0.problemId) }).subtracting(ticks.map { Int($0.problemId) })
    }

    private func setCenter(_ coordinate: CLLocationCoordinate2D, zoom: CGFloat, padding: UIEdgeInsets) {
        flyinToSomething = true
        mapView.setContentInset(padding, animated: false)
        mapView.setCenter(coordinate, zoomLevel: Double(zoom), direction: -1, animated: true) { [weak self] in
            self?.flyinToSomething = false
            self?.triggerMapDetectors()
        }
    }

    private func easeToCenter(_ coordinate: CLLocationCoordinate2D, padding: UIEdgeInsets) {
        flyinToSomething = true
        mapView.setContentInset(padding, animated: false)
        mapView.setCenter(coordinate, zoomLevel: mapView.zoomLevel, direction: -1, animated: true) { [weak self] in
            self?.flyinToSomething = false
        }
    }

    private func fit(_ coordinates: [CLLocationCoordinate2D], minZoom: CGFloat?, maxZoom: Double? = nil, padding: UIEdgeInsets) {
        guard !coordinates.isEmpty else { return }
        flyinToSomething = true
        coordinates.withUnsafeBufferPointer { buffer in
            if let baseAddress = buffer.baseAddress {
                mapView.setVisibleCoordinates(
                    baseAddress,
                    count: UInt(coordinates.count),
                    edgePadding: padding,
                    direction: -1,
                    duration: flyinDuration,
                    animationTimingFunction: nil
                ) { [weak self] in
                    self?.flyinToSomething = false
                    self?.triggerMapDetectors()
                }
            }
        }
        if let minZoom, mapView.zoomLevel < minZoom {
            mapView.setZoomLevel(Double(minZoom), animated: true)
        }
        if let maxZoom, mapView.zoomLevel > maxZoom {
            mapView.setZoomLevel(maxZoom, animated: true)
        }
    }

    private func coordinateIsInside(_ coordinate: CLLocationCoordinate2D, bounds: MLNCoordinateBounds) -> Bool {
        coordinate.latitude >= bounds.sw.latitude &&
        coordinate.latitude <= bounds.ne.latitude &&
        coordinate.longitude >= bounds.sw.longitude &&
        coordinate.longitude <= bounds.ne.longitude
    }

    private func visibleFeatures(at point: CGPoint, layers: [String]) -> [MLNFeature] {
        let existingLayers = layers.filter(layerExists)
        guard !existingLayers.isEmpty else { return [] }
        return mapView.visibleFeatures(at: point, styleLayerIdentifiers: Set(existingLayers), predicate: nil)
    }

    private func visibleFeatures(in rect: CGRect, layers: [String]) -> [MLNFeature] {
        let existingLayers = layers.filter(layerExists)
        guard !existingLayers.isEmpty else { return [] }
        return mapView.visibleFeatures(in: rect, styleLayerIdentifiers: Set(existingLayers), predicate: nil)
    }

    private func sortedByDistance(from tapPoint: CGPoint, features: [MLNFeature]) -> [MLNFeature] {
        let tapCoordinate = mapView.convert(tapPoint, toCoordinateFrom: mapView)
        let tapLocation = CLLocation(latitude: tapCoordinate.latitude, longitude: tapCoordinate.longitude)
        return features.sorted { first, second in
            let firstLocation = CLLocation(latitude: first.coordinate.latitude, longitude: first.coordinate.longitude)
            let secondLocation = CLLocation(latitude: second.coordinate.latitude, longitude: second.coordinate.longitude)
            return firstLocation.distance(from: tapLocation) < secondLocation.distance(from: tapLocation)
        }
    }

    private func interactiveLayerIds() -> [String] {
        [
            MapLayerContract.Layers.problems,
            MapLayerContract.SelectedLayers.problems,
            MapLayerContract.Layers.pois,
            MapLayerContract.SelectedLayers.pois,
            MapLayerContract.Layers.areas,
            MapLayerContract.SelectedLayers.areas,
            MapLayerContract.Layers.areaHulls,
            MapLayerContract.Layers.clusters,
            MapLayerContract.SelectedLayers.clusters,
            MapLayerContract.Layers.clusterHulls,
            MapLayerContract.Layers.regions,
            MapLayerContract.SelectedLayers.regions,
            MapLayerContract.Layers.regionHulls
        ]
    }

    private func layerExists(_ identifier: String) -> Bool {
        mapView.style?.layer(withIdentifier: identifier) != nil
    }

    private func vectorLayer(_ identifier: String) -> MLNVectorStyleLayer? {
        mapView.style?.layer(withIdentifier: identifier) as? MLNVectorStyleLayer
    }
}

protocol MapLibreViewDelegate: AnyObject {
    func selectProblem(id: Int)
    func selectPoi(name: String, location: CLLocationCoordinate2D, googleUrl: String?)
    func selectArea(id: Int)
    func selectCluster(id: Int)
    func selectRegion(id: Int)
    func unselectArea()
    func unselectCluster()
    func cameraChanged(state: MapLibreCameraState)
    func dismissProblemDetails()
    func mapBecameAvailable()
    func mapBecameUnavailable(message: String)
}
