//
//  MicroGestureDetector.swift
//  GazeTurn
//
//  Created by Claude Code on 2025/11/21.
//

import Foundation
import Vision
import CoreML
import AVFoundation

/// 微手勢類型
enum MicroGestureType: String, CaseIterable {
    case eyebrowRaise = "eyebrow_raise"
    case smile = "smile"
    case gazeShift = "gaze_shift"
    case pupilDilation = "pupil_dilation"
    case nostrilFlare = "nostril_flare"
    case lipPurse = "lip_purse"

    var displayName: String {
        switch self {
        case .eyebrowRaise: return "眉毛上揚"
        case .smile: return "微笑"
        case .gazeShift: return "視線轉移"
        case .pupilDilation: return "瞳孔變化"
        case .nostrilFlare: return "鼻翼張開"
        case .lipPurse: return "抿嘴"
        }
    }

    var iconName: String {
        switch self {
        case .eyebrowRaise: return "face.smiling"
        case .smile: return "face.smiling.fill"
        case .gazeShift: return "eye"
        case .pupilDilation: return "eye.circle"
        case .nostrilFlare: return "nose"
        case .lipPurse: return "mouth"
        }
    }

    var difficulty: GestureDifficulty {
        switch self {
        case .smile, .gazeShift: return .easy
        case .eyebrowRaise: return .medium
        case .pupilDilation, .nostrilFlare, .lipPurse: return .advanced
        }
    }

    enum GestureDifficulty {
        case easy, medium, advanced

        var description: String {
            switch self {
            case .easy: return "簡單"
            case .medium: return "中等"
            case .advanced: return "進階"
            }
        }
    }
}

/// 微手勢檢測結果
struct MicroGestureResult {
    let type: MicroGestureType
    let confidence: Double
    let intensity: Double
    let duration: TimeInterval
    let timestamp: Date
    let landmarks: VNFaceLandmarks2D?

    /// 手勢強度分級
    var intensityLevel: IntensityLevel {
        switch intensity {
        case 0.0..<0.3: return .subtle
        case 0.3..<0.7: return .moderate
        case 0.7...1.0: return .strong
        default: return .subtle
        }
    }

    enum IntensityLevel {
        case subtle, moderate, strong

        var description: String {
            switch self {
            case .subtle: return "微弱"
            case .moderate: return "適中"
            case .strong: return "明顯"
            }
        }
    }
}

/// 面部特徵點分析器
struct FacialLandmarkAnalyzer {
    /// 分析眉毛位置
    static func analyzeEyebrows(from landmarks: VNFaceLandmarks2D) -> EyebrowAnalysis? {
        guard let leftEyebrow = landmarks.leftEyebrow,
              let rightEyebrow = landmarks.rightEyebrow,
              let leftEye = landmarks.leftEye,
              let rightEye = landmarks.rightEye else {
            return nil
        }

        let leftEyebrowHeight = calculateEyebrowHeight(eyebrow: leftEyebrow, eye: leftEye)
        let rightEyebrowHeight = calculateEyebrowHeight(eyebrow: rightEyebrow, eye: rightEye)

        return EyebrowAnalysis(
            leftHeight: leftEyebrowHeight,
            rightHeight: rightEyebrowHeight,
            symmetry: abs(leftEyebrowHeight - rightEyebrowHeight),
            averageHeight: (leftEyebrowHeight + rightEyebrowHeight) / 2
        )
    }

    /// 分析嘴唇形狀
    static func analyzeLips(from landmarks: VNFaceLandmarks2D) -> LipAnalysis? {
        guard let outerLips = landmarks.outerLips,
              let innerLips = landmarks.innerLips else {
            return nil
        }

        let lipWidth = calculateLipWidth(outerLips: outerLips)
        let lipHeight = calculateLipHeight(outerLips: outerLips)
        let lipCurvature = calculateLipCurvature(innerLips: innerLips)
        let lipAsymmetry = calculateLipAsymmetry(outerLips: outerLips)

        return LipAnalysis(
            width: lipWidth,
            height: lipHeight,
            curvature: lipCurvature,
            asymmetry: lipAsymmetry,
            aspectRatio: lipWidth / lipHeight
        )
    }

