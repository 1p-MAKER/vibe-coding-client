import Foundation
import Combine
import SwiftUI

class NetworkManager: ObservableObject {
    static let shared = NetworkManager()
    
    @Published var hostIP: String = "" {
        didSet {
            UserDefaults.standard.set(hostIP, forKey: "hostIP")
        }
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    var baseURL: URL? {
        if hostIP.isEmpty { return nil }
        return URL(string: "http://\(hostIP):8000")
    }
    
    private init() {
        self.hostIP = UserDefaults.standard.string(forKey: "hostIP") ?? ""
    }
    
    func sendScroll(delta: CGFloat) {
        guard let url = baseURL?.appendingPathComponent("action/scroll") else { return }
        
        let body: [String: CGFloat] = ["delta": delta]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTaskPublisher(for: request)
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &cancellables)
    }
    
    func sendType(text: String, completion: @escaping (Bool) -> Void) {
        guard let url = baseURL?.appendingPathComponent("action/type") else {
            completion(false)
            return
        }
        
        let body: [String: String] = ["text": text]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTaskPublisher(for: request)
            .map { $0.response as? HTTPURLResponse }
            .sink(receiveCompletion: { result in
                switch result {
                case .finished:
                    break
                case .failure:
                    DispatchQueue.main.async { completion(false) }
                }
            }, receiveValue: { response in
                DispatchQueue.main.async {
                    completion(response?.statusCode == 200)
                }
            })
            .store(in: &cancellables)
    }
    
    func sendCommand(action: String) {
        guard let url = baseURL?.appendingPathComponent("action/command") else { return }
        
        let body: [String: String] = ["command": action]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTaskPublisher(for: request)
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &cancellables)
    }
    
    func getStreamURL() -> URL? {
        return baseURL?.appendingPathComponent("stream")
    }
    
    // MARK: - App Management
    
    struct AppListResponse: Codable {
        let apps: [String]
    }
    
    @Published var appFetchError: String? = nil
    
    // ...
    
    func fetchApps(completion: @escaping ([String]) -> Void) {
        self.appFetchError = nil // Reset error
        
        guard let url = baseURL?.appendingPathComponent("apps") else {
            self.appFetchError = "Invalid URL"
            completion([])
            return
        }
        
        URLSession.shared.dataTaskPublisher(for: url)
            .map { $0.data }
            .decode(type: AppListResponse.self, decoder: JSONDecoder())
            .map { $0.apps }
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completionStatus in
                switch completionStatus {
                case .finished:
                    break
                case .failure(let error):
                    print("Error fetching apps: \(error)")
                    self.appFetchError = error.localizedDescription
                    completion([])
                }
            }, receiveValue: { apps in
                self.appFetchError = nil
                completion(apps)
            })
            .store(in: &cancellables)
    }
    
    func activateApp(name: String) {
        guard let url = baseURL?.appendingPathComponent("action/activate") else { return }
        
        let body: [String: String] = ["app_name": name]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTaskPublisher(for: request)
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &cancellables)
    }
    
    // MARK: - Cursor Control
    
    func sendMove(x: Double, y: Double, click: Bool = true) {
        guard let url = baseURL?.appendingPathComponent("action/move") else { return }
        
        // Ensure coordinates are within 0.0 - 1.0
        let clampedX = max(0.0, min(1.0, x))
        let clampedY = max(0.0, min(1.0, y))
        
        let body: [String: Any] = ["x": clampedX, "y": clampedY, "click": click]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTaskPublisher(for: request)
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &cancellables)
    }
    
    struct ScreenSizeResponse: Codable {
        let width: Double
        let height: Double
    }
    
    func fetchScreenSize(completion: @escaping (CGSize?) -> Void) {
        guard let url = baseURL?.appendingPathComponent("screen_size") else {
            completion(nil)
            return
        }
        
        URLSession.shared.dataTaskPublisher(for: url)
            .map { $0.data }
            .decode(type: ScreenSizeResponse.self, decoder: JSONDecoder())
            .replaceError(with: ScreenSizeResponse(width: 0, height: 0))
            .receive(on: DispatchQueue.main)
            .sink { response in
                if response.width > 0 && response.height > 0 {
                    completion(CGSize(width: response.width, height: response.height))
                } else {
                    completion(nil)
                }
            }
            .store(in: &cancellables)
    }
    
    func sendRightClick() {
        guard let url = baseURL?.appendingPathComponent("action/right_click") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        URLSession.shared.dataTaskPublisher(for: request)
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &cancellables)
    }
    
    func sendForceQuit() {
        sendCommand(action: "force_quit")
    }
}
