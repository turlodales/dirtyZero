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
    
    @AppStorage("tweakArray") var tweakArray: [ZeroSection] = TweakArray.tweaks
    
    @AppStorage("enableDebugSettings") var enableDebugSettings: Bool = false
    @AppStorage("enableRiskyTweaks") var enableRiskyTweaks: Bool = false
    
    @State private var customZeroPath: String = ""
    
    @State private var showSettingsView: Bool = false
    @State private var showCustomTweaksView: Bool = false
    
    @State private var selectedTweak: ZeroTweak?
    
    let version = doubleSystemVersion()
    
    var body: some View {
        Group {
            if UIDevice.current.userInterfaceIdiom == .phone {
                NavigationStack {
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
                }
            } else {
                NavigationSplitView(sidebar: {
                    List {
                        ApplyingSection
                            .listRowSeparator(.hidden)
                        ApplyingButtons
                        if enableDebugSettings {
                            DebuggingSection
                                .listRowSeparator(.hidden)
                        }
                    }
                    .listStyle(.plain)
                    .navigationTitle("dirtyZero")
                    .modifier(RemoveSidebarToggle())
                    .navigationSplitViewColumnWidth(385)
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
                }) {
                    List {
                        ListedTweaksSection
                    }
                    .listStyle(.plain)
                    .toolbar(.hidden, for: .navigationBar)
                }
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
        .sheet(item: $selectedTweak) { tweak in
            TweakInfoView(tweak: tweak)
        }
    }
    
    // MARK: Applying Section
    private var ApplyingSection: some View {
        Section(header: HeaderLabel(text: "Logs", icon: "terminal"), footer: Text("Made with love by the [jailbreak.party](https://jailbreak.party) team.\nJoin the jailbreak.party [discord!](https://jailbreak.party/discord)").font(.footnote).foregroundStyle(.secondary)) {
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
                LogView()
                    .modifier(TerminalPlatter())
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
                            let sectionColor = sectionType == .custom ? .purple : sectionType == .risky ? .red : Color.accentColor
                            
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
                                        .swipeActions {
                                            Button(action: {
                                                selectedTweak = tweak
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

// this is annoying but whatever
struct RemoveSidebarToggle: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            content
                .toolbar(removing: .sidebarToggle)
        } else {
            
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(dirtyZeroManager())
}
