//
//  CustomTweaksView.swift
//  dirtyZero
//
//  Created by Main on 10/10/25.
//

import SwiftUI
import PartyUI
import UIKit
import DeviceKit
import SFSymbolsPicker

struct CustomTweaksView: View {
    @EnvironmentObject var mgr: dirtyZeroManager
    @Environment(\.dismiss) var dismiss
    
    @AppStorage("tweakArray") var tweakArray: [ZeroSection] = TweakArray.tweaks
    @AppStorage("enableDebugSettings") var enableDebugSettings: Bool = false
    
    @State private var tweakName: String = ""
    @State private var tweakIcon: String = "paintbrush"
    @State private var path2Add: String = ""
    @State private var targetPaths: [String] = []
    
    @State private var showIconPicker: Bool = false
    
    var body: some View {
        NavigationStack {
            List {
                if enableDebugSettings {
                    Section(header: HeaderLabel(text: "Debugging", icon: "ant")) {
                        Button(action: {
                            tweakName = "Hide Dock Background"
                            targetPaths = ["/System/Library/PrivateFrameworks/CoreMaterial.framework/dockDark.materialrecipe", "/System/Library/PrivateFrameworks/CoreMaterial.framework/dockLight.materialrecipe"]
                        }) {
                            ButtonLabel(text: "Populate Arrays", icon: "character.cursor.ibeam")
                        }
                        .buttonStyle(TranslucentButtonStyle())
                    }
                    .listRowInsets(.dropdownRowInsets)
                    .listRowSeparator(.hidden)
                }
                Section(header: HeaderLabel(text: "Create Tweak", icon: "paintbrush")) {
                    VStack {
                        HStack(spacing: 10) {
                            Button(action: {
                                showIconPicker.toggle()
                            }) {
                                Image(systemName: tweakIcon)
                                    .frame(width: 22, height: 20)
                            }
                            .buttonStyle(.plain)
                            TextField("Tweak Name", text: $tweakName)
                        }
                        .modifier(PrimaryTextFieldStyle())
                        HStack {
                            TextField("/path/to/zero", text: $path2Add)
                                .modifier(PrimaryTextFieldStyle())
                            Button(action: {
                                if targetPaths.contains(path2Add) {
                                    Haptic.shared.play(.heavy)
                                    Alertinator.shared.alert(title: "Error!", body: "That path matches one or more paths that you have already included as a target path. Please try a different path.")
                                } else {
                                    Haptic.shared.play(.soft)
                                    targetPaths.append(path2Add)
                                }
                            }) {
                                Image(systemName: "plus")
                                    .frame(width: 24, height: 24)
                            }
                            .buttonStyle(TranslucentButtonStyle(color: .purple, useFullWidth: false))
                            .disabled(path2Add.isEmpty || tweakName.isEmpty)
                        }
                    }
                }
                .listRowInsets(.dropdownRowInsets)
                .listRowSeparator(.hidden)
                
                if !targetPaths.isEmpty {
                    Section(header: HeaderLabel(text: "Target Paths", icon: "character.cursor.ibeam")) {
                        ForEach(targetPaths, id: \.self) { path in
                            Text(path)
                                .font(.system(.footnote, design: .monospaced))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                                .background(Color(.secondarySystemBackground), in: .rect(cornerRadius: DesignStyle.defaultComponentRadius))
                                .swipeActions {
                                    Button(role: .destructive, action: {
                                        targetPaths.removeAll { $0 == path }
                                    }) {
                                        Image(systemName: "xmark")
                                    }
                                    .tint(.red)
                                }
                        }
                    }
                    .listRowInsets(.dropdownRowInsets)
                    .listRowSeparator(.hidden)
                }
            }
            .listStyle(.plain)
            .navigationTitle("Tweak Creator")
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom) {
                Button(action: {
                    let customTweaksIndex = tweakArray.firstIndex(where: { $0.name == "Custom Tweaks" }) ?? 0
                    tweakArray[customTweaksIndex].tweaks.append(ZeroTweak(name: tweakName, icon: tweakIcon, paths: targetPaths))
                }) {
                    ButtonLabel(text: "Add Tweak", icon: "plus")
                }
                .buttonStyle(TranslucentButtonStyle(color: .purple))
                .disabled(path2Add.isEmpty || tweakName.isEmpty)
                .modifier(OverlayBackground())
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                    }
                    .modifier(SolariumButtonTint())
                }
            }
            .sheet(isPresented: $showIconPicker) {
                SymbolsPicker(selection: $tweakIcon, title: "", autoDismiss: true)
            }
            .tint(.purple)
        }
    }
}