    /// 分析鼻孔
    static func analyzeNose(from landmarks: VNFaceLandmarks2D) -> NoseAnalysis? {
        guard let nose = landmarks.nose,
              let noseCrest = landmarks.noseCrest else {
            return nil
        }

        let nostrilWidth = calculateNostrilWidth(nose: nose)
        let noseLength = calculateNoseLength(noseCrest: noseCrest)

        return NoseAnalysis(
            nostrilWidth: nostrilWidth,
            noseLength: noseLength,
            aspectRatio: nostrilWidth / noseLength
        )
    }

    // MARK: - Helper Methods

    private static func calculateEyebrowHeight(eyebrow: VNFaceLandmarkRegion2D, eye: VNFaceLandmarkRegion2D) -> Double {
        let eyebrowPoints = eyebrow.normalizedPoints
        let eyePoints = eye.normalizedPoints

        guard !eyebrowPoints.isEmpty && !eyePoints.isEmpty else { return 0 }

        let avgEyebrowY = eyebrowPoints.map { $0.y }.reduce(0, +) / Double(eyebrowPoints.count)
        let avgEyeY = eyePoints.map { $0.y }.reduce(0, +) / Double(eyePoints.count)

        return abs(avgEyebrowY - avgEyeY)
    }

    private static func calculateLipWidth(outerLips: VNFaceLandmarkRegion2D) -> Double {
        let points = outerLips.normalizedPoints
        guard points.count >= 4 else { return 0 }

        let leftCorner = points[0]
        let rightCorner = points[points.count / 2]

        return abs(rightCorner.x - leftCorner.x)
    }

    private static func calculateLipHeight(outerLips: VNFaceLandmarkRegion2D) -> Double {
        let points = outerLips.normalizedPoints
        guard points.count >= 8 else { return 0 }

        let topPoint = points[points.count / 4]
        let bottomPoint = points[3 * points.count / 4]

        return abs(topPoint.y - bottomPoint.y)
    }

    private static func calculateLipCurvature(innerLips: VNFaceLandmarkRegion2D) -> Double {
        // 簡化的曲率計算
        let points = innerLips.normalizedPoints
        guard points.count >= 6 else { return 0 }

        let leftCorner = points[0]
        let center = points[points.count / 2]
        let rightCorner = points[points.count - 1]

        let midY = (leftCorner.y + rightCorner.y) / 2
        return center.y - midY // 正值表示向上彎曲（笑），負值表示向下彎曲
    }

    private static func calculateLipAsymmetry(outerLips: VNFaceLandmarkRegion2D) -> Double {
        let points = outerLips.normalizedPoints
        guard points.count >= 4 else { return 0 }

        let leftSide = Array(points.prefix(points.count / 2))
        let rightSide = Array(points.suffix(points.count / 2))

        let leftAvgY = leftSide.map { $0.y }.reduce(0, +) / Double(leftSide.count)
        let rightAvgY = rightSide.map { $0.y }.reduce(0, +) / Double(rightSide.count)

        return abs(leftAvgY - rightAvgY)
    }

    private static func calculateNostrilWidth(nose: VNFaceLandmarkRegion2D) -> Double {
        let points = nose.normalizedPoints
        guard points.count >= 4 else { return 0 }

        let leftNostril = points[0]
        let rightNostril = points[points.count - 1]

        return abs(rightNostril.x - leftNostril.x)
    }

    private static func calculateNoseLength(noseCrest: VNFaceLandmarkRegion2D) -> Double {
        let points = noseCrest.normalizedPoints
        guard points.count >= 2 else { return 0 }

        let topPoint = points[0]
        let bottomPoint = points[points.count - 1]

        return abs(bottomPoint.y - topPoint.y)
    }
}

