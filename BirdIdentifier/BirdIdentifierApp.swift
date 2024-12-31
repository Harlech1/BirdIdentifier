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
    @StateObject var premiumManager = TKPremiumManager.shared
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var showInitialPaywall = false
    let persistenceController = CoreDataManager.shared

    init() {
        TPackage.configure(withAPIKey: "appl_VPaGiXzlKHXmvZUClhWCvSAWYGT", entitlementIdentifier: "Premium")
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if granted {
                print("Notification permission granted")
            } else if let error = error {
                print("Error requesting notification permission: \(error)")
            }
        }
        UIPageControl.appearance().currentPageIndicatorTintColor = .systemGreen
        UIPageControl.appearance().pageIndicatorTintColor = .systemGreen.withAlphaComponent(0.2)
    }

    var body: some Scene {
        WindowGroup {
            TabView {
                CollectionView()
                    .tabItem {
                        Image(systemName: "bird.fill")
                        Text("Habitat")
                    }

                SettingsView()
                    .tabItem {
                        Image(systemName: "gear")
                        Text("Settings")
                    }
            }
            .environmentObject(premiumManager)
            .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
