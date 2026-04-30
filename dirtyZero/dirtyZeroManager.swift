//
//  dirtyZeroManager.swift
//  dirtyZero
//
//  Created by lunginspector on 4/14/26.
//

import SwiftUI
import PartyUI

enum ExploitOptions: String, CaseIterable {
    case l0ckwire, DarkSword, none
}

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
    
    @Published var isDirtyZeroSupported: Bool = {
        let vrs = ProcessInfo.processInfo.operatingSystemVersion
        
        if vrs.majorVersion < 16 {
            return false
        } else if vrs.majorVersion >= 16 && vrs.majorVersion <= 18 {
            if vrs.majorVersion == 18 && vrs.minorVersion == 7 && vrs.patchVersion > 1 {
                return false
            }
            return true
        } else if vrs.majorVersion == 26 {
            if vrs.minorVersion > 0 {
                return false
            }
            return true
        } else {
            return false
        }
    }()
    @Published var chosenExploit: ExploitOptions = {
        let version = doubleSystemVersion()
        if version <= 18.3 {
            return .l0ckwire
        } else if version >= 18.4 && version <= 18.7  {
            return .DarkSword
        } else if version >= 19.0 && version < 26.1 {
            return .DarkSword
        } else {
            return .none
        }
    }()
    @Published var isDirtyZeroReady: Bool = false
    @Published var doesDeviceSupportl0ckwire: Bool = {
        let version = doubleSystemVersion()
        if version <= 18.3 {
            return true
        } else {
            return false
        }
    }()
    
    // MARK: bullshit incoming
    // will need these
    @Published var dsrunning: Bool = false
    @Published var dsready: Bool = false
    @Published var dsattempted: Bool = false
    @Published var dsfailed: Bool = false
    @Published var dsprogress: Double = 0.0
    
    @Published var kernbase: UInt64 = 0
    @Published var kernslide: UInt64 = 0
    
    @Published var vfsready: Bool = false
    @Published var vfsinitlog: String = ""
    @Published var vfsattempted: Bool = false
    @Published var vfsfailed: Bool = false
    @Published var vfsrunning: Bool = false
    @Published var vfsprogress: Double = 0.0
    
    init() {}
    
    // MARK: DarkSword bullshit
    
    func run(completion: ((Bool) -> Void)? = nil) {
        guard !dsrunning else { return }
        dsrunning = true
        dsready = false
        dsfailed = false
        dsattempted = true
        dsprogress = 0.0
        
        ds_set_log_callback { messageCStr in
            guard let messageCStr else { return }
            let message = String(cString: messageCStr)
            DispatchQueue.main.async {
                print("(ds) \(message)")
            }
        }
        ds_set_progress_callback { progress in
            DispatchQueue.main.async {
                dirtyZeroManager.shared.dsprogress = progress
            }
        }
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let result = ds_run()
            
            DispatchQueue.main.async {
                guard let self else { return }
                self.dsrunning = false
                let success = result == 0 && ds_is_ready()
                if success {
                    self.dsready = true
                    self.dsfailed = false
                    self.kernbase = ds_get_kernel_base()
                    self.kernslide = ds_get_kernel_slide()
                    print(String(format: "kernel_base:  0x%llx", self.kernbase))
                    print(String(format: "kernel_slide: 0x%llx\n", self.kernslide))
                    print("exploit success!")
                } else {
                    self.dsfailed = true
                    print("exploit failed.")
                }
                self.dsprogress = 1.0
                completion?(success)
            }
        }
    }
    
    func vfsinit(completion: ((Bool) -> Void)? = nil) {
        vfs_setlogcallback(dirtyZeroManager.vfslogcallback)
        vfs_setprogresscallback { progress in
            DispatchQueue.main.async {
                dirtyZeroManager.shared.vfsprogress = progress
            }
        }
        vfsattempted = true
        vfsfailed = false
        vfsrunning = true
        vfsprogress = 0.0
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let r = vfs_init()
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.vfsready = (r == 0 && vfs_isready())
                if self.vfsready {
                    self.vfsfailed = false
                    print("\nvfs ready!\n")
                    self.isDirtyZeroReady = true
                } else {
                    self.vfsfailed = true
                    print("\nvfs init failed.\n")
                }
                self.vfsrunning = false
                self.vfsprogress = 1.0
                completion?(self.vfsready)
            }
        }
    }
    
    private static let vfslogcallback: @convention(c) (UnsafePointer<CChar>?) -> Void = { msg in
        guard let msg = msg else { return }
        let s = String(cString: msg)
        DispatchQueue.main.async {
            dirtyZeroManager.shared.vfsinitlog += "(vfs) " + s + "\n"
            print("(vfs) " + s)
        }
    }
    /*
    func vfswrite(path: String, data: Data) -> Bool {
        guard vfsready else { return false }
        return data.withUnsafeBytes { ptr in
            let n = vfs_write(path, ptr.baseAddress, data.count, 0)
            return n > 0
        }
    }
    
    func vfsoverwritewithdata(target: String, data: Data) -> Bool {
        guard vfsready else { return false }
        let tmp = NSTemporaryDirectory() + "vfs_src_\(arc4random()).bin"
        do { try data.write(to: URL(fileURLWithPath: tmp)) } catch { return false }
        let ok = vfsoverwritefromlocalpath(target: target, source: tmp)
        try? FileManager.default.removeItem(atPath: tmp)
        return ok
    }
    
    func vfsoverwritefromlocalpath(target: String, source: String) -> Bool {
        print("(vfs) target \(source) -> \(target)")
        
        guard vfsready else {
            print("(vfs) not ready")
            return false
        }
        
        guard FileManager.default.fileExists(atPath: source) else {
            print("(vfs) source file not found: \(source)")
            return false
        }
        
        let r = vfs_overwritefile(target, source)
        
        print("(vfs) vfs_overwritefile returned: \(r)")
        
        if r == 0 {
            print("(vfs) file overwritten")
        } else {
            print("(vfs) failed to overwrite file")
        }
        
        return r == 0
    }
    */
    func vfszeropage(at path: String) -> Bool {
        let result = path.withCString { cpath in
            vfs_zeropage(cpath, 0)
        }
        
        if result != 0 {
            print("(vfs) zeropage failed")
            return false
        }
        
        print("(vfs) zeroed first page of \(path)")
        return true
    }
    
    /*
    @discardableResult
    func lara_overwritefile(target: String, data: Data) -> (ok: Bool, message: String) {
        let result = sbxready ? sbxoverwrite(path: target, data: data) : (false, "sbx not ready")
        if result.0 {
            return result
        }
        
        guard vfsready else {
            return (false, result.1 + ", vfs not ready")
        }
        
        let ok = vfsoverwritewithdata(target: target, data: data)
        return ok ? (true, "vfs overwrite ok") : (false, result.1 + ", vfs overwrite failed")
    }
    */
    
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
                        if chosenExploit == .l0ckwire {
                            try zeroPoC(path: path)
                        } else {
                            vfszeropage(at: path)
                        }
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
