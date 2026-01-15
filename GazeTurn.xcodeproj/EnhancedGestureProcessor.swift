//
//  EnhancedGestureProcessor.swift
//  GazeTurn
//
//  Created by Claude Code on 2025/1/15.
//

import Foundation
import Vision
import Combine

/// 增強的手勢處理器，整合 AI 學習引擎
class EnhancedGestureProcessor: ObservableObject {
    
    // MARK: - Published Properties
    
    /// 當前檢測信心度
    @Published var detectionConfidence: Double = 0.0
    
    /// 手勢品質評分
    @Published var gestureQuality: GestureQuality = .unknown
    
    /// 處理狀態
    @Published var processingStatus: ProcessingStatus = .idle
    
    // MARK: - Components
    
    private let visionProcessor: VisionProcessor
    private let learningEngine: GestureLearningEngine?
    private var currentContext: GestureContext?
    
    /// 是否啟用 AI 學習
    var enableLearning: Bool = true
    
    /// 環境光線檢測
    private var currentBrightness: Float = 0.8
    
    /// 用戶距離估算（基於臉部大小）
    private var estimatedDistance: Double = 50.0 // cm
    
    // MARK: - Statistics
    
    private var processingStats = ProcessingStatistics()
    
    // MARK: - Initialization
    
    init(
        visionProcessor: VisionProcessor,
        enableLearning: Bool = true
    ) {
        self.visionProcessor = visionProcessor
        self.enableLearning = enableLearning
        self.learningEngine = enableLearning ? GestureLearningEngine() : nil
        
        // 啟用詳細特徵提取
        visionProcessor.enableDetailedFeatures = true
    }
    
    // MARK: - Main Processing Pipeline
    
    /// 處理影像幀並執行完整的手勢識別流程
    /// - Parameters:
    ///   - pixelBuffer: 影像數據
    ///   - instrumentMode: 當前樂器模式
    /// - Returns: 手勢處理結果
    func processGesture(
        from pixelBuffer: CVPixelBuffer,
        mode: InstrumentMode
    ) -> GestureProcessingResult? {
        
        processingStatus = .processing
        
        // 1️⃣ 執行 Vision 處理
        guard let result = visionProcessor.processFrameWithFeatures(pixelBuffer) else {
            processingStatus = .failed(reason: "未檢測到臉部")
            processingStats.failedFrames += 1
            return nil
        }
        
        processingStats.processedFrames += 1
        
        // 2️⃣ 更新環境上下文
        updateContext(from: result, mode: mode)
        
        // 3️⃣ 評估檢測品質
        let quality = evaluateGestureQuality(result: result)
        
        DispatchQueue.main.async {
            self.gestureQuality = quality
            self.detectionConfidence = Double(result.confidence)
        }
        
        // 4️⃣ 如果品質不佳，提供反饋
        if quality == .poor || quality == .veryPoor {
            processingStatus = .warning(message: getQualityFeedback(for: quality))
        } else {
            processingStatus = .success
        }
        
        // 5️⃣ 記錄到學習引擎（如果啟用）
        if enableLearning, let context = currentContext {
            recordToLearningEngine(
                result: result,
                context: context,
                mode: mode
            )
        }
        
        return result
    }
    
    /// 處理手勢事件並記錄學習數據
    /// - Parameters:
    ///   - gestureType: 手勢類型
    ///   - features: 手勢特徵
    ///   - outcome: 手勢結果
    ///   - threshold: 使用的閾值
    func recordGestureEvent(
        type: GestureTrainingData.GestureType,
        features: GestureFeatures,
        outcome: GestureTrainingData.GestureOutcome,
        threshold: Double
    ) {
        guard enableLearning,
              let engine = learningEngine,
              let context = currentContext else {
            return
        }
        
        let trainingData = GestureTrainingData(
            gestureType: type,
            timestamp: Date(),
            context: context,
            features: features,
            outcome: outcome,
            threshold: threshold,
            confidence: detectionConfidence
        )
        
        engine.recordGestureData(trainingData)
        
        // 更新統計
        processingStats.gesturesRecorded += 1
    }
    
    /// 獲取自適應閾值
    /// - Parameters:
    ///   - parameter: 參數名稱
    ///   - defaultValue: 預設值
    /// - Returns: 調整後的閾值
    func getAdaptiveThreshold(for parameter: String, defaultValue: Double) -> Double {
        guard enableLearning,
              let engine = learningEngine,
              let context = currentContext else {
            return defaultValue
        }
        
        return engine.getAdaptiveThreshold(for: parameter, context: context)
    }
    
