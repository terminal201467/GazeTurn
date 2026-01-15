//
//  SettingsView.swift
//  GazeTurn
//
//  Created by Claude Code on 2025/11/21.
//

import SwiftUI
import UIKit

/// 設定介面 - 允許用戶調整手勢控制參數
struct SettingsView: View {

    // MARK: - Properties

    /// 當前樂器模式
    @State private var instrumentMode: InstrumentMode = InstrumentMode.current()

    /// 眨眼敏感度（0.01 - 0.10）
    @State private var blinkThreshold: Double

    /// 搖頭角度敏感度（15 - 60 度）
    @State private var shakeAngleThreshold: Double

    /// 搖頭持續時間（0.1 - 1.0 秒）
    @State private var shakeDuration: Double

    /// 確認超時時間（1.0 - 5.0 秒）
    @State private var confirmationTimeout: Double

    /// 是否顯示重置警告
    @State private var showingResetAlert: Bool = false

    /// 是否顯示樂器選擇
    @State private var showingInstrumentSelection: Bool = false

    /// 用於導航返回
    @Environment(\.dismiss) private var dismiss

    // MARK: - Initialization

    init() {
        let mode = InstrumentMode.current()
        _blinkThreshold = State(initialValue: mode.blinkThreshold)
        _shakeAngleThreshold = State(initialValue: mode.shakeAngleThreshold)
        _shakeDuration = State(initialValue: mode.shakeDuration)
        _confirmationTimeout = State(initialValue: mode.confirmationTimeout)
    }

    // MARK: - Body