/// 眉毛分析結果
struct EyebrowAnalysis {
    let leftHeight: Double
    let rightHeight: Double
    let symmetry: Double
    let averageHeight: Double

    var isRaised: Bool {
        return averageHeight > 0.08 // 閾值可調整
    }

    var raisedIntensity: Double {
        return min(max((averageHeight - 0.05) / 0.05, 0), 1)
    }
}

/// 嘴唇分析結果
struct LipAnalysis {
    let width: Double
    let height: Double
    let curvature: Double
    let asymmetry: Double
    let aspectRatio: Double

    var isSmiling: Bool {
        return curvature > 0.02 && aspectRatio > 2.0
    }

    var smileIntensity: Double {
        let curvatureScore = min(max((curvature - 0.01) / 0.04, 0), 1)
        let widthScore = min(max((aspectRatio - 2.0) / 2.0, 0), 1)
        return (curvatureScore + widthScore) / 2
    }

    var isPursed: Bool {
        return aspectRatio < 1.5 && height < 0.03
    }
}

/// 鼻孔分析結果
struct NoseAnalysis {
    let nostrilWidth: Double
    let noseLength: Double
    let aspectRatio: Double

    var isFlared: Bool {
        return nostrilWidth > 0.08 // 閾值可調整
    }

    var flareIntensity: Double {
        return min(max((nostrilWidth - 0.06) / 0.04, 0), 1)
    }
}

/// 視線分析器
class GazeAnalyzer {
    private var previousGazePoints: [CGPoint] = []
    private let gazeHistoryLimit = 10

    func analyzeGazeShift(from faceObservation: VNFaceObservation) -> GazeShiftResult? {
        // 簡化的視線分析（實際實作可能需要更複雜的算法）
        guard let leftPupil = faceObservation.landmarks?.leftPupil,
              let rightPupil = faceObservation.landmarks?.rightPupil else {
            return nil
        }

        let leftPupilPoints = leftPupil.normalizedPoints
        let rightPupilPoints = rightPupil.normalizedPoints

        guard !leftPupilPoints.isEmpty && !rightPupilPoints.isEmpty else {
            return nil
        }

        let leftPupilCenter = leftPupilPoints[0] // 簡化處理
        let rightPupilCenter = rightPupilPoints[0]
        let gazePoint = CGPoint(
            x: (leftPupilCenter.x + rightPupilCenter.x) / 2,
            y: (leftPupilCenter.y + rightPupilCenter.y) / 2
        )

        previousGazePoints.append(gazePoint)
        if previousGazePoints.count > gazeHistoryLimit {
            previousGazePoints.removeFirst()
        }

        guard previousGazePoints.count >= 3 else { return nil }

        let recentMovement = calculateGazeMovement()
        return GazeShiftResult(
            direction: recentMovement.direction,
            magnitude: recentMovement.magnitude,
            velocity: recentMovement.velocity
        )
    }

    private func calculateGazeMovement() -> (direction: CGVector, magnitude: Double, velocity: Double) {
        let recent = Array(previousGazePoints.suffix(3))
        let start = recent[0]
        let end = recent[recent.count - 1]

        let direction = CGVector(dx: end.x - start.x, dy: end.y - start.y)
        let magnitude = sqrt(direction.dx * direction.dx + direction.dy * direction.dy)
        let velocity = magnitude / Double(recent.count - 1)

        return (direction, Double(magnitude), velocity)
    }
}

/// 視線轉移結果
struct GazeShiftResult {
    let direction: CGVector
    let magnitude: Double
    let velocity: Double

    var isSignificant: Bool {
        return magnitude > 0.1 && velocity > 0.05
    }

    var intensity: Double {
        return min(magnitude * 5, 1.0) // 放大並限制在 0-1
    }
}

/// 微手勢檢測器主類 - GazeTurn v2 進階手勢識別
class MicroGestureDetector: NSObject {

    // MARK: - Properties

    /// 啟用的微手勢類型
    var enabledGestureTypes: Set<MicroGestureType> = [.eyebrowRaise, .smile, .gazeShift]

