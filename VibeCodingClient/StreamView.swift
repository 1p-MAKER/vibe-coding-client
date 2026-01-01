import SwiftUI
import WebKit

struct StreamView: View {
    @ObservedObject var networkManager = NetworkManager.shared
    
    // Zoom & Pan State
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    @State private var cursorNormalizedPos: CGPoint = CGPoint(x: 0.5, y: 0.5)
    
    // Throttling for Move/Scroll
    @State private var lastMoveTime: Date = Date()
    @State private var lastScrollTime: Date = Date()
    @State private var lastScrollTranslation: CGFloat = 0
    
    @State private var remoteAspectRatio: CGFloat? = 16.0 / 9.0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .trailing) {
                // 1. Stream Content
                ZStack {
                    // We need a GeometryReader INSIDE the aspect-ratio constrained view
                    // to get the actual size of the video frame for touch normalization.
                    GeometryReader { innerGeo in
                        ZStack {
                            WebView(url: networkManager.getStreamURL())
                                .id(networkManager.getStreamURL())
                            
                            // Virtual Cursor Overlay
                            ZStack {
                                Circle()
                                    .stroke(Color.red, lineWidth: 2)
                                    .frame(width: 30, height: 30)
                                
                                // Crosshair lines
                                Path { path in
                                    path.move(to: CGPoint(x: 15, y: 0))
                                    path.addLine(to: CGPoint(x: 15, y: 30))
                                    path.move(to: CGPoint(x: 0, y: 15))
                                    path.addLine(to: CGPoint(x: 30, y: 15))
                                }
                                .stroke(Color.red, lineWidth: 1)
                                .frame(width: 30, height: 30)
                            }
                            .position(
                                // Visual Correction: Shift Red Circle Right/Down to cover the Mac Arrow body
                                // The Mac Arrow tip is at (normX, normY). The body is to the right/down.
                                // We shift the overlay +12px so the Circle centers on the Arrow body.
                                x: (cursorNormalizedPos.x * innerGeo.size.width) + (12 / scale),
                                y: (cursorNormalizedPos.y * innerGeo.size.height) + (12 / scale)
                            )
                            .shadow(color: .black, radius: 1, x: 0, y: 0)
                            .allowsHitTesting(false)
                            
                            // Touch Control Overlay
                            TouchControlView(
                                onCursorMove: { location in
                                    handleMove(location: location, viewSize: innerGeo.size)
                                },
                                onClick: { location in
                                    handleClick(location: location, viewSize: innerGeo.size)
                                },
                                onViewPan: { translation in
                                    if scale > 1.0 {
                                        offset = CGSize(
                                            width: lastOffset.width + translation.width,
                                            height: lastOffset.height + translation.height
                                        )
                                    }
                                },
                                onViewPanEnded: {
                                    if scale > 1.0 {
                                        lastOffset = offset
                                    }
                                },
                                onViewZoom: { zoomScale in
                                    let delta = zoomScale / lastScale
                                    lastScale = zoomScale
                                    scale *= delta
                                    scale = min(max(scale, 1.0), 5.0)
                                },
                                onViewZoomEnded: {
                                    lastScale = 1.0
                                    if scale < 1.0 {
                                        scale = 1.0
                                        offset = .zero
                                        lastOffset = .zero
                                    }
                                }
                            )
                        }
                    }
                }
                .aspectRatio(remoteAspectRatio, contentMode: .fit) // Force Aspect Ratio
                .scaleEffect(scale)
                .offset(offset)
                .onAppear {
                    networkManager.fetchScreenSize { size in
                        if let size = size {
                            remoteAspectRatio = size.width / size.height
                        }
                    }
                }
                .onChange(of: networkManager.hostIP) { _ in
                    networkManager.fetchScreenSize { size in
                         if let size = size {
                             remoteAspectRatio = size.width / size.height
                         }
                    }
                }
                
                // 2. Scroll Slider Overlay (Right Edge)
                GeometryReader { sliderGeo in
                    HStack {
                        Spacer()
                        ZStack(alignment: .top) {
                            // Track
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.4))
                                .frame(width: 40) // Slider Width
                                .overlay(
                                    VStack {
                                        Image(systemName: "arrow.up.and.down")
                                        .foregroundColor(.white)
                                        .font(.title2)
                                        .padding(.top, 20)
                                        Spacer()
                                        Image(systemName: "arrow.up.and.down")
                                        .foregroundColor(.white)
                                        .font(.title2)
                                        .padding(.bottom, 20)
                                    }
                                )
                            
                            // Touch Handling
                            Color.clear
                                .contentShape(Rectangle())
                        }
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    handleScroll(currentTranslation: value.translation.height)
                                }
                                .onEnded { _ in
                                    lastScrollTranslation = 0
                                }
                        )
                    }
                }
                .frame(width: 60) // Container width
                .padding(.trailing, 0)
                
                // 4. Center Cursor & Right Click Buttons (Floating)
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        
                        
                        // Center Cursor Button (Scope)
                        Button(action: {
                            centerCursor(viewSize: geometry.size)
                        }) {
                                Image(systemName: "scope")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                                .frame(width: 50, height: 50)
                                .background(Color.blue.opacity(0.8))
                                .clipShape(Circle())
                                .shadow(radius: 4)
                        }
                        .padding(.trailing, 60) // Left of scroll slider
                        .padding(.bottom, 20)
                    }
                }
            }
            .clipped()
        }
    }
    
    // MARK: - Logic
    
    private func centerCursor(viewSize: CGSize) {
        // Formula: Norm = 0.5 - (Offset / (Size * Scale))
        let normalizedX = 0.5 - (offset.width / (viewSize.width * scale))
        let normalizedY = 0.5 - (offset.height / (viewSize.height * scale))
        
        // Update Local State
        cursorNormalizedPos = CGPoint(x: normalizedX, y: normalizedY)
        
        NetworkManager.shared.sendMove(x: Double(normalizedX), y: Double(normalizedY), click: false)
        HapticsManager.shared.playSelection()
    }
    
    private func handleMove(location: CGPoint, viewSize: CGSize) {
        let now = Date()
        if now.timeIntervalSince(lastMoveTime) < 0.03 { return }
        lastMoveTime = now
        
        sendNormalizedMove(location: location, viewSize: viewSize, click: false)
    }
    
    private func handleClick(location: CGPoint, viewSize: CGSize) {
        sendNormalizedMove(location: location, viewSize: viewSize, click: true)
        HapticsManager.shared.playSelection()
    }
    
    private func sendNormalizedMove(location: CGPoint, viewSize: CGSize, click: Bool) {
        // Since TouchControlView is inside the scaled/panned ZStack, 
        // 'location' and 'viewSize' are already local to the content.
        
        // 1. Apply Offset (User Request: "Cursor slightly above finger")
        // We apply a fixed SCREEN offset (-20, -50), adjusted by scale so it remains visually constant.
        let screenOffsetX: CGFloat = -20
        let screenOffsetY: CGFloat = -50
        
        // This 'adjustedLocation' is where the Cursor (and Mouse) should actually BE.
        let adjustedX = location.x + (screenOffsetX / scale)
        let adjustedY = location.y + (screenOffsetY / scale)
        
        // 2. Normalize based on the view size (Content Size)
        let normalizedX = adjustedX / viewSize.width
        let normalizedY = adjustedY / viewSize.height
        
        // 3. Update Local Overlay (Red Circle)
        // VISUAL FIX for ZOOM:
        // The Mac Arrow (Video) scales with the view (zoom).
        // To keep the Red Circle centered on the Arrow Body, the offset must be in VIEW COORDINATES (not screen).
        // We add +10pt (base view units). When zoomed 2x, this becomes 20 screen pixels, matching the 2x Arrow size.
        let visualOffset: CGFloat = 10
        
        // Note: adjustedX/Y are in view coordinates. We add the fixed offset directly.
        let visualX = adjustedX + visualOffset
        let visualY = adjustedY + visualOffset
        
        cursorNormalizedPos = CGPoint(x: visualX / viewSize.width, y: visualY / viewSize.height)
        
        // 4. Send to Server (Mac Mouse Tip)
        // We send the normalized coordinates of the TIP.
        NetworkManager.shared.sendMove(x: Double(normalizedX), y: Double(normalizedY), click: click)
    }
    
    private func handleScroll(currentTranslation: CGFloat) {
        let now = Date()
        if now.timeIntervalSince(lastScrollTime) < 0.05 { return }
        lastScrollTime = now
        
        // Calculate delta
        let delta = currentTranslation - lastScrollTranslation
        lastScrollTranslation = currentTranslation
        
        // Send scroll
        NetworkManager.shared.sendScroll(delta: delta)
    }
}

struct WebView: UIViewRepresentable {
    let url: URL?
    
    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        
        // Inject scaling logic into the MJPEG stream page
        let scalingScript = """
        var meta = document.createElement('meta');
        meta.name = 'viewport';
        meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';
        document.getElementsByTagName('head')[0].appendChild(meta);
        
        var style = document.createElement('style');
        style.innerHTML = 'body { margin: 0; background-color: black; display: flex; justify-content: center; align-items: center; height: 100vh; overflow: hidden; } img { width: 100%; height: 100%; object-fit: fill; }';
        document.head.appendChild(style);
        """
        
        let userScript = WKUserScript(source: scalingScript, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        configuration.userContentController.addUserScript(userScript)
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.scrollView.isScrollEnabled = false // Disable native scroll
        webView.isOpaque = false
        webView.backgroundColor = .black
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        if let url = url {
            if context.coordinator.lastLoadedURL != url {
                let request = URLRequest(url: url)
                webView.load(request)
                context.coordinator.lastLoadedURL = url
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator {
        var lastLoadedURL: URL?
    }
}