#Preview {
    CustomTweaksView()
}

/*
// i fucking hate this. but it makes it work so please don't change this.
// Skadz, 10/11/25 7:17 PM
struct PathItem: Identifiable, Hashable {
    let id = UUID()
    var path: String
}

struct CustomTweaksView: View {
    @State private var tweakName: String = ""
    @State private var targetPaths: [PathItem] = []
    @State private var path2Add: String = ""
    
    @Environment(\.dismiss) private var dismiss
    @AppStorage("customTweaks") private var customTweaks: [ZeroTweak] = []
    
    let device = Device.current
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: HeaderLabel(text: "Tweak Info", icon: "info.circle")) {
                    VStack(spacing: 10) {
                        TextField("Tweak Name", text: $tweakName)
                            .modifier(PrimaryTextFieldStyle())
                        HStack {
                            PrimaryTextFieldButton(titleKey: "/path/to/zero", text: $path2Add, button: {
                                Button(action: {
                                    Haptic.shared.play(.soft)
                                    path2Add = UIPasteboard.general.string ?? ""
                                }) {
                                    Image(systemName: "doc.on.doc")
                                        .frame(width: 18, height: 24)
                                }
                            })
                            Button(action: {
                                Haptic.shared.play(.soft)
                                addPath()
                            }) {
                                Image(systemName: "plus")
                                    .frame(height: 24)
                            }
                            .buttonStyle(TranslucentButtonStyle())
                            .disabled(path2Add.isEmpty || tweakName.isEmpty)
                        }
                    }
                }
                .listRowSeparator(.hidden)
                .listRowInsets(.dropdownRowInsets)
                
                Section(header: HeaderLabel(text: "Added Paths", icon: "pencil")) {
                    ForEach(targetPaths) { item in
                        HStack {
                            Text(item.path)
                            Spacer()
                            Button(action: {
                                Haptic.shared.play(.soft)
                                withAnimation {
                                    targetPaths.removeAll { $0.id == item.id }
                                }
                            }) {
                                Image(systemName: "xmark")
                            }
                            .buttonStyle(.plain)
                        }
                        .modifier(ListTogglePlatter())
                    }
                }
                .listRowSeparator(.hidden)
                .listRowInsets(.dropdownRowInsets)
            }
            .listStyle(.plain)
            .navigationTitle("Create Tweak")
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
            .safeAreaInset(edge: .bottom) {
                VStack {
                    Button(action: {
                        Haptic.shared.play(.soft)
                        if tweakName.isEmpty || targetPaths.isEmpty {
                            Alertinator.shared.alert(title: "No paths were added!", body: "Add some paths & set a tweak name, then try again.")
                        } else {
                            var tweakPaths: [String] = []
                            for item in targetPaths {
                                tweakPaths.append(item.path)
                            }
                            let newCustomTweak = ZeroTweak(icon: "paintbrush.pointed", name: tweakName, minSupportedVersion: 16.0, maxSupportedVersion: 18.9, paths: tweakPaths)
                            customTweaks.append(newCustomTweak)
                            dismiss()
                        }
                    }) {
                        ButtonLabel(text: "Add Tweak", icon: "plus")
                    }
                    .buttonStyle(TranslucentButtonStyle(color: tweakName.isEmpty || targetPaths.isEmpty ? .gray : .accentColor))
                }
                .modifier(OverlayBackground(stickBottomPadding: device.isPad ? true : false))
            }
        }
        .tint(.purple)
    }
    
    private func addPath() {
        withAnimation {
            targetPaths.append(PathItem(path: path2Add))
            path2Add = ""
        }
    }
    
    private func deletePath(at offsets: IndexSet) {
        withAnimation {
            targetPaths.remove(atOffsets: offsets)
        }
    }
}

#Preview {
    CustomTweaksView()
}
*/
