import SwiftUI

struct CommandGridView: View {
    var body: some View {
        HStack(spacing: 12) {
            // Left Column (RUN / STOP)
            VStack(spacing: 12) {
                CommandButton(
                    title: "RUN",
                    color: .blue,
                    icon: "play.fill"
                ) {
                    sendCommand("run")
                }
                
                CommandButton(
                    title: "STOP",
                    color: .orange,
                    icon: "stop.fill"
                ) {
                    sendCommand("stop")
                }
            }
            
            // Right Column Removed (User request: "I'll press it myself")
        }
        .padding(12)
    }
    
    private func sendCommand(_ action: String) {
        HapticsManager.shared.playImpact()
        NetworkManager.shared.sendCommand(action: action)
    }
}

struct CommandButton: View {
    let title: String
    let color: Color
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                Text(title)
                    .fontWeight(.bold)
            }
            .font(.title3)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(color)
            .foregroundColor(.white)
            .cornerRadius(12)
            .shadow(radius: 2, y: 2)
        }
    }
}
