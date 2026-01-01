import SwiftUI

struct InputAreaView: View {
    @State private var text: String = ""
    @State private var clearOnSend: Bool = true
    @State private var isSending: Bool = false
    
    var body: some View {
        VStack(spacing: 8) {
            // Header removed as per request to remove Auto-clear toggle
            // HStack containing Prompt label and Toggle is removed.
            
            HStack(alignment: .bottom) {
                TextEditor(text: $text)
                    .frame(maxHeight: .infinity)
                    .padding(4)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(.separator), lineWidth: 1)
                    )
                
                Button(action: sendMessage) {
                    Group {
                        if isSending {
                            ProgressView()
                        } else {
                            Image(systemName: "paperplane.fill")
                                .font(.title2)
                        }
                    }
                    .frame(width: 44, height: 44)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .disabled(text.isEmpty || isSending)
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .background(Color(.systemBackground))
    }
    
    private func sendMessage() {
        guard !text.isEmpty else { return }
        
        isSending = true
        HapticsManager.shared.playSelection()
        
        NetworkManager.shared.sendType(text: text) { success in
            isSending = false
            if success {
                HapticsManager.shared.playSuccess()
                if clearOnSend {
                    text = ""
                }
            } else {
                HapticsManager.shared.playError()
            }
        }
    }
}
