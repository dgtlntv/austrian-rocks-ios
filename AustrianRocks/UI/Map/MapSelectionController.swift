//
//  MapSelectionController.swift
//  Austrian.rocks
//
//  Copyright © 2026 Austrian.rocks. All rights reserved.
//

import Foundation
import MapLibre

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

    private let mapView: MLNMapView
    private var current: Selection?
    private var originalBasePredicates: [String: StoredPredicate] = [:]
    private var originalGrowExpressions: [String: NSExpression] = [:]
    private var originalIconRotations: [String: NSExpression] = [:]
    private var supplementalPredicates: [Kind: NSPredicate] = [:]
    private var animationToken = UUID()

    private let growDuration: TimeInterval = 0.52
    private let clearDuration: TimeInterval = 0.22
    private let iconGrowScale: CGFloat = 1.25
    private let iconClearScale: CGFloat = 0.72
    private let circleGrowScale: CGFloat = 1.4
    private let circleClearScale: CGFloat = 1.0
    private let iconSettleOvershoot: CGFloat = 0.1
    private let circleSettleOvershoot: CGFloat = 0.08
    private let iconWiggleDegrees: CGFloat = 5

    init(mapView: MLNMapView) {
        self.mapView = mapView
    }

    func styleDidLoad() {
        originalBasePredicates.removeAll()
        originalGrowExpressions.removeAll()
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

    func setSupplementalPredicate(_ predicate: NSPredicate?, for kind: Kind) {
        supplementalPredicates[kind] = predicate
        guard let current, current.kind == kind else {
            applyClearedPredicate(to: kind)
            return
        }
        applySelectedPredicate(for: current)
    }

    private func applySelection(_ selection: Selection, animated: Bool) {
        guard layerExists(selection.kind.selectedLayerId) else { return }

        applySelectedPredicate(for: selection)
        excludeFromBaseLayer(selection.kind, id: selection.id)

        if animated {
            startGrowAnimation(for: selection.kind)
        } else {
            applySelectionFrame(kind: selection.kind, scale: selection.kind.isCircle ? circleGrowScale : iconGrowScale, progress: 1)
        }
    }

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
              let layer = vectorLayer(baseLayerId) else { return }

        if originalBasePredicates[baseLayerId] == nil {
            originalBasePredicates[baseLayerId] = StoredPredicate(predicate: layer.predicate)
        }

        let original = originalBasePredicates[baseLayerId]?.predicate
        let exclusion = NSPredicate(format: "%K != %@", kind.idProperty, NSNumber(value: id))
        layer.predicate = combinedPredicate([original, exclusion])
    }

    private func restoreBaseLayer(_ kind: Kind) {
        guard let baseLayerId = kind.baseLayerId,
              let stored = originalBasePredicates[baseLayerId],
              let layer = vectorLayer(baseLayerId) else { return }
        layer.predicate = stored.predicate
    }

    private func setPredicate(combining predicates: [NSPredicate?], on layerId: String) {
        vectorLayer(layerId)?.predicate = combinedPredicate(predicates)
    }

    private func combinedPredicate(_ predicates: [NSPredicate?]) -> NSPredicate? {
        let active = predicates.compactMap { $0 }
        guard !active.isEmpty else { return nil }
        return active.count == 1 ? active[0] : NSCompoundPredicate(andPredicateWithSubpredicates: active)
    }

    private func startGrowAnimation(for kind: Kind) {
        cancelAnimation()
        let token = animationToken
        let targetScale = kind.isCircle ? circleGrowScale : iconGrowScale
        let overshoot = kind.isCircle ? circleSettleOvershoot : iconSettleOvershoot
        animate(duration: growDuration, token: token) { [weak self] progress in
            guard let self else { return }
            self.applySelectionFrame(kind: kind, scale: self.settleScale(progress: progress, targetScale: targetScale, overshoot: overshoot), progress: progress)
        }
    }

    private func startClearAnimation(for selection: Selection, finish: @escaping () -> Void) {
        let token = animationToken
        let kind = selection.kind
        let startScale = kind.isCircle ? circleGrowScale : iconGrowScale
        let endScale = kind.isCircle ? circleClearScale : iconClearScale
        animate(duration: clearDuration, token: token, completion: finish) { [weak self] progress in
            let eased = 1 - pow(1 - progress, 3)
            self?.applySelectionFrame(kind: kind, scale: startScale + ((endScale - startScale) * eased), progress: 1)
        }
    }

    private func animate(duration: TimeInterval, token: UUID, completion: (() -> Void)? = nil, step: @escaping (CGFloat) -> Void) {
        let start = CACurrentMediaTime()
        func tick() {
            guard token == animationToken else { return }
            let progress = min(CGFloat((CACurrentMediaTime() - start) / duration), 1)
            step(progress)
            if progress < 1 {
                DispatchQueue.main.asyncAfter(deadline: .now() + (1.0 / 60.0)) { tick() }
            } else {
                completion?()
            }
        }
        tick()
    }

    private func cancelAnimation() {
        animationToken = UUID()
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
        if kind.isCircle {
            guard let layer = circleLayer(kind.selectedLayerId) else { return }
            let original = originalGrowExpression(for: kind, current: layer.circleRadius ?? NSExpression(forConstantValue: 1))
            layer.circleRadius = scaledExpression(original, scale: scale)
        } else {
            guard let layer = symbolLayer(kind.selectedLayerId) else { return }
            let original = originalGrowExpression(for: kind, current: layer.iconScale ?? NSExpression(forConstantValue: 1))
            layer.iconScale = scaledExpression(original, scale: scale)
        }
    }

    private func applyIconWiggle(kind: Kind, progress: CGFloat) {
        guard let layer = symbolLayer(kind.selectedLayerId) else { return }
        let base = originalIconRotation(for: kind, current: layer.iconRotation ?? NSExpression(forConstantValue: 0))
        let baseDegrees = (base.constantValue as? NSNumber)?.doubleValue ?? 0
        let easedProgress = 1 - pow(1 - progress, 2)
        let amplitude = Double(iconWiggleDegrees * max(0, 1 - easedProgress))
        let rotation = baseDegrees + (sin(Double(easedProgress) * .pi * 2.5) * amplitude)
        layer.iconRotation = NSExpression(forConstantValue: rotation)
    }

    private func restoreIconRotation(kind: Kind) {
        guard !kind.isCircle,
              let original = originalIconRotations[kind.selectedLayerId],
              let layer = symbolLayer(kind.selectedLayerId) else { return }
        layer.iconRotation = original
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

    private func scaledExpression(_ expression: NSExpression, scale: CGFloat) -> NSExpression {
        guard scale != 1 else { return expression }

        let jsonObject = expression.mgl_jsonExpressionObject
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

    private func layerExists(_ identifier: String) -> Bool {
        mapView.style?.layer(withIdentifier: identifier) != nil
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

private extension MapSelectionController.Kind {
    static let allCases: [MapSelectionController.Kind] = [.region, .cluster, .area, .poi, .problem]
}

private extension Array where Element: Hashable {
    func uniqued() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}
