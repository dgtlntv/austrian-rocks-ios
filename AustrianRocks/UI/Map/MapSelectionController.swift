//
//  MapSelectionController.swift
//  Austrian.rocks
//
//  Copyright © 2026 Austrian.rocks. All rights reserved.
//

import Foundation
import MapLibre
import QuartzCore

/// Style mutations the selection controller performs, abstracted so the
/// selection/animation state machine is testable without a live MLNMapView.
protocol MapSelectionStyling: AnyObject {
    func layerExists(_ identifier: String) -> Bool
    func predicate(forLayer identifier: String) -> NSPredicate?
    func setPredicate(_ predicate: NSPredicate?, forLayer identifier: String)
    func growExpression(forLayer identifier: String, isCircle: Bool) -> NSExpression?
    func setGrowExpression(_ expression: NSExpression, forLayer identifier: String, isCircle: Bool)
    func iconRotation(forLayer identifier: String) -> NSExpression?
    func setIconRotation(_ expression: NSExpression, forLayer identifier: String)
}

/// Drives per-frame animation ticks. The production driver uses CADisplayLink
/// so selection animations stay in sync with screen refresh; tests inject a
/// driver they advance manually.
protocol SelectionAnimationDriver: AnyObject {
    var isRunning: Bool { get }
    func start(_ tick: @escaping (CFTimeInterval) -> Void)
    func stop()
}

final class DisplayLinkAnimationDriver: SelectionAnimationDriver {
    private var displayLink: CADisplayLink?
    private var tick: ((CFTimeInterval) -> Void)?

    var isRunning: Bool { displayLink != nil }

    func start(_ tick: @escaping (CFTimeInterval) -> Void) {
        stop()
        self.tick = tick
        let link = CADisplayLink(target: WeakProxy(driver: self), selector: #selector(WeakProxy.fire))
        link.add(to: .main, forMode: .common)
        displayLink = link
    }

    func stop() {
        displayLink?.invalidate()
        displayLink = nil
        tick = nil
    }

    deinit {
        displayLink?.invalidate()
    }

    fileprivate func fire() {
        tick?(CACurrentMediaTime())
    }

    // CADisplayLink retains its target; the proxy keeps the driver (and the
    // selection controller behind it) deallocatable while a link is live.
    private final class WeakProxy: NSObject {
        weak var driver: DisplayLinkAnimationDriver?

        init(driver: DisplayLinkAnimationDriver) {
            self.driver = driver
        }

        @objc func fire() {
            driver?.fire()
        }
    }
}

/// Mirrors the Rails MapSelection state machine: one selected map entity at a
/// time, rendered through shared `*-selected` layers filtered by id and the
/// `-1` cleared sentinel instead of feature-state.
final class MapSelectionController {
    enum Kind {
        case region
        case cluster
        case area
        case poi
        case problem

        var selectedLayerId: String {
            switch self {
            case .region: return MapLayerContract.SelectedLayers.regions
            case .cluster: return MapLayerContract.SelectedLayers.clusters
            case .area: return MapLayerContract.SelectedLayers.areas
            case .poi: return MapLayerContract.SelectedLayers.pois
            case .problem: return MapLayerContract.SelectedLayers.problems
            }
        }

        var baseLayerId: String? {
            switch self {
            case .region: return MapLayerContract.Layers.regions
            case .cluster: return MapLayerContract.Layers.clusters
            case .area: return MapLayerContract.Layers.areas
            case .poi: return MapLayerContract.Layers.pois
            case .problem: return nil
            }
        }

        var idProperty: String {
            switch self {
            case .region: return MapLayerContract.Properties.regionId
            case .cluster: return MapLayerContract.Properties.clusterId
            case .area: return MapLayerContract.Properties.areaId
            case .poi: return MapLayerContract.Properties.poiId
            case .problem: return MapLayerContract.Properties.problemId
            }
        }

        var isCircle: Bool { self == .problem }
    }

    private struct Selection: Equatable {
        let kind: Kind
        let id: Int
        let selectedIds: [Int]
    }

    private struct StoredPredicate {
        let predicate: NSPredicate?
    }

    private let styling: MapSelectionStyling
    private let driver: SelectionAnimationDriver
    private var current: Selection?
    private var originalBasePredicates: [String: StoredPredicate] = [:]
    private var originalGrowExpressions: [String: NSExpression] = [:]
    private var originalGrowExpressionJSON: [String: Any] = [:]
    private var originalIconRotations: [String: NSExpression] = [:]
    private var supplementalPredicates: [Kind: NSPredicate] = [:]

