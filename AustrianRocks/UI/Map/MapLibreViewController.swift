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

    private let manifestClient: MapTileManifestClient
    private let styleCache: MapTileStyleCache
    private var currentFilters: Filters?
    private var currentStyleChoice: MapStyleChoice?
    private var styleLoadTask: Task<Void, Never>?
    private var lastCameraDelegateUpdate = Date.distantPast
    private var flyinToSomething = false
    private let flyinDuration = 0.5
    private let safePadding = UIEdgeInsets(top: 180, left: 20, bottom: 180, right: 20)
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
        self.manifestClient = manifestClient
        self.styleCache = styleCache
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        self.manifestClient = MapTileManifestClient()
        self.styleCache = MapTileStyleCache()
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
        currentStyleChoice = choice

        styleLoadTask = Task { [weak self] in
            guard let self else { return }

            do {
                let manifest = try await manifestClient.fetchManifest(from: BrandConfig.MapTiles.manifestURL)
                let styleURL = try manifest.styleURL(for: choice)
                try styleCache.recordSuccess(manifest: manifest, choice: choice, styleURL: styleURL)
                await MainActor.run {
                    self.installStyle(url: styleURL)
                }
            } catch {
                if let cached = styleCache.lastKnownStyle(for: choice) {
                    await MainActor.run {
                        self.installStyle(url: cached.styleURL)
                    }
                } else {
                    await MainActor.run {
                        self.delegate?.mapBecameUnavailable(message: String(localized: "map.unavailable.message"))
                    }
                }
            }
        }
    }

    @MainActor
    private func installStyle(url: URL) {
        guard mapView.styleURL != url else {
            delegate?.mapBecameAvailable()
            return
        }

        delegate?.mapBecameAvailable()
        mapView.styleURL = url
    }

    func mapView(_ mapView: MLNMapView, didFinishLoading style: MLNStyle) {
        delegate?.mapBecameAvailable()
        if let filters = currentFilters {
            applyFilters(filters)
        }
    }

    func mapView(_ mapView: MLNMapView, didFailLoadingMapWithError error: Error) {
        delegate?.mapBecameUnavailable(message: error.localizedDescription)
    }

    func mapViewRegionIsChanging(_ mapView: MLNMapView) {
        guard !flyinToSomething else { return }
        guard Date().timeIntervalSince(lastCameraDelegateUpdate) > 0.1 else { return }
        lastCameraDelegateUpdate = Date()
        delegate?.cameraChanged(state: MapLibreCameraState(center: mapView.centerCoordinate, zoom: mapView.zoomLevel))
    }

    func mapView(_ mapView: MLNMapView, regionDidChangeAnimated animated: Bool) {
        guard !flyinToSomething else { return }
        delegate?.cameraChanged(state: MapLibreCameraState(center: mapView.centerCoordinate, zoom: mapView.zoomLevel))
    }

    @objc private func handleTap(_ recognizer: UITapGestureRecognizer) {
        guard recognizer.state == .ended else { return }
        findFeatures(tapPoint: recognizer.location(in: mapView))
    }

    func findFeatures(tapPoint: CGPoint) {
    }

    func applyFilters(_ filters: Filters) {
        currentFilters = filters
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
        fit(coordinates, minZoom: nil, padding: safePaddingForBoulder)
    }

    func setProblemAsSelected(problemFeatureId: String) {
    }

    func unselectPreviousProblem() {
    }

    func triggerMapDetectors() {
    }

    private func setCenter(_ coordinate: CLLocationCoordinate2D, zoom: CGFloat, padding: UIEdgeInsets) {
        flyinToSomething = true
        mapView.setContentInset(padding, animated: false)
        mapView.setCenter(coordinate, zoomLevel: zoom, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + flyinDuration) { [weak self] in
            self?.flyinToSomething = false
            self?.triggerMapDetectors()
        }
    }

    private func fit(_ coordinates: [CLLocationCoordinate2D], minZoom: CGFloat?, padding: UIEdgeInsets) {
        guard !coordinates.isEmpty else { return }
        flyinToSomething = true
        coordinates.withUnsafeBufferPointer { buffer in
            if let baseAddress = buffer.baseAddress {
                mapView.setVisibleCoordinates(baseAddress, count: UInt(coordinates.count), edgePadding: padding, animated: true)
            }
        }
        if let minZoom, mapView.zoomLevel < minZoom {
            mapView.setZoomLevel(minZoom, animated: true)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + flyinDuration) { [weak self] in
            self?.flyinToSomething = false
            self?.triggerMapDetectors()
        }
    }

    private func coordinateIsInside(_ coordinate: CLLocationCoordinate2D, bounds: MLNCoordinateBounds) -> Bool {
        coordinate.latitude >= bounds.sw.latitude &&
        coordinate.latitude <= bounds.ne.latitude &&
        coordinate.longitude >= bounds.sw.longitude &&
        coordinate.longitude <= bounds.ne.longitude
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
