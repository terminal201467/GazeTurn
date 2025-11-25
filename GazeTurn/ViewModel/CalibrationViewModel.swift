//
//  CalibrationViewModel.swift
//  GazeTurn
//
//  Created by Claude Code on 2025/3/20.
//

import Foundation
import Combine
import AVFoundation
import Vision
import UIKit

/// 校準步驟
enum CalibrationStep: Int, CaseIterable {
    case welcome = 0
    case blinkCalibration = 1
    case headShakeCalibration = 2
    case verification = 3
    case complete = 4

    var title: String {
        switch self {
        case .welcome:
            return "歡迎使用校準精靈"
        case .blinkCalibration:
            return "眨眼校準"
        case .headShakeCalibration:
            return "搖頭校準"
        case .verification:
            return "驗證校準"
        case .complete:
            return "校準完成"
        }
    }

    var instruction: String {
        switch self {
        case .welcome:
            return "我們將引導您進行手勢校準，以確保最佳的檢測效果。整個過程約需 2-3 分鐘。"
        case .blinkCalibration:
            return "請在聽到提示音時進行眨眼，我們會記錄您的自然眨眼特徵。"
        case .headShakeCalibration:
            return "請在聽到提示音時向左或向右搖頭，幅度適中即可。"
        case .verification:
            return "讓我們驗證校準結果。請嘗試執行以下手勢。"
        case .complete:
            return "校準已完成！您的個人化設定已儲存。"
        }
    }
}

/// 校準樣本類型
enum CalibrationSampleType {
    case blinkSample(eyeHeight: Double)
    case headShakeSample(yawAngle: Double, direction: HeadShakeDirection)
}

/// 校準向導狀態
enum CalibrationWizardStatus: Equatable {
    case idle
    case collectingSamples
    case calculating
    case completed
    case failed(Error)

    static func == (lhs: CalibrationWizardStatus, rhs: CalibrationWizardStatus) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle),
             (.collectingSamples, .collectingSamples),
             (.calculating, .calculating),
             (.completed, .completed):
            return true

        case (.failed, .failed):
            return true    // ❗忽略 Error，不比較

        default:
            return false
        }
    }
}

/// 校準 ViewModel
class CalibrationViewModel: ObservableObject {

    // MARK: - Published Properties

    /// 當前步驟
    @Published var currentStep: CalibrationStep = .welcome

    /// 校準狀態
    @Published var status: CalibrationWizardStatus = .idle

    /// 進度（0.0 ~ 1.0）
    @Published var progress: Double = 0.0

    /// 狀態訊息
    @Published var statusMessage: String = ""

    /// 是否準備好進入下一步
    @Published var isReadyForNextStep: Bool = true

    /// 相機是否可用
    @Published var isCameraAvailable: Bool = false

    /// 眨眼樣本數量
    @Published var blinkSampleCount: Int = 0

    /// 搖頭樣本數量
    @Published var headShakeSampleCount: Int = 0

    /// 目標樣本數量
    let targetBlinkSamples = 10
    let targetHeadShakeSamples = 8

    // MARK: - Components

    private let cameraManager: CameraManager
    private let visionProcessor: VisionProcessor
    private let blinkRecognizer: BlinkRecognizer
    private let headPoseDetector: HeadPoseDetector

    // MARK: - Calibration Data

    private var blinkSamples: [Double] = []
    private var headShakeSamples: [(angle: Double, direction: HeadShakeDirection)] = []

    /// 正在校準的樂器模式
    var instrumentMode: InstrumentMode

    /// 校準完成回調
    var onCalibrationComplete: ((InstrumentMode) -> Void)?

    // MARK: - Initialization

    init(instrumentMode: InstrumentMode) {
        self.instrumentMode = instrumentMode
        self.cameraManager = CameraManager()
        self.visionProcessor = VisionProcessor()
        self.blinkRecognizer = BlinkRecognizer()
        self.headPoseDetector = HeadPoseDetector()

        self.cameraManager.delegate = self
    }

    // MARK: - Step Control

    /// 前往下一步
    func nextStep() {
        guard let nextStep = CalibrationStep(rawValue: currentStep.rawValue + 1) else {
            return
        }

        currentStep = nextStep
        prepareCurrentStep()
    }

    /// 返回上一步
    func previousStep() {
        guard currentStep.rawValue > 0,
              let previousStep = CalibrationStep(rawValue: currentStep.rawValue - 1) else {
            return
        }

        currentStep = previousStep
        prepareCurrentStep()
    }