    let growDuration: TimeInterval = 0.52
    let clearDuration: TimeInterval = 0.22
    let iconGrowScale: CGFloat = 1.25
    // Intentional deviations from the Rails constants (web follows via the
    // 0005 cross-repo list): the circle grow is softened from 1.4 to 1.2,
    // and clear animates back to exactly the base scale 1.0 (web shrinks to
    // 0.72 and pops when the unselected pin reappears).
    let circleGrowScale: CGFloat = 1.2
    let clearScale: CGFloat = 1.0
    let iconSettleOvershoot: CGFloat = 0.1
    let circleSettleOvershoot: CGFloat = 0.08
    let iconWiggleDegrees: CGFloat = 5

    init(styling: MapSelectionStyling, driver: SelectionAnimationDriver = DisplayLinkAnimationDriver()) {
        self.styling = styling
        self.driver = driver
    }

    convenience init(mapView: MLNMapView) {
        self.init(styling: MapLibreSelectionStyling(mapView: mapView))
    }

    deinit {
        driver.stop()
    }

    func styleDidLoad() {
        originalBasePredicates.removeAll()
        originalGrowExpressions.removeAll()
        originalGrowExpressionJSON.removeAll()
        originalIconRotations.removeAll()
        Kind.allCases.forEach { applyClearedPredicate(to: $0) }
        if let current {
            applySelection(current, animated: false)
        }
    }

    func select(_ kind: Kind, id: Int, additionalIds: [Int] = [], animated: Bool = true) {
        let selectedIds = ([id] + additionalIds.filter { $0 != id }).uniqued()
        let selection = Selection(kind: kind, id: id, selectedIds: selectedIds)
        guard current != selection else { return }

        clear(animated: false)
        current = selection
        applySelection(selection, animated: animated)
    }

    func clear(animated: Bool = true) {
        guard let current else { return }
        cancelAnimation()

        if animated {
            startClearAnimation(for: current) { [weak self] in
                self?.finishClear(current)
            }
        } else {
            finishClear(current)
        }
    }

    /// Clears only when the current selection is of the given kind, so e.g.
    /// dismissing the problem sheet never wipes a fresh POI/area selection.
    func clear(ifKind kind: Kind, animated: Bool = true) {
        guard current?.kind == kind else { return }
        clear(animated: animated)
    }

    func setSupplementalPredicate(_ predicate: NSPredicate?, for kind: Kind) {
        supplementalPredicates[kind] = predicate
        guard let current, current.kind == kind else {
            applyClearedPredicate(to: kind)
            return
        }
        applySelectedPredicate(for: current)
    }

    private func applySelection(_ selection: Selection, animated: Bool) {
        guard styling.layerExists(selection.kind.selectedLayerId) else { return }

        applySelectedPredicate(for: selection)
        excludeFromBaseLayer(selection.kind, id: selection.id)

        if animated {
            startGrowAnimation(for: selection.kind)
        } else {
            applySelectionFrame(kind: selection.kind, scale: selection.kind.isCircle ? circleGrowScale : iconGrowScale, progress: 1)
        }
    }

    // The selected pin lands at exactly base scale, then the selected-layer
    // sentinel and base-layer exclusion swap in the same frame, so the
    // selected pin visually becomes the unselected pin with no gap.
    private func finishClear(_ selection: Selection) {
        guard current == selection else { return }
        applyGrowScale(kind: selection.kind, scale: 1)
        restoreIconRotation(kind: selection.kind)
        applyClearedPredicate(to: selection.kind)
        restoreBaseLayer(selection.kind)
        current = nil
    }

    private func applySelectedPredicate(for selection: Selection) {
        let idPredicate: NSPredicate
        if selection.selectedIds.count == 1, let id = selection.selectedIds.first {
            idPredicate = NSPredicate(format: "%K == %@", selection.kind.idProperty, NSNumber(value: id))
        } else {
            idPredicate = NSPredicate(format: "%K IN %@", selection.kind.idProperty, selection.selectedIds.map { NSNumber(value: $0) })
        }
        setPredicate(combining: [idPredicate, supplementalPredicates[selection.kind]], on: selection.kind.selectedLayerId)
    }

    private func applyClearedPredicate(to kind: Kind) {
        let sentinel = NSPredicate(format: "%K == %@", kind.idProperty, NSNumber(value: MapLayerContract.clearedSentinel))
        setPredicate(combining: [sentinel, supplementalPredicates[kind]], on: kind.selectedLayerId)
    }

    private func excludeFromBaseLayer(_ kind: Kind, id: Int) {
        guard let baseLayerId = kind.baseLayerId,
              styling.layerExists(baseLayerId) else { return }

        if originalBasePredicates[baseLayerId] == nil {
            originalBasePredicates[baseLayerId] = StoredPredicate(predicate: styling.predicate(forLayer: baseLayerId))
        }

        let original = originalBasePredicates[baseLayerId]?.predicate
        let exclusion = NSPredicate(format: "%K != %@", kind.idProperty, NSNumber(value: id))
        styling.setPredicate(combinedPredicate([original, exclusion]), forLayer: baseLayerId)
    }

