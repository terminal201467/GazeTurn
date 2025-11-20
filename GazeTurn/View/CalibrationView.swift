//
//  CalibrationView.swift
//  GazeTurn
//
//  Created by Claude Code on 2025/3/20.
//

import SwiftUI

/// 校準精靈介面
struct CalibrationView: View {

    // MARK: - Properties

    @StateObject private var viewModel: CalibrationViewModel
    @Environment(\.dismiss) private var dismiss

    /// 是否顯示跳過確認
    @State private var showingSkipConfirmation = false

    // MARK: - Initialization

    init(instrumentMode: InstrumentMode) {
        _viewModel = StateObject(wrappedValue: CalibrationViewModel(instrumentMode: instrumentMode))
    }

    // MARK: - Body

    var body: some View {
        NavigationView {
            ZStack {
                // 背景漸層
                LinearGradient(
                    colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    // 進度指示器
                    progressIndicator

                    // 步驟內容
                    ScrollView {
                        VStack(spacing: 24) {
                            stepContent
                        }
                        .padding()
                    }

                    // 底部按鈕
                    bottomButtons
                }
            }
            .navigationTitle("手勢校準")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("跳過") {
                        showingSkipConfirmation = true
                    }
                    .foregroundColor(.secondary)
                }
            }
            .confirmationDialog(
                "跳過校準？",
                isPresented: $showingSkipConfirmation,
                titleVisibility: .visible
            ) {
                Button("使用預設值", role: .destructive) {
                    viewModel.skipCalibration()
                    dismiss()
                }
                Button("繼續校準", role: .cancel) {}
            } message: {
                Text("跳過校準將使用預設的手勢檢測參數，可能影響準確度。")
            }
            .onAppear {
                setupCallbacks()
            }
        }
    }

    // MARK: - Progress Indicator

    private var progressIndicator: some View {
        VStack(spacing: 8) {
            // 步驟點
            HStack(spacing: 12) {
                ForEach(CalibrationStep.allCases, id: \.self) { step in
                    stepDot(for: step)
                }
            }
            .padding(.horizontal)

            // 進度條
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // 背景
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 4)

                    // 進度
                    Rectangle()
                        .fill(Color.blue)
                        .frame(width: geometry.size.width * overallProgress, height: 4)
                        .animation(.easeInOut, value: overallProgress)
                }
            }
            .frame(height: 4)
            .padding(.horizontal)
        }
        .padding(.vertical, 16)
        .background(Color(uiColor: .systemBackground))
    }

    private func stepDot(for step: CalibrationStep) -> some View {
        Circle()
            .fill(dotColor(for: step))
            .frame(width: 12, height: 12)
            .overlay(
                Circle()
                    .stroke(Color.blue, lineWidth: step == viewModel.currentStep ? 2 : 0)
                    .frame(width: 20, height: 20)
            )
    }

    private func dotColor(for step: CalibrationStep) -> Color {
        if step.rawValue < viewModel.currentStep.rawValue {
            return .green // 已完成
        } else if step == viewModel.currentStep {
            return .blue // 當前
        } else {
            return .gray.opacity(0.3) // 未開始
        }
    }

    private var overallProgress: Double {
        let stepProgress = Double(viewModel.currentStep.rawValue) / Double(CalibrationStep.allCases.count - 1)
        let inStepProgress = viewModel.progress * (1.0 / Double(CalibrationStep.allCases.count))
        return stepProgress + inStepProgress
    }

    // MARK: - Step Content

    @ViewBuilder
    private var stepContent: some View {
        VStack(spacing: 24) {
            // 標題
            Text(viewModel.currentStep.title)
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            // 說明
            Text(viewModel.currentStep.instruction)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            // 步驟特定內容
            switch viewModel.currentStep {
            case .welcome:
                welcomeContent
            case .blinkCalibration:
                blinkCalibrationContent
            case .headShakeCalibration:
                headShakeCalibrationContent
            case .verification:
                verificationContent
            case .complete:
                completeContent
            }

            // 狀態訊息
            if !viewModel.statusMessage.isEmpty {
                Text(viewModel.statusMessage)
                    .font(.callout)
                    .foregroundColor(.blue)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.blue.opacity(0.1))
                    )
            }
        }
    }

    // MARK: - Welcome Content

    private var welcomeContent: some View {
        VStack(spacing: 20) {
            Image(systemName: "hand.wave.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)

            VStack(alignment: .leading, spacing: 12) {
                FeatureRow(icon: "eye.fill", text: "校準您的眨眼檢測")
                FeatureRow(icon: "arrow.left.and.right", text: "校準您的搖頭檢測")
                FeatureRow(icon: "checkmark.circle.fill", text: "驗證校準結果")
            }
            .padding()
        }
    }

    // MARK: - Blink Calibration Content

    private var blinkCalibrationContent: some View {
        VStack(spacing: 24) {
            if viewModel.instrumentMode.enableBlink {
                // 眨眼動畫示意圖
                Image(systemName: viewModel.blinkSampleCount % 2 == 0 ? "eye.fill" : "eye.slash.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                    .animation(.easeInOut(duration: 0.3), value: viewModel.blinkSampleCount)

                // 進度環
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 10)
                        .frame(width: 120, height: 120)

                    Circle()
                        .trim(from: 0, to: viewModel.progress)
                        .stroke(Color.blue, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut, value: viewModel.progress)

                    VStack {
                        Text("\(viewModel.blinkSampleCount)")
                            .font(.system(size: 32, weight: .bold))
                        Text("/ \(viewModel.targetBlinkSamples)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Text("請自然地眨眼，不要用力")
                    .font(.callout)
                    .foregroundColor(.secondary)

            } else {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.green)

                Text("您的樂器模式不需要眨眼檢測")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Head Shake Calibration Content

    private var headShakeCalibrationContent: some View {
        VStack(spacing: 24) {
            if viewModel.instrumentMode.enableHeadShake {
                // 搖頭動畫示意圖
                HStack(spacing: 40) {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 40))
                        .foregroundColor(.blue)
                        .opacity(viewModel.headShakeSampleCount % 2 == 0 ? 1.0 : 0.3)

                    Image(systemName: "face.smiling")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)

                    Image(systemName: "arrow.right")
                        .font(.system(size: 40))
                        .foregroundColor(.blue)
                        .opacity(viewModel.headShakeSampleCount % 2 == 1 ? 1.0 : 0.3)
                }
                .animation(.easeInOut(duration: 0.3), value: viewModel.headShakeSampleCount)

                // 進度環
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 10)
                        .frame(width: 120, height: 120)

                    Circle()
                        .trim(from: 0, to: viewModel.progress)
                        .stroke(Color.purple, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut, value: viewModel.progress)

                    VStack {
                        Text("\(viewModel.headShakeSampleCount)")
                            .font(.system(size: 32, weight: .bold))
                        Text("/ \(viewModel.targetHeadShakeSamples)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Text("請適度地向左或向右搖頭")
                    .font(.callout)
                    .foregroundColor(.secondary)

            } else {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.green)

                Text("您的樂器模式不需要搖頭檢測")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Verification Content

    private var verificationContent: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)

            VStack(alignment: .leading, spacing: 12) {
                if viewModel.instrumentMode.enableBlink {
                    Text("✓ 眨眼檢測已校準")
                        .font(.headline)
                }

                if viewModel.instrumentMode.enableHeadShake {
                    Text("✓ 搖頭檢測已校準")
                        .font(.headline)
                }
            }

            Text("請嘗試執行手勢，確認檢測正常")
                .font(.callout)
                .foregroundColor(.secondary)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.orange.opacity(0.1))
                )
        }
    }

    // MARK: - Complete Content

    private var completeContent: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 100))
                .foregroundColor(.green)
                .symbolEffect(.bounce, value: viewModel.currentStep == .complete)

            Text("校準成功！")
                .font(.title2)
                .fontWeight(.semibold)

            Text("您的個人化手勢設定已儲存，現在可以開始使用免手翻頁功能了。")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            // 校準結果摘要
            VStack(alignment: .leading, spacing: 8) {
                Text("校準結果摘要")
                    .font(.headline)
                    .padding(.bottom, 4)

                if viewModel.instrumentMode.enableBlink {
                    ResultRow(title: "眨眼閾值", value: String(format: "%.3f", viewModel.instrumentMode.blinkThreshold))
                }

                if viewModel.instrumentMode.enableHeadShake {
                    ResultRow(title: "搖頭角度", value: String(format: "%.1f°", viewModel.instrumentMode.shakeAngleThreshold))
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(uiColor: .secondarySystemBackground))
            )
        }
    }

    // MARK: - Bottom Buttons

    private var bottomButtons: some View {
        HStack(spacing: 16) {
            // 上一步按鈕
            if viewModel.currentStep != .welcome && viewModel.currentStep != .complete {
                Button {
                    withAnimation {
                        viewModel.previousStep()
                    }
                } label: {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("上一步")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .foregroundColor(.primary)
                    .cornerRadius(12)
                }
            }

            // 下一步/完成按鈕
            Button {
                handleNextButton()
            } label: {
                HStack {
                    Text(nextButtonTitle)
                    if viewModel.currentStep != .complete {
                        Image(systemName: "chevron.right")
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(viewModel.isReadyForNextStep ? Color.blue : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(!viewModel.isReadyForNextStep)
        }
        .padding()
        .background(Color(uiColor: .systemBackground))
    }

    private var nextButtonTitle: String {
        switch viewModel.currentStep {
        case .complete:
            return "完成"
        case .verification:
            return "確認完成"
        default:
            return "下一步"
        }
    }

    // MARK: - Actions

    private func handleNextButton() {
        if viewModel.currentStep == .complete {
            dismiss()
        } else {
            withAnimation {
                viewModel.nextStep()
            }
        }
    }

    private func setupCallbacks() {
        viewModel.onCalibrationComplete = { mode in
            // 校準完成的回調處理
            print("Calibration completed for \(mode.instrumentType.displayName)")
        }
    }
}

// MARK: - Feature Row

struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 32)

            Text(text)
                .font(.body)
                .foregroundColor(.primary)

            Spacer()
        }
    }
}

// MARK: - Result Row

struct ResultRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()

            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
        }
    }
}

// MARK: - Preview

#Preview("Welcome Step") {
    CalibrationView(instrumentMode: InstrumentMode.stringInstrumentsMode())
}

#Preview("Keyboard Mode") {
    CalibrationView(instrumentMode: InstrumentMode.keyboardMode())
}

#Preview("Hybrid Mode") {
    CalibrationView(instrumentMode: InstrumentMode.woodwindBrassMode())
}
