//
//  GazeTurnApp.swift
//  GazeTurn
//
//  Created by Jhen Mu on 2025/3/9.
//

import SwiftUI

@main
struct GazeTurnApp: App {

    init() {
        // 處理 UI 測試的啟動參數
        #if DEBUG
        if CommandLine.arguments.contains("--uitesting") {
            // UI 測試模式 - 重置 UserDefaults
            if let bundleID = Bundle.main.bundleIdentifier {
                UserDefaults.standard.removePersistentDomain(forName: bundleID)
            }
        }
        if CommandLine.arguments.contains("--reset-onboarding") {
            // 重置 onboarding 狀態
            UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")
        }
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