    var body: some View {
        NavigationView {
            List {
                // 樂器選擇區塊
                instrumentSection

                // 眨眼設定區塊
                if instrumentMode.enableBlink {
                    blinkSection
                }

                // 搖頭設定區塊
                if instrumentMode.enableHeadShake {
                    headShakeSection
                }

                // 混合模式設定
                if instrumentMode.requireConfirmation {
                    hybridModeSection
                }

                // 操作區塊
                actionSection
            }
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                    .accessibilityIdentifier("cancelButton")
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("儲存") {
                        saveSettings()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .accessibilityIdentifier("saveButton")
                }
            }
        }
        .sheet(isPresented: $showingInstrumentSelection) {
            InstrumentSelectionView(
                isFirstLaunch: false,
                onInstrumentSelected: { instrument in
                    updateInstrumentMode(instrument)
                },
                onSkip: {
                    // 不執行任何操作
                }
            )
        }
        .alert("重置設定", isPresented: $showingResetAlert) {
            Button("重置", role: .destructive) {
                resetToDefaults()
            }
            Button("取消", role: .cancel) { }
        } message: {
            Text("這將會重置所有手勢控制設定為預設值。此操作無法復原。")
        }
    }

    // MARK: - View Components

    /// 樂器選擇區塊
    private var instrumentSection: some View {
        Section {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: instrumentMode.instrumentType.iconName)
                            .font(.title2)
                            .foregroundColor(.blue)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(instrumentMode.instrumentType.displayName)
                                .font(.headline)

                            Text(instrumentMode.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Spacer()

                Button("更改") {
                    showingInstrumentSelection = true
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .accessibilityIdentifier("changeInstrumentButton")
            }
            .padding(.vertical, 4)
        } header: {
            Text("樂器類型")
                .accessibilityIdentifier("instrumentTypeHeader")
        } footer: {
            Text("不同樂器類型有不同的預設手勢控制設定")
        }
    }

    /// 眨眼設定區塊
    private var blinkSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                Text("眨眼敏感度")
                    .font(.headline)

                HStack {
                    Text("低")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Slider(value: $blinkThreshold, in: 0.01...0.10, step: 0.005) {
                        Text("眨眼敏感度")
                    }
                    .accentColor(.blue)
                    .accessibilityIdentifier("blinkThresholdSlider")

                    Text("高")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("當前值：")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(String(format: "%.3f", blinkThreshold))
                        .font(.caption)
                        .foregroundColor(.primary)

                    Spacer()
                }
            }
            .padding(.vertical, 4)
        } header: {
            Text("眨眼控制")
        } footer: {
            Text("較低的數值表示較容易觸發眨眼檢測，但可能增加誤觸率")
        }
    }

    /// 搖頭設定區塊
    private var headShakeSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 16) {
                // 搖頭角度設定
                VStack(alignment: .leading, spacing: 8) {
                    Text("搖頭角度敏感度")
                        .font(.headline)

                    HStack {
                        Text("15°")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Slider(value: $shakeAngleThreshold, in: 15...60, step: 5) {
                            Text("搖頭角度")
                        }
                        .accentColor(.green)
                        .accessibilityIdentifier("shakeAngleSlider")

                        Text("60°")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("當前值：")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text("\(Int(shakeAngleThreshold))°")
                            .font(.caption)
                            .foregroundColor(.primary)

                        Spacer()
                    }
                }

                // 搖頭持續時間設定
                VStack(alignment: .leading, spacing: 8) {
                    Text("搖頭持續時間")
                        .font(.headline)

                    HStack {
                        Text("0.1s")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Slider(value: $shakeDuration, in: 0.1...1.0, step: 0.1) {
                            Text("搖頭持續時間")
                        }
                        .accentColor(.green)
                        .accessibilityIdentifier("shakeDurationSlider")

                        Text("1.0s")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("當前值：")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text(String(format: "%.1fs", shakeDuration))
                            .font(.caption)
                            .foregroundColor(.primary)

                        Spacer()
                    }
                }
            }
            .padding(.vertical, 4)
        } header: {
            Text("搖頭控制")
        } footer: {
            Text("較大的角度和較長的持續時間可以降低意外觸發，但需要更明顯的頭部動作")
        }
    }

    /// 混合模式設定區塊
    private var hybridModeSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                Text("確認超時時間")
                    .font(.headline)

                HStack {
                    Text("1.0s")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Slider(value: $confirmationTimeout, in: 1.0...5.0, step: 0.5) {
                        Text("確認超時時間")
                    }
                    .accentColor(.orange)
                    .accessibilityIdentifier("confirmationTimeoutSlider")

                    Text("5.0s")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("當前值：")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(String(format: "%.1fs", confirmationTimeout))
                        .font(.caption)
                        .foregroundColor(.primary)

                    Spacer()
                }
            }
            .padding(.vertical, 4)
        } header: {
            Text("混合模式")
        } footer: {
            Text("搖頭後等待眨眼確認的時間。較長的時間給您更多時間確認，但可能影響使用流暢性")
        }
    }

    /// 操作區塊
    private var actionSection: some View {
        Section {
            HStack {
                Button {
                    showingResetAlert = true
                } label: {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("重置為預設值")
                    }
                    .foregroundColor(.red)
                }
                .accessibilityIdentifier("resetButton")

                Spacer()
            }
            .padding(.vertical, 4)
        } footer: {
            Text("重置會將所有設定恢復為當前樂器類型的預設值")
        }
    }

    // MARK: - Methods

    /// 更新樂器模式
    private func updateInstrumentMode(_ instrumentType: InstrumentType) {
        let newMode = InstrumentMode.modeFor(instrumentType: instrumentType)
        instrumentMode = newMode

        // 更新滑桿值為新樂器的預設值
        blinkThreshold = newMode.blinkThreshold
        shakeAngleThreshold = newMode.shakeAngleThreshold
        shakeDuration = newMode.shakeDuration
        confirmationTimeout = newMode.confirmationTimeout
    }

    /// 儲存設定
    private func saveSettings() {
        let updatedMode = InstrumentMode(
            instrumentType: instrumentMode.instrumentType,
            enableBlink: instrumentMode.enableBlink,
            blinkThreshold: blinkThreshold,
            blinkTimeWindow: instrumentMode.blinkTimeWindow,
            minBlinkDuration: instrumentMode.minBlinkDuration,
            requiredBlinkCount: instrumentMode.requiredBlinkCount,
            longBlinkDuration: instrumentMode.longBlinkDuration,
            enableHeadShake: instrumentMode.enableHeadShake,
            shakeAngleThreshold: shakeAngleThreshold,
            shakeDuration: shakeDuration,
            shakeCooldown: instrumentMode.shakeCooldown,
            requireConfirmation: instrumentMode.requireConfirmation,
            confirmationTimeout: confirmationTimeout
        )

        updatedMode.save()

        // 提供觸覺反饋
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }

    /// 重置為預設值
    private func resetToDefaults() {
        let defaultMode = InstrumentMode.modeFor(instrumentType: instrumentMode.instrumentType)

        blinkThreshold = defaultMode.blinkThreshold
        shakeAngleThreshold = defaultMode.shakeAngleThreshold
        shakeDuration = defaultMode.shakeDuration
        confirmationTimeout = defaultMode.confirmationTimeout

        // 提供觸覺反饋
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
}

// MARK: - Previews

#Preview {
    SettingsView()
}