//
//  SmartCalibrationEngine.swift
//  GazeTurn
//
//  Created by Claude Code on 2024-11-21.
//

import Foundation
import Vision
import SwiftUI
import Combine

/// Calibration status for different gesture types
enum CalibrationStatus: String, CaseIterable {
    case notStarted = "not_started"
    case inProgress = "in_progress"
    case completed = "completed"
    case optimizing = "optimizing"

    var localizedDescription: String {
        switch self {
        case .notStarted: return "未開始"
        case .inProgress: return "校準中"
        case .completed: return "已完成"
        case .optimizing: return "優化中"
        }
    }
}

/// Smart calibration configuration for different contexts
struct CalibrationContext {
    let environmentalCondition: EnvironmentalCondition
    let instrumentType: InstrumentType
    let userDistance: Double
    let lightingQuality: LightingQuality
    let timestamp: Date

    var contextId: String {
        return "\(instrumentType.rawValue)_\(Int(userDistance))_\(lightingQuality.rawValue)"
    }
}

/// Calibration learning data for continuous improvement
struct CalibrationLearningData {
    let gestureType: String
    let threshold: Double
    let accuracy: Double
    let context: CalibrationContext
    let userFeedback: CalibrationFeedback
    let timestamp: Date
}

/// User feedback on calibration quality
enum CalibrationFeedback: String, CaseIterable {
    case tooSensitive = "too_sensitive"
    case tooInsensitive = "too_insensitive"
    case perfect = "perfect"
    case needsAdjustment = "needs_adjustment"

    var adjustmentFactor: Double {
        switch self {
        case .tooSensitive: return 1.2
        case .tooInsensitive: return 0.8
        case .perfect: return 1.0
        case .needsAdjustment: return 1.1
        }
    }
}

/// One-shot calibration result with confidence scoring
struct OneshotCalibrationResult {
    let gestureType: String
    let recommendedThreshold: Double
    let confidence: Double
    let sampleSize: Int
    let variance: Double
    let context: CalibrationContext

    var isReliable: Bool {
        return confidence > 0.7 && sampleSize >= 3
    }
}

/// Background optimization task for continuous learning
struct BackgroundOptimizationTask {
    let id = UUID()
    let gestureType: String
    let targetAccuracy: Double
    let maxDuration: TimeInterval
    let startTime: Date
    let context: CalibrationContext

    var isExpired: Bool {
        Date().timeIntervalSince(startTime) > maxDuration
    }
}

/// Smart Calibration Engine v2 - One-shot calibration with continuous learning
@MainActor
class SmartCalibrationEngine: ObservableObject {

    // MARK: - Published Properties
    @Published var calibrationStatus: [String: CalibrationStatus] = [:]
    @Published var currentAccuracy: [String: Double] = [:]
    @Published var isBackgroundOptimizing = false
    @Published var lastOptimizationTime: Date?
    @Published var contextualRecommendations: [String] = []

    // MARK: - Private Properties
    private let gestureTypes = ["blink", "head_shake", "eyebrow_raise", "smile", "head_nod", "mouth_open"]
    private let userDefaults = UserDefaults.standard
    private let learningEngine: GestureLearningEngine
    private let environmentAnalyzer: EnvironmentAnalyzer

    private var calibrationHistory: [CalibrationLearningData] = []
    private var contextualThresholds: [String: [String: Double]] = [:]
    private var backgroundTasks: [BackgroundOptimizationTask] = []
    private var continuousLearningTimer: Timer?

    // MARK: - Constants
    private struct Constants {
        static let minSampleSize = 3
        static let maxSampleSize = 10
        static let confidenceThreshold = 0.7
        static let accuracyTarget = 0.95
        static let backgroundOptimizationInterval: TimeInterval = 300 // 5 minutes
        static let contextSimilarityThreshold = 0.8
        static let adaptationRate = 0.1
    }

    // MARK: - Initialization
    init(learningEngine: GestureLearningEngine, environmentAnalyzer: EnvironmentAnalyzer) {
        self.learningEngine = learningEngine
        self.environmentAnalyzer = environmentAnalyzer

        loadCalibrationHistory()
        loadContextualThresholds()
        initializeCalibrationStatus()
        startContinuousLearning()
    }

    deinit {
        continuousLearningTimer?.invalidate()
    }

    // MARK: - Public Methods

