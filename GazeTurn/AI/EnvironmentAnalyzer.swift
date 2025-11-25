//
//  EnvironmentAnalyzer.swift
//  GazeTurn
//
//  Created by Claude Code on 2025/11/21.
//

import Foundation
import CoreVideo
import Vision
import CoreImage
import AVFoundation
import UIKit

/// 照明品質評估
enum LightingQuality: String, CaseIterable, Codable {
    case excellent = "excellent"
    case good = "good"
    case fair = "fair"
    case poor = "poor"
    case dark = "dark"

    var description: String {
        switch self {
        case .excellent: return "照明優秀"
        case .good: return "照明良好"
        case .fair: return "照明普通"
        case .poor: return "照明不佳"
        case .dark: return "環境昏暗"
        }
    }

    var recommendedFrameRate: Int {
        switch self {
        case .excellent, .good: return 60
        case .fair: return 45
        case .poor: return 30
        case .dark: return 15
        }
    }

    var gestureThresholdMultiplier: Double {
        switch self {
        case .excellent: return 1.0
        case .good: return 0.95
        case .fair: return 0.85
        case .poor: return 0.75
        case .dark: return 0.6
        }
    }
}

/// 環境噪聲等級
enum NoiseLevel: String, CaseIterable, Codable {
    case minimal = "minimal"
    case low = "low"
    case moderate = "moderate"
    case high = "high"
    case extreme = "extreme"

    var description: String {
        switch self {
        case .minimal: return "環境穩定"
        case .low: return "輕微干擾"
        case .moderate: return "中等干擾"
        case .high: return "嚴重干擾"
        case .extreme: return "極度不穩定"
        }
    }

    var stabilizationFactor: Double {
        switch self {
        case .minimal: return 1.0
        case .low: return 0.9
        case .moderate: return 0.8
        case .high: return 0.6
        case .extreme: return 0.4
        }
    }
}

/// 用戶距離範圍
enum UserDistanceRange: String, CaseIterable, Codable {
    case tooClose = "too_close"      // < 30cm
    case close = "close"             // 30-50cm
    case optimal = "optimal"         // 50-80cm
    case far = "far"                 // 80-120cm
    case tooFar = "too_far"          // > 120cm

    var description: String {
        switch self {
        case .tooClose: return "距離過近"
        case .close: return "稍近"
        case .optimal: return "最佳距離"
        case .far: return "稍遠"
        case .tooFar: return "距離過遠"
        }
    }

    var recommendedAction: String {
        switch self {
        case .tooClose: return "請將設備稍微遠離一些"
        case .close: return "距離良好，可稍微調遠"
        case .optimal: return "距離完美，保持當前位置"
        case .far: return "可以稍微靠近一些"
        case .tooFar: return "請將設備靠近一些"
        }
    }

    var gestureScalingFactor: Double {
        switch self {
        case .tooClose: return 1.3
        case .close: return 1.1
        case .optimal: return 1.0
        case .far: return 0.9
        case .tooFar: return 0.7
        }
    }
}

/// 環境條件綜合評估
struct EnvironmentalCondition: Codable {
    let lighting: LightingQuality
    let noise: NoiseLevel
    let userDistance: UserDistanceRange
    let timestamp: Date
    let confidence: Double

    /// 整體環境品質評分 (0.0 - 1.0)
    var overallQuality: Double {
        let lightingScore = getLightingScore()
        let noiseScore = noise.stabilizationFactor
        let distanceScore = getDistanceScore()

        return (lightingScore + noiseScore + distanceScore) / 3.0 * confidence
    }

    private func getLightingScore() -> Double {
        switch lighting {
        case .excellent: return 1.0
        case .good: return 0.8
        case .fair: return 0.6
        case .poor: return 0.4
        case .dark: return 0.2
        }
    }