    /// 檢測敏感度
    var sensitivity: Double = 0.5 {
        didSet {
            updateThresholds()
        }
    }

    /// 最小手勢持續時間
    var minimumGestureDuration: TimeInterval = 0.1

    /// 檢測結果回調
    var onGestureDetected: ((MicroGestureResult) -> Void)?

    // MARK: - Private Properties

    private var thresholds: [MicroGestureType: Double] = [:]
    private var gestureStates: [MicroGestureType: GestureState] = [:]
    private var gazeAnalyzer = GazeAnalyzer()

    private let processingQueue = DispatchQueue(label: "micro.gesture.processing", qos: .userInteractive)

    // MARK: - Initialization

    override init() {
        super.init()
        setupDefaultThresholds()
        initializeGestureStates()
    }

    // MARK: - Public Methods

    /// 處理面部觀察結果
    func processFaceObservation(_ observation: VNFaceObservation) {
        processingQueue.async { [weak self] in
            self?.performMicroGestureDetection(observation)
        }
    }

    /// 設置手勢類型啟用狀態
    func setGestureEnabled(_ type: MicroGestureType, enabled: Bool) {
        if enabled {
            enabledGestureTypes.insert(type)
        } else {
            enabledGestureTypes.remove(type)
        }

        // 重置該手勢的狀態
        gestureStates[type] = GestureState()
    }

    /// 獲取當前檢測統計
    func getDetectionStatistics() -> [MicroGestureType: GestureStatistics] {
        return gestureStates.compactMapValues { state in
            GestureStatistics(
                totalDetections: state.detectionCount,
                averageConfidence: state.averageConfidence,
                averageIntensity: state.averageIntensity,
                lastDetection: state.lastDetectionTime
            )
        }
    }

    /// 重置所有手勢狀態
    func resetGestureStates() {
        initializeGestureStates()
    }

    // MARK: - Private Methods

    /// 執行微手勢檢測
    private func performMicroGestureDetection(_ observation: VNFaceObservation) {
        guard let landmarks = observation.landmarks else { return }

        let currentTime = Date()
        var detectedGestures: [MicroGestureResult] = []

        // 檢測眉毛上揚
        if enabledGestureTypes.contains(.eyebrowRaise) {
            if let result = detectEyebrowRaise(landmarks: landmarks, confidence: observation.confidence) {
                detectedGestures.append(result)
            }
        }

        // 檢測微笑
        if enabledGestureTypes.contains(.smile) {
            if let result = detectSmile(landmarks: landmarks, confidence: observation.confidence) {
                detectedGestures.append(result)
            }
        }

        // 檢測視線轉移
        if enabledGestureTypes.contains(.gazeShift) {
            if let result = detectGazeShift(observation: observation) {
                detectedGestures.append(result)
            }
        }

        // 檢測抿嘴
        if enabledGestureTypes.contains(.lipPurse) {
            if let result = detectLipPurse(landmarks: landmarks, confidence: observation.confidence) {
                detectedGestures.append(result)
            }
        }

        // 檢測鼻翼張開
        if enabledGestureTypes.contains(.nostrilFlare) {
            if let result = detectNostrilFlare(landmarks: landmarks, confidence: observation.confidence) {
                detectedGestures.append(result)
            }
        }

        // 處理檢測結果
        for gesture in detectedGestures {
            processDetectionResult(gesture, at: currentTime)
        }
    }

    /// 檢測眉毛上揚
    private func detectEyebrowRaise(landmarks: VNFaceLandmarks2D, confidence: Float) -> MicroGestureResult? {
        guard let analysis = FacialLandmarkAnalyzer.analyzeEyebrows(from: landmarks) else {
            return nil
        }

        let threshold = thresholds[.eyebrowRaise] ?? 0.5
        let adjustedThreshold = threshold * sensitivity

        if analysis.isRaised && analysis.raisedIntensity > adjustedThreshold {
            return MicroGestureResult(
                type: .eyebrowRaise,
                confidence: Double(confidence),
                intensity: analysis.raisedIntensity,
                duration: 0, // 將在狀態處理中計算
                timestamp: Date(),
                landmarks: landmarks
            )
        }

        return nil
    }

