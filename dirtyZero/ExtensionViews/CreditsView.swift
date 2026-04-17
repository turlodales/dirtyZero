//
//  CreditsView.swift
//  dirtyZero
//
//  Created by lunginspector on 4/15/26.
//

import SwiftUI
import PartyUI

struct CreditsView: View {
    var body: some View {
        NavigationStack {
            List {
                LinkCreditCell(image: Image("skadz108"), name: "Skadz", description: "Initial developer, backend, and exploit-related management.", url: "https://github.com/skadz108")
                LinkCreditCell(image: Image("lunginspector"), name: "lunginspector", description: "Frontend developer, tweak creator, and app UI.", url: "https://github.com/skadz108")
                LinkCreditCell(image: Image("ianbeer"), name: "Ian Beer (Gooogle Project Zero)", description: "Discovering & publishing CVE-2025-24203.", url: "https://project-zero.issues.chromium.org/issues/391518636")
                LinkCreditCell(image: Image("neonmodder123"), name: "neonmodder123", description: "Developed WebView respring method.", url: "https://github.com/neonmodder123")
            }
            .navigationTitle("Credits")
        }
    }
}
