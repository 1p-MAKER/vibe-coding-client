import SwiftUI
import UIKit

struct TouchControlView: UIViewRepresentable {
    // Callbacks for gestures
    var onCursorMove: (CGPoint) -> Void
    var onClick: (CGPoint) -> Void
    var onViewPan: (CGSize) -> Void
    var onViewPanEnded: () -> Void
    var onViewZoom: (CGFloat) -> Void
    var onViewZoomEnded: () -> Void
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        view.isMultipleTouchEnabled = true
        
        // 1. One-Finger Pan (Cursor Move)
        let oneFingerPan = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleOneFingerPan(_:)))
        oneFingerPan.maximumNumberOfTouches = 1
        oneFingerPan.delegate = context.coordinator
        view.addGestureRecognizer(oneFingerPan)
        
        // 2. Tap (Click)
        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        tap.numberOfTouchesRequired = 1
        view.addGestureRecognizer(tap)
        
        // 3. Two-Finger Pan (View Pan)
        let twoFingerPan = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTwoFingerPan(_:)))
        twoFingerPan.minimumNumberOfTouches = 2
        twoFingerPan.maximumNumberOfTouches = 2
        twoFingerPan.delegate = context.coordinator
        view.addGestureRecognizer(twoFingerPan)
        
        // 4. Pinch (Zoom)
        let pinch = UIPinchGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePinch(_:)))
        pinch.delegate = context.coordinator
        view.addGestureRecognizer(pinch)
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var parent: TouchControlView
        
        init(_ parent: TouchControlView) {
            self.parent = parent
        }
        
        // MARK: - Gesture Handlers
        
        @objc func handleOneFingerPan(_ gesture: UIPanGestureRecognizer) {
            let location = gesture.location(in: gesture.view)
            parent.onCursorMove(location)
        }
        
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            let location = gesture.location(in: gesture.view)
            parent.onClick(location)
        }
        
        @objc func handleTwoFingerPan(_ gesture: UIPanGestureRecognizer) {
            if gesture.state == .changed {
                let translation = gesture.translation(in: gesture.view)
                parent.onViewPan(CGSize(width: translation.x, height: translation.y))
            } else if gesture.state == .ended || gesture.state == .cancelled {
                parent.onViewPanEnded()
            }
        }
        
        @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
            if gesture.state == .changed {
                parent.onViewZoom(gesture.scale)
            } else if gesture.state == .ended || gesture.state == .cancelled {
                parent.onViewZoomEnded()
            }
        }
        
        // MARK: - Delegate (Conflict Resolution)
        
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            
            // Allow Two-Finger Pan and Pinch together
            if (gestureRecognizer is UIPanGestureRecognizer && (gestureRecognizer as! UIPanGestureRecognizer).minimumNumberOfTouches == 2) &&
                otherGestureRecognizer is UIPinchGestureRecognizer {
                return true
            }
            if (gestureRecognizer is UIPinchGestureRecognizer) &&
                (otherGestureRecognizer is UIPanGestureRecognizer && (otherGestureRecognizer as! UIPanGestureRecognizer).minimumNumberOfTouches == 2) {
                return true
            }
            
            return false
        }
        
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            // One-finger Pan should fail if Two-finger Pan is detected?
            // Or rather: If we have 2 touches, One-Finger pan shouldn't fire.
            // But `maximumNumberOfTouches = 1` sets that constraint naturally? 
            // Often touches begin as 1 and become 2.
            
            // If One-Finger Pan sees a second touch, it usually fails or cancels.
            return false
        }
    }
}