    // MARK: - Quality Evaluation
    
    /// 評估手勢檢測品質
    /// - Parameter result: Vision 處理結果
    /// - Returns: 手勢品質等級
    private func evaluateGestureQuality(result: GestureProcessingResult) -> GestureQuality {
        var score: Double = 0.0
        
        // 1. 臉部檢測信心度 (40%)
        let confidenceScore = Double(result.confidence) * 0.4
        score += confidenceScore
        
        // 2. 追蹤品質 (20%)
        let trackingScore = evaluateTrackingQuality(result.features.trackingQuality) * 0.2
        score += trackingScore
        
        // 3. 環境光線 (20%)
        let lightingScore = evaluateLightingCondition() * 0.2
        score += lightingScore
        
        // 4. 臉部角度 (20%)
        let angleScore = evaluateFaceAngle(result.features) * 0.2
        score += angleScore
        
        // 根據分數返回品質等級
        switch score {
        case 0.9...1.0: return .excellent
        case 0.7..<0.9: return .good
        case 0.5..<0.7: return .fair
        case 0.3..<0.5: return .poor
        default: return .veryPoor
        }
    }
    
    private func evaluateTrackingQuality(_ quality: FaceTrackingQuality) -> Double {
        switch quality {
        case .high:
            return 1.0
        case .medium:
            return 0.7
        case .low:
            return 0.4
        }
    }
    
    private func evaluateLightingCondition() -> Double {
        switch currentBrightness {
        case 0.8...1.0: return 1.0
        case 0.6..<0.8: return 0.8
        case 0.4..<0.6: return 0.6
        case 0.2..<0.4: return 0.4
        default: return 0.2
        }
    }
    
    private func evaluateFaceAngle(_ features: ExtractedFaceFeatures) -> Double {
        // 理想情況：臉部正對相機
        let yawDegrees = abs(features.yaw * 180.0 / .pi)
        let pitchDegrees = abs(features.pitch * 180.0 / .pi)
        
        // 偏離角度越大，分數越低
        let yawScore = max(0, 1.0 - yawDegrees / 45.0)
        let pitchScore = max(0, 1.0 - pitchDegrees / 30.0)
        
        return (yawScore + pitchScore) / 2.0
    }
    
    private func getQualityFeedback(for quality: GestureQuality) -> String {
        switch quality {
        case .veryPoor:
            return "檢測品質很低，請確保：1) 光線充足 2) 臉部正對相機 3) 距離適中"
        case .poor:
            return "檢測品質較低，建議調整光線或臉部角度"
        case .fair:
            return "檢測品質一般，可繼續使用但建議優化環境"
        default:
            return ""
        }
    }
    
    // MARK: - Context Management
    
    /// 更新當前手勢上下文
    private func updateContext(from result: GestureProcessingResult, mode: InstrumentMode) {
        // 估算用戶距離（基於臉部大小）
        let faceSize = result.faceObservation.boundingBox.width
        estimatedDistance = estimateDistance(from: faceSize)
        
        // 更新環境光線（這裡簡化處理，實際可從相機獲取）
        // 可以通過分析 pixelBuffer 的平均亮度來獲取
        currentBrightness = 0.8 // 暫時使用固定值
        
        currentContext = GestureContext(
            instrumentType: mode.instrumentType,
            lightingCondition: .from(brightness: currentBrightness),
            userDistance: estimatedDistance,
            sessionDuration: Date().timeIntervalSince(processingStats.sessionStartTime),
            practiceMode: false
        )
    }
    
    /// 估算用戶距離
    private func estimateDistance(from faceSize: CGFloat) -> Double {
        // 簡化的距離估算
        // 假設標準臉部寬度約 15cm，使用相似三角形原理
        // 這是一個粗略估算，實際應該通過校準獲得更準確的值
        
        let referenceFaceWidth: Double = 15.0 // cm
        let referenceFaceSize: CGFloat = 0.3 // 在 30cm 時的標準化大小
        
        guard faceSize > 0 else { return 100.0 }
        
        let distance = (referenceFaceWidth * Double(referenceFaceSize)) / Double(faceSize)
        return min(max(distance, 20.0), 200.0) // 限制在 20-200cm 範圍
    }
    
    // MARK: - Learning Integration
    
    /// 記錄數據到學習引擎
    private func recordToLearningEngine(
        result: GestureProcessingResult,
        context: GestureContext,
        mode: InstrumentMode
    ) {
        // 將 Vision 特徵轉換為學習引擎的特徵格式
        let features = convertToGestureFeatures(
            visionFeatures: result.features,
            context: context
        )
        
        // 這裡記錄一個觀察樣本（不是實際手勢）
        // 實際手勢會在檢測到時由 recordGestureEvent 記錄
    }
    
