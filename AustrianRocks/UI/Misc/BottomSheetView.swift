//
//  BottomSheetView.swift
//  Austrian.rocks
//
//  Originally created for Boolder by Nicolas Mondollot on 04/01/2026.
//  Copyright © 2026 Nicolas Mondollot. All rights reserved.
//

import SwiftUI

@available(iOS 26.0, *)
struct BottomSheetView<Content: View>: View {
    @Binding var isPresented: Bool
    var onSwipeUp: (() -> Void)? = nil
    // Overrides the default half-screen height with a smaller initial card.
    var compactHeight: CGFloat? = nil
    // When true, a swipe up grows the sheet to reveal the full content
    // instead of calling onSwipeUp; swiping down collapses it back first.
    var expandable = false
    @ViewBuilder var content: () -> Content

    private func heightWithFallbackForSmallDevices(defaultHeight: CGFloat) -> CGFloat {
        if UIScreen.main.bounds.height <= 667 { // iPhone SE (all generations) & iPhone 8 and earlier
            return 420
        }
        else {
            return defaultHeight
        }
    }

    var body: some View {
        GeometryReader { geo in
            BottomSheetUIKitView(
                isPresented: $isPresented,
                sheetHeight: compactHeight ?? heightWithFallbackForSmallDevices(defaultHeight: geo.size.height * 0.5 + 12),
                expandedHeight: expandable ? max(geo.size.height * 0.8, compactHeight ?? 0) : nil,
                onSwipeUp: onSwipeUp,
                content: content
            )
        }
        .ignoresSafeArea()
    }
}

@available(iOS 26.0, *)
private struct BottomSheetUIKitView<Content: View>: UIViewRepresentable {
    @Binding var isPresented: Bool
    let sheetHeight: CGFloat
    let expandedHeight: CGFloat?
    let onSwipeUp: (() -> Void)?
    @ViewBuilder var content: () -> Content

    func makeUIView(context: Context) -> PassThroughView {
        let view = PassThroughView()
        view.backgroundColor = .clear
        context.coordinator.setupSheet(in: view, content: content, height: sheetHeight, expandedHeight: expandedHeight)
        return view
    }

    func updateUIView(_ uiView: PassThroughView, context: Context) {
        context.coordinator.updatePresentation(isPresented: isPresented)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(isPresented: $isPresented, onSwipeUp: onSwipeUp)
    }

    class Coordinator: NSObject {
        @Binding var isPresented: Bool
        private let onSwipeUp: (() -> Void)?

        private var sheetView: UIView!
        private var hostingController: UIHostingController<Content>?
        private var sheetHeight: CGFloat = 0
        private var expandedHeight: CGFloat? = nil
        private var heightConstraint: NSLayoutConstraint!
        private var isExpanded = false
        private var panGesture: UIPanGestureRecognizer!
        private var isAnimating = false

        private var currentHeight: CGFloat {
            heightConstraint?.constant ?? sheetHeight
        }

        init(isPresented: Binding<Bool>, onSwipeUp: (() -> Void)?) {
            _isPresented = isPresented
            self.onSwipeUp = onSwipeUp
        }

        func setupSheet<C: View>(in containerView: UIView, content: () -> C, height: CGFloat, expandedHeight: CGFloat?) {
            self.sheetHeight = height
            self.expandedHeight = expandedHeight

            sheetView = UIView()
            sheetView.backgroundColor = .clear
            sheetView.translatesAutoresizingMaskIntoConstraints = false
            sheetView.clipsToBounds = true
            sheetView.layer.cornerRadius = 32
            if UIScreen.main.bounds.height <= 667 { // iPhone SE (all generations) & iPhone 8 and earlier
                sheetView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
            }
                
            sheetView.layer.shadowColor = UIColor.black.cgColor
            sheetView.layer.shadowOpacity = 0.15
            sheetView.layer.shadowRadius = 12
            sheetView.layer.shadowOffset = CGSize(width: 0, height: -4)
            
            // Add blur background
            let blurEffect = UIBlurEffect(style: .systemMaterial)
            let blurView = UIVisualEffectView(effect: blurEffect)
            blurView.translatesAutoresizingMaskIntoConstraints = false
            sheetView.addSubview(blurView)
            
            // Add SwiftUI content
            let hosting = UIHostingController(rootView: content() as! C)
            hosting.view.backgroundColor = .clear
            hosting.view.translatesAutoresizingMaskIntoConstraints = false
            sheetView.addSubview(hosting.view)
            self.hostingController = hosting as? UIHostingController<Content>
            
            // Standard grabber capsule: the sheet is resizable/dismissable by
            // drag, so the affordance must be visible (HIG).
            let grabber = UIView()
            grabber.backgroundColor = .tertiaryLabel
            grabber.layer.cornerRadius = 2.5
            grabber.translatesAutoresizingMaskIntoConstraints = false
            grabber.isAccessibilityElement = true
            grabber.accessibilityLabel = NSLocalizedString("sheet.grabber.accessibility", comment: "")
            sheetView.addSubview(grabber)

            containerView.addSubview(sheetView)

            // Width = min(containerWidth, 600), centered
            let preferredWidth = sheetView.widthAnchor.constraint(equalToConstant: 600)
            preferredWidth.priority = UILayoutPriority(999)
            let maxLeading = sheetView.leadingAnchor.constraint(greaterThanOrEqualTo: containerView.leadingAnchor)
            let maxTrailing = sheetView.trailingAnchor.constraint(lessThanOrEqualTo: containerView.trailingAnchor)

            heightConstraint = sheetView.heightAnchor.constraint(equalToConstant: height)

            NSLayoutConstraint.activate([
                blurView.topAnchor.constraint(equalTo: sheetView.topAnchor),
                blurView.leadingAnchor.constraint(equalTo: sheetView.leadingAnchor),
                blurView.trailingAnchor.constraint(equalTo: sheetView.trailingAnchor),
                blurView.bottomAnchor.constraint(equalTo: sheetView.bottomAnchor),

                hosting.view.topAnchor.constraint(equalTo: sheetView.topAnchor),
                hosting.view.leadingAnchor.constraint(equalTo: sheetView.leadingAnchor),
                hosting.view.trailingAnchor.constraint(equalTo: sheetView.trailingAnchor),
                hosting.view.bottomAnchor.constraint(equalTo: sheetView.bottomAnchor),

                grabber.centerXAnchor.constraint(equalTo: sheetView.centerXAnchor),
                grabber.topAnchor.constraint(equalTo: sheetView.topAnchor, constant: 8),
                grabber.widthAnchor.constraint(equalToConstant: 36),
                grabber.heightAnchor.constraint(equalToConstant: 5),

                sheetView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
                maxLeading,
                maxTrailing,
                sheetView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
                heightConstraint,
                preferredWidth
            ])

            // Start off-screen
            sheetView.transform = CGAffineTransform(translationX: 0, y: height)
            
            // Setup pan gesture
            panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
            sheetView.addGestureRecognizer(panGesture)
        }
        
