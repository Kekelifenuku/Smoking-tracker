//
//  Smoking_trackerApp.swift
//  Smoking tracker
//
//  Created by Fenuku kekeli on 8/15/25.
//

import SwiftUI

@main
struct Smoking_trackerApp: App {
    @StateObject private var data = SmokingTrackerData()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(data)
        }
    }
}