    private func getDistanceScore() -> Double {
        switch userDistance {
        case .optimal: return 1.0
        case .close, .far: return 0.8
        case .tooClose, .tooFar: return 0.4
        }
    }

    /// 是否需要優化建議
    var needsOptimization: Bool {
        return overallQuality < 0.7
    }

    /// 獲取優化建議
    var optimizationSuggestions: [String] {
        var suggestions: [String] = []

        if lighting == .poor || lighting == .dark {
            suggestions.append("建議增加照明或移動到光線充足的環境")
        }

        if noise == .high || noise == .extreme {
            suggestions.append("環境不穩定，請保持設備穩定或移動到安靜的空間")
        }

        if userDistance != .optimal {
            suggestions.append(userDistance.recommendedAction)
        }

        if confidence < 0.8 {
            suggestions.append("面部檢測信號不穩定，請調整姿勢或位置")
        }

        return suggestions
    }
}

/// 優化設定建議
struct OptimizationSettings {
    let frameRate: Int
    let gestureThreshold: Double
    let stabilizationEnabled: Bool
    let adaptiveMode: FrameRateMode
    let recommendedActions: [String]

    /// 建議的手勢敏感度調整
    var sensitivityAdjustment: Double {
        return gestureThreshold
    }

    /// 是否建議啟用額外穩定化
    var enhancedStabilization: Bool {
        return stabilizationEnabled
    }
}

/// 照明分析結果
struct LightingAnalysis {
    let brightness: Float           // 0.0 - 1.0
    let contrast: Float            // 0.0 - 1.0
    let uniformity: Float          // 照明均勻度 0.0 - 1.0
    let quality: LightingQuality
    let histogram: [Int]           // 亮度直方圖
    let shadowAreas: Int           // 陰影區域數量
    let highlightAreas: Int        // 高亮區域數量

    var isBacklit: Bool {
        return brightness < 0.3 && highlightAreas > shadowAreas
    }

    var hasHarshShadows: Bool {
        return contrast > 0.7 && uniformity < 0.4
    }
}

/// 距離估算結果
struct DistanceEstimation {
    let estimatedDistance: Double   // 公分
    let confidence: Double         // 0.0 - 1.0
    let range: UserDistanceRange
    let faceSize: CGSize          // 標準化面部大小
    let method: EstimationMethod

    enum EstimationMethod {
        case faceSize
        case eyeDistance
        case headPose
        case hybrid
    }

    var isReliable: Bool {
        return confidence > 0.7
    }
}

/// 噪聲檢測結果
struct NoiseDetectionResult {
    let movementVariance: Double    // 頭部移動方差
    let jitterLevel: Double        // 抖動程度
    let stabilityScore: Double     // 穩定性評分 0.0 - 1.0
    let noiseLevel: NoiseLevel
    let noiseFrequency: Double     // 噪聲頻率 Hz
    let motionPatterns: [MotionPattern]

    enum MotionPattern {
        case rhythmic       // 規律性運動
        case random         // 隨機運動
        case drift          // 漂移
        case vibration      // 震動
    }

    var isPredictableNoise: Bool {
        return motionPatterns.contains(.rhythmic)
    }
}

/// 環境分析器 - GazeTurn v2 智能環境適應核心
class EnvironmentAnalyzer: NSObject {

    // MARK: - Properties

    /// 分析結果回調
    var onEnvironmentAnalyzed: ((EnvironmentalCondition) -> Void)?

    /// 優化建議回調
    var onOptimizationRecommended: ((OptimizationSettings) -> Void)?

    /// 是否啟用連續分析
    var continuousAnalysisEnabled: Bool = true

    /// 分析間隔（秒）
    var analysisInterval: TimeInterval = 2.0

    // MARK: - Private Properties

    private var analysisHistory: [EnvironmentalCondition] = []
    private let historyLimit = 30 // 保留 30 次分析結果

    private var faceTrackingHistory: [VNFaceObservation] = []
    private let trackingHistoryLimit = 60 // 保留 60 幀面部追蹤

