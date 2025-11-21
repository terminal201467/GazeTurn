//
//  ContentView.swift
//  GazeTurn
//
//  Created by Jhen Mu on 2025/3/9.
//

import SwiftUI

struct ContentView: View {

    // MARK: - Properties

    /// 是否為首次啟動
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false

    /// 是否顯示樂器選擇介面
    @State private var showingInstrumentSelection: Bool = false

    /// 是否顯示設定介面
    @State private var showingSettings: Bool = false

    /// 當前選擇的樂器類型
    @State private var currentInstrument: InstrumentType = InstrumentMode.current().instrumentType

    // MARK: - Body

    var body: some View {
        Group {
            if !hasCompletedOnboarding {
                // 首次啟動：顯示樂器選擇
                InstrumentSelectionView(
                    isFirstLaunch: true,
                    onInstrumentSelected: { instrument in
                        currentInstrument = instrument
                        hasCompletedOnboarding = true
                    },
                    onSkip: {
                        // 使用預設鍵盤模式
                        currentInstrument = .keyboard
                        hasCompletedOnboarding = true
                    }
                )
            } else {
                // 主介面
                mainView
            }
        }
        .sheet(isPresented: $showingInstrumentSelection) {
            InstrumentSelectionView(
                isFirstLaunch: false,
                onInstrumentSelected: { instrument in
                    currentInstrument = instrument
                    showingInstrumentSelection = false
                }
            )
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
    }

    // MARK: - Main View

    private var mainView: some View {
        NavigationStack {
            FileListView()
                .navigationTitle("GazeTurn")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        settingsMenu
                    }
                }
        }
    }

    // MARK: - Settings Menu

    private var settingsMenu: some View {
        Menu {
            // 當前樂器資訊
            Section {
                Label(currentInstrument.displayName, systemImage: currentInstrument.iconName)
                Text(currentInstrument.controlModeDescription)
                    .font(.caption)
            }

            Divider()

            // 手勢設定
            Button {
                showingSettings = true
            } label: {
                Label("手勢設定", systemImage: "slider.horizontal.3")
            }

            // 更改樂器
            Button {
                showingInstrumentSelection = true
            } label: {
                Label("更改樂器", systemImage: "music.note")
            }

            // 重置引導
            Button(role: .destructive) {
                hasCompletedOnboarding = false
            } label: {
                Label("重置引導", systemImage: "arrow.counterclockwise")
            }
        } label: {
            Image(systemName: "gear")
        }
    }
}

// MARK: - Preview

#Preview("First Launch") {
    ContentView()
}

#Preview("Main View") {
    ContentView(hasCompletedOnboarding: true)
}