    /// 檢測微笑
    private func detectSmile(landmarks: VNFaceLandmarks2D, confidence: Float) -> MicroGestureResult? {
        guard let analysis = FacialLandmarkAnalyzer.analyzeLips(from: landmarks) else {
            return nil
        }

        let threshold = thresholds[.smile] ?? 0.3
        let adjustedThreshold = threshold * sensitivity

        if analysis.isSmiling && analysis.smileIntensity > adjustedThreshold {
            return MicroGestureResult(
                type: .smile,
                confidence: Double(confidence),
                intensity: analysis.smileIntensity,
                duration: 0,
                timestamp: Date(),
                landmarks: landmarks
            )
        }

        return nil
    }

    /// 檢測視線轉移
    private func detectGazeShift(observation: VNFaceObservation) -> MicroGestureResult? {
        guard let gazeResult = gazeAnalyzer.analyzeGazeShift(from: observation) else {
            return nil
        }

        let threshold = thresholds[.gazeShift] ?? 0.3
        let adjustedThreshold = threshold * sensitivity

        if gazeResult.isSignificant && gazeResult.intensity > adjustedThreshold {
            return MicroGestureResult(
                type: .gazeShift,
                confidence: Double(observation.confidence),
                intensity: gazeResult.intensity,
                duration: 0,
                timestamp: Date(),
                landmarks: observation.landmarks
            )
        }

        return nil
    }

    /// 檢測抿嘴
    private func detectLipPurse(landmarks: VNFaceLandmarks2D, confidence: Float) -> MicroGestureResult? {
        guard let analysis = FacialLandmarkAnalyzer.analyzeLips(from: landmarks) else {
            return nil
        }

        let threshold = thresholds[.lipPurse] ?? 0.4

        if analysis.isPursed {
            let intensity = 1.0 - analysis.aspectRatio / 2.0 // 反比例關係
            let adjustedThreshold = threshold * sensitivity

            if intensity > adjustedThreshold {
                return MicroGestureResult(
                    type: .lipPurse,
                    confidence: Double(confidence),
                    intensity: intensity,
                    duration: 0,
                    timestamp: Date(),
                    landmarks: landmarks
                )
            }
        }

        return nil
    }

    /// 檢測鼻翼張開
    private func detectNostrilFlare(landmarks: VNFaceLandmarks2D, confidence: Float) -> MicroGestureResult? {
        guard let analysis = FacialLandmarkAnalyzer.analyzeNose(from: landmarks) else {
            return nil
        }

        let threshold = thresholds[.nostrilFlare] ?? 0.5
        let adjustedThreshold = threshold * sensitivity

        if analysis.isFlared && analysis.flareIntensity > adjustedThreshold {
            return MicroGestureResult(
                type: .nostrilFlare,
                confidence: Double(confidence),
                intensity: analysis.flareIntensity,
                duration: 0,
                timestamp: Date(),
                landmarks: landmarks
            )
        }

        return nil
    }

    /// 處理檢測結果
    private func processDetectionResult(_ result: MicroGestureResult, at time: Date) {
        let gestureType = result.type

        // 獲取或創建手勢狀態
        var state = gestureStates[gestureType] ?? GestureState()

        if !state.isActive {
            // 開始新的手勢
            state.startGesture(at: time, intensity: result.intensity)
        } else {
            // 更新現有手勢
            state.updateGesture(intensity: result.intensity)
        }

        gestureStates[gestureType] = state

        // 檢查是否應該觸發手勢事件
        if state.duration >= minimumGestureDuration && !state.hasTriggered {
            let finalResult = MicroGestureResult(
                type: result.type,
                confidence: result.confidence,
                intensity: state.averageIntensity,
                duration: state.duration,
                timestamp: state.startTime,
                landmarks: result.landmarks
            )

            state.markAsTriggered()
            gestureStates[gestureType] = state

            DispatchQueue.main.async { [weak self] in
                self?.onGestureDetected?(finalResult)
            }
        }

        // 清理過期的手勢狀態
        cleanupExpiredGestures(currentTime: time)
    }