    /// 準備當前步驟
    private func prepareCurrentStep() {
        isReadyForNextStep = false

        switch currentStep {
        case .welcome:
            statusMessage = "準備開始校準"
            isReadyForNextStep = true

        case .blinkCalibration:
            if instrumentMode.enableBlink {
                startBlinkCalibration()
            } else {
                // 跳過此步驟
                statusMessage = "您的模式不需要眨眼校準"
                isReadyForNextStep = true
            }

        case .headShakeCalibration:
            if instrumentMode.enableHeadShake {
                startHeadShakeCalibration()
            } else {
                // 跳過此步驟
                statusMessage = "您的模式不需要搖頭校準"
                isReadyForNextStep = true
            }

        case .verification:
            startVerification()

        case .complete:
            finishCalibration()
        }
    }

    // MARK: - Blink Calibration

    private func startBlinkCalibration() {
        blinkSamples.removeAll()
        blinkSampleCount = 0
        status = .collectingSamples
        statusMessage = "請正常眨眼 \(targetBlinkSamples) 次"
        progress = 0.0

        startCamera()
    }

    private func recordBlinkSample(eyeHeight: Double) {
        guard status == .collectingSamples,
              currentStep == .blinkCalibration else {
            return
        }

        blinkSamples.append(eyeHeight)
        blinkSampleCount = blinkSamples.count
        progress = Double(blinkSampleCount) / Double(targetBlinkSamples)

        // 觸覺反饋
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()

        if blinkSampleCount >= targetBlinkSamples {
            calculateBlinkThreshold()
        } else {
            statusMessage = "已記錄 \(blinkSampleCount)/\(targetBlinkSamples) 次眨眼"
        }
    }

    private func calculateBlinkThreshold() {
        status = .calculating
        statusMessage = "正在計算最佳閾值..."

        DispatchQueue.global(qos: .userInitiated).async {
            // 計算閉眼時的平均眼睛高度
            let closedEyeHeights = self.blinkSamples.sorted().prefix(self.targetBlinkSamples / 2)
            let averageClosedHeight = closedEyeHeights.reduce(0.0, +) / Double(closedEyeHeights.count)

            // 設定閾值略高於閉眼高度，以確保準確檢測
            let calculatedThreshold = averageClosedHeight * 1.2

            DispatchQueue.main.async {
                // 更新樂器模式
                self.instrumentMode = InstrumentMode(
                    instrumentType: self.instrumentMode.instrumentType,
                    enableBlink: self.instrumentMode.enableBlink,
                    blinkThreshold: calculatedThreshold,
                    blinkTimeWindow: self.instrumentMode.blinkTimeWindow,
                    minBlinkDuration: self.instrumentMode.minBlinkDuration,
                    requiredBlinkCount: self.instrumentMode.requiredBlinkCount,
                    longBlinkDuration: self.instrumentMode.longBlinkDuration,
                    enableHeadShake: self.instrumentMode.enableHeadShake,
                    shakeAngleThreshold: self.instrumentMode.shakeAngleThreshold,
                    shakeDuration: self.instrumentMode.shakeDuration,
                    shakeCooldown: self.instrumentMode.shakeCooldown,
                    requireConfirmation: self.instrumentMode.requireConfirmation,
                    confirmationTimeout: self.instrumentMode.confirmationTimeout
                )

                self.status = .completed
                self.statusMessage = "眨眼校準完成"
                self.isReadyForNextStep = true

                // 停止相機
                self.stopCamera()
            }
        }
    }

    // MARK: - Head Shake Calibration

    private func startHeadShakeCalibration() {
        headShakeSamples.removeAll()
        headShakeSampleCount = 0
        status = .collectingSamples
        statusMessage = "請向左或向右搖頭 \(targetHeadShakeSamples) 次"
        progress = 0.0

        startCamera()
    }

    private func recordHeadShakeSample(yawAngle: Double, direction: HeadShakeDirection) {
        guard status == .collectingSamples,
              currentStep == .headShakeCalibration,
              direction != .none else {
            return
        }

        headShakeSamples.append((angle: abs(yawAngle), direction: direction))
        headShakeSampleCount = headShakeSamples.count
        progress = Double(headShakeSampleCount) / Double(targetHeadShakeSamples)

        // 觸覺反饋
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()

        if headShakeSampleCount >= targetHeadShakeSamples {
            calculateHeadShakeThreshold()
        } else {
            statusMessage = "已記錄 \(headShakeSampleCount)/\(targetHeadShakeSamples) 次搖頭"
        }
    }

