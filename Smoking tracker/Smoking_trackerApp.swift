//
//  Smoking_trackerApp.swift
//  Smoking tracker
//
//  Created by Fenuku kekeli on 8/15/25.
//

import SwiftUI
import StoreKit

@main
struct Smoking_trackerApp: App {
    @StateObject private var data = SmokingTrackerData()
    @AppStorage("launchCount") private var launchCount: Int = 0

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(data)
                .onAppear {
                    incrementLaunchCount()
                }
        }
    }

    private func incrementLaunchCount() {
        launchCount += 1
        print("App launched \(launchCount) times")

        // Request review after 3 launches (adjust as needed)
        if launchCount == 3 {
            requestAppReview()
        }
    }

    private func requestAppReview() {
        if let scene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
            SKStoreReviewController.requestReview(in: scene)
        }
    }
}