    private var lightingHistory: [LightingAnalysis] = []
    private let lightingHistoryLimit = 10

    private var lastAnalysisTime = Date()
    private var analysisTimer: Timer?

    private let ciContext = CIContext()
    private let processingQueue = DispatchQueue(label: "environment.analysis", qos: .userInteractive)

    // MARK: - Initialization

    override init() {
        super.init()
        startContinuousAnalysis()
    }

    deinit {
        stopContinuousAnalysis()
    }

    // MARK: - Public Methods

    /// 分析單幀環境條件
    func analyzeEnvironment(frame: CVPixelBuffer, faceObservation: VNFaceObservation?) -> EnvironmentalCondition {
        let lightingAnalysis = analyzeLightingCondition(from: frame)
        let distanceEstimation = estimateUserDistance(from: faceObservation)
        let noiseDetection = detectEnvironmentalNoise()

        let condition = EnvironmentalCondition(
            lighting: lightingAnalysis.quality,
            noise: noiseDetection.noiseLevel,
            userDistance: distanceEstimation.range,
            timestamp: Date(),
            confidence: calculateOverallConfidence(
                lighting: lightingAnalysis,
                distance: distanceEstimation,
                noise: noiseDetection
            )
        )

        // 更新歷史記錄
        updateAnalysisHistory(condition)

        // 更新面部追蹤歷史
        if let face = faceObservation {
            updateFaceTrackingHistory(face)
        }

        // 觸發回調
        DispatchQueue.main.async { [weak self] in
            self?.onEnvironmentAnalyzed?(condition)
        }

        return condition
    }

    /// 獲取環境優化建議
    func getOptimizationRecommendations(for condition: EnvironmentalCondition) -> OptimizationSettings {
        let frameRate = calculateOptimalFrameRate(for: condition)
        let thresholdMultiplier = calculateGestureThreshold(for: condition)
        let needsStabilization = condition.noise.stabilizationFactor < 0.8
        let adaptiveMode = determineAdaptiveMode(for: condition)

        let settings = OptimizationSettings(
            frameRate: frameRate,
            gestureThreshold: thresholdMultiplier,
            stabilizationEnabled: needsStabilization,
            adaptiveMode: adaptiveMode,
            recommendedActions: condition.optimizationSuggestions
        )

        DispatchQueue.main.async { [weak self] in
            self?.onOptimizationRecommended?(settings)
        }

        return settings
    }

    /// 獲取環境品質趨勢
    func getEnvironmentQualityTrend() -> EnvironmentTrend {
        guard analysisHistory.count >= 5 else {
            return EnvironmentTrend.stable
        }

        let recentQuality = Array(analysisHistory.suffix(5))
        let earlierQuality = Array(analysisHistory.prefix(5))

        let recentAvg = recentQuality.map { $0.overallQuality }.reduce(0, +) / Double(recentQuality.count)
        let earlierAvg = earlierQuality.map { $0.overallQuality }.reduce(0, +) / Double(earlierQuality.count)

        let improvement = recentAvg - earlierAvg

        if improvement > 0.1 {
            return .improving
        } else if improvement < -0.1 {
            return .degrading
        } else {
            return .stable
        }
    }

    /// 重置分析歷史
    func resetAnalysisHistory() {
        analysisHistory.removeAll()
        faceTrackingHistory.removeAll()
        lightingHistory.removeAll()
    }

