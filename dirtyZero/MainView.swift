//
//  MainView.swift
//  dirtyZero
//
//  Created by Main on 1/21/26.
//

import SwiftUI
import PartyUI
import DeviceKit

let dirtyZeroTextArt = #"""
    
          _ _      _         ______              
         | (_)    | |       |___  /              
       __| |_ _ __| |_ _   _   / / ___ _ __ ___  
      / _` | | '__| __| | | | / / / _ \ '__/ _ \ 
     | (_| | | |  | |_| |_| |/ /_|  __/ | | (_) |
      \__,_|_|_|   \__|\__, /_____\___|_|  \___/ 
                        __/ |                    
                       |___/    
                 
    """#

let dirtyZeroTextArtDebug = #"""
    
          _ _      _         ______              
         | (_)    | |       |___  /              
       __| |_ _ __| |_ _   _   / / ___ _ __ ___  
      / _` | | '__| __| | | | / / / _ \ '__/ _ \ 
     | (_| | | |  | |_| |_| |/ /_|  __/ | | (_) |
      \__,_|_|_|   \__|\__, /_____\___|_|  \___/ 
                        __/ |                    
                       |___/                DEBUG
                 
    """#

struct MainView: View {
    @StateObject private var mgr = dirtyZeroManager.shared
    @StateObject private var theme = AppTheme.shared
    
    let device = Device.current
    
    var body: some View {
        Group {
            if UIDevice.current.userInterfaceIdiom == .pad {
                /*
                 NavigationSplitView {
                 ContentView()
                 .navigationSplitViewColumnWidth(385)
                 } detail: {
                 ListedTweaksView()
                 .navigationTitle("Tweaks")
                 .navigationBarTitleDisplayMode(.inline)
                 }
                 */
            } else {
                ContentView()
            }
        }
        .environmentObject(mgr)
        .environmentObject(theme)
        .tint(theme.accentColor)
        .preferredColorScheme(theme.appearance.appearances)
        .overlay {
            if mgr.showRespringView {
                RespringView()
                    .brightness(-1.0)
                    .ignoresSafeArea()
            }
        }
        .onAppear {
            /*
            if weOnADebugBuild {
                print(dirtyZeroTextArtDebug)
            } else {
                print(dirtyZeroTextArt)
            }*/
            print("\n[*] Welcome to dirtyZero! Running on \(device.systemName ?? "nil") \(device.systemVersion ?? "0.0"), \(device.description).")
            print("[*] All tweaks are done in memory, so if something goes wrong, simply reboot your device.")
        }
    }
}

#Preview {
    MainView()
        .environmentObject(dirtyZeroManager())
        .environmentObject(AppTheme())
}