    /// 轉換 Vision 特徵到學習引擎格式
    private func convertToGestureFeatures(
        visionFeatures: ExtractedFaceFeatures,
        context: GestureContext
    ) -> GestureFeatures {
        return GestureFeatures(
            eyeAspectRatio: visionFeatures.eyeAspectRatio,
            blinkDuration: 0.0, // 需要從時序數據計算
            blinkVelocity: 0.0, // 需要從時序數據計算
            headYaw: visionFeatures.yaw,
            headPitch: visionFeatures.pitch,
            headRoll: visionFeatures.roll,
            headMovementVelocity: 0.0, // 需要從時序數據計算
            faceConfidence: Double(detectionConfidence),
            eyeOpenness: (visionFeatures.leftEyeOpenness + visionFeatures.rightEyeOpenness) / 2.0,
            mouthCurvature: visionFeatures.mouthCurvature ?? 0.0,
            timeSinceLastGesture: 0.0, // 需要追蹤
            gestureFrequency: 0.0, // 需要統計
            ambientLight: currentBrightness,
            deviceMotion: 0.0 // 需要從設備運動感測器獲取
        )
    }
    
    // MARK: - Statistics and Diagnostics
    
    /// 獲取處理統計信息
    func getProcessingStatistics() -> String {
        var stats = visionProcessor.getProcessingStats()
        stats += "\n\n"
        stats += processingStats.description
        
        if let engine = learningEngine {
            stats += "\n\n"
            stats += "Learning Engine:\n"
            stats += "- Accuracy: \(String(format: "%.1f", engine.recentAccuracy * 100))%\n"
            stats += "- Adaptation Progress: \(String(format: "%.1f", engine.adaptationProgress * 100))%"
        }
        
        return stats
    }
    
    /// 重置統計數據
    func resetStatistics() {
        visionProcessor.resetStats()
        processingStats = ProcessingStatistics()
    }
    
    /// 獲取學習引擎建議
    func getLearningRecommendations() -> [String] {
        return learningEngine?.getPersonalizedRecommendations() ?? []
    }
    
    /// 導出學習數據
    func exportLearningData() -> Data? {
        return learningEngine?.exportLearningData()
    }
    
    /// 匯入學習數據
    func importLearningData(_ data: Data) -> Bool {
        return learningEngine?.importLearningData(data) ?? false
    }
}

// MARK: - Supporting Types

/// 手勢品質等級
enum GestureQuality {
    case excellent  // 優秀
    case good       // 良好
    case fair       // 一般
    case poor       // 較差
    case veryPoor   // 很差
    case unknown    // 未知
    
    var displayName: String {
        switch self {
        case .excellent: return "優秀"
        case .good: return "良好"
        case .fair: return "一般"
        case .poor: return "較差"
        case .veryPoor: return "很差"
        case .unknown: return "未知"
        }
    }
    
    var emoji: String {
        switch self {
        case .excellent: return "🌟"
        case .good: return "✅"
        case .fair: return "⚠️"
        case .poor: return "⚠️"
        case .veryPoor: return "❌"
        case .unknown: return "❓"
        }
    }
}

/// 處理狀態
enum ProcessingStatus {
    case idle
    case processing
    case success
    case warning(message: String)
    case failed(reason: String)
    
    var displayMessage: String {
        switch self {
        case .idle: return "就緒"
        case .processing: return "處理中..."
        case .success: return "成功"
        case .warning(let message): return "警告: \(message)"
        case .failed(let reason): return "失敗: \(reason)"
        }
    }
}

/// 處理統計
struct ProcessingStatistics: CustomStringConvertible {
    var sessionStartTime: Date = Date()
    var processedFrames: Int = 0
    var failedFrames: Int = 0
    var gesturesRecorded: Int = 0
    
    var successRate: Double {
        guard processedFrames > 0 else { return 0 }
        return Double(processedFrames - failedFrames) / Double(processedFrames) * 100
    }
    
    var description: String {
        let sessionDuration = Date().timeIntervalSince(sessionStartTime)
        return """
        Processing Statistics:
        - Session Duration: \(String(format: "%.1f", sessionDuration))s
        - Processed Frames: \(processedFrames)
        - Failed Frames: \(failedFrames)
        - Success Rate: \(String(format: "%.1f", successRate))%
        - Gestures Recorded: \(gesturesRecorded)
        """
    }
}
