//
//  VisionProcessor.swift
//  GazeTurn
//
//  Created by Jhen Mu on 2025/3/9.
//

import Vision
import AVFoundation

/// 手勢處理結果
struct GestureProcessingResult {
    let faceObservation: VNFaceObservation
    let features: ExtractedFaceFeatures
    let confidence: Float
    let timestamp: Date
}

/// 追蹤品質等級
enum FaceTrackingQuality {
    case high
    case medium
    case low
}

/// 提取的臉部特徵
struct ExtractedFaceFeatures {
    // 眼睛特徵
    let leftEyeOpenness: Double
    let rightEyeOpenness: Double
    let eyeAspectRatio: Double
    
    // 頭部姿態
    let yaw: Double
    let pitch: Double
    let roll: Double
    
    // 面部表情特徵
    let mouthCurvature: Double?
    let eyebrowHeight: Double?
    
    // 環境因素（基於檢測信心度）
    let trackingQuality: FaceTrackingQuality
}

/// `VisionProcessor` 負責處理 Vision 框架的影像分析，
/// 包括臉部偵測、眼動追蹤、頭部姿態偵測等。
///
/// 此類返回完整的 VNFaceObservation，其中包含：
/// - landmarks: 臉部特徵點（眼睛、鼻子、嘴巴等）
/// - yaw: 頭部左右旋轉角度
/// - pitch: 頭部上下傾斜角度
/// - roll: 頭部左右傾斜角度
class VisionProcessor {
    /// Vision 請求處理器
    private let sequenceHandler = VNSequenceRequestHandler()
    /// 臉部特徵偵測請求
    private let faceLandmarksRequest: VNDetectFaceLandmarksRequest
    
    /// 是否啟用詳細特徵提取
    var enableDetailedFeatures: Bool = true
    
    /// 處理統計
    private var frameCount: Int = 0
    private var successCount: Int = 0
    private var lastErrorTime: Date?

    /// 初始化 VisionProcessor
    init() {
        faceLandmarksRequest = VNDetectFaceLandmarksRequest()
        // 使用最新的臉部特徵偵測版本
        faceLandmarksRequest.revision = VNDetectFaceLandmarksRequestRevision3
        // 確保返回頭部姿態資訊 (yaw, pitch, roll)
        // 注意：VNFaceObservation 預設就會包含頭部姿態資訊
    }
    
