//
//  GazeTurnViewModel.swift
//  GazeTurn
//
//  Created by Claude Code on 2025/3/20.
//

import Foundation
import Combine
import AVFoundation
import Vision
import UIKit

/// GazeTurn 主視圖模型，統一管理所有手勢檢測和頁面控制組件
class GazeTurnViewModel: ObservableObject {

    // MARK: - Published Properties

    /// 當前頁面索引
    @Published var currentPage: Int = 0

    /// 總頁數
    @Published var totalPages: Int = 1

    /// 是否正在處理手勢
    @Published var isProcessingGesture: Bool = false

    /// 手勢檢測狀態訊息（用於除錯）
    @Published var gestureStatusMessage: String = ""

    /// 是否等待確認（混合模式）
    @Published var isWaitingForConfirmation: Bool = false

    /// 等待確認的方向
    @Published var pendingDirection: PageDirection?

    /// 相機是否可用
    @Published var isCameraAvailable: Bool = false

    /// 相機權限狀態
    @Published var cameraPermissionStatus: AVAuthorizationStatus = .notDetermined

    /// 手勢視覺化數據
    @Published var visualizationData: GestureVisualizationData = GestureVisualizationData()

    // MARK: - Components

    private let cameraManager: CameraManager
    private let visionProcessor: VisionProcessor
    private let blinkRecognizer: BlinkRecognizer
    private let headPoseDetector: HeadPoseDetector
    private let gestureCoordinator: GestureCoordinator

    // MARK: - Page Control

    /// 頁面控制回調（由 BrowseView 設定）
    var onPageChange: ((Int) -> Void)?

    // MARK: - Initialization

    /// 初始化 ViewModel
    /// - Parameter instrumentMode: 樂器模式（預設使用當前儲存的模式）
    init(instrumentMode: InstrumentMode = InstrumentMode.current()) {
        // 初始化組件
        self.cameraManager = CameraManager()
        self.visionProcessor = VisionProcessor()
        self.blinkRecognizer = BlinkRecognizer()
        self.headPoseDetector = HeadPoseDetector()
        self.gestureCoordinator = GestureCoordinator(
            mode: instrumentMode,
            blinkRecognizer: blinkRecognizer,
            headPoseDetector: headPoseDetector
        )

        // 設定 delegates
        self.cameraManager.delegate = self
        self.gestureCoordinator.delegate = self

        // 檢查相機權限
        checkCameraPermission()
    }

    // MARK: - Camera Management

    /// 開始相機捕捉
    func startCamera() {
        // 重新檢查權限狀態
        checkCameraPermission()

        guard cameraPermissionStatus == .authorized else {
            print("相機權限未授權，當前狀態: \(cameraPermissionStatus.rawValue)")
            return
        }

        print("正在啟動相機...")
        cameraManager.startSession()
        isCameraAvailable = true
        updateGestureStatus("相機已啟動")
        print("相機已啟動，樂器模式: \(gestureCoordinator.currentMode.instrumentType.displayName)")
        print("啟用搖頭: \(gestureCoordinator.currentMode.enableHeadShake), 啟用眨眼: \(gestureCoordinator.currentMode.enableBlink)")
    }

    /// 停止相機捕捉
    func stopCamera() {
        cameraManager.stopSession()
        isCameraAvailable = false
        updateGestureStatus("相機已停止")
    }

    /// 檢查相機權限
    func checkCameraPermission() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        // 同步更新，避免時機問題
        self.cameraPermissionStatus = status
    }

    /// 請求相機權限
    func requestCameraPermission(completion: @escaping (Bool) -> Void) {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                self.cameraPermissionStatus = granted ? .authorized : .denied
                completion(granted)
            }
        }
    }

    // MARK: - Gesture Control

    /// 更新樂器模式
    func updateInstrumentMode(_ mode: InstrumentMode) {
        gestureCoordinator.updateMode(mode)
        updateGestureStatus("已切換至 \(mode.instrumentType.displayName) 模式")
    }

    /// 手動翻頁（用於測試或備用控制）
    func manualPageTurn(direction: PageDirection) {
        handlePageTurn(direction: direction)
    }

    // MARK: - Page Navigation

    private func handlePageTurn(direction: PageDirection) {
        let newPage: Int

        switch direction {
        case .next:
            newPage = min(currentPage + 1, totalPages - 1)
        case .previous:
            newPage = max(currentPage - 1, 0)
        }

        guard newPage != currentPage else {
            updateGestureStatus("已在\(direction == .next ? "最後" : "第一")頁")
            return
        }

        currentPage = newPage
        onPageChange?(newPage)

        // 觸覺反饋
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        updateGestureStatus("翻至第 \(newPage + 1) 頁")
    }

    // MARK: - Status Updates

    private func updateGestureStatus(_ message: String) {
        DispatchQueue.main.async {
            self.gestureStatusMessage = message
        }
    }

    // MARK: - Public Methods

    /// 重置頁面
    func resetPage() {
        currentPage = 0
        onPageChange?(0)
    }

    /// 設定總頁數
    func setTotalPages(_ count: Int) {
        totalPages = count
    }

    /// 獲取當前狀態描述
    func getStatusDescription() -> String {
        var status = "狀態：\n"
        status += "- 相機：\(isCameraAvailable ? "運行中" : "未啟動")\n"
        status += "- 當前頁面：\(currentPage + 1) / \(totalPages)\n"
        status += "- 樂器模式：\(gestureCoordinator.currentMode.instrumentType.displayName)\n"
        status += "- 等待確認：\(isWaitingForConfirmation ? "是" : "否")\n"
        return status
    }

    deinit {
        stopCamera()
    }
}

// MARK: - CameraManagerDelegate