    /// 獲取詳細環境報告
    func generateEnvironmentReport() -> EnvironmentReport {
        guard !analysisHistory.isEmpty else {
            return EnvironmentReport(
                averageQuality: 0,
                dominantLighting: .poor,
                averageDistance: .tooFar,
                commonNoiseLevel: .extreme,
                recommendations: ["需要更多數據來生成報告"],
                analysisCount: 0
            )
        }

        let avgQuality = analysisHistory.map { $0.overallQuality }.reduce(0, +) / Double(analysisHistory.count)
        let dominantLighting = findDominantLighting()
        let avgDistance = findAverageDistance()
        let commonNoise = findCommonNoiseLevel()
        let recommendations = generateComprehensiveRecommendations()

        return EnvironmentReport(
            averageQuality: avgQuality,
            dominantLighting: dominantLighting,
            averageDistance: avgDistance,
            commonNoiseLevel: commonNoise,
            recommendations: recommendations,
            analysisCount: analysisHistory.count
        )
    }

    // MARK: - Private Analysis Methods

    /// 分析照明條件
    private func analyzeLightingCondition(from frame: CVPixelBuffer) -> LightingAnalysis {
        let ciImage = CIImage(cvPixelBuffer: frame)

        // 計算亮度
        let brightness = calculateBrightness(from: ciImage)

        // 計算對比度
        let contrast = calculateContrast(from: ciImage)

        // 計算照明均勻度
        let uniformity = calculateUniformity(from: ciImage)

        // 生成亮度直方圖
        let histogram = generateHistogram(from: ciImage)

        // 檢測陰影和高光區域
        let (shadowAreas, highlightAreas) = detectLightingAreas(from: ciImage)

        // 確定照明品質
        let quality = determineLightingQuality(
            brightness: brightness,
            contrast: contrast,
            uniformity: uniformity
        )

        let analysis = LightingAnalysis(
            brightness: brightness,
            contrast: contrast,
            uniformity: uniformity,
            quality: quality,
            histogram: histogram,
            shadowAreas: shadowAreas,
            highlightAreas: highlightAreas
        )

        // 更新照明歷史
        lightingHistory.append(analysis)
        if lightingHistory.count > lightingHistoryLimit {
            lightingHistory.removeFirst()
        }

        return analysis
    }

    /// 估算用戶距離
    private func estimateUserDistance(from faceObservation: VNFaceObservation?) -> DistanceEstimation {
        guard let face = faceObservation else {
            return DistanceEstimation(
                estimatedDistance: 100.0, // 預設距離
                confidence: 0.0,
                range: .optimal,
                faceSize: .zero,
                method: .faceSize
            )
        }

        // 方法1: 基於面部尺寸
        let faceSize = CGSize(width: face.boundingBox.width, height: face.boundingBox.height)
        let faceSizeDistance = estimateDistanceFromFaceSize(faceSize)

        // 方法2: 基於眼距
        var eyeDistanceEstimation: Double = 100.0
        if let leftEye = face.landmarks?.leftEye,
           let rightEye = face.landmarks?.rightEye {
            eyeDistanceEstimation = estimateDistanceFromEyeDistance(leftEye, rightEye)
        }

        // 混合估算
        let estimatedDistance = (faceSizeDistance + eyeDistanceEstimation) / 2.0
        let confidence = face.confidence > 0.8 ? Double(face.confidence) : 0.5

        let range = determineDistanceRange(estimatedDistance)

        return DistanceEstimation(
            estimatedDistance: estimatedDistance,
            confidence: confidence,
            range: range,
            faceSize: faceSize,
            method: .hybrid
        )
    }

