//
//  dirtyZeroManager.swift
//  dirtyZero
//
//  Created by lunginspector on 4/14/26.
//

import SwiftUI
import PartyUI

@MainActor
final class dirtyZeroManager: ObservableObject {
    static let shared = dirtyZeroManager()
    
    // tweak counts
    @Published var enabledTweaks: Int = 0
    
    // status information
    @Published var applyShortStatus: String = "Ready to Apply!"
    @Published var applyIcon: String = "checkmark.circle.fill"
    @Published var applyColor: Color = Color(.label)
    
    @Published var applyCurrentTweak: Int = 0
    @Published var applyCurrentTweakName: String = ""
    
    // tell app to do stuff
    @Published var showRespringView: Bool = false
    
    // imported AppStorage properties, only requried for reading.
    @AppStorage("useRespringApp") var useRespringApp: Bool = false
    @AppStorage("respringAppBID") var respringAppBID: String = "com.jbdotparty.respringr"
    
    init() {}
    
    // apply tweaks function (using DirtyZero)
    @MainActor func applyTweaks(tweakData: [ZeroSection]) {
        applyCurrentTweak = 0
        
        do {
            let tweaks = tweakData.flatMap { $0.tweaks }
            
            for tweak in tweaks {
                if tweak.isOn {
                    applyCurrentTweak += 1
                    applyCurrentTweakName = tweak.name
                    
                    print("[*] (\(applyCurrentTweak)/\(enabledTweaks)) zeroing paths for the tweak \(tweak.name): \(tweak.paths)")
                    
                    for path in tweak.paths {
                        try zeroPoC(path: path)
                    }
                }
            }
            
            Alertinator.shared.alert(title: "All tweaks applied successfully!", body: "Respring your device to see changes take effect.", actionLabel: "Respring", action: {
                self.respringDevice()
            })
        } catch {
            print("[!] (\(applyCurrentTweak)/\(enabledTweaks)) failed to apply the tweak \(applyCurrentTweakName): \(error)")
            Alertinator.shared.alert(title: "(\(applyCurrentTweak)/\(enabledTweaks)) Failed to apply the tweak \(applyCurrentTweakName)!", body: "\(error)")
            
            applyShortStatus = "Failed to apply!"
            applyIcon = "xmark.circle.fill"
            applyColor = .red
        }
    }
    
    @MainActor func revertTweaks() {
        Alertinator.shared.alert(title: "Are you sure you'd like to revert your tweaks?", body: "Your device will reboot to revert all of your tweaks", action: {
            do {
                try zeroPoC(path: "/usr/lib/dyld")
            } catch {
                print("[!] failed to reboot device: \(error)")
                Alertinator.shared.alert(title: "Failed to reboot device!", body: "\(error)")
            }
        })
    }
    
    func respringDevice() {
        if !useRespringApp {
            print("[*] attempting to respring device...")
            showRespringView = true
        } else {
            if isAppInstalled(respringAppBID) {
                LSApplicationWorkspace.default().openApplication(withBundleID: respringAppBID)
            } else if isAppInstalled("com.respring.app") { // check if old respringapp is installed
                LSApplicationWorkspace.default().openApplication(withBundleID: "com.respring.app")
            } else {
                Alertinator.shared.alert(title: "RespringApp Not Detected", body: "Make sure you have RespringApp installed, then try again.")
            }
        }
    }
    
    // funny "sandbox escape" that was also patched in 18.4
    func isAppInstalled(_ bundleID: String) -> Bool {
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
