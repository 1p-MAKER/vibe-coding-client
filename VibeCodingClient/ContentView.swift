import SwiftUI
import Combine

struct ContentView: View {
    @State private var showingSettings = false
    @State private var showingApps = false
    @State private var keyboardHeight: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            let isLandscape = geometry.size.width > geometry.size.height
            
            if isLandscape {
                // Landscape Layout: Side-by-Side (Max Stream / Fixed Controls)
                HStack(spacing: 0) {
                    // Left: Stream (Max Width)
                    StreamView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .clipped()
                        .edgesIgnoringSafeArea(.all)
                    
                    Divider()
                    
                    // Right: Controls (Fixed 70pt)
                    VStack(spacing: 12) {
                        // 1. Settings / Apps Buttons (Moved from Toolbar)
                        VStack(spacing: 16) {
                            Button(action: { showingApps = true }) {
                                Image(systemName: "square.stack.3d.up.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.white)
                                    .frame(width: 44, height: 44)
                                    .background(Color.gray.opacity(0.3))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                            
                            Button(action: { showingSettings = true }) {
                                Image(systemName: "gear")
                                    .font(.system(size: 20))
                                    .foregroundColor(.white)
                                    .frame(width: 44, height: 44)
                                    .background(Color.gray.opacity(0.3))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                        }
                        .padding(.top, 10)
                        
                        Divider()
                            .background(Color.gray)
                        
                        // 2. Prompt Input (Compact)
                        InputAreaView()
                            .frame(maxHeight: .infinity)
                        
                        if keyboardHeight == 0 {
                            Divider()
                                .background(Color.gray)
                            
                            // 3. Command Grid (Compact)
                            CommandGridView()
                                .frame(height: geometry.size.height * 0.4)
                        }
                    }
                    .frame(width: 70) // Fixed Compact Width
                    .background(Color.black) // Ensure background matches
                }
                .navigationBarHidden(true) // Hide top bar
                .edgesIgnoringSafeArea(.all)
            } else {
                // Portrait Layout: Vertical Stack (Keep Toolbar)
                VStack(spacing: 0) {
                    // Top Area: Stream
                    // Adjust height: If keyboard is up, give it remaining space after Input
                    let inputHeight = geometry.size.height * 0.20
                    let commandHeight = keyboardHeight > 0 ? 0 : geometry.size.height * 0.20 // Hide commands when typing
                    let streamHeight = geometry.size.height - inputHeight - commandHeight
                    
                    StreamView()
                        .frame(height: max(0, streamHeight))
                        .clipped()
                    
                    Divider()
                    
                    // Middle Area: Prompt Input
                    InputAreaView()
                        .frame(height: inputHeight)
                    
                    if keyboardHeight == 0 {
                        Divider()
                        
                        // Bottom Area: Command Grid
                        CommandGridView()
                            .frame(height: commandHeight)
                            .transition(.move(edge: .bottom))
                    }
                }
                .animation(.easeOut(duration: 0.25), value: keyboardHeight)
                .toolbar {
                     ToolbarItem(placement: .topBarTrailing) {
                         HStack {
                             Button(action: { showingApps = true }) {
                                 Image(systemName: "square.stack.3d.up.fill")
                             }
                             Button(action: { showingSettings = true }) {
                                 Image(systemName: "gear")
                             }
                         }
                     }
                     ToolbarItem(placement: .keyboard) {
                         HStack {
                             Spacer()
                             Button("Done") {
                                 hideKeyboard()
                             }
                         }
                     }
                 }
            }
        }
        .onReceive(Publishers.keyboardHeight) { self.keyboardHeight = $0 }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showingApps) {
            AppSwitcherView()
        }
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

extension Publishers {
    static var keyboardHeight: AnyPublisher<CGFloat, Never> {
        let willShow = NotificationCenter.default.publisher(for: UIApplication.keyboardWillShowNotification)
            .map { $0.keyboardHeight }
        
        let willHide = NotificationCenter.default.publisher(for: UIApplication.keyboardWillHideNotification)
            .map { _ in CGFloat(0) }
        
        return Merge(willShow, willHide)
            .eraseToAnyPublisher()
    }
}

extension Notification {
    var keyboardHeight: CGFloat {
        return (userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect)?.height ?? 0
    }
}