    /// 檢測環境噪聲
    private func detectEnvironmentalNoise() -> NoiseDetectionResult {
        guard faceTrackingHistory.count >= 10 else {
            return NoiseDetectionResult(
                movementVariance: 0.0,
                jitterLevel: 0.0,
                stabilityScore: 1.0,
                noiseLevel: .minimal,
                noiseFrequency: 0.0,
                motionPatterns: []
            )
        }

        // 分析頭部位置變化
        let headPositions = faceTrackingHistory.map { $0.boundingBox.center }
        let movementVariance = calculateMovementVariance(headPositions)

        // 計算抖動程度
        let jitterLevel = calculateJitterLevel(headPositions)

        // 計算穩定性評分
        let stabilityScore = max(0.0, 1.0 - (movementVariance + jitterLevel) / 2.0)

        // 確定噪聲等級
        let noiseLevel = determineNoiseLevel(variance: movementVariance, jitter: jitterLevel)

        // 分析運動頻率
        let noiseFrequency = calculateMotionFrequency(headPositions)

        // 識別運動模式
        let motionPatterns = identifyMotionPatterns(headPositions)

        return NoiseDetectionResult(
            movementVariance: movementVariance,
            jitterLevel: jitterLevel,
            stabilityScore: stabilityScore,
            noiseLevel: noiseLevel,
            noiseFrequency: noiseFrequency,
            motionPatterns: motionPatterns
        )
    }

    // MARK: - Calculation Helpers

    private func calculateBrightness(from image: CIImage) -> Float {
        let extent = image.extent
        let filter = CIFilter(name: "CIAreaAverage")!
        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(CIVector(cgRect: extent), forKey: kCIInputExtentKey)

        guard let outputImage = filter.outputImage else { return 0.5 }

        var bitmap = [UInt8](repeating: 0, count: 4)
        ciContext.render(outputImage,
                        toBitmap: &bitmap,
                        rowBytes: 4,
                        bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
                        format: .RGBA8,
                        colorSpace: nil)

        return Float(bitmap[0]) / 255.0
    }

    private func calculateContrast(from image: CIImage) -> Float {
        // 簡化的對比度計算
        let filter = CIFilter(name: "CIColorControls")!
        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(1.0, forKey: kCIInputContrastKey)

        // 實際實作會更複雜，這裡返回估算值
        return 0.5
    }

    private func calculateUniformity(from image: CIImage) -> Float {
        // 簡化的照明均勻度計算
        // 實際實作會分析圖像的亮度分布
        return 0.7
    }

    private func generateHistogram(from image: CIImage) -> [Int] {
        // 簡化的直方圖生成
        return Array(repeating: 0, count: 256)
    }

    private func detectLightingAreas(from image: CIImage) -> (shadowAreas: Int, highlightAreas: Int) {
        // 簡化的陰影和高光檢測
        return (shadowAreas: 2, highlightAreas: 1)
    }

    private func determineLightingQuality(brightness: Float, contrast: Float, uniformity: Float) -> LightingQuality {
        if brightness > 0.7 && contrast < 0.8 && uniformity > 0.8 {
            return .excellent
        } else if brightness > 0.5 && contrast < 0.9 && uniformity > 0.6 {
            return .good
        } else if brightness > 0.3 {
            return .fair
        } else if brightness > 0.1 {
            return .poor
        } else {
            return .dark
        }
    }

    private func estimateDistanceFromFaceSize(_ faceSize: CGSize) -> Double {
        // 基於標準面部尺寸的距離估算
        let avgFaceWidth = 0.14 // 標準化座標中的平均面部寬度
        let realFaceWidth = 14.0 // 實際面部寬度約 14cm

        let distance = (realFaceWidth * avgFaceWidth) / Double(faceSize.width)
        return max(20.0, min(distance, 200.0)) // 限制在合理範圍
    }

    private func estimateDistanceFromEyeDistance(_ leftEye: VNFaceLandmarkRegion2D, _ rightEye: VNFaceLandmarkRegion2D) -> Double {
        let leftPoints = leftEye.normalizedPoints
        let rightPoints = rightEye.normalizedPoints

        guard !leftPoints.isEmpty && !rightPoints.isEmpty else { return 100.0 }

        let leftCenter = leftPoints[0] // 簡化處理
        let rightCenter = rightPoints[0]

        let eyeDistance = abs(rightCenter.x - leftCenter.x)
        let realEyeDistance = 6.3 // 平均瞳距 6.3cm

        let distance = realEyeDistance / Double(eyeDistance)
        return max(20.0, min(distance, 200.0))
    }