    /// 清理過期的手勢狀態
    private func cleanupExpiredGestures(currentTime: Date) {
        let expirationTime: TimeInterval = 1.0 // 1秒無更新則認為手勢結束

        for (gestureType, state) in gestureStates {
            if state.isActive && currentTime.timeIntervalSince(state.lastUpdateTime) > expirationTime {
                gestureStates[gestureType]?.endGesture()
            }
        }
    }

    /// 設置預設閾值
    private func setupDefaultThresholds() {
        thresholds = [
            .eyebrowRaise: 0.6,
            .smile: 0.4,
            .gazeShift: 0.3,
            .pupilDilation: 0.5,
            .nostrilFlare: 0.7,
            .lipPurse: 0.5
        ]
    }

    /// 根據敏感度更新閾值
    private func updateThresholds() {
        // 敏感度影響閾值：高敏感度 = 低閾值
        let factor = 2.0 - sensitivity // 將 0.5 敏感度映射為 1.5 因子

        for gestureType in thresholds.keys {
            let baseThreshold = getBaseThreshold(for: gestureType)
            thresholds[gestureType] = baseThreshold * factor
        }
    }

    /// 獲取基礎閾值
    private func getBaseThreshold(for gestureType: MicroGestureType) -> Double {
        switch gestureType {
        case .eyebrowRaise: return 0.4
        case .smile: return 0.3
        case .gazeShift: return 0.2
        case .pupilDilation: return 0.4
        case .nostrilFlare: return 0.5
        case .lipPurse: return 0.4
        }
    }

    /// 初始化手勢狀態
    private func initializeGestureStates() {
        for gestureType in MicroGestureType.allCases {
            gestureStates[gestureType] = GestureState()
        }
    }
}

// MARK: - Supporting Structures

/// 手勢狀態追蹤
private struct GestureState {
    var isActive: Bool = false
    var hasTriggered: Bool = false
    var startTime: Date = Date()
    var lastUpdateTime: Date = Date()
    var intensityHistory: [Double] = []
    var detectionCount: Int = 0

    var duration: TimeInterval {
        return lastUpdateTime.timeIntervalSince(startTime)
    }

    var averageIntensity: Double {
        guard !intensityHistory.isEmpty else { return 0 }
        return intensityHistory.reduce(0, +) / Double(intensityHistory.count)
    }

    var averageConfidence: Double {
        // 簡化處理，實際可能需要單獨追蹤
        return averageIntensity
    }

    mutating func startGesture(at time: Date, intensity: Double) {
        isActive = true
        hasTriggered = false
        startTime = time
        lastUpdateTime = time
        intensityHistory = [intensity]
    }

    mutating func updateGesture(intensity: Double) {
        lastUpdateTime = Date()
        intensityHistory.append(intensity)

        // 限制歷史記錄大小
        if intensityHistory.count > 10 {
            intensityHistory.removeFirst()
        }
    }

    mutating func endGesture() {
        isActive = false
        hasTriggered = false
        if !intensityHistory.isEmpty {
            detectionCount += 1
        }
    }

    mutating func markAsTriggered() {
        hasTriggered = true
        detectionCount += 1
    }
}

/// 手勢統計資訊
struct GestureStatistics {
    let totalDetections: Int
    let averageConfidence: Double
    let averageIntensity: Double
    let lastDetection: Date?

    var detectionsPerHour: Double {
        guard let lastDetection = lastDetection else { return 0 }
        let hoursSinceFirst = Date().timeIntervalSince(lastDetection) / 3600
        return hoursSinceFirst > 0 ? Double(totalDetections) / hoursSinceFirst : 0
    }
}