        func updatePresentation(isPresented: Bool) {
            guard !isAnimating else { return }
            
            if isPresented && sheetView.transform.ty > 0 {
                animateIn()
            } else if !isPresented && sheetView.transform.ty == 0 {
                animateOut()
            }
        }
        
        private func animateIn() {
            isAnimating = true
            UIView.animate(
                withDuration: 0.4,
                delay: 0,
                usingSpringWithDamping: 0.85,
                initialSpringVelocity: 0,
                options: .curveEaseOut
            ) {
                self.sheetView.transform = .identity
            } completion: { _ in
                self.isAnimating = false
            }
        }
        
        private func animateOut() {
            isAnimating = true
            UIView.animate(
                withDuration: 0.3,
                delay: 0,
                options: .curveEaseIn
            ) {
                self.sheetView.transform = CGAffineTransform(translationX: 0, y: self.currentHeight)
            } completion: { _ in
                self.resetToCompactOffscreen()
                self.isAnimating = false
            }
        }

        // After a dismissal the next presentation starts at the compact size.
        private func resetToCompactOffscreen() {
            isExpanded = false
            heightConstraint.constant = sheetHeight
            sheetView.superview?.layoutIfNeeded()
            sheetView.transform = CGAffineTransform(translationX: 0, y: sheetHeight)
        }

        private func setExpanded(_ expanded: Bool) {
            guard let expandedHeight else { return }
            isExpanded = expanded
            heightConstraint.constant = expanded ? expandedHeight : sheetHeight
            UIView.animate(
                withDuration: 0.4,
                delay: 0,
                usingSpringWithDamping: 0.85,
                initialSpringVelocity: 0,
                options: .curveEaseOut
            ) {
                self.sheetView.transform = .identity
                self.sheetView.superview?.layoutIfNeeded()
            }
        }
        
        @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
            let translation = gesture.translation(in: sheetView.superview)
            let velocity = gesture.velocity(in: sheetView.superview)
            
            switch gesture.state {
            case .changed:
                if translation.y > 0 {
                    sheetView.transform = CGAffineTransform(translationX: 0, y: translation.y)
                } else {
                    // Rubber band effect
                    let resistance: CGFloat = 0.3
                    sheetView.transform = CGAffineTransform(translationX: 0, y: translation.y * resistance)
                }
                
            case .ended, .cancelled:
                let shouldExpand = translation.y < -120 || velocity.y < -500
                let shouldDismiss = translation.y > 120 || velocity.y > 500

                if shouldExpand {
                    if expandedHeight != nil, !isExpanded {
                        setExpanded(true)
                    } else {
                        onSwipeUp?()
                        UIView.animate(
                            withDuration: 0.4,
                            delay: 0,
                            usingSpringWithDamping: 0.85,
                            initialSpringVelocity: 0,
                            options: .curveEaseOut
                        ) {
                            self.sheetView.transform = .identity
                        }
                    }
                } else if shouldDismiss {
                    if isExpanded {
                        // Step down detent by detent, like a system sheet.
                        setExpanded(false)
                    } else {
                        isAnimating = true
                        UIView.animate(
                            withDuration: 0.3,
                            delay: 0,
                            options: .curveEaseIn
                        ) {
                            self.sheetView.transform = CGAffineTransform(translationX: 0, y: self.currentHeight)
                        } completion: { _ in
                            self.resetToCompactOffscreen()
                            self.isAnimating = false
                            self.isPresented = false
                        }
                    }
                } else {
                    UIView.animate(
                        withDuration: 0.4,
                        delay: 0,
                        usingSpringWithDamping: 0.85,
                        initialSpringVelocity: 0,
                        options: .curveEaseOut
                    ) {
                        self.sheetView.transform = .identity
                    }
                }
                
            default:
                break
            }
        }
    }
}

// A UIView that passes through touches outside of its subviews
private class PassThroughView: UIView {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let hitView = super.hitTest(point, with: event)
        // Only respond to touches on subviews, not on self
        return hitView == self ? nil : hitView
    }
}