    /// Perform one-shot calibration for a specific gesture type
    func performOnesShotCalibration(
        for gestureType: String,
        context: CalibrationContext,
        samples: [GestureTrainingData]
    ) async -> OnesShotCalibrationResult {

        calibrationStatus[gestureType] = .inProgress

        // Analyze samples for optimal threshold
        let thresholds = samples.map { $0.threshold }
        let meanThreshold = thresholds.reduce(0, +) / Double(thresholds.count)
        let variance = calculateVariance(values: thresholds, mean: meanThreshold)

        // Calculate confidence based on sample consistency
        let confidence = calculateConfidence(variance: variance, sampleSize: samples.count)

        // Apply contextual adjustments
        let contextualThreshold = applyContextualAdjustments(
            baseThreshold: meanThreshold,
            gestureType: gestureType,
            context: context
        )

        let result = OnesShotCalibrationResult(
            gestureType: gestureType,
            recommendedThreshold: contextualThreshold,
            confidence: confidence,
            sampleSize: samples.count,
            variance: variance,
            context: context
        )

        // Save result if reliable
        if result.isReliable {
            saveCalibrationResult(result)
            calibrationStatus[gestureType] = .completed
        }

        return result
    }

    /// Get adaptive threshold for current context
    func getAdaptiveThreshold(for gestureType: String, context: CalibrationContext) -> Double {
        let contextId = context.contextId

        // Check for exact context match
        if let contextThreshold = contextualThresholds[gestureType]?[contextId] {
            return contextThreshold
        }

        // Find similar contexts
        let similarThreshold = findSimilarContextThreshold(
            gestureType: gestureType,
            targetContext: context
        )

        if let threshold = similarThreshold {
            return threshold
        }

        // Fall back to base threshold
        return getBaseThreshold(for: gestureType)
    }

    /// Record calibration feedback for continuous improvement
    func recordCalibrationFeedback(
        gestureType: String,
        feedback: CalibrationFeedback,
        context: CalibrationContext
    ) {
        let currentThreshold = getAdaptiveThreshold(for: gestureType, context: context)
        let adjustedThreshold = currentThreshold * feedback.adjustmentFactor

        let learningData = CalibrationLearningData(
            gestureType: gestureType,
            threshold: adjustedThreshold,
            accuracy: calculateCurrentAccuracy(for: gestureType),
            context: context,
            userFeedback: feedback,
            timestamp: Date()
        )

        calibrationHistory.append(learningData)
        updateContextualThreshold(
            gestureType: gestureType,
            context: context,
            newThreshold: adjustedThreshold
        )

        saveCalibrationHistory()

        // Schedule background optimization if needed
        scheduleBackgroundOptimization(for: gestureType, context: context)
    }

    /// Start background optimization for continuous learning
    func startBackgroundOptimization() {
        guard !isBackgroundOptimizing else { return }

        isBackgroundOptimizing = true
        lastOptimizationTime = Date()

        Task {
            await performBackgroundOptimization()
            await MainActor.run {
                self.isBackgroundOptimizing = false
            }
        }
    }

    /// Get contextual recommendations for the user
    func getContextualRecommendations(for context: CalibrationContext) -> [String] {
        var recommendations: [String] = []

        // Check lighting conditions
        if context.lightingQuality == .poor {
            recommendations.append("建議改善照明環境以獲得更好的手勢識別效果")
        }

        // Check distance
        if context.userDistance < 30 {
            recommendations.append("建議保持 30-60 公分的最佳觀看距離")
        } else if context.userDistance > 80 {
            recommendations.append("您離設備較遠，可能需要調整手勢幅度")
        }

        // Check calibration status
        let uncalibratedGestures = gestureTypes.filter {
            calibrationStatus[$0] != .completed
        }

        if !uncalibratedGestures.isEmpty {
            recommendations.append("建議先校準 \(uncalibratedGestures.joined(separator: "、")) 手勢")
        }

        // Check accuracy
        let lowAccuracyGestures = currentAccuracy.filter { $0.value < 0.8 }
        if !lowAccuracyGestures.isEmpty {
            recommendations.append("以下手勢識別準確度較低，建議重新校準：\(lowAccuracyGestures.keys.joined(separator: "、"))")
        }

        return recommendations
    }

    /// Reset calibration for specific gesture or all gestures
    func resetCalibration(for gestureType: String? = nil) {
        if let specificGesture = gestureType {
            calibrationStatus[specificGesture] = .notStarted
            currentAccuracy[specificGesture] = 0.0
            contextualThresholds[specificGesture] = [:]
        } else {
            // Reset all
            initializeCalibrationStatus()
            contextualThresholds.removeAll()
            calibrationHistory.removeAll()
        }

        saveCalibrationHistory()
        saveContextualThresholds()
    }