    private func determineDistanceRange(_ distance: Double) -> UserDistanceRange {
        switch distance {
        case 0..<30: return .tooClose
        case 30..<50: return .close
        case 50..<80: return .optimal
        case 80..<120: return .far
        default: return .tooFar
        }
    }

    private func calculateMovementVariance(_ positions: [CGPoint]) -> Double {
        guard positions.count > 1 else { return 0.0 }

        let avgX = positions.map { $0.x }.reduce(0, +) / CGFloat(positions.count)
        let avgY = positions.map { $0.y }.reduce(0, +) / CGFloat(positions.count)

        let variance = positions.map {
            pow(Double($0.x - avgX), 2) + pow(Double($0.y - avgY), 2)
        }.reduce(0, +) / Double(positions.count)

        return variance
    }

    private func calculateJitterLevel(_ positions: [CGPoint]) -> Double {
        guard positions.count > 2 else { return 0.0 }

        var totalJitter = 0.0
        for i in 1..<positions.count-1 {
            let prev = positions[i-1]
            let curr = positions[i]
            let next = positions[i+1]

            let jitter = abs(Double(curr.x - (prev.x + next.x)/2)) +
                        abs(Double(curr.y - (prev.y + next.y)/2))
            totalJitter += jitter
        }

        return totalJitter / Double(positions.count - 2)
    }

    private func determineNoiseLevel(variance: Double, jitter: Double) -> NoiseLevel {
        let noiseScore = variance + jitter

        switch noiseScore {
        case 0..<0.001: return .minimal
        case 0.001..<0.005: return .low
        case 0.005..<0.02: return .moderate
        case 0.02..<0.05: return .high
        default: return .extreme
        }
    }

    private func calculateMotionFrequency(_ positions: [CGPoint]) -> Double {
        // 簡化的頻率分析
        return 0.0
    }

    private func identifyMotionPatterns(_ positions: [CGPoint]) -> [NoiseDetectionResult.MotionPattern] {
        // 簡化的模式識別
        return [.random]
    }

    // MARK: - Optimization Calculations

    private func calculateOptimalFrameRate(for condition: EnvironmentalCondition) -> Int {
        let baseFrameRate = condition.lighting.recommendedFrameRate
        let distanceAdjustment = condition.userDistance == .optimal ? 1.0 : 0.8
        let noiseAdjustment = condition.noise.stabilizationFactor

        let adjustedFrameRate = Double(baseFrameRate) * distanceAdjustment * noiseAdjustment
        return max(15, min(Int(adjustedFrameRate), 60))
    }

    private func calculateGestureThreshold(for condition: EnvironmentalCondition) -> Double {
        let lightingMultiplier = condition.lighting.gestureThresholdMultiplier
        let distanceMultiplier = condition.userDistance.gestureScalingFactor
        let noiseMultiplier = condition.noise.stabilizationFactor

        return lightingMultiplier * distanceMultiplier * noiseMultiplier
    }

    private func determineAdaptiveMode(for condition: EnvironmentalCondition) -> FrameRateMode {
        if condition.overallQuality > 0.8 {
            return .performance
        } else if condition.overallQuality > 0.5 {
            return .balanced
        } else {
            return .battery
        }
    }

    private func calculateOverallConfidence(lighting: LightingAnalysis, distance: DistanceEstimation, noise: NoiseDetectionResult) -> Double {
        let lightingConfidence = lighting.brightness > 0.3 ? 0.8 : 0.4
        let distanceConfidence = distance.confidence
        let stabilityConfidence = noise.stabilityScore

        return (lightingConfidence + distanceConfidence + stabilityConfidence) / 3.0
    }

    // MARK: - History Management

    private func updateAnalysisHistory(_ condition: EnvironmentalCondition) {
        analysisHistory.append(condition)
        if analysisHistory.count > historyLimit {
            analysisHistory.removeFirst()
        }
    }

