import SwiftUI

struct AppSwitcherView: View {
    @ObservedObject var networkManager = NetworkManager.shared // Observe for errors
    @State private var apps: [String] = []
    @State private var isLoading = true
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            List {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else if let error = networkManager.appFetchError {
                    VStack(alignment: .leading) {
                        Text("Error Loading Apps")
                            .font(.headline)
                            .foregroundColor(.red)
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Button("Retry") {
                            loadApps()
                        }
                        .padding(.top, 4)
                    }
                } else if apps.isEmpty {
                    VStack {
                         Text("No apps found")
                            .foregroundColor(.secondary)
                         Button("Retry") {
                             loadApps()
                         }
                         .padding(.top, 4)
                    }
                } else {
                    ForEach(apps, id: \.self) { appName in
                        Button(action: {
                            activateApp(appName)
                        }) {
                            HStack {
                                Text(appName)
                                    .fontWeight(.medium)
                                Spacer()
                                Image(systemName: "arrow.up.right.square")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Switch Application")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .onAppear {
                loadApps()
            }
        }
    }
    
    private func loadApps() {
        isLoading = true
        NetworkManager.shared.fetchApps { fetchedApps in
            self.apps = fetchedApps
            self.isLoading = false
        }
    }
    
    private func activateApp(_ name: String) {
        HapticsManager.shared.playSuccess()
        NetworkManager.shared.activateApp(name: name)
        presentationMode.wrappedValue.dismiss()
    }
}
