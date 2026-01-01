import SwiftUI

struct SettingsView: View {
    @ObservedObject var networkManager = NetworkManager.shared
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("接続設定")) {
                    TextField("MacのIPアドレス", text: $networkManager.hostIP)
                        .keyboardType(.numbersAndPunctuation)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    
                    if let url = networkManager.getStreamURL() {
                        Text("配信URL: \(url.absoluteString)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section(header: Text("緊急操作")) {
                    Button(action: {
                        networkManager.sendForceQuit()
                        HapticsManager.shared.playNotification()
                    }) {
                        Label("強制終了 (Opt+Cmd+Esc)", systemImage: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                    }
                }
                
                Section(header: Text("画質設定")) {
                    Toggle("高画質モード", isOn: .constant(true))
                        .disabled(true)
                    Text("画質は現在サーバー側で最適化されています。")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Section(header: Text("操作説明")) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("• 2本指ドラッグ: 画面移動 (Pan)")
                        Text("• ピンチ: 拡大/縮小")
                        Text("• 青ボタン(Scope): カーソルを画面中央へ")
                        Text("• 再生ボタン: ビルド & 実行 (Cmd+R)")
                        Text("• 停止ボタン: 実行停止 (Cmd+.)")
                    }
                    .font(.footnote)
                    .foregroundColor(.secondary)
                }
                
                Section {
                    Button("完了") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .navigationTitle("設定")
        }
    }
}
