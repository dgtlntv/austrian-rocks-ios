//
//  ZoomableScrollView.swift
//  Austrian.rocks
//
//  Created by Nicolas Mondollot on 26/04/2025.
//  Copyright © 2025 Nicolas Mondollot. All rights reserved.
//

import SwiftUI

// MARK: – ZoomableScrollView
struct ZoomableScrollView<Content: View>: UIViewRepresentable {
    @Binding var zoomScale: CGFloat
    let isZoomEnabled: Bool

    private let minimumZoomScale: CGFloat
    private let maximumZoomScale: CGFloat
    @ViewBuilder private var content: () -> Content

    init(
        zoomScale: Binding<CGFloat>,
        isZoomEnabled: Bool = true,
        minimumZoomScale: CGFloat = 1.0,
        maximumZoomScale: CGFloat = 5.0,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self._zoomScale = zoomScale
        self.isZoomEnabled = isZoomEnabled
        self.minimumZoomScale = minimumZoomScale
        self.maximumZoomScale = maximumZoomScale
        self.content = content
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.delegate = context.coordinator
        scrollView.maximumZoomScale = maximumZoomScale
        scrollView.minimumZoomScale = minimumZoomScale
        scrollView.bouncesZoom = isZoomEnabled
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.alwaysBounceHorizontal = false // Don't steal horizontal gestures from outer paging ScrollView at 1x zoom
        scrollView.zoomScale = isZoomEnabled ? zoomScale : minimumZoomScale
        scrollView.contentInsetAdjustmentBehavior = .never // To avoid a wierb animation buf with safe areas

        // Add double tap gesture recognizer
        let doubleTapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleDoubleTap(_:)))
        doubleTapGesture.numberOfTapsRequired = 2
        doubleTapGesture.delegate = context.coordinator
        scrollView.addGestureRecognizer(doubleTapGesture)
        context.coordinator.doubleTapGesture = doubleTapGesture

        // Host SwiftUI content
        let hostedController = UIHostingController(rootView: content())
        hostedController.view.backgroundColor = .clear
        context.coordinator.hostingController = hostedController
        scrollView.addSubview(hostedController.view)

        // Pin hosted view to scroll view's content and frame guides
        hostedController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostedController.view.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            hostedController.view.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            hostedController.view.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            hostedController.view.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            hostedController.view.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
            hostedController.view.heightAnchor.constraint(equalTo: scrollView.frameLayoutGuide.heightAnchor)
        ])

        context.coordinator.applyZoomConfiguration(to: scrollView, animated: false)

        return scrollView
    }

    func updateUIView(_ uiView: UIScrollView, context: Context) {
        context.coordinator.parent = self

        // Update content and recenter on layout/zoom changes.
        // The hosted content type remains stable, so SwiftUI preserves TopoView's @State.
        context.coordinator.hostingController?.rootView = content()
        context.coordinator.applyZoomConfiguration(to: uiView, animated: false)
        context.coordinator.recenterContent(in: uiView)
    }

    class Coordinator: NSObject, UIScrollViewDelegate, UIGestureRecognizerDelegate {
        var hostingController: UIHostingController<Content>?
        var parent: ZoomableScrollView
        weak var doubleTapGesture: UITapGestureRecognizer?
        private var isApplyingZoomConfiguration = false

        init(_ parent: ZoomableScrollView) {
            self.parent = parent
            super.init()
        }

        // Allow simultaneous gesture recognition
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            return true
        }

        @objc func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
            guard parent.isZoomEnabled, let scrollView = gesture.view as? UIScrollView else { return }
            scrollView.setZoomScale(parent.minimumZoomScale, animated: true)
        }

        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            hostingController?.view
        }

        func scrollViewDidZoom(_ scrollView: UIScrollView) {
            recenterContent(in: scrollView)
            setParentZoomScale(scrollView.zoomScale, deferred: isApplyingZoomConfiguration)
            // Enable horizontal bounce only when zoomed, so panning feels natural.
            // At 1x zoom, keep it off to let an outer paging ScrollView handle swipes.
            scrollView.alwaysBounceHorizontal = parent.isZoomEnabled && scrollView.zoomScale > scrollView.minimumZoomScale + 0.01
        }

        func applyZoomConfiguration(to scrollView: UIScrollView, animated: Bool) {
            isApplyingZoomConfiguration = true
            defer { isApplyingZoomConfiguration = false }

            if parent.isZoomEnabled {
                scrollView.minimumZoomScale = parent.minimumZoomScale
                scrollView.maximumZoomScale = max(parent.minimumZoomScale, parent.maximumZoomScale)
                scrollView.bouncesZoom = true
                scrollView.isScrollEnabled = true
                scrollView.panGestureRecognizer.isEnabled = true
                scrollView.pinchGestureRecognizer?.isEnabled = true
                doubleTapGesture?.isEnabled = true

                let clampedZoomScale = min(max(parent.zoomScale, scrollView.minimumZoomScale), scrollView.maximumZoomScale)
                if scrollView.zoomScale != clampedZoomScale {
                    scrollView.setZoomScale(clampedZoomScale, animated: animated)
                }
                setParentZoomScale(clampedZoomScale, deferred: true)
            } else {
                let disabledZoomScale = parent.minimumZoomScale
                if scrollView.zoomScale != disabledZoomScale {
                    scrollView.setZoomScale(disabledZoomScale, animated: false)
                }
                setParentZoomScale(disabledZoomScale, deferred: true)

                scrollView.minimumZoomScale = disabledZoomScale
                scrollView.maximumZoomScale = disabledZoomScale
                scrollView.bouncesZoom = false
                scrollView.isScrollEnabled = false
                scrollView.panGestureRecognizer.isEnabled = false
                scrollView.pinchGestureRecognizer?.isEnabled = false
                doubleTapGesture?.isEnabled = false
                scrollView.alwaysBounceHorizontal = false
                scrollView.alwaysBounceVertical = false
                scrollView.setContentOffset(.zero, animated: false)
            }
        }

        private func setParentZoomScale(_ zoomScale: CGFloat, deferred: Bool) {
            guard parent.zoomScale != zoomScale else { return }

            if deferred {
                DispatchQueue.main.async { [weak self] in
                    guard let self, self.parent.zoomScale != zoomScale else { return }
                    self.parent.zoomScale = zoomScale
                }
            } else {
                parent.zoomScale = zoomScale
            }
        }

        /// Centers the hosted view within the scroll view if it's smaller than the scroll view bounds.
        func recenterContent(in scrollView: UIScrollView) {
            guard let view = hostingController?.view else { return }
            let offsetX = max((scrollView.bounds.width - view.frame.width) * 0.5, 0)
            let offsetY = max((scrollView.bounds.height - view.frame.height) * 0.5, 0)
            scrollView.contentInset = UIEdgeInsets(top: offsetY, left: offsetX, bottom: offsetY, right: offsetX)
        }
    }
}
