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
    @Environment(\.dismiss) var dismiss
    @Environment(\.openURL) var openURL
    
    @AppStorage("tweakArray") var tweakArray: [ZeroSection] = TweakArray.tweaks
    
    @AppStorage("useRespringApp") var useRespringApp: Bool = false
    @AppStorage("respringAppBID") var respringAppBID: String = "com.jbdotparty.respringr"
    
    @AppStorage("enableDebugSettings") var enableDebugSettings: Bool = false
    @AppStorage("enableRiskyTweaks") var enableRiskyTweaks: Bool = false
    @AppStorage("showLogs") var showLogs: Bool = true
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: HeaderLabel(text: "Info", icon: "info.circle")) {
                    VStack {
                        AppInfoCell()
                            .frame(maxWidth: .infinity, alignment: .leading)
                        HStack {
                            Button(action: {
                                openURL(URL(string: "https://jailbreak.party/discord")!)
                            }) {
                                ButtonLabel(text: "Discord", icon: "discord", useImage: true)
                            }
                            .buttonStyle(TranslucentButtonStyle(color: .discord))
                            Button(action: {
                                openURL(URL(string: "https://jailbreak.party/discord")!)
                            }) {
                                ButtonLabel(text: "GitHub", icon: "github", useImage: true)
                            }
                            .buttonStyle(TranslucentButtonStyle(color: .gitHub))
                        }
                        Button(action: {
                            openURL(URL(string: "https://jailbreak.party/discord")!)
                        }) {
                            ButtonLabel(text: "Website", icon: "globe")
                        }
                        .buttonStyle(TranslucentButtonStyle(color: .blue))
                    }
                    NavigationLink("Credits", destination: CreditsView())
                }
                Section(header: HeaderLabel(text: "Applying", icon: "checkmark.seal")) {
                    Toggle(isOn: $useRespringApp) {
                        Text("Use Respring App")
                        Text("Only enable this if you prefer using a [seperate app](https://github.com/jailbreakdotparty/dirtyZero/releases/tag/respringr) to respring your device.")
                    }
                    if useRespringApp {
                        TextField("Respring App BID", text: $respringAppBID)
                    }
                }
                Section(header: HeaderLabel(text: "Customizaton", icon: "checklist")) {
                    Toggle("Debug Settings", isOn: $enableDebugSettings)
                    Toggle("Risky Tweaks", isOn: $enableRiskyTweaks)
                    Toggle("Show Logs", isOn: $showLogs)
                    NavigationLink("Customize", destination: CustomizeView(colorOptions: [
                        ColorOption(label: "Default", color: Color.accent),
                        ColorOption(label: "Blue", color: Color.blue),
                        ColorOption(label: "Purple", color: Color.purple),
                        ColorOption(label: "Pink", color: Color.pink),
                        ColorOption(label: "Red", color: Color.red),
                        ColorOption(label: "Orange", color: Color.orange),
                        ColorOption(label: "Yellow", color: Color.yellow),
                        ColorOption(label: "Green", color: Color.green)
                    ]))
                }
                Section(header: HeaderLabel(text: "Data", icon: "externaldrive")) {
                    VStack {
                        Button(action: {
                            tweakArray = TweakArray.tweaks
                        }) {
                            ButtonLabel(text: "Reset Selected Tweaks", icon: "checklist")
                        }
                        .buttonStyle(TranslucentButtonStyle())
                        Button(action: {
                            Alertinator.shared.alert(title: "Are you sure you'd like to remove all your tweaks?", body: "This will remove every tweak that you have created.", action: {
                                let customTweaksIndex = tweakArray.firstIndex(where: { $0.name == "Custom Tweaks" }) ?? 0
                                
                                tweakArray[customTweaksIndex].tweaks.removeAll()
                            })
                        }) {
                            ButtonLabel(text: "Remove Custom Tweaks", icon: "trash")
                        }
                        .buttonStyle(TranslucentButtonStyle(color: .red))
                    }
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                    }
                }
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppTheme())
}

/*
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
                        AppInfoCell()
                        Button(action: {
                            Haptic.shared.play(.soft)
                            openURL(URL(string: "https://jailbreak.party")!)
                        }) {
                            ButtonLabel(text: "Website", icon: "globe")
                        }
                        .buttonStyle(TranslucentButtonStyle(color: .blue))
                        HStack {
                            Button(action: {
                                Haptic.shared.play(.soft)
                                openURL(URL(string: "https://jailbreak.party/discord")!)
                            }) {
                                ButtonLabel(text: "Discord", icon: "discord", useImage: true)
                            }
                            .buttonStyle(TranslucentButtonStyle(color: .discord))
                            Button(action: {
                                Haptic.shared.play(.soft)
                                openURL(URL(string: "https://github.com/jailbreakdotparty/dirtyZero")!)
                            }) {
                                ButtonLabel(text: "GitHub", icon: "github", useImage: true)
                            }
                            .buttonStyle(TranslucentButtonStyle(color: .gitHub))
                        }
                    }
                }
                Section(header: HeaderLabel(text: "Credits", icon: "person")) {
                    LinkCreditCell(image: Image("skadz108"), name: "Skadz", description: "Initial developer, backend, and exploit-related management.", url: "https://github.com/skadz108")
                    LinkCreditCell(image: Image("lunginspector"), name: "lunginspector", description: "Frontend developer, tweak creator, and app UI.", url: "https://github.com/skadz108")
                    LinkCreditCell(image: Image("ianbeer"), name: "Ian Beer (Gooogle Project Zero)", description: "Discovering & publishing CVE-2025-24203.", url: "https://project-zero.issues.chromium.org/issues/391518636")
                    LinkCreditCell(image: Image("neonmodder123"), name: "neonmodder123", description: "Developed WebView respring method.", url: "https://github.com/neonmodder123")
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
                        .buttonStyle(TranslucentButtonStyle(color: .orange))
                        Button(action: {
                            Haptic.shared.play(.heavy)
                            Alertinator.shared.alert(title: "Are you sure you want to do this?", body: "This will permanently remove all custom tweaks that you have created.", actionLabel: "Continue", action: {
                                customTweaks.removeAll()
                            })
                        }) {
                            ButtonLabel(text: "Remove Custom Tweaks", icon: "paintpalette")
                        }
                        .buttonStyle(TranslucentButtonStyle(color: .red))
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
*/