    // MARK: - Private Methods

    private func initializeCalibrationStatus() {
        for gestureType in gestureTypes {
            calibrationStatus[gestureType] = .notStarted
            currentAccuracy[gestureType] = 0.0
        }
    }

    private func calculateVariance(values: [Double], mean: Double) -> Double {
        guard !values.isEmpty else { return 0 }

        let sumOfSquaredDeviations = values.map { pow($0 - mean, 2) }.reduce(0, +)
        return sumOfSquaredDeviations / Double(values.count)
    }

    private func calculateConfidence(variance: Double, sampleSize: Int) -> Double {
        // Higher sample size and lower variance = higher confidence
        let sizeConfidence = min(Double(sampleSize) / Double(Constants.maxSampleSize), 1.0)
        let varianceConfidence = max(0.0, 1.0 - variance)

        return (sizeConfidence + varianceConfidence) / 2.0
    }

    private func applyContextualAdjustments(
        baseThreshold: Double,
        gestureType: String,
        context: CalibrationContext
    ) -> Double {
        var adjustedThreshold = baseThreshold

        // Adjust for lighting
        switch context.lightingQuality {
        case .poor:
            adjustedThreshold *= 1.2 // Less sensitive in poor lighting
        case .excellent:
            adjustedThreshold *= 0.9 // More sensitive in good lighting
        default:
            break
        }

        // Adjust for distance
        if context.userDistance > 60 {
            adjustedThreshold *= 1.1 // Less sensitive for far distances
        } else if context.userDistance < 40 {
            adjustedThreshold *= 0.95 // More sensitive for close distances
        }

        // Instrument-specific adjustments
        switch context.instrumentType {
        case .vocal:
            if gestureType == "mouth_open" {
                adjustedThreshold *= 0.8 // More sensitive for vocal gestures
            }
        case .percussion:
            if gestureType == "head_nod" {
                adjustedThreshold *= 0.9 // More sensitive for percussive timing
            }
        default:
            break
        }

        return max(0.1, min(1.0, adjustedThreshold))
    }

    private func findSimilarContextThreshold(
        gestureType: String,
        targetContext: CalibrationContext
    ) -> Double? {
        guard let gestureThresholds = contextualThresholds[gestureType] else {
            return nil
        }

        var bestMatch: (contextId: String, similarity: Double, threshold: Double)?

        for (contextId, threshold) in gestureThresholds {
            let similarity = calculateContextSimilarity(
                target: targetContext,
                candidate: contextId
            )

            if similarity > Constants.contextSimilarityThreshold {
                if bestMatch == nil || similarity > bestMatch!.similarity {
                    bestMatch = (contextId, similarity, threshold)
                }
            }
        }

        return bestMatch?.threshold
    }

    private func calculateContextSimilarity(
        target: CalibrationContext,
        candidate: String
    ) -> Double {
        let candidateParts = candidate.split(separator: "_")
        guard candidateParts.count == 3 else { return 0 }

        let instrumentMatch = candidateParts[0] == target.instrumentType.rawValue ? 1.0 : 0.0
        let distanceDiff = abs(Double(candidateParts[1]) ?? 0 - target.userDistance)
        let distanceMatch = max(0.0, 1.0 - distanceDiff / 50.0)
        let lightingMatch = candidateParts[2] == target.lightingQuality.rawValue ? 1.0 : 0.0

        return (instrumentMatch + distanceMatch + lightingMatch) / 3.0
    }

    private func getBaseThreshold(for gestureType: String) -> Double {
        // Default thresholds based on gesture type
        switch gestureType {
        case "blink": return 0.6
        case "head_shake": return 15.0
        case "eyebrow_raise": return 0.3
        case "smile": return 0.4
        case "head_nod": return 12.0
        case "mouth_open": return 0.5
        default: return 0.5
        }
    }

    private func calculateCurrentAccuracy(for gestureType: String) -> Double {
        let recentData = calibrationHistory
            .filter { $0.gestureType == gestureType }
            .suffix(10)

        guard !recentData.isEmpty else { return 0.0 }

        return recentData.map { $0.accuracy }.reduce(0, +) / Double(recentData.count)
    }

