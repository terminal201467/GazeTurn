//
//  InstrumentSelectionView.swift
//  GazeTurn
//
//  Created by Claude Code on 2025/3/20.
//

import SwiftUI

/// 樂器選擇介面 - 用於首次啟動或更改樂器類型
struct InstrumentSelectionView: View {

    // MARK: - Properties

    /// 是否為首次啟動
    let isFirstLaunch: Bool

    /// 選擇完成的回調
    var onInstrumentSelected: ((InstrumentType) -> Void)?

    /// 跳過選擇的回調
    var onSkip: (() -> Void)?

    /// 當前選中的樂器類型
    @State private var selectedInstrument: InstrumentType?

    /// 是否顯示詳細資訊
    @State private var showingDetail: Bool = false

    /// 是否顯示校準介面
    @State private var showingCalibration: Bool = false

    /// 選中的樂器模式（用於傳遞給校準介面）
    @State private var selectedMode: InstrumentMode?

    /// 用於導航返回
    @Environment(\.dismiss) private var dismiss

    // MARK: - Body

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // 標題區域
                    headerSection

                    // 樂器選擇網格
                    instrumentGrid

                    // 底部按鈕
                    if isFirstLaunch {
                        skipButton
                    }
                }
                .padding()
            }
            .navigationTitle(isFirstLaunch ? "選擇您的樂器" : "更改樂器")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if !isFirstLaunch {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("取消") {
                            dismiss()
                        }
                        .accessibilityIdentifier("cancelButton")
                    }
                }
            }
            .sheet(isPresented: $showingCalibration) {
                if let mode = selectedMode {
                    CalibrationView(instrumentMode: mode)
                }
            }
        }
    }

    // MARK: - View Components

    /// 標題說明區域
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "music.note.list")
                .font(.system(size: 60))
                .foregroundColor(.accentColor)

            Text(isFirstLaunch ? "歡迎使用 GazeTurn" : "選擇您的樂器")
                .font(.title2)
                .fontWeight(.bold)

            Text("根據您的樂器類型，我們會自動配置最適合的手勢控制方式")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.vertical)
    }

    /// 樂器選擇網格
    private var instrumentGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16)
        ], spacing: 16) {
            ForEach(InstrumentType.allCases.filter { $0 != .custom }, id: \.self) { instrument in
                InstrumentCard(
                    instrument: instrument,
                    isSelected: selectedInstrument == instrument
                ) {
                    handleInstrumentSelection(instrument)
                }
            }
        }
    }

    /// 跳過按鈕
    private var skipButton: some View {
        VStack(spacing: 12) {
            Divider()
                .padding(.vertical)

            Button(action: {
                onSkip?()
            }) {
                Text("暫時跳過")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .accessibilityIdentifier("skipButton")

            Text("跳過後將使用鍵盤模式（搖頭控制，不進行校準）")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Actions

    /// 處理樂器選擇
    private func handleInstrumentSelection(_ instrument: InstrumentType) {
        selectedInstrument = instrument

        // 觸覺反饋
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        // 創建樂器模式
        let mode = InstrumentMode.defaultMode(for: instrument)
        selectedMode = mode

        // 延遲一下以顯示選中效果，然後顯示校準介面
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            if isFirstLaunch {
                // 首次啟動時顯示校準介面
                showingCalibration = true
            } else {
                // 更改樂器時直接儲存並通知
                mode.save()
                onInstrumentSelected?(instrument)
                dismiss()
            }
        }
    }
}

// MARK: - Instrument Card

/// 樂器選擇卡片
struct InstrumentCard: View {
    let instrument: InstrumentType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                // 圖示
                Image(systemName: instrument.iconName)
                    .font(.system(size: 40))
                    .foregroundColor(isSelected ? .white : .accentColor)
                    .frame(height: 50)

                // 樂器名稱
                Text(instrument.displayName)
                    .font(.headline)
                    .foregroundColor(isSelected ? .white : .primary)

                // 控制方式說明
                Text(instrument.controlModeDescription)
                    .font(.caption)
                    .foregroundColor(isSelected ? .white.opacity(0.9) : .secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .frame(height: 180)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color.accentColor : Color(.systemBackground))
                    .shadow(color: .black.opacity(isSelected ? 0.2 : 0.1), radius: isSelected ? 8 : 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.clear : Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        .accessibilityIdentifier("instrumentCard_\(instrument.rawValue)")
    }
}

// MARK: - Preview

#Preview("First Launch") {
    InstrumentSelectionView(
        isFirstLaunch: true,
        onInstrumentSelected: { instrument in
            print("Selected: \(instrument.displayName)")
        },
        onSkip: {
            print("Skipped")
        }
    )
}

#Preview("Change Instrument") {
    InstrumentSelectionView(
        isFirstLaunch: false,
        onInstrumentSelected: { instrument in
            print("Selected: \(instrument.displayName)")
        }
    )
}

#Preview("Instrument Card") {
    VStack {
        HStack(spacing: 16) {
            InstrumentCard(
                instrument: .keyboard,
                isSelected: false,
                action: {}
            )

            InstrumentCard(
                instrument: .stringInstruments,
                isSelected: true,
                action: {}
            )
        }
        .padding()
    }
}
