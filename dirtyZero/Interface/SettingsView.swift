//
//  SettingsView.swift
//  dirtyZero
//
//  Created by lunginspector on 10/8/25.
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
                    NavigationLink("Credits") {
                        List {
                            LinkCreditCell(image: Image("skadz108"), name: "Skadz", description: "Initial developer, backend, and exploit-related management.", url: "https://github.com/skadz108")
                            LinkCreditCell(image: Image("lunginspector"), name: "lunginspector", description: "Frontend developer, tweak creator, and app UI.", url: "https://github.com/skadz108")
                            LinkCreditCell(image: Image("ianbeer"), name: "Ian Beer (Gooogle Project Zero)", description: "Discovering & publishing CVE-2025-24203.", url: "https://project-zero.issues.chromium.org/issues/391518636")
                            LinkCreditCell(image: Image("neonmodder123"), name: "neonmodder123", description: "Developed WebView respring method.", url: "https://github.com/neonmodder123")
                        }
                        .navigationTitle("Credits")
                    }
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
}