    private func updateContextualThreshold(
        gestureType: String,
        context: CalibrationContext,
        newThreshold: Double
    ) {
        let contextId = context.contextId

        if contextualThresholds[gestureType] == nil {
            contextualThresholds[gestureType] = [:]
        }

        // Apply learning rate for gradual adaptation
        if let existingThreshold = contextualThresholds[gestureType]?[contextId] {
            let adaptedThreshold = existingThreshold * (1 - Constants.adaptationRate) +
                                 newThreshold * Constants.adaptationRate
            contextualThresholds[gestureType]?[contextId] = adaptedThreshold
        } else {
            contextualThresholds[gestureType]?[contextId] = newThreshold
        }

        saveContextualThresholds()
    }

    private func scheduleBackgroundOptimization(
        for gestureType: String,
        context: CalibrationContext
    ) {
        let task = BackgroundOptimizationTask(
            gestureType: gestureType,
            targetAccuracy: Constants.accuracyTarget,
            maxDuration: Constants.backgroundOptimizationInterval,
            startTime: Date(),
            context: context
        )

        backgroundTasks.append(task)

        // Start background optimization if not already running
        if !isBackgroundOptimizing {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.startBackgroundOptimization()
            }
        }
    }

    private func performBackgroundOptimization() async {
        // Clean up expired tasks
        backgroundTasks.removeAll { $0.isExpired }

        guard !backgroundTasks.isEmpty else { return }

        for task in backgroundTasks {
            await optimizeGestureThreshold(task: task)
        }

        // Clear completed tasks
        backgroundTasks.removeAll()

        await MainActor.run {
            self.lastOptimizationTime = Date()
        }
    }

    private func optimizeGestureThreshold(task: BackgroundOptimizationTask) async {
        let gestureType = task.gestureType
        let currentThreshold = getAdaptiveThreshold(for: gestureType, context: task.context)
        let currentAccuracy = calculateCurrentAccuracy(for: gestureType)

        if currentAccuracy < task.targetAccuracy {
            // Try to improve threshold based on recent feedback
            let recentFeedback = calibrationHistory
                .filter { $0.gestureType == gestureType }
                .suffix(5)

            if let averageAdjustment = calculateAverageAdjustment(from: recentFeedback) {
                let optimizedThreshold = currentThreshold * averageAdjustment

                updateContextualThreshold(
                    gestureType: gestureType,
                    context: task.context,
                    newThreshold: optimizedThreshold
                )
            }
        }

        await MainActor.run {
            self.calibrationStatus[gestureType] = .optimizing
        }
    }

    private func calculateAverageAdjustment(from feedback: [CalibrationLearningData]) -> Double? {
        guard !feedback.isEmpty else { return nil }

        let adjustments = feedback.map { $0.userFeedback.adjustmentFactor }
        return adjustments.reduce(0, +) / Double(adjustments.count)
    }

    private func startContinuousLearning() {
        continuousLearningTimer = Timer.scheduledTimer(withTimeInterval: Constants.backgroundOptimizationInterval, repeats: true) { _ in
            Task { @MainActor in
                if !self.isBackgroundOptimizing && !self.backgroundTasks.isEmpty {
                    self.startBackgroundOptimization()
                }
            }
        }
    }

    private func saveCalibrationResult(_ result: OnesShotCalibrationResult) {
        updateContextualThreshold(
            gestureType: result.gestureType,
            context: result.context,
            newThreshold: result.recommendedThreshold
        )

        currentAccuracy[result.gestureType] = result.confidence
    }

    // MARK: - Persistence

    private func loadCalibrationHistory() {
        if let data = userDefaults.data(forKey: "SmartCalibrationHistory"),
           let history = try? JSONDecoder().decode([CalibrationLearningData].self, from: data) {
            calibrationHistory = history
        }
    }

    private func saveCalibrationHistory() {
        if let data = try? JSONEncoder().encode(calibrationHistory) {
            userDefaults.set(data, forKey: "SmartCalibrationHistory")
        }
    }

    private func loadContextualThresholds() {
        if let data = userDefaults.data(forKey: "ContextualThresholds"),
           let thresholds = try? JSONDecoder().decode([String: [String: Double]].self, from: data) {
            contextualThresholds = thresholds
        }
    }

    private func saveContextualThresholds() {
        if let data = try? JSONEncoder().encode(contextualThresholds) {
            userDefaults.set(data, forKey: "ContextualThresholds")
        }
    }
}

// MARK: - Extensions

extension CalibrationLearningData: Codable {}
extension CalibrationFeedback: Codable {}
extension CalibrationContext: Codable {}