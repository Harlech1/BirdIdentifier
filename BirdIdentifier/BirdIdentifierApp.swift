//
//  BirdIdentifierApp.swift
//  BirdIdentifier
//
//  Created by Türker Kızılcık on 30.12.2024.
//

import SwiftUI
import TPackage

@main
struct BirdIdentifierApp: App {
    init() {
        TPackage.configure(withAPIKey: "appl_VPaGiXzlKHXmvZUClhWCvSAWYGT", entitlementIdentifier: "Premium")
    }
    var body: some Scene {
        WindowGroup {
            CustomPaywallView()
        }
    }
}