    /// 處理相機影像幀，並執行臉部偵測。
    /// - Parameter pixelBuffer: 來自相機的影像數據。
    /// - Returns: 偵測到的 `VNFaceObservation`，若無偵測到臉部則回傳 `nil`。
    func processFrame(_ pixelBuffer: CVPixelBuffer) -> VNFaceObservation? {
        frameCount += 1
        
        do {
            try sequenceHandler.perform([faceLandmarksRequest], on: pixelBuffer, orientation: .up)
            if let results = faceLandmarksRequest.results, let face = results.first {
                successCount += 1
                
                // 驗證檢測質量
                if face.confidence < 0.5 {
                    logWarning("臉部檢測置信度較低: \(face.confidence)")
                }
                
                return face
            } else {
                logError("未檢測到臉部")
                return nil
            }
        } catch {
            logError("Vision request failed: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// 處理影像幀並提取詳細特徵
    /// - Parameter pixelBuffer: 來自相機的影像數據
    /// - Returns: 手勢處理結果，包含詳細特徵
    func processFrameWithFeatures(_ pixelBuffer: CVPixelBuffer) -> GestureProcessingResult? {
        guard let faceObservation = processFrame(pixelBuffer) else {
            return nil
        }
        
        guard enableDetailedFeatures else {
            // 簡化模式：只返回基本信息
            let basicFeatures = ExtractedFaceFeatures(
                leftEyeOpenness: 1.0,
                rightEyeOpenness: 1.0,
                eyeAspectRatio: 0.3,
                yaw: faceObservation.yaw?.doubleValue ?? 0.0,
                pitch: faceObservation.pitch?.doubleValue ?? 0.0,
                roll: faceObservation.roll?.doubleValue ?? 0.0,
                mouthCurvature: nil as Double?,
                eyebrowHeight: nil as Double?,
                trackingQuality: FaceTrackingQuality.high
            )
            
            return GestureProcessingResult(
                faceObservation: faceObservation,
                features: basicFeatures,
                confidence: faceObservation.confidence,
                timestamp: Date()
            )
        }
        
        // 提取詳細特徵
        let features = extractFeatures(from: faceObservation)
        
        return GestureProcessingResult(
            faceObservation: faceObservation,
            features: features,
            confidence: faceObservation.confidence,
            timestamp: Date()
        )
    }
    
    /// 從臉部觀察結果中提取詳細特徵
    /// - Parameter face: Vision 框架偵測到的臉部觀察結果
    /// - Returns: 提取的臉部特徵
    private func extractFeatures(from face: VNFaceObservation) -> ExtractedFaceFeatures {
        // 提取眼睛特徵
        var leftEyeOpenness = 1.0
        var rightEyeOpenness = 1.0
        var eyeAspectRatio = 0.3
        
        if let leftEye = face.landmarks?.leftEye,
           let rightEye = face.landmarks?.rightEye {
            leftEyeOpenness = calculateEyeOpenness(landmark: leftEye)
            rightEyeOpenness = calculateEyeOpenness(landmark: rightEye)
            eyeAspectRatio = (leftEyeOpenness + rightEyeOpenness) / 2.0
        }
        
        // 提取頭部姿態
        let yaw = face.yaw?.doubleValue ?? 0.0
        let pitch = face.pitch?.doubleValue ?? 0.0
        let roll = face.roll?.doubleValue ?? 0.0
        
        // 提取嘴部特徵（可選）
        var mouthCurvature: Double? = nil as Double?
        if let outerLips = face.landmarks?.outerLips {
            mouthCurvature = calculateMouthCurvature(landmark: outerLips)
        }
        
        // 提取眉毛特徵（可選）
        var eyebrowHeight: Double? = nil as Double?
        if let leftEyebrow = face.landmarks?.leftEyebrow,
           let rightEyebrow = face.landmarks?.rightEyebrow {
            eyebrowHeight = calculateEyebrowHeight(
                leftEyebrow: leftEyebrow,
                rightEyebrow: rightEyebrow
            )
        }
        
        // 根據檢測信心度評估追蹤品質
        let trackingQuality: FaceTrackingQuality
        if face.confidence > 0.8 {
            trackingQuality = .high
        } else if face.confidence > 0.5 {
            trackingQuality = .medium
        } else {
            trackingQuality = .low
        }
        
        return ExtractedFaceFeatures(
            leftEyeOpenness: leftEyeOpenness,
            rightEyeOpenness: rightEyeOpenness,
            eyeAspectRatio: eyeAspectRatio,
            yaw: yaw,
            pitch: pitch,
            roll: roll,
            mouthCurvature: mouthCurvature,
            eyebrowHeight: eyebrowHeight,
            trackingQuality: trackingQuality
        )
    }
    
    /// 計算眼睛張開程度
    /// - Parameter landmark: 眼睛特徵點
    /// - Returns: 眼睛張開程度（0.0 = 閉合，1.0 = 完全張開）
    private func calculateEyeOpenness(landmark: VNFaceLandmarkRegion2D) -> Double {
        let points = landmark.normalizedPoints
        guard points.count >= 6 else { return 1.0 }
        
        // 計算眼睛高度（上下眼瞼的距離）
        let eyeHeight = abs(points[1].y - points[5].y)
        
        // 正規化（假設完全張開時高度約為 0.03）
        return min(eyeHeight / 0.03, 1.0)
    }
    
    /// 計算嘴部曲率（微笑檢測）
    /// - Parameter landmark: 嘴唇特徵點
    /// - Returns: 嘴部曲率值
    private func calculateMouthCurvature(landmark: VNFaceLandmarkRegion2D) -> Double {
        let points = landmark.normalizedPoints
        guard points.count >= 6 else { return 0.0 }
        
        // 簡化的微笑檢測：比較嘴角和嘴中心的 y 座標
        let leftCorner = points[0]
        let rightCorner = points[6]
        let topCenter = points[3]
        
        let cornerAvgY = (leftCorner.y + rightCorner.y) / 2.0
        let curvature = topCenter.y - cornerAvgY
        
        return Double(curvature)
    }
    
    /// 計算眉毛高度
    /// - Parameters:
    ///   - leftEyebrow: 左眉毛特徵點
    ///   - rightEyebrow: 右眉毛特徵點
    /// - Returns: 眉毛高度值
    private func calculateEyebrowHeight(
        leftEyebrow: VNFaceLandmarkRegion2D,
        rightEyebrow: VNFaceLandmarkRegion2D
    ) -> Double {
        let leftPoints = leftEyebrow.normalizedPoints
        let rightPoints = rightEyebrow.normalizedPoints
        
        guard !leftPoints.isEmpty && !rightPoints.isEmpty else { return 0.0 }
        
        // 計算眉毛的平均 y 座標
        let leftAvgY = leftPoints.map { Float($0.y) }.reduce(0, +) / Float(leftPoints.count)
        let rightAvgY = rightPoints.map { Float($0.y) }.reduce(0, +) / Float(rightPoints.count)
        
        return Double((leftAvgY + rightAvgY) / 2.0)
    }
    
    /// 獲取處理統計信息
    func getProcessingStats() -> String {
        let successRate = frameCount > 0 ? Double(successCount) / Double(frameCount) * 100 : 0
        return """
        Vision Processing Statistics:
        - Total Frames: \(frameCount)
        - Successful Detections: \(successCount)
        - Success Rate: \(String(format: "%.1f", successRate))%
        """
    }
    
    /// 重置統計
    func resetStats() {
        frameCount = 0
        successCount = 0
        lastErrorTime = nil
    }
    
    // MARK: - Logging
    
    private func logError(_ message: String) {
        let now = Date()
        // 避免頻繁日誌：每 2 秒最多記錄一次錯誤
        if let lastError = lastErrorTime, now.timeIntervalSince(lastError) < 2.0 {
            return
        }
        lastErrorTime = now
        print("❌ VisionProcessor Error: \(message)")
    }
    
    private func logWarning(_ message: String) {
        print("⚠️ VisionProcessor Warning: \(message)")
    }
}