    private func calculateHeadShakeThreshold() {
        status = .calculating
        statusMessage = "正在計算最佳閾值..."

        DispatchQueue.global(qos: .userInitiated).async {
            // 計算平均搖頭角度
            let angles = self.headShakeSamples.map { $0.angle }
            let averageAngle = angles.reduce(0.0, +) / Double(angles.count)

            // 計算標準差
            let variance = angles.map { pow($0 - averageAngle, 2) }.reduce(0.0, +) / Double(angles.count)
            let standardDeviation = sqrt(variance)

            // 設定閾值為平均值減去一個標準差（確保大部分手勢都能被檢測到）
            let calculatedThreshold = max(averageAngle - standardDeviation, 15.0) // 最小 15 度

            DispatchQueue.main.async {
                // 更新樂器模式
                self.instrumentMode = InstrumentMode(
                    instrumentType: self.instrumentMode.instrumentType,
                    enableBlink: self.instrumentMode.enableBlink,
                    blinkThreshold: self.instrumentMode.blinkThreshold,
                    blinkTimeWindow: self.instrumentMode.blinkTimeWindow,
                    minBlinkDuration: self.instrumentMode.minBlinkDuration,
                    requiredBlinkCount: self.instrumentMode.requiredBlinkCount,
                    longBlinkDuration: self.instrumentMode.longBlinkDuration,
                    enableHeadShake: self.instrumentMode.enableHeadShake,
                    shakeAngleThreshold: calculatedThreshold,
                    shakeDuration: self.instrumentMode.shakeDuration,
                    shakeCooldown: self.instrumentMode.shakeCooldown,
                    requireConfirmation: self.instrumentMode.requireConfirmation,
                    confirmationTimeout: self.instrumentMode.confirmationTimeout
                )

                self.status = .completed
                self.statusMessage = "搖頭校準完成"
                self.isReadyForNextStep = true

                // 停止相機
                self.stopCamera()
            }
        }
    }

    // MARK: - Verification

    private func startVerification() {
        statusMessage = "請執行手勢進行驗證"
        isReadyForNextStep = true
        startCamera()
    }

    // MARK: - Finish

    private func finishCalibration() {
        // 儲存校準結果
        instrumentMode.save()

        statusMessage = "校準已儲存"
        isReadyForNextStep = true

        // 通知完成
        onCalibrationComplete?(instrumentMode)

        stopCamera()
    }

    // MARK: - Camera Management

    func startCamera() {
        cameraManager.startSession()
        isCameraAvailable = true
    }

    func stopCamera() {
        cameraManager.stopSession()
        isCameraAvailable = false
    }

    // MARK: - Skip Calibration

    func skipCalibration() {
        // 使用預設值
        instrumentMode.save()
        onCalibrationComplete?(instrumentMode)
    }
}

// MARK: - CameraManagerDelegate

extension CalibrationViewModel: CameraManagerDelegate {
    func didCaptureFrame(_ sampleBuffer: CMSampleBuffer) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }

        // 處理影像幀
        guard let faceObservation = visionProcessor.processFrame(pixelBuffer) else {
            return
        }

        // 根據當前步驟處理不同的手勢
        switch currentStep {
        case .blinkCalibration:
            // 記錄眼睛高度
            if let leftEye = faceObservation.landmarks?.leftEye,
               let rightEye = faceObservation.landmarks?.rightEye {
                let leftHeight = calculateEyeHeight(landmark: leftEye)
                let rightHeight = calculateEyeHeight(landmark: rightEye)
                let averageHeight = (leftHeight + rightHeight) / 2.0

                // 檢測眨眼事件
                let leftOpen = isEyeOpen(landmark: leftEye)
                let rightOpen = isEyeOpen(landmark: rightEye)

                if blinkRecognizer.detectBlink(leftOpen: leftOpen, rightOpen: rightOpen) {
                    DispatchQueue.main.async {
                        self.recordBlinkSample(eyeHeight: averageHeight)
                    }
                }
            }

        case .headShakeCalibration:
            // 記錄搖頭角度
            if let yaw = faceObservation.yaw?.doubleValue {
                let direction = headPoseDetector.detectShake(from: faceObservation)

                if direction != .none {
                    DispatchQueue.main.async {
                        self.recordHeadShakeSample(yawAngle: yaw, direction: direction)
                    }
                }
            }

        case .verification, .complete:
            // 驗證階段，僅顯示檢測結果
            break

        default:
            break
        }
    }

    /// 計算眼睛高度
    private func calculateEyeHeight(landmark: VNFaceLandmarkRegion2D) -> Double {
        let points = landmark.normalizedPoints
        guard points.count >= 6 else { return 0.0 }

        // 計算上下眼瞼的距離
        let eyeHeight = abs(points[1].y - points[5].y)
        return eyeHeight
    }

    /// 判斷眼睛是否張開
    private func isEyeOpen(landmark: VNFaceLandmarkRegion2D) -> Bool {
        let eyeHeight = calculateEyeHeight(landmark: landmark)
        return eyeHeight > instrumentMode.blinkThreshold
    }
}
