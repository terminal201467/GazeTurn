//
//  GestureRecognitionIntegrationGuide.swift
//  GazeTurn
//
//  整合指南：完整的手勢識別流程
//  Created by Claude Code on 2025/1/15.
//

/*
 
 # 手勢識別完整流程整合指南
 
 ## 🎯 概述
 
 本指南說明如何將增強的手勢處理器整合到 GazeTurn 應用中，完成完整的手勢識別流程。
 
 ## 📊 系統架構
 
 ```
 相機輸入 (CameraManager)
    ↓
 影像處理 (VisionProcessor)
    ↓
 特徵提取 (ExtractedFaceFeatures)
    ↓
 增強處理器 (EnhancedGestureProcessor)
    ↓
 手勢協調器 (GestureCoordinator)
    ├── 眨眼識別 (BlinkRecognizer)
    └── 頭部姿態檢測 (HeadPoseDetector)
    ↓
 AI 學習引擎 (GestureLearningEngine) [可選]
    ↓
 頁面控制 (GazeTurnViewModel)
 ```
 
 ## 🔧 整合步驟
 
 ### 步驟 1: 更新 GazeTurnViewModel
 
 在 `GazeTurnViewModel` 中添加增強處理器：
 
 ```swift
 class GazeTurnViewModel: ObservableObject {
     
     // 現有組件
     private let cameraManager: CameraManager
     private let visionProcessor: VisionProcessor
     private let blinkRecognizer: BlinkRecognizer
     private let headPoseDetector: HeadPoseDetector
     private let gestureCoordinator: GestureCoordinator
     
     // 新增：增強處理器
     private let enhancedProcessor: EnhancedGestureProcessor
     
     init(instrumentMode: InstrumentMode = InstrumentMode.current()) {
         // ... 現有初始化代碼
         
         // 初始化增強處理器
         self.enhancedProcessor = EnhancedGestureProcessor(
             visionProcessor: visionProcessor,
             enableLearning: true  // 啟用 AI 學習
         )
         
         // ... 其他設置
     }
 }
 ```
 
 ### 步驟 2: 更新影像處理流程
 
 修改 `didCaptureFrame` 方法以使用增強處理器：
 
 ```swift
 extension GazeTurnViewModel: CameraManagerDelegate {
     
     func didCaptureFrame(_ sampleBuffer: CMSampleBuffer) {
         guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
             return
         }
         
         // 使用增強處理器處理影像
         guard let result = enhancedProcessor.processGesture(
             from: pixelBuffer,
             mode: gestureCoordinator.currentMode
         ) else {
             DispatchQueue.main.async {
                 self.visualizationData.faceDetected = false
             }
             return
         }
         
         // 更新視覺化數據
         updateVisualizationData(from: result)
         
         // 處理眨眼檢測
         processBlinkGesture(from: result)
         
         // 處理搖頭檢測
         processHeadShakeGesture(from: result)
     }
     
     private func updateVisualizationData(from result: GestureProcessingResult) {
         DispatchQueue.main.async {
             let features = result.features
             
             self.visualizationData.faceDetected = true
             self.visualizationData.leftEyeOpen = features.leftEyeOpenness > 0.5
             self.visualizationData.rightEyeOpen = features.rightEyeOpenness > 0.5
             self.visualizationData.leftEyeHeight = features.leftEyeOpenness
             self.visualizationData.rightEyeHeight = features.rightEyeOpenness
             self.visualizationData.blinkThreshold = self.gestureCoordinator.currentMode.blinkThreshold
             
             self.visualizationData.headYaw = features.yaw * 180.0 / .pi
             self.visualizationData.headPitch = features.pitch * 180.0 / .pi
             self.visualizationData.headRoll = features.roll * 180.0 / .pi
             self.visualizationData.shakeThreshold = self.gestureCoordinator.currentMode.shakeAngleThreshold
         }
     }
     
     private func processBlinkGesture(from result: GestureProcessingResult) {
         let features = result.features
         let leftOpen = features.leftEyeOpenness > 0.5
         let rightOpen = features.rightEyeOpenness > 0.5
         
         // 使用自適應閾值
         let adaptiveThreshold = enhancedProcessor.getAdaptiveThreshold(
             for: "blinkThreshold",
             defaultValue: gestureCoordinator.currentMode.blinkThreshold
         )
         
         // 處理眨眼
         let blinkDetected = blinkRecognizer.detectBlink(leftOpen: leftOpen, rightOpen: rightOpen)
         
         if blinkDetected {
             // 記錄到學習引擎
             let gestureFeatures = createGestureFeatures(from: result)
             enhancedProcessor.recordGestureEvent(
                 type: .blink,
                 features: gestureFeatures,
                 outcome: .truePositive,  // 或根據實際情況判斷
                 threshold: adaptiveThreshold
             )
         }
         
         // 傳遞給協調器
         DispatchQueue.main.async {
             self.gestureCoordinator.processEyeState(leftOpen: leftOpen, rightOpen: rightOpen)
         }
     }
     
     private func processHeadShakeGesture(from result: GestureProcessingResult) {
         let headShakeDirection = headPoseDetector.detectShake(from: result.faceObservation)
         
         if headShakeDirection != .none {
             // 記錄到學習引擎
             let gestureFeatures = createGestureFeatures(from: result)
             let adaptiveThreshold = enhancedProcessor.getAdaptiveThreshold(
                 for: "headShakeAngle",
                 defaultValue: gestureCoordinator.currentMode.shakeAngleThreshold
             )
             
             enhancedProcessor.recordGestureEvent(
                 type: .headShake(direction: headShakeDirection),
                 features: gestureFeatures,
                 outcome: .truePositive,
                 threshold: adaptiveThreshold
             )
         }
         
         // 傳遞給協調器
         DispatchQueue.main.async {
             self.gestureCoordinator.processHeadShake(headShakeDirection)
         }
     }
     
     private func createGestureFeatures(from result: GestureProcessingResult) -> GestureFeatures {
         let features = result.features
         
         return GestureFeatures(
             eyeAspectRatio: features.eyeAspectRatio,
             blinkDuration: 0.0,  // 需要從時序追蹤
             blinkVelocity: 0.0,  // 需要從時序追蹤
             headYaw: features.yaw,
             headPitch: features.pitch,
             headRoll: features.roll,
             headMovementVelocity: 0.0,  // 需要從時序追蹤
             faceConfidence: Double(result.confidence),
             eyeOpenness: (features.leftEyeOpenness + features.rightEyeOpenness) / 2.0,
             mouthCurvature: features.mouthCurvature ?? 0.0,
             timeSinceLastGesture: 0.0,
             gestureFrequency: 0.0,
             ambientLight: 0.8,  // 從環境獲取
             deviceMotion: 0.0   // 從運動感測器獲取
         )
     }
 }
 ```
 
 ### 步驟 3: 添加診斷和調試功能
 
 在 ViewModel 中添加診斷方法：
 
 ```swift
 extension GazeTurnViewModel {
     
     /// 獲取完整的診斷信息
     func getCompleteDiagnostics() -> String {
         var diagnostics = ""
         
         // 基本狀態
         diagnostics += getStatusDescription()
         diagnostics += "\n\n"
         
         // 處理統計
         diagnostics += enhancedProcessor.getProcessingStatistics()
         diagnostics += "\n\n"
         
         // 協調器狀態
         diagnostics += gestureCoordinator.getCurrentStateDescription()
         
         return diagnostics
     }
     
     /// 獲取 AI 學習建議
     func getAIRecommendations() -> [String] {
         return enhancedProcessor.getLearningRecommendations()
     }
     
     /// 導出學習數據
     func exportLearningData() -> Data? {
         return enhancedProcessor.exportLearningData()
     }
     
     /// 匯入學習數據
     func importLearningData(_ data: Data) -> Bool {
         return enhancedProcessor.importLearningData(data)
     }
 }
 ```
 
 ### 步驟 4: UI 整合（可選）
 
 在設置界面中添加 AI 學習狀態顯示：
 
 ```swift
 struct AILearningStatusView: View {
     @ObservedObject var processor: EnhancedGestureProcessor
     
     var body: some View {
         VStack(alignment: .leading, spacing: 12) {
             Text("AI 學習狀態")
                 .font(.headline)
             
             HStack {
                 Text("檢測品質:")
                 Spacer()
                 Text("\(processor.gestureQuality.emoji) \(processor.gestureQuality.displayName)")
             }
             
             HStack {
                 Text("檢測信心度:")
                 Spacer()
                 Text("\(Int(processor.detectionConfidence * 100))%")
             }
             
             HStack {
                 Text("狀態:")
                 Spacer()
                 Text(processor.processingStatus.displayMessage)
                     .foregroundColor(statusColor)
             }
         }
         .padding()
         .background(Color.gray.opacity(0.1))
         .cornerRadius(8)
     }
     
     private var statusColor: Color {
         switch processor.processingStatus {
         case .success: return .green
         case .warning: return .orange
         case .failed: return .red
         default: return .primary
         }
     }
 }
 ```
 
 ## 🎨 進階功能
 
 ### 用戶反饋整合
 
 允許用戶確認或拒絕手勢識別結果：
 
 ```swift
 extension GazeTurnViewModel {
     
     /// 用戶確認手勢
     func confirmGesture(type: GestureTrainingData.GestureType) {
         guard let lastFeatures = getLastGestureFeatures() else { return }
         
         enhancedProcessor.recordGestureEvent(
             type: type,
             features: lastFeatures,
             outcome: .userConfirmed,
             threshold: getCurrentThreshold(for: type)
         )
     }
     
     /// 用戶拒絕手勢
     func rejectGesture(type: GestureTrainingData.GestureType) {
         guard let lastFeatures = getLastGestureFeatures() else { return }
         
         enhancedProcessor.recordGestureEvent(
             type: type,
             features: lastFeatures,
             outcome: .userRejected,
             threshold: getCurrentThreshold(for: type)
         )
     }
 }
 ```
 
 ### 校準模式
 
 添加專門的校準模式以提高識別準確度：
 
 ```swift
 class CalibrationMode {
     private let processor: EnhancedGestureProcessor
     private var calibrationSamples: [GestureProcessingResult] = []
     
     func startCalibration(for gestureType: GestureTrainingData.GestureType) {
         calibrationSamples.removeAll()
     }
     
     func collectSample(_ result: GestureProcessingResult) {
         calibrationSamples.append(result)
     }
     
     func finishCalibration() -> Double? {
         // 分析樣本並返回建議的閾值
         guard !calibrationSamples.isEmpty else { return nil }
         
         // 計算最佳閾值
         let values = calibrationSamples.map { $0.features.eyeAspectRatio }
         let average = values.reduce(0, +) / Double(values.count)
         
         return average
     }
 }
 ```
 
 ## ✅ 測試檢查清單
 
 完成整合後，請測試以下功能：
 
 - [ ] 相機能正常啟動並捕獲影像
 - [ ] VisionProcessor 能檢測到臉部
 - [ ] 眨眼檢測能正常工作
 - [ ] 搖頭檢測能正常工作
 - [ ] 視覺化數據正確更新
 - [ ] AI 學習引擎正確記錄數據
 - [ ] 自適應閾值能改善識別準確度
 - [ ] 診斷信息能正確顯示
 - [ ] 學習數據能導出和匯入
 - [ ] 不同樂器模式正常切換
 
 ## 🐛 常見問題排查
 
 ### 問題 1: 無法檢測到臉部
 **解決方案:**
 - 檢查相機權限
 - 確保光線充足
 - 確認臉部在鏡頭範圍內
 - 查看 `processingStatus` 的錯誤信息
 
 ### 問題 2: 手勢識別不準確
 **解決方案:**
 - 檢查 `gestureQuality` 評分
 - 調整閾值設定
 - 收集更多訓練數據
 - 使用校準模式重新校準
 
 ### 問題 3: 性能問題
 **解決方案:**
 - 檢查處理統計中的幀率
 - 考慮禁用詳細特徵提取
 - 降低影像處理頻率
 - 優化 Vision 請求設定
 
 ## 📚 參考資料
 
 - `VisionProcessor.swift` - 影像處理
 - `EnhancedGestureProcessor.swift` - 增強處理器
 - `GestureCoordinator.swift` - 手勢協調
 - `GestureLearningEngine.swift` - AI 學習引擎
 - `BlinkRecognizer.swift` - 眨眼識別
 - `HeadPoseDetector.swift` - 頭部姿態檢測
 
 */

import Foundation

// 這個檔案僅作為文檔參考，不包含可執行代碼
