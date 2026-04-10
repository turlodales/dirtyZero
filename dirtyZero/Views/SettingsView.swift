//
//  SettingsView.swift
//  dirtyZero
//
//  Created by Main on 10/8/25.
//

import SwiftUI
import PartyUI
import DeviceKit

struct SettingsView: View {
    @AppStorage("enabledTweaks") private var enabledTweakIds: [String] = []
    @AppStorage("customTweaks") private var customTweaks: [ZeroTweak] = []
    @AppStorage("showLogs") var showLogs: Bool = true
    @AppStorage("showDebugSettings") var showDebugSettings: Bool = false
    @AppStorage("showRiskyTweaks") var showRiskyTweaks: Bool = false
    @AppStorage("useRespringApp") var useRespringApp: Bool = false
    @AppStorage("respringAppBID") var respringAppBID: String = "com.jbdotparty.respringr"
    @AppStorage("changeRespringAppBID") var changeRespringAppBundleID: Bool = false
    @Environment(\.openURL) var openURL
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: HeaderLabel(text: "About", icon: "info.circle")) {
                    VStack(spacing: 10) {
                        AppInfoCell(imageName: "dirtyZero", title: "dirtyZero", subtitle: "Version \(UIApplication.appVersion!) (\(weOnADebugBuild ? "Debug" : "Release"))")
                        Button(action: {
                            Haptic.shared.play(.soft)
                            openURL(URL(string: "https://jailbreak.party")!)
                        }) {
                            ButtonLabel(text: "Website", icon: "globe")
                        }
                        .buttonStyle(GlassyButtonStyle(color: .blue))
                        HStack {
                            Button(action: {
                                Haptic.shared.play(.soft)
                                openURL(URL(string: "https://jailbreak.party/discord")!)
                            }) {
                                ButtonLabel(text: "Discord", icon: "discord", isRegularImage: true)
                            }
                            .buttonStyle(GlassyButtonStyle(color: .discord))
                            Button(action: {
                                Haptic.shared.play(.soft)
                                openURL(URL(string: "https://github.com/jailbreakdotparty/dirtyZero")!)
                            }) {
                                ButtonLabel(text: "GitHub", icon: "github", isRegularImage: true)
                            }
                            .buttonStyle(GlassyButtonStyle(color: .gitHub))
                        }
                    }
                }
                Section(header: HeaderLabel(text: "Credits", icon: "person")) {
                    LinkCreditCell(image: "skadz108", name: "Skadz", text: "Initial developer, backend, and exploit-related management.", link: "https://github.com/skadz108")
                    LinkCreditCell(image: "lunginspector", name: "lunginspector", text: "Frontend developer, tweak creator, and app UI.", link: "https://github.com/skadz108")
                    LinkCreditCell(image: "ianbeer", name: "Ian Beer (Gooogle Project Zero)", text: "Discovering & publishing CVE-2025-24203.", link: "https://project-zero.issues.chromium.org/issues/391518636")
                    LinkCreditCell(image: "neonmodder123", name: "neonmodder123", text: "Developed WebView respring method.", link: "https://github.com/neonmodder123")
                }
                Section(header: HeaderLabel(text: "Settings", icon: "gearshape"), footer: Text("If you are unable to respring using the WebView method, you can try the old RespringApp method. Requires [respringr](https://github.com/jailbreakdotparty/dirtyZero/releases/tag/respringr) installed.")) {
                    Toggle("Show Risky Tweaks", isOn: $showRiskyTweaks)
                        .disabled(weOnADebugBuild)
                    Toggle("Show Debug Settings", isOn: $showDebugSettings)
                        .disabled(weOnADebugBuild)
                    Toggle("Show Logs", isOn: $showLogs)
                    Toggle("Use RespringApp", isOn: $useRespringApp)
                }
                Section(header: HeaderLabel(text: "Actions", icon: "hammer")) {
                    VStack(spacing: 10) {
                        Button(action: {
                            Haptic.shared.play(.heavy)
                            enabledTweakIds.removeAll()
                        }) {
                            ButtonLabel(text: "Reset Selected Tweaks", icon: "trash")
                        }
                        .buttonStyle(GlassyButtonStyle(color: .orange))
                        Button(action: {
                            Haptic.shared.play(.heavy)
                            Alertinator.shared.alert(title: "Are you sure you want to do this?", body: "This will permanently remove all custom tweaks that you have created.", actionLabel: "Continue", action: {
                                customTweaks.removeAll()
                            })
                        }) {
                            ButtonLabel(text: "Remove Custom Tweaks", icon: "paintpalette")
                        }
                        .buttonStyle(GlassyButtonStyle(color: .red))
                    }
                    if useRespringApp {
                        Toggle("Change Respring App Bundle ID", isOn: $changeRespringAppBundleID)
                        if changeRespringAppBundleID {
                            TextField("Respring App Bundle ID", text: $respringAppBID)
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                    }
                }
            }
        }
    }
}

#Preview {
    SettingsView()
}