    private func updateFaceTrackingHistory(_ face: VNFaceObservation) {
        faceTrackingHistory.append(face)
        if faceTrackingHistory.count > trackingHistoryLimit {
            faceTrackingHistory.removeFirst()
        }
    }

    // MARK: - Continuous Analysis

    private func startContinuousAnalysis() {
        guard continuousAnalysisEnabled else { return }

        analysisTimer = Timer.scheduledTimer(withTimeInterval: analysisInterval, repeats: true) { [weak self] _ in
            self?.performPeriodicAnalysis()
        }
    }

    private func stopContinuousAnalysis() {
        analysisTimer?.invalidate()
        analysisTimer = nil
    }

    private func performPeriodicAnalysis() {
        // 定期分析會在有新幀時觸發
        // 這裡可以執行趨勢分析和長期優化
    }

    // MARK: - Report Generation

    private func findDominantLighting() -> LightingQuality {
        let lightingCounts = analysisHistory.reduce(into: [:]) { counts, condition in
            counts[condition.lighting, default: 0] += 1
        }

        return lightingCounts.max(by: { $0.value < $1.value })?.key ?? .fair
    }

    private func findAverageDistance() -> UserDistanceRange {
        let distanceCounts = analysisHistory.reduce(into: [:]) { counts, condition in
            counts[condition.userDistance, default: 0] += 1
        }

        return distanceCounts.max(by: { $0.value < $1.value })?.key ?? .optimal
    }

    private func findCommonNoiseLevel() -> NoiseLevel {
        let noiseCounts = analysisHistory.reduce(into: [:]) { counts, condition in
            counts[condition.noise, default: 0] += 1
        }

        return noiseCounts.max(by: { $0.value < $1.value })?.key ?? .low
    }

    private func generateComprehensiveRecommendations() -> [String] {
        var recommendations: [String] = []

        let avgQuality = analysisHistory.map { $0.overallQuality }.reduce(0, +) / Double(analysisHistory.count)

        if avgQuality < 0.6 {
            recommendations.append("整體環境品質需要改善")
        }

        let dominantLighting = findDominantLighting()
        if dominantLighting == .poor || dominantLighting == .dark {
            recommendations.append("建議改善照明條件")
        }

        let avgDistance = findAverageDistance()
        if avgDistance != .optimal {
            recommendations.append("建議調整設備距離到最佳範圍 (50-80cm)")
        }

        let commonNoise = findCommonNoiseLevel()
        if commonNoise == .high || commonNoise == .extreme {
            recommendations.append("建議減少環境干擾或使用穩定支架")
        }

        return recommendations
    }
}

// MARK: - Supporting Types

enum EnvironmentTrend {
    case improving
    case stable
    case degrading

    var description: String {
        switch self {
        case .improving: return "環境品質改善中"
        case .stable: return "環境品質穩定"
        case .degrading: return "環境品質下降"
        }
    }
}

struct EnvironmentReport {
    let averageQuality: Double
    let dominantLighting: LightingQuality
    let averageDistance: UserDistanceRange
    let commonNoiseLevel: NoiseLevel
    let recommendations: [String]
    let analysisCount: Int

    var qualityGrade: String {
        switch averageQuality {
        case 0.9...1.0: return "A+"
        case 0.8..<0.9: return "A"
        case 0.7..<0.8: return "B+"
        case 0.6..<0.7: return "B"
        case 0.5..<0.6: return "C"
        default: return "D"
        }
    }
}

// MARK: - Extensions

extension CGPoint {
    static func distance(_ p1: CGPoint, _ p2: CGPoint) -> Double {
        return sqrt(pow(Double(p2.x - p1.x), 2) + pow(Double(p2.y - p1.y), 2))
    }
}

extension CGRect {
    var center: CGPoint {
        return CGPoint(x: midX, y: midY)
    }
}