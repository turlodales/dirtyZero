//
//  ContentView.swift
//  dirtyZero
//
//  Created by Skadz on 5/8/25.
//

import SwiftUI
import PartyUI
import DeviceKit
import UIKit

enum SectionType {
    case custom, risky, normal
}

struct ContentView: View {
    @EnvironmentObject var mgr: dirtyZeroManager
    @EnvironmentObject var theme: AppTheme
    
    @AppStorage("tweakArray") var tweakArray: [ZeroSection] = TweakArray.tweaks
    
    @AppStorage("enableDebugSettings") var enableDebugSettings: Bool = false
    @AppStorage("enableRiskyTweaks") var enableRiskyTweaks: Bool = false
    @AppStorage("showLogs") var showLogs: Bool = true
    
    @State private var customZeroPath: String = ""
    
    @State private var showSettingsView: Bool = false
    @State private var showCustomTweaksView: Bool = false
    @State private var showTweakInfoView: Bool = false
    
    @State private var selectedTweak: ZeroTweak = ZeroTweak(name: "", icon: "", paths: [])
    
    let version = doubleSystemVersion()
    
    var body: some View {
        NavigationStack {
            if UIDevice.current.userInterfaceIdiom == .phone {
                List {
                    ApplyingSection
                        .listRowSeparator(.hidden)
                    if enableDebugSettings {
                        DebuggingSection
                            .listRowSeparator(.hidden)
                    }
                    ListedTweaksSection
                        .listRowSeparator(.hidden)
                }
                .listStyle(.plain)
                .navigationTitle("dirtyZero")
                .safeAreaInset(edge: .bottom) {
                    ApplyingButtons
                        .modifier(OverlayBackground())
                }
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button(action: { showSettingsView.toggle() }) {
                            Image(systemName: "gear")
                        }
                        .modifier(SolariumButtonTint())
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(action: { showCustomTweaksView.toggle() }) {
                            Image(systemName: "paintbrush")
                        }
                        .modifier(SolariumButtonTint())
                    }
                }
            } else {
                
            }
        }
        .onChange(of: tweakArray) { _ in
            let tweaks = tweakArray.flatMap { $0.tweaks }
            mgr.enabledTweaks = tweaks.filter { $0.isOn }.count
        }
        .onAppear {
            let tweaks = tweakArray.flatMap { $0.tweaks }
            mgr.enabledTweaks = tweaks.filter { $0.isOn }.count
        }
        .sheet(isPresented: $showSettingsView) {
            SettingsView()
        }
        .sheet(isPresented: $showCustomTweaksView) {
            CustomTweaksView()
        }
        .sheet(isPresented: $showTweakInfoView) {
            TweakInfoView(tweak: selectedTweak)
        }
    }
    
    // MARK: Applying Section
    private var ApplyingSection: some View {
        Section(header: HeaderLabel(text: "Logs", icon: "terminal")) {
            VStack {
                VStack(alignment: .leading) {
                    HStack {
                        HStack {
                            Image(systemName: mgr.applyIcon)
                            Text(mgr.applyShortStatus)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .fontWeight(.semibold)
                        }
                        Text("\(mgr.applyCurrentTweak)/\(mgr.enabledTweaks)")
                    }
                }
                .tint(mgr.applyColor)
                if showLogs {
                    LogView()
                        .modifier(TerminalPlatter())
                } else {
                    Text(mgr.applyStatus)
                }
            }
            .modifier(SectionPlatter())
        }
        .listRowInsets(.dropdownRowInsets)
    }
    
    // MARK: Debugging Section
    private var DebuggingSection: some View {
        Section(header: HeaderLabel(text: "Debugging", icon: "ant")) {
            HStack {
                TextField("Custom Path", text: $customZeroPath)
                    .modifier(PrimaryTextFieldStyle())
                Button(action: {
                    do {
                        try zeroPoC(path: customZeroPath)
                    } catch {
                        print("[!] failed to zero custom path at \(customZeroPath): \(error)")
                    }
                }) {
                    Image(systemName: "checkmark")
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(TranslucentButtonStyle(color: .green, useFullWidth: false))
                .disabled(customZeroPath.isEmpty)
            }
            Button(action: {
                tweakArray = TweakArray.tweaks
            }) {
                HeaderLabel(text: "Obliterate AppStorage", icon: "flame")
            }
            .buttonStyle(TranslucentButtonStyle(color: .red))
        }
        .listRowInsets(.dropdownRowInsets)
    }
    
    // MARK: Listed Tweaks Section
    // i hate this whole section a lot, but breaking this up into three seperate arrays would suck for management. this is likely the best solution.
    private var ListedTweaksSection: some View {
        Group {
            ForEach($tweakArray) { $section in
                let sectionType: SectionType = section.name == "Custom Tweaks" ? .custom : section.name == "Risky Tweaks" ? .risky : .normal
                
                if sectionType == .risky && enableRiskyTweaks || sectionType != .risky && !section.tweaks.isEmpty {
                    Section(header: HeaderDropdown(text: section.name, icon: section.icon, isExpanded: $section.isExpanded, useItemCount: true, itemCount: section.tweaks.count)) {
                        if section.isExpanded {
                            let sectionColor = sectionType == .custom ? .purple : sectionType == .risky ? .red : theme.accentColor
                            
                            withAnimation {
                                ForEach($section.tweaks) { $tweak in
                                    if version >= tweak.minSupportedVersion && version <= tweak.maxSupportedVersion || enableDebugSettings {
                                        Button(action: {
                                            tweak.isOn.toggle()
                                        }) {
                                            HStack(spacing: 10) {
                                                Image(systemName: tweak.icon)
                                                    .frame(width: 22, height: 20)
                                                Text(tweak.name)
                                                    .frame(maxWidth: .infinity, alignment: .leading)
                                                BindedCheckmark(isOn: $tweak.isOn)
                                            }
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                        }
                                        .buttonStyle(PlatterButtonStyle(color: sectionColor))
                                        .listRowSeparator(.hidden)
                                        .listRowInsets(.dropdownRowInsets)
                                        .contextMenu {
                                            Button(action: {
                                                Alertinator.shared.alert(title: "\(tweak.name)", body: "\(tweak.paths)")
                                            }) {
                                                Label("Target Paths", systemImage: "folder")
                                            }
                                            .modifier(SolariumButtonTint())
                                        }
                                        .swipeActions {
                                            Button(action: {
                                                selectedTweak = tweak
                                                showTweakInfoView.toggle()
                                            }) {
                                                Image(systemName: "info.circle")
                                            }
                                            if sectionType == .custom {
                                                Button(action: {
                                                    let customTweaksIndex = tweakArray.firstIndex(where: { $0.name == "Custom Tweaks" }) ?? 0
                                                    
                                                    tweakArray[customTweaksIndex].tweaks.removeAll { $0.name == tweak.name }
                                                }) {
                                                    Image(systemName: "trash")
                                                }
                                                .tint(.red)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: Applying Buttons
    private var ApplyingButtons: some View {
        VStack {
            Button(action: {
                mgr.applyTweaks(tweakData: tweakArray)
            }) {
                ButtonLabel(text: "Apply Tweaks", icon: "checkmark")
            }
            .buttonStyle(TranslucentButtonStyle(color: .green))
            HStack {
                Button(action: {
                    mgr.revertTweaks()
                }) {
                    ButtonLabel(text: "Revert", icon: "xmark")
                }
                .buttonStyle(TranslucentButtonStyle(color: .red))
                Button(action: {
                    mgr.respringDevice()
                }) {
                    ButtonLabel(text: "Respring", icon: "goforward")
                }
                .buttonStyle(TranslucentButtonStyle(color: .orange))
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(dirtyZeroManager())
        .environmentObject(AppTheme())
}

/*
struct ZeroTweak: Identifiable, Codable, Equatable {
    var id: String { name }
    var icon: String
    var name: String
    var minSupportedVersion: Double
    var maxSupportedVersion: Double
    var paths: [String]
    
    enum CodingKeys: String, CodingKey {
        case icon, name, minSupportedVersion, maxSupportedVersion, paths
    }
}

struct ContentView: View {
    let device = Device.current
    @AppStorage("enabledTweaks") private var enabledTweakIds: [String] = []
    
    @State private var hasShownWelcome = false
    @State private var customZeroPath: String = ""
    @State private var addedCustomPaths: [String] = []
    @State private var isSupported: Bool = true
    @State private var showSettingsPopover: Bool = false
    @State private var showCustomTweaksPopover: Bool = false
    @State private var debugSettingsExpanded: Bool = false
    
    @State private var showRespringView: Bool = false
    
    @State private var statusMessage: String = ""
    @State private var statusDescription: String = ""
    @State private var statusIcon: String = ""
    @State private var statusIconColor: Color = .primary
    
    @FocusState private var isCustomPathFieldFocused: Bool
    
    @AppStorage("showLogs") private var showLogs: Bool = true
    @AppStorage("showDebugSettings") private var showDebugSettings: Bool = false
    @AppStorage("showRiskyTweaks") private var showRiskyTweaks: Bool = false
    @AppStorage("useRespringApp") var useRespringApp: Bool = false
    @AppStorage("respringAppBID") private var respringAppBID: String = "com.jbdotparty.respringr"
    @AppStorage("customTweaks") private var customTweaks: [ZeroTweak] = []
    
    private var tweaks: [ZeroTweak] {
        homeScreen + lockScreen + alertsOverlays + fontsIcons + controlCenter + soundEffects + riskyTweaks + customTweaks
    }
    
    private var enabledTweaks: [ZeroTweak] {
        tweaks.filter { tweak in enabledTweakIds.contains(tweak.id) }
    }
    
    private func isTweakEnabled(_ tweak: ZeroTweak) -> Bool {
        enabledTweakIds.contains(tweak.id)
    }
    
    private func toggleTweak(_ tweak: ZeroTweak) {
        if isTweakEnabled(tweak) {
            enabledTweakIds.removeAll { $0 == tweak.id }
        } else {
            enabledTweakIds.append(tweak.id)
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Headername(text: "Version \(UIApplication.appVersion!) (\(weOnADebugBuild ? "Debug" : "Release"))", icon: "info.circle"), footer: Text("Made with love by the [jailbreak.party](https://jailbreak.party/) team.\n[Join the jailbreak.party Discord!](https://jailbreak.party/discord)").font(.footnote)) {
                    VStack {
                        VStack(alignment: .leading) {
                            HStack {
                                if statusIcon == "showMeProgressPlease" {
                                    ProgressView()
                                } else {
                                    Image(systemName: statusIcon)
                                        .foregroundStyle(statusIconColor)
                                }
                                Text(statusMessage)
                                    .fontWeight(.medium)
                            }
                            if showLogs {
                                LogView()
                                    .modifier(TerminalPlatter())
                            } else {
                                Text(statusDescription)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .font(.body)
                                    .multilineTextAlignment(.leading)
                                    .opacity(0.8)
                            }
                            if !device.isPad {
                                HStack {
                                    HStack {
                                        Image(systemName: device.isPad ? "ipad" : "iphone.gen2")
                                            .frame(width: 20, height: 20)
                                        Text("\(device.systemName!) \(device.systemVersion!)")
                                    }
                                    .frame(maxWidth: .infinity)
                                    .modifier(SmallInfoPlatter())
                                    HStack {
                                        Image(systemName: "wrench.and.screwdriver")
                                            .frame(width: 20, height: 20)
                                        if enabledTweaks.count == 1 {
                                            Text("\(enabledTweaks.count) tweak")
                                        } else {
                                            Text("\(enabledTweaks.count) tweaks")
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                    .modifier(SmallInfoPlatter())
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .modifier(SectionPlatter())
                        .listRowBackground(Color.clear)
                        .listRowInsets(device.isPad ? .dropdownRowInsets : .zeroInsets)
                        if device.isPad {
                            HStack {
                                HStack {
                                    Image(systemName: device.isPad ? "ipad" : "iphone.gen2")
                                        .frame(width: 20, height: 20)
                                    Text("\(device.systemName!) \(device.systemVersion!)")
                                }
                                .frame(maxWidth: .infinity)
                                .modifier(SmallInfoPlatter())
                                HStack {
                                    Image(systemName: "wrench.and.screwdriver")
                                        .frame(width: 20, height: 20)
                                    if enabledTweaks.count == 1 {
                                        Text("\(enabledTweaks.count) tweak")
                                    } else {
                                        Text("\(enabledTweaks.count) tweaks")
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .modifier(SmallInfoPlatter())
                            }
                        }
                    }
                }
                .listRowSeparator(.hidden)
                .listRowInsets(.dropdownRowInsets)
                
                if UIDevice.current.userInterfaceIdiom == .pad {
                    Section(header: Headername(text: "Actions", icon: "hammer")) {
                        VStack {
                            Button(action: {
                                Haptic.shared.play(.heavy)
                                if enabledTweaks.isEmpty {
                                    Alertinator.shared.alert(title: "No tweaks were selected!", body: "Select some tweaks first, then try again.")
                                } else {
                                    applyTweaks(tweaks: enabledTweaks)
                                }
                            }) {
                                Buttonname(text: "Apply Tweaks", icon: "checkmark")
                            }
                            .buttonStyle(TranslucentButtonStyle(color: enabledTweaks.isEmpty ? .gray : .green))
                            HStack {
                                Button(action: {
                                    Haptic.shared.play(.soft)
                                    Alertinator.shared.alert(title: "Warning!", body: "To revert all tweaks currently applied, we'll have to reboot your device.", actionname: "Reboot", action: {
                                        try? zeroPoC(path: "/usr/lib/dyld")
                                    })
                                }) {
                                    Buttonname(text: "Remove", icon: "xmark")
                                }
                                .buttonStyle(TranslucentButtonStyle(color: .red))
                                Button(action: {
                                    Haptic.shared.play(.heavy)
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                        if isDatAppInstalled(respringAppBID) {
                                            LSApplicationWorkspace.default().openApplication(withBundleID: respringAppBID)
                                        } else {
                                            Alertinator.shared.alert(title: "RespringApp Not Detected", body: "Make sure you have RespringApp installed, then try again.")
                                        }
                                    }
                                }) {
                                    Buttonname(text: "Respring", icon: "goforward")
                                }
                                .buttonStyle(TranslucentButtonStyle(color: .orange))
                            }
                        }
                    }
                    .listRowSeparator(.hidden)
                    .listRowInsets(.dropdownRowInsets)
                }
                
                if weOnADebugBuild || showDebugSettings {
                    Section(header: HeaderDropdown(text: "Debugging", icon: "ant", isExpanded: $debugSettingsExpanded)) {
                        if debugSettingsExpanded {
                            VStack {
                                HStack {
                                    PrimaryTextFieldButton(titleKey: "/path/to/zero", text: $customZeroPath, button: {
                                        Button(action: {
                                            Haptic.shared.play(.soft)
                                            customZeroPath = UIPasteboard.general.string ?? ""
                                        }) {
                                            Image(systemName: "doc.on.doc")
                                        }
                                        .buttonStyle(.plain)
                                    })
                                    Button(action: {
                                        Haptic.shared.play(.heavy)
                                        try? zeroPoC(path: customZeroPath)
                                        Alertinator.shared.alert(title: "Custom path zeroed successfully!", body: "Zeroed out \(customZeroPath).", actionname: "Respring", action: {
                                            if isDatAppInstalled(respringAppBID) {
                                                LSApplicationWorkspace.default().openApplication(withBundleID: respringAppBID)
                                            } else {
                                                Alertinator.shared.alert(title: "RespringApp Not Detected", body: "Make sure you have RespringApp installed, then try again.")
                                            }
                                        })
                                    }) {
                                        Image(systemName: "checkmark")
                                            .frame(width: 18, height: 24)
                                    }
                                    .buttonStyle(TranslucentButtonStyle(useFullWidth: false))
                                    .disabled(customZeroPath.isEmpty)
                                }
                                Button(action: {
                                    Haptic.shared.play(.soft)
                                    print("===== dirtyZero Debug =====\n[*] isSupported: \(isSupported)\n[*] weOnADebugBuild: \(weOnADebugBuild)\n[*] enabledTweakIds: \(enabledTweakIds)\n[*] customTweaks: \(customTweaks)")
                                }) {
                                    Buttonname(text: "Print Debug Info", icon: "ant")
                                }
                                .buttonStyle(TranslucentButtonStyle())
                            }
                        }
                    }
                    .listRowSeparator(.hidden)
                    .listRowInsets(.dropdownRowInsets)
                    .animation(.default, value: debugSettingsExpanded)
                }
                if UIDevice.current.userInterfaceIdiom == .phone {
                    ListedTweaksView()
                }
            }
            .listStyle(.plain)
            .navigationTitle("dirtyZero")
            .safeAreaInset(edge: .bottom) {
                if UIDevice.current.userInterfaceIdiom == .phone {
                    VStack {
                        Button(action: {
                            Haptic.shared.play(.heavy)
                            if enabledTweaks.isEmpty {
                                Alertinator.shared.alert(title: "No tweaks were selected!", body: "Select some tweaks first, then try again.")
                            } else {
                                applyTweaks(tweaks: enabledTweaks)
                            }
                        }) {
                            Buttonname(text: "Apply Tweaks", icon: "checkmark")
                        }
                        .buttonStyle(TranslucentButtonStyle(color: enabledTweaks.isEmpty ? .gray : .green))
                        HStack {
                            Button(action: {
                                Haptic.shared.play(.soft)
                                Alertinator.shared.alert(title: "Warning!", body: "To revert all tweaks currently applied, we'll have to reboot your device.", actionname: "Reboot", action: {
                                    try? zeroPoC(path: "/usr/lib/dyld")
                                })
                            }) {
                                Buttonname(text: "Remove", icon: "xmark")
                            }
                            .buttonStyle(TranslucentButtonStyle(color: .red))
                            Button(action: {
                                Haptic.shared.play(.heavy)
                                if !useRespringApp {
                                    // use WebView method
                                    showRespringView = true
                                } else {
                                    if isDatAppInstalled(respringAppBID) {
                                        LSApplicationWorkspace.default().openApplication(withBundleID: respringAppBID)
                                    } else if isDatAppInstalled("com.respring.app") { // check if old respringapp is installed
                                        LSApplicationWorkspace.default().openApplication(withBundleID: "com.respring.app")
                                    } else {
                                        Alertinator.shared.alert(title: "RespringApp Not Detected", body: "Make sure you have RespringApp installed, then try again.")
                                    }
                                }
                            }) {
                                Buttonname(text: "Respring", icon: "goforward")
                            }
                            .buttonStyle(TranslucentButtonStyle(color: .orange))
                        }
                    }
                    .modifier(OverlayBackground())
                }
            }
            .onAppear {
                if weOnADebugBuild {
                    print("[!] We're on a debug build!")
                }
                if !hasShownWelcome {
                    print("[*] Welcome to dirtyZero!\n[*] Running on \(device.systemName!) \(device.systemVersion!), \(device.description)\n[!] All tweaks are done in memory, so if something goes wrong, you can force reboot to revert changes.")
                    hasShownWelcome = true
                }
                if !isdirtyZeroSupported() && !weOnADebugBuild {
                    statusMessage = "Unsupported device detected!"
                    statusIcon = "exclamationmark.triangle.fill"
                    statusIconColor = .yellow
                    statusDescription = "This version of iOS does not support dirtyZero and never will. Sorry for any inconveniences."
                    Alertinator.shared.alert(title: "Warning!", body: "This software version (\(device.systemName!) \(device.systemVersion!)) does not support dirtyZero and never will. Sorry for any inconveniences.", showCancel: false, actionname: "Exit App", action: {
                        exitinator()
                    })
                } else {
                    statusMessage = "Ready to Apply!"
                    statusIcon = "checkmark.circle.fill"
                    statusIconColor = .primary
                    statusDescription = "Select some tweaks of your choice. Then, hit apply. All tweaks are done in memory, so if something goes wrong, you can force reboot to revert changes."
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: {
                        showSettingsPopover = true
                    }) {
                        Image(systemName: "gearshape")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        showCustomTweaksPopover = true
                    }) {
                        Image(systemName: "paintpalette")
                    }
                }
            }
            .sheet(isPresented: $showSettingsPopover) {
                SettingsView()
            }
            .sheet(isPresented: $showCustomTweaksPopover) {
                CustomTweaksView()
            }
            .fullScreenCover(isPresented: $showRespringView) {
                RespringView()
            }
        }
    }
    
    // MARK: Functions
    func applyTweaks(tweaks: [ZeroTweak]) {
        var applyingString = "[*] Applying the selected tweaks: "
        let tweakNames = enabledTweaks.map { $0.name }.joined(separator: ", ")
        applyingString += tweakNames
        
        print(applyingString)
        
        let totalTweaks = enabledTweaks.count
        var currentTweak = 1
        
        do {
            for tweak in enabledTweaks {
                applyingString = "[\(currentTweak)/\(totalTweaks)] Applying \(tweak.name)..."
                print(applyingString)
                for path in tweak.paths {
                    try zeroPoC(path: path)
                }
                print("[*] Applied tweak \(currentTweak)/\(totalTweaks)!")
                currentTweak += 1
                statusMessage = "Applying Tweaks..."
                statusDescription = "Applying tweak \(currentTweak)/\(totalTweaks)..."
                statusIcon = "showMeProgressPlease"
            }
            print("[*] Successfully applied all tweaks!")
            statusMessage = "Tweaks applied successfully!"
            statusDescription = "\(totalTweaks)/\(totalTweaks) tweaks applied! If you'd like to respring, ensure you have RespringApp installed."
            statusIcon = "checkmark.circle.fill"
            statusIconColor = .green
            Alertinator.shared.alert(title: "Tweaks Applied Successfully!", body: "\(totalTweaks)/\(totalTweaks) tweaks applied! If you'd like to respring, ensure you have RespringApp installed.")
        } catch {
            let failedString = "There was an error while applying tweak \(currentTweak)/\(totalTweaks): \(error)."
            statusMessage = "Failed to apply tweak \(currentTweak)/\(totalTweaks)!"
            statusDescription = failedString
            statusIcon = "xmark.circle.fill"
            statusIconColor = .green
            print("[!] \(error)")
            Alertinator.shared.alert(title: "Failed to Apply", body: failedString)
            return
        }
    }
    
    // the super useful "sandbox escape" that only tells you what apps are installed :fire:
    func isDatAppInstalled(_ bundleID: String) -> Bool {
        typealias SBSLaunchFunction = @convention(c) (
            String,
            URL?,
            [String: Any]?,
            [String: Any]?,
            Bool
        ) -> Int32
        
        guard let sbsLib = dlopen("/System/Library/PrivateFrameworks/SpringBoardServices.framework/SpringBoardServices", RTLD_NOW) else {
            print("[!] dlopen fail !!")
            return false
        }
        
        defer {
            dlclose(sbsLib)
        }
        
        guard let sbsAddr = dlsym(sbsLib, "SBSLaunchApplicationWithIdentifierAndURLAndLaunchOptions") else {
            print("[!] dlsym fail !!")
            return false
        }
        
        let sbsFunction = unsafeBitCast(sbsAddr, to: SBSLaunchFunction.self)
        
        let result = sbsFunction(bundleID, nil, nil, nil, true)
        
        return result == 9
    }
}

struct ListedTweaksView: View {
    @AppStorage("enabledTweaks") private var enabledTweakIds: [String] = []
    @AppStorage("customTweaks") private var customTweaks: [ZeroTweak] = []
    @AppStorage("showRiskyTweaks") private var showRiskyTweaks: Bool = false
    
    var body: some View {
        if UIDevice.current.userInterfaceIdiom == .pad {
            List {
                TweakSectionList(sectionname: "Custom Tweaks", sectionIcon: "wrench.and.screwdriver", tweaks: customTweaks, isCustomTweak: true, enabledTweakIds: $enabledTweakIds)
                TweakSectionList(sectionname: "Home Screen", sectionIcon: "house", tweaks: homeScreen, enabledTweakIds: $enabledTweakIds)
                TweakSectionList(sectionname: "Lock Screen", sectionIcon: "lock", tweaks: lockScreen, enabledTweakIds: $enabledTweakIds)
                TweakSectionList(sectionname: "Alerts & Overlays", sectionIcon: "exclamationmark.triangle", tweaks: alertsOverlays, enabledTweakIds: $enabledTweakIds)
                TweakSectionList(sectionname: "Fonts & Icons", sectionIcon: "paintbrush", tweaks: fontsIcons, enabledTweakIds: $enabledTweakIds)
                TweakSectionList(sectionname: "Control Center", sectionIcon: "square.grid.2x2", tweaks: controlCenter, enabledTweakIds: $enabledTweakIds)
                TweakSectionList(sectionname: "Sound Effects", sectionIcon: "speaker.wave.2", tweaks: soundEffects, enabledTweakIds: $enabledTweakIds)
                if weOnADebugBuild || showRiskyTweaks {
                    TweakSectionList(sectionname: "Risky Tweaks", sectionIcon: "exclamationmark.triangle", tweaks: riskyTweaks, isRiskyTweak: true, enabledTweakIds: $enabledTweakIds)
                }
            }
            .listStyle(.plain)
        } else {
            TweakSectionList(sectionname: "Custom Tweaks", sectionIcon: "wrench.and.screwdriver", tweaks: customTweaks, isCustomTweak: true, enabledTweakIds: $enabledTweakIds)
            TweakSectionList(sectionname: "Home Screen", sectionIcon: "house", tweaks: homeScreen, enabledTweakIds: $enabledTweakIds)
            TweakSectionList(sectionname: "Lock Screen", sectionIcon: "lock", tweaks: lockScreen, enabledTweakIds: $enabledTweakIds)
            TweakSectionList(sectionname: "Alerts & Overlays", sectionIcon: "exclamationmark.triangle", tweaks: alertsOverlays, enabledTweakIds: $enabledTweakIds)
            TweakSectionList(sectionname: "Fonts & Icons", sectionIcon: "paintbrush", tweaks: fontsIcons, enabledTweakIds: $enabledTweakIds)
            TweakSectionList(sectionname: "Control Center", sectionIcon: "square.grid.2x2", tweaks: controlCenter, enabledTweakIds: $enabledTweakIds)
            TweakSectionList(sectionname: "Sound Effects", sectionIcon: "speaker.wave.2", tweaks: soundEffects, enabledTweakIds: $enabledTweakIds)
            if weOnADebugBuild || showRiskyTweaks {
                TweakSectionList(sectionname: "Risky Tweaks", sectionIcon: "exclamationmark.triangle", tweaks: riskyTweaks, isRiskyTweak: true, enabledTweakIds: $enabledTweakIds)
            }
        }
    }
}

#Preview {
    ContentView()
}
*/