    private func restoreBaseLayer(_ kind: Kind) {
        guard let baseLayerId = kind.baseLayerId,
              let stored = originalBasePredicates[baseLayerId] else { return }
        styling.setPredicate(stored.predicate, forLayer: baseLayerId)
    }

    private func setPredicate(combining predicates: [NSPredicate?], on layerId: String) {
        styling.setPredicate(combinedPredicate(predicates), forLayer: layerId)
    }

    private func combinedPredicate(_ predicates: [NSPredicate?]) -> NSPredicate? {
        let active = predicates.compactMap { $0 }
        guard !active.isEmpty else { return nil }
        return active.count == 1 ? active[0] : NSCompoundPredicate(andPredicateWithSubpredicates: active)
    }

    private func startGrowAnimation(for kind: Kind) {
        cancelAnimation()
        let targetScale = kind.isCircle ? circleGrowScale : iconGrowScale
        let overshoot = kind.isCircle ? circleSettleOvershoot : iconSettleOvershoot
        animate(duration: growDuration) { [weak self] progress in
            guard let self else { return }
            self.applySelectionFrame(kind: kind, scale: self.settleScale(progress: progress, targetScale: targetScale, overshoot: overshoot), progress: progress)
        }
    }

    private func startClearAnimation(for selection: Selection, finish: @escaping () -> Void) {
        let kind = selection.kind
        let startScale = kind.isCircle ? circleGrowScale : iconGrowScale
        let endScale = clearScale
        animate(duration: clearDuration, completion: finish) { [weak self] progress in
            let eased = 1 - pow(1 - progress, 3)
            self?.applySelectionFrame(kind: kind, scale: startScale + ((endScale - startScale) * eased), progress: 1)
        }
    }

    private func animate(duration: TimeInterval, completion: (() -> Void)? = nil, step: @escaping (CGFloat) -> Void) {
        driver.stop()
        var startTime: CFTimeInterval?
        step(0)
        driver.start { [weak self] time in
            guard let self else { return }
            if startTime == nil { startTime = time }
            let progress = min(CGFloat((time - (startTime ?? time)) / duration), 1)
            step(progress)
            if progress >= 1 {
                self.driver.stop()
                completion?()
            }
        }
    }

    private func cancelAnimation() {
        driver.stop()
    }

    private func settleScale(progress: CGFloat, targetScale: CGFloat, overshoot: CGFloat) -> CGFloat {
        if progress < 0.55 {
            let eased = 1 - pow(1 - (progress / 0.55), 3)
            return 1 + ((targetScale + overshoot) - 1) * eased
        }

        let settle = (progress - 0.55) / 0.45
        let wave = sin(settle * .pi * 2) * (1 - settle) * (overshoot * 0.55)
        return targetScale + wave
    }

    private func applySelectionFrame(kind: Kind, scale: CGFloat, progress: CGFloat) {
        applyGrowScale(kind: kind, scale: scale)
        if !kind.isCircle {
            applyIconWiggle(kind: kind, progress: progress)
        }
    }

    private func applyGrowScale(kind: Kind, scale: CGFloat) {
        let layerId = kind.selectedLayerId
        guard styling.layerExists(layerId) else { return }
        let current = styling.growExpression(forLayer: layerId, isCircle: kind.isCircle) ?? NSExpression(forConstantValue: 1)
        let original = originalGrowExpression(for: kind, current: current)
        styling.setGrowExpression(scaledExpression(original, layerId: layerId, scale: scale), forLayer: layerId, isCircle: kind.isCircle)
    }

    private func applyIconWiggle(kind: Kind, progress: CGFloat) {
        let layerId = kind.selectedLayerId
        guard styling.layerExists(layerId) else { return }
        let base = originalIconRotation(for: kind, current: styling.iconRotation(forLayer: layerId) ?? NSExpression(forConstantValue: 0))
        let baseDegrees = (base.constantValue as? NSNumber)?.doubleValue ?? 0
        let easedProgress = 1 - pow(1 - progress, 2)
        let amplitude = Double(iconWiggleDegrees * max(0, 1 - easedProgress))
        let rotation = baseDegrees + (sin(Double(easedProgress) * .pi * 2.5) * amplitude)
        styling.setIconRotation(NSExpression(forConstantValue: rotation), forLayer: layerId)
    }

    private func restoreIconRotation(kind: Kind) {
        guard !kind.isCircle,
              let original = originalIconRotations[kind.selectedLayerId] else { return }
        styling.setIconRotation(original, forLayer: kind.selectedLayerId)
    }

    private func originalGrowExpression(for kind: Kind, current: NSExpression) -> NSExpression {
        if let original = originalGrowExpressions[kind.selectedLayerId] { return original }
        originalGrowExpressions[kind.selectedLayerId] = current
        return current
    }

