//
//  dirtyZeroApp.swift
//  dirtyZero
//
//  Created by Skadz on 5/8/25.
//

import SwiftUI
import PartyUI
import DeviceKit

var weOnADebugBuild: Bool = false
var pipe = Pipe()
var sema = DispatchSemaphore(value: 0)

@main
struct dirtyZeroApp: App {
    @StateObject private var mgr = dirtyZeroManager.shared
    
    @AppStorage("enableDebugSettings") var enableDebugSettings: Bool = false
    
    let device = Device.current
    
    init() {
        // Setup log stuff (redirect stdout)
        setvbuf(stdout, nil, _IONBF, 0)
        dup2(pipe.fileHandleForWriting.fileDescriptor, STDOUT_FILENO)
        
        // Give us a debug build bool
        #if DEBUG
        weOnADebugBuild = true
        enableDebugSettings = true
        #else
        weOnADebugBuild = false
        #endif
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(mgr)
                .overlay {
                    if mgr.showRespringView {
                        RespringView()
                            .brightness(-1.0)
                            .ignoresSafeArea()
                    }
                }
                .onAppear {
                    print("\n[*] Welcome to dirtyZero! Running on \(device.systemName ?? "nil") \(device.systemVersion ?? "0.0"), \(device.description).")
                    print("[*] All tweaks are done in memory, so if something goes wrong, simply reboot your device.")
                }
        }
    }
}

@MainActor func isdirtyZeroSupported() -> Bool {
    return doubleSystemVersion() <= 18.3
}

extension String: @retroactive Error {}

// allows us to put arrays into AppStorage
extension Array: @retroactive RawRepresentable where Element: Codable {
    public init?(rawValue: String) {
        guard let data = rawValue.data(using: .utf8),
              let result = try? JSONDecoder().decode([Element].self, from: data)
        else {
            return nil
        }
        self = result
    }
    
    public var rawValue: String {
        guard let data = try? JSONEncoder().encode(self),
              let result = String(data: data, encoding: .utf8)
        else {
            return "[]"
        }
        return result
    }
}