extension GazeTurnViewModel: CameraManagerDelegate {
    // 用於限制日誌輸出頻率
    private static var frameCount = 0
    private static var lastLogTime = Date()

    func didCaptureFrame(_ sampleBuffer: CMSampleBuffer) {
        // 在背景執行緒處理 Vision
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            print("無法取得 pixelBuffer")
            return
        }

        // 每 60 幀輸出一次日誌
        GazeTurnViewModel.frameCount += 1
        if GazeTurnViewModel.frameCount % 60 == 0 {
            print("已處理 \(GazeTurnViewModel.frameCount) 幀")
        }

        // 處理影像幀
        guard let faceObservation = visionProcessor.processFrame(pixelBuffer) else {
            // 未偵測到臉部
            DispatchQueue.main.async {
                self.visualizationData.faceDetected = false
            }
            // 每 2 秒輸出一次未偵測到臉部的日誌
            let now = Date()
            if now.timeIntervalSince(GazeTurnViewModel.lastLogTime) > 2 {
                print("未偵測到臉部")
                GazeTurnViewModel.lastLogTime = now
            }
            return
        }

        // 更新視覺化數據 - 臉部已檢測
        DispatchQueue.main.async {
            self.visualizationData.faceDetected = true
        }

        // 處理眼睛狀態（眨眼檢測）
        if let leftEye = faceObservation.landmarks?.leftEye,
           let rightEye = faceObservation.landmarks?.rightEye {
            let leftOpen = isEyeOpen(landmark: leftEye)
            let rightOpen = isEyeOpen(landmark: rightEye)
            let leftHeight = calculateEyeHeight(landmark: leftEye)
            let rightHeight = calculateEyeHeight(landmark: rightEye)

            DispatchQueue.main.async {
                // 更新視覺化數據
                self.visualizationData.leftEyeOpen = leftOpen
                self.visualizationData.rightEyeOpen = rightOpen
                self.visualizationData.leftEyeHeight = leftHeight
                self.visualizationData.rightEyeHeight = rightHeight
                self.visualizationData.blinkThreshold = self.gestureCoordinator.currentMode.blinkThreshold

                // 處理手勢
                self.gestureCoordinator.processEyeState(leftOpen: leftOpen, rightOpen: rightOpen)
            }
        }

        // 處理頭部姿態（搖頭檢測）
        let headShakeDirection = headPoseDetector.detectShake(from: faceObservation)

        // 更新頭部姿態數據
        let yaw = faceObservation.yaw?.doubleValue ?? 0.0
        let pitch = faceObservation.pitch?.doubleValue ?? 0.0
        let roll = faceObservation.roll?.doubleValue ?? 0.0
        let yawDegrees = yaw * 180.0 / .pi

        // 每秒輸出一次頭部角度
        if GazeTurnViewModel.frameCount % 30 == 0 {
            let threshold = self.gestureCoordinator.currentMode.shakeAngleThreshold
            print("頭部 Yaw: \(String(format: "%.1f", yawDegrees))° (閾值: \(threshold)°)")
        }

        DispatchQueue.main.async {
            self.visualizationData.headYaw = yawDegrees
            self.visualizationData.headPitch = pitch * 180.0 / .pi
            self.visualizationData.headRoll = roll * 180.0 / .pi
            self.visualizationData.shakeThreshold = self.gestureCoordinator.currentMode.shakeAngleThreshold

            if headShakeDirection != .none {
                print("檢測到搖頭: \(headShakeDirection.displayName)")
                self.gestureCoordinator.processHeadShake(headShakeDirection)
            }
        }
    }

    /// 計算眼睛高度
    private func calculateEyeHeight(landmark: VNFaceLandmarkRegion2D) -> Double {
        let points = landmark.normalizedPoints
        guard points.count >= 6 else { return 0.0 }
        return abs(points[1].y - points[5].y)
    }

    /// 判斷眼睛是否張開
    private func isEyeOpen(landmark: VNFaceLandmarkRegion2D) -> Bool {
        let points = landmark.normalizedPoints
        guard points.count >= 6 else { return true }

        // 計算眼睛高度（上下眼瞼的距離）
        let eyeHeight = abs(points[1].y - points[5].y)

        // 閾值（可以從 InstrumentMode 獲取）
        let threshold = gestureCoordinator.currentMode.blinkThreshold
        return eyeHeight > threshold
    }
}

// MARK: - GestureCoordinatorDelegate

extension GazeTurnViewModel: GestureCoordinatorDelegate {
    func didDetectPageTurn(direction: PageDirection) {
        handlePageTurn(direction: direction)

        // 更新視覺化數據
        let gestureName = direction == .next ? "翻至下一頁" : "翻至上一頁"
        DispatchQueue.main.async {
            self.visualizationData.lastGesture = gestureName
            self.visualizationData.lastGestureTime = Date()

            // 重置等待確認狀態
            self.isWaitingForConfirmation = false
            self.pendingDirection = nil
        }
    }

    func waitingForConfirmation(direction: PageDirection) {
        DispatchQueue.main.async {
            self.isWaitingForConfirmation = true
            self.pendingDirection = direction
            self.visualizationData.lastGesture = "等待確認 - \(direction == .next ? "下一頁" : "上一頁")"
            self.visualizationData.lastGestureTime = Date()
            self.updateGestureStatus("等待眨眼確認 - \(direction == .next ? "下一頁" : "上一頁")")
        }
    }

    func confirmationTimeout() {
        DispatchQueue.main.async {
            self.isWaitingForConfirmation = false
            self.pendingDirection = nil
            self.visualizationData.lastGesture = "確認超時"
            self.visualizationData.lastGestureTime = Date()
            self.updateGestureStatus("確認超時")
        }
    }
}