    private func originalIconRotation(for kind: Kind, current: NSExpression) -> NSExpression {
        if let original = originalIconRotations[kind.selectedLayerId] { return original }
        originalIconRotations[kind.selectedLayerId] = current
        return current
    }

    private func scaledExpression(_ expression: NSExpression, layerId: String, scale: CGFloat) -> NSExpression {
        guard scale != 1 else { return expression }

        // Parse the base expression once per layer; per-frame work only swaps
        // the scale constant instead of rebuilding NSExpression trees.
        let jsonObject: Any
        if let cached = originalGrowExpressionJSON[layerId] {
            jsonObject = cached
        } else {
            jsonObject = expression.mgl_jsonExpressionObject
            originalGrowExpressionJSON[layerId] = jsonObject
        }

        if let zoomScaled = Self.zoomSafeScaledJSONObject(jsonObject, scale: scale) {
            return NSExpression(mglJSONObject: zoomScaled)
        }

        return NSExpression(mglJSONObject: ["*", NSNumber(value: Double(scale)), jsonObject])
    }

    static func zoomSafeScaledJSONObject(_ jsonObject: Any, scale: CGFloat) -> Any? {
        guard var expression = jsonObject as? [Any],
              let operatorName = expression.first as? String else { return nil }

        let scaleNumber = NSNumber(value: Double(scale))

        switch operatorName {
        case "interpolate":
            guard expression.count >= 5, isZoomExpression(expression[2]) else { return nil }
            var outputIndex = 4
            while outputIndex < expression.count {
                expression[outputIndex] = scaledJSONObject(expression[outputIndex], scale: scaleNumber)
                outputIndex += 2
            }
            return expression
        case "step":
            guard expression.count >= 4, isZoomExpression(expression[1]) else { return nil }
            expression[2] = scaledJSONObject(expression[2], scale: scaleNumber)
            var outputIndex = 4
            while outputIndex < expression.count {
                expression[outputIndex] = scaledJSONObject(expression[outputIndex], scale: scaleNumber)
                outputIndex += 2
            }
            return expression
        default:
            return nil
        }
    }

    private static func scaledJSONObject(_ jsonObject: Any, scale: NSNumber) -> Any {
        if let number = jsonObject as? NSNumber {
            return NSNumber(value: number.doubleValue * scale.doubleValue)
        }

        return ["*", scale, jsonObject]
    }

    private static func isZoomExpression(_ jsonObject: Any) -> Bool {
        guard let expression = jsonObject as? [Any],
              expression.count == 1,
              let operatorName = expression.first as? String else { return false }
        return operatorName == "zoom"
    }
}

/// MLNMapView-backed styling used by the live map.
final class MapLibreSelectionStyling: MapSelectionStyling {
    private let mapView: MLNMapView

    init(mapView: MLNMapView) {
        self.mapView = mapView
    }

    func layerExists(_ identifier: String) -> Bool {
        mapView.style?.layer(withIdentifier: identifier) != nil
    }

    func predicate(forLayer identifier: String) -> NSPredicate? {
        vectorLayer(identifier)?.predicate
    }

    func setPredicate(_ predicate: NSPredicate?, forLayer identifier: String) {
        vectorLayer(identifier)?.predicate = predicate
    }

    func growExpression(forLayer identifier: String, isCircle: Bool) -> NSExpression? {
        if isCircle {
            return circleLayer(identifier)?.circleRadius
        }
        return symbolLayer(identifier)?.iconScale
    }

    func setGrowExpression(_ expression: NSExpression, forLayer identifier: String, isCircle: Bool) {
        if isCircle {
            circleLayer(identifier)?.circleRadius = expression
        } else {
            symbolLayer(identifier)?.iconScale = expression
        }
    }

    func iconRotation(forLayer identifier: String) -> NSExpression? {
        symbolLayer(identifier)?.iconRotation
    }

    func setIconRotation(_ expression: NSExpression, forLayer identifier: String) {
        symbolLayer(identifier)?.iconRotation = expression
    }

    private func vectorLayer(_ identifier: String) -> MLNVectorStyleLayer? {
        mapView.style?.layer(withIdentifier: identifier) as? MLNVectorStyleLayer
    }

    private func symbolLayer(_ identifier: String) -> MLNSymbolStyleLayer? {
        mapView.style?.layer(withIdentifier: identifier) as? MLNSymbolStyleLayer
    }

    private func circleLayer(_ identifier: String) -> MLNCircleStyleLayer? {
        mapView.style?.layer(withIdentifier: identifier) as? MLNCircleStyleLayer
    }
}

extension MapSelectionController.Kind {
    static let allCases: [MapSelectionController.Kind] = [.region, .cluster, .area, .poi, .problem]
}

private extension Array where Element: Hashable {
    func uniqued() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}
