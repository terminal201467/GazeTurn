//
//  GestureLearningEngine.swift
//  GazeTurn
//
//  Created by Claude Code on 2025/11/21.
//

import Foundation
import CoreML
import Vision
import Combine

/// 手勢學習資料結構
struct GestureTrainingData {
    let gestureType: GestureType
    let timestamp: Date
    let context: GestureContext
    let features: GestureFeatures
    let outcome: GestureOutcome
    let confidence: Double

    enum GestureType {
        case blink
        case headShake(direction: HeadShakeDirection)
        case microGesture(type: MicroGestureType)

        enum MicroGestureType {
            case eyebrowRaise
            case smile
            case gazeShift
        }
    }

    enum GestureOutcome {
        case truePositive    // 正確識別的手勢
        case falsePositive   // 誤識別
        case falseNegative   // 漏識別
        case userConfirmed   // 用戶確認
        case userRejected    // 用戶拒絕
    }
}

/// 手勢上下文資訊
struct GestureContext {
    let instrumentType: InstrumentType
    let lightingCondition: LightingCondition
    let userDistance: Double
    let sessionDuration: TimeInterval
    let practiceMode: Bool

    enum LightingCondition {
        case excellent
        case good
        case poor
        case dark

        static func from(brightness: Float) -> LightingCondition {
            switch brightness {
            case 0.8...1.0: return .excellent
            case 0.5..<0.8: return .good
            case 0.2..<0.5: return .poor
            default: return .dark
            }
        }
    }
}

/// 手勢特徵向量
struct GestureFeatures {
    // 眨眼特徵
    let eyeAspectRatio: Double
    let blinkDuration: Double
    let blinkVelocity: Double

    // 頭部姿態特徵
    let headYaw: Double
    let headPitch: Double
    let headRoll: Double
    let headMovementVelocity: Double

    // 面部特徵
    let faceConfidence: Double
    let eyeOpenness: Double
    let mouthCurvature: Double

    // 時間特徵
    let timeSinceLastGesture: TimeInterval
    let gestureFrequency: Double

    // 環境特徵
    let ambientLight: Float
    let deviceMotion: Double
}

/// 個人化手勢檔案
struct PersonalGestureProfile {
    var userId: UUID
    var createdDate: Date
    var lastUpdated: Date

    // 個人化閾值
    var personalizedThresholds: [String: Double] = [:]

    // 手勢偏好
    var gesturePreferences: GesturePreferences = GesturePreferences()

    // 學習歷史
    var learningHistory: [LearningSession] = []

    // 性能指標
    var performanceMetrics: PersonalPerformanceMetrics = PersonalPerformanceMetrics()

    struct GesturePreferences {
        var preferredGestureTypes: Set<GestureTrainingData.GestureType> = []
        var sensitivityPreference: SensitivityLevel = .medium
        var adaptationSpeed: AdaptationSpeed = .normal

        enum SensitivityLevel {
            case low, medium, high
        }

        enum AdaptationSpeed {
            case slow, normal, fast
        }
    }

    struct LearningSession {
        let date: Date
        let duration: TimeInterval
        let gesturesProcessed: Int
        let accuracyImprovement: Double
        let instrumentType: InstrumentType
    }

    struct PersonalPerformanceMetrics {
        var totalGestures: Int = 0
        var correctGestures: Int = 0
        var falsePositives: Int = 0
        var falseNegatives: Int = 0
        var averageConfidence: Double = 0
        var adaptationRate: Double = 0

        var accuracy: Double {
            guard totalGestures > 0 else { return 0 }
            return Double(correctGestures) / Double(totalGestures)
        }

        var precision: Double {
            let detectedPositive = correctGestures + falsePositives
            guard detectedPositive > 0 else { return 0 }
            return Double(correctGestures) / Double(detectedPositive)
        }

        var recall: Double {
            let actualPositive = correctGestures + falseNegatives
            guard actualPositive > 0 else { return 0 }
            return Double(correctGestures) / Double(actualPositive)
        }
    }
}

/// AI 手勢學習引擎 - GazeTurn v2 智能核心
class GestureLearningEngine: ObservableObject {

    // MARK: - Published Properties

    @Published var currentProfile: PersonalGestureProfile
    @Published var learningEnabled: Bool = true
    @Published var adaptationProgress: Double = 0
    @Published var recentAccuracy: Double = 0
    @Published var learningInsights: [String] = []

    // MARK: - Private Properties

    private var trainingData: [GestureTrainingData] = []
    private let trainingDataLimit = 1000 // 保留最近 1000 個訓練樣本

    private var adaptiveThresholds: [String: AdaptiveThreshold] = [:]
    private var contextualModels: [String: ContextualModel] = [:]

    private var realtimeAnalyzer: RealtimeGestureAnalyzer
    private var patternRecognizer: GesturePatternRecognizer

    // 學習參數
    private let learningRate: Double = 0.01
    private let adaptationWindow = 50 // 每 50 個樣本進行一次適應
    private var sampleCounter = 0

    // 存儲管理
    private let profilesKey = "PersonalGestureProfiles"
    private let currentProfileKey = "CurrentGestureProfileId"

    // MARK: - Initialization

    init() {
        // 載入或創建個人檔案
        self.currentProfile = Self.loadOrCreateProfile()
        self.realtimeAnalyzer = RealtimeGestureAnalyzer()
        self.patternRecognizer = GesturePatternRecognizer()

        setupInitialThresholds()
        startLearningSession()
    }

    // MARK: - Public Methods

    /// 記錄手勢訓練資料
    func recordGestureData(_ data: GestureTrainingData) {
        trainingData.append(data)

        // 限制訓練資料大小
        if trainingData.count > trainingDataLimit {
            trainingData.removeFirst()
        }

        // 更新性能指標
        updatePerformanceMetrics(with: data)

        // 累積樣本計數
        sampleCounter += 1

        // 定期觸發適應
        if sampleCounter % adaptationWindow == 0 {
            performAdaptation()
        }

        // 即時分析
        if learningEnabled {
            realtimeAnalyzer.analyze(data)
        }
    }

    /// 獲取動態調整的閾值
    func getAdaptiveThreshold(for parameter: String, context: GestureContext) -> Double {
        let key = "\(parameter)_\(context.instrumentType)_\(context.lightingCondition)"

        if let threshold = adaptiveThresholds[key] {
            return threshold.getCurrentValue(for: context)
        }

        // 返回預設閾值
        return getDefaultThreshold(for: parameter)
    }

    /// 獲取手勢置信度評分
    func getGestureConfidence(for features: GestureFeatures, context: GestureContext) -> Double {
        let contextKey = generateContextKey(context)

        if let model = contextualModels[contextKey] {
            return model.predict(features)
        }

        // 使用基礎評分算法
        return calculateBaselineConfidence(features)
    }

    /// 提供個人化建議
    func getPersonalizedRecommendations() -> [String] {
        var recommendations: [String] = []
        let metrics = currentProfile.performanceMetrics

        // 基於準確率提供建議
        if metrics.accuracy < 0.8 {
            recommendations.append("檢測到識別準確率較低，建議重新校準手勢參數")
        }

        if metrics.falsePositives > metrics.totalGestures / 10 {
            recommendations.append("誤觸發較多，建議提高手勢檢測敏感度閾值")
        }

        if metrics.falseNegatives > metrics.totalGestures / 20 {
            recommendations.append("漏檢較多，建議降低手勢檢測敏感度閾值")
        }

        // 基於使用模式提供建議
        analyzeUsagePatterns(&recommendations)

        return recommendations
    }

    /// 重置學習資料
    func resetLearningData() {
        trainingData.removeAll()
        adaptiveThresholds.removeAll()
        contextualModels.removeAll()

        currentProfile.performanceMetrics = PersonalGestureProfile.PersonalPerformanceMetrics()
        currentProfile.lastUpdated = Date()

        setupInitialThresholds()
        saveProfile()

        learningInsights.append("學習資料已重置，系統將重新開始適應您的手勢模式")
    }

    /// 導出學習資料（用於分析或備份）
    func exportLearningData() -> Data? {
        let exportData = LearningDataExport(
            profile: currentProfile,
            trainingData: trainingData,
            thresholds: adaptiveThresholds.mapValues { $0.description }
        )

        return try? JSONEncoder().encode(exportData)
    }

    /// 匯入學習資料
    func importLearningData(_ data: Data) -> Bool {
        guard let exportData = try? JSONDecoder().decode(LearningDataExport.self, from: data) else {
            return false
        }

        currentProfile = exportData.profile
        trainingData = exportData.trainingData

        // 重建適應性閾值
        setupInitialThresholds()

        saveProfile()
        return true
    }

    // MARK: - Private Methods

    /// 設置初始閾值
    private func setupInitialThresholds() {
        let parameters = [
            "blinkThreshold", "headShakeAngle", "headShakeDuration",
            "eyebrowRaiseThreshold", "smileThreshold", "gazeShiftThreshold"
        ]

        for parameter in parameters {
            adaptiveThresholds[parameter] = AdaptiveThreshold(
                initialValue: getDefaultThreshold(for: parameter),
                learningRate: learningRate
            )
        }
    }

    /// 執行適應性調整
    private func performAdaptation() {
        guard trainingData.count >= adaptationWindow else { return }

        let recentData = Array(trainingData.suffix(adaptationWindow))

        // 分析最近的性能
        let recentAccuracy = calculateAccuracy(from: recentData)
        let contextGroups = groupByContext(recentData)

        // 為每個上下文調整閾值
        for (context, data) in contextGroups {
            adaptThresholdsForContext(context, data: data)
        }

        // 更新模型
        updateContextualModels(with: recentData)

        // 更新進度
        DispatchQueue.main.async {
            self.adaptationProgress = min(self.adaptationProgress + 0.02, 1.0)
            self.recentAccuracy = recentAccuracy
            self.generateLearningInsights()
        }

        saveProfile()
    }

    /// 為特定上下文調整閾值
    private func adaptThresholdsForContext(_ context: GestureContext, data: [GestureTrainingData]) {
        let contextKey = generateContextKey(context)

        for parameter in adaptiveThresholds.keys {
            let relevantData = data.filter { isRelevant($0, for: parameter) }

            if !relevantData.isEmpty {
                let adaptationValue = calculateAdaptationValue(for: parameter, data: relevantData)
                adaptiveThresholds[parameter]?.adapt(value: adaptationValue, context: contextKey)
            }
        }
    }

    /// 更新上下文模型
    private func updateContextualModels(with data: [GestureTrainingData]) {
        let contextGroups = groupByContext(data)

        for (context, contextData) in contextGroups {
            let contextKey = generateContextKey(context)

            if contextualModels[contextKey] == nil {
                contextualModels[contextKey] = ContextualModel(context: context)
            }

            contextualModels[contextKey]?.update(with: contextData)
        }
    }

    /// 更新性能指標
    private func updatePerformanceMetrics(with data: GestureTrainingData) {
        currentProfile.performanceMetrics.totalGestures += 1

        switch data.outcome {
        case .truePositive, .userConfirmed:
            currentProfile.performanceMetrics.correctGestures += 1
        case .falsePositive:
            currentProfile.performanceMetrics.falsePositives += 1
        case .falseNegative:
            currentProfile.performanceMetrics.falseNegatives += 1
        case .userRejected:
            // 處理用戶拒絕的情況
            break
        }

        // 更新平均置信度
        let totalConfidence = currentProfile.performanceMetrics.averageConfidence *
                              Double(currentProfile.performanceMetrics.totalGestures - 1) + data.confidence
        currentProfile.performanceMetrics.averageConfidence =
            totalConfidence / Double(currentProfile.performanceMetrics.totalGestures)

        currentProfile.lastUpdated = Date()
    }

    /// 生成學習洞察
    private func generateLearningInsights() {
        learningInsights.removeAll()

        let metrics = currentProfile.performanceMetrics

        if metrics.accuracy > 0.95 {
            learningInsights.append("🎉 手勢識別準確率優秀！系統已很好地適應您的使用模式")
        } else if metrics.accuracy > 0.85 {
            learningInsights.append("👍 手勢識別準確率良好，系統持續學習中")
        } else {
            learningInsights.append("🔧 系統正在努力學習您的手勢模式，請繼續使用以提高準確率")
        }

        // 分析改善趨勢
        if let recentSessions = currentProfile.learningHistory.suffix(5) as? [PersonalGestureProfile.LearningSession],
           recentSessions.count >= 3 {
            let improvements = recentSessions.map { $0.accuracyImprovement }
            let avgImprovement = improvements.reduce(0, +) / Double(improvements.count)

            if avgImprovement > 0.05 {
                learningInsights.append("📈 檢測到明顯改善趨勢，學習效果良好")
            }
        }
    }

    // MARK: - Utility Methods

    private func calculateAccuracy(from data: [GestureTrainingData]) -> Double {
        let correct = data.filter {
            $0.outcome == .truePositive || $0.outcome == .userConfirmed
        }.count

        guard !data.isEmpty else { return 0 }
        return Double(correct) / Double(data.count)
    }

    private func groupByContext(_ data: [GestureTrainingData]) -> [GestureContext: [GestureTrainingData]] {
        return Dictionary(grouping: data) { $0.context }
    }

    private func generateContextKey(_ context: GestureContext) -> String {
        return "\(context.instrumentType)_\(context.lightingCondition)_\(Int(context.userDistance * 10))"
    }

    private func getDefaultThreshold(for parameter: String) -> Double {
        switch parameter {
        case "blinkThreshold": return 0.03
        case "headShakeAngle": return 30.0
        case "headShakeDuration": return 0.3
        case "eyebrowRaiseThreshold": return 0.15
        case "smileThreshold": return 0.2
        case "gazeShiftThreshold": return 0.1
        default: return 0.5
        }
    }

    private func calculateBaselineConfidence(_ features: GestureFeatures) -> Double {
        // 簡化的置信度計算
        let faceConfidence = features.faceConfidence
        let gestureStrength = (features.blinkVelocity + features.headMovementVelocity) / 2
        let environmentalFactor = Double(features.ambientLight) / 1.0

        return min((faceConfidence + gestureStrength + environmentalFactor) / 3, 1.0)
    }

    private func isRelevant(_ data: GestureTrainingData, for parameter: String) -> Bool {
        switch parameter {
        case "blinkThreshold", "blinkDuration":
            return data.gestureType == .blink
        case "headShakeAngle", "headShakeDuration":
            if case .headShake = data.gestureType {
                return true
            }
        case "eyebrowRaiseThreshold":
            if case .microGesture(type: .eyebrowRaise) = data.gestureType {
                return true
            }
        default:
            break
        }
        return false
    }

    private func calculateAdaptationValue(for parameter: String, data: [GestureTrainingData]) -> Double {
        // 簡化的適應值計算
        let successfulGestures = data.filter {
            $0.outcome == .truePositive || $0.outcome == .userConfirmed
        }

        guard !successfulGestures.isEmpty else { return getDefaultThreshold(for: parameter) }

        let values = successfulGestures.map { extractParameterValue(from: $0.features, parameter: parameter) }
        return values.reduce(0, +) / Double(values.count)
    }

    private func extractParameterValue(from features: GestureFeatures, parameter: String) -> Double {
        switch parameter {
        case "blinkThreshold": return features.eyeAspectRatio
        case "headShakeAngle": return abs(features.headYaw)
        case "headShakeDuration": return features.blinkDuration // 簡化處理
        default: return 0
        }
    }

    private func analyzeUsagePatterns(_ recommendations: inout [String]) {
        let sessions = currentProfile.learningHistory

        if let lastSession = sessions.last,
           lastSession.date.timeIntervalSinceNow > -TimeInterval(7 * 24 * 3600) {
            recommendations.append("建議定期使用以維持系統學習效果")
        }

        // 分析樂器類型偏好
        let instrumentFrequency = sessions.reduce(into: [:]) { result, session in
            result[session.instrumentType, default: 0] += 1
        }

        if let mostUsedInstrument = instrumentFrequency.max(by: { $0.value < $1.value })?.key {
            recommendations.append("檢測到您主要使用 \(mostUsedInstrument.displayName)，已為此樂器優化設定")
        }
    }

    private func startLearningSession() {
        let session = PersonalGestureProfile.LearningSession(
            date: Date(),
            duration: 0,
            gesturesProcessed: 0,
            accuracyImprovement: 0,
            instrumentType: InstrumentMode.current().instrumentType
        )

        currentProfile.learningHistory.append(session)
    }

    // MARK: - Persistence

    private static func loadOrCreateProfile() -> PersonalGestureProfile {
        if let savedProfileId = UserDefaults.standard.object(forKey: "CurrentGestureProfileId") as? String,
           let profilesData = UserDefaults.standard.data(forKey: "PersonalGestureProfiles"),
           let profiles = try? JSONDecoder().decode([UUID: PersonalGestureProfile].self, from: profilesData),
           let profileUUID = UUID(uuidString: savedProfileId),
           let profile = profiles[profileUUID] {
            return profile
        }

        // 創建新檔案
        return PersonalGestureProfile(
            userId: UUID(),
            createdDate: Date(),
            lastUpdated: Date()
        )
    }

    private func saveProfile() {
        var profiles: [UUID: PersonalGestureProfile] = [:]

        // 載入現有檔案
        if let profilesData = UserDefaults.standard.data(forKey: profilesKey),
           let existingProfiles = try? JSONDecoder().decode([UUID: PersonalGestureProfile].self, from: profilesData) {
            profiles = existingProfiles
        }

        // 更新當前檔案
        profiles[currentProfile.userId] = currentProfile

        // 儲存
        if let data = try? JSONEncoder().encode(profiles) {
            UserDefaults.standard.set(data, forKey: profilesKey)
            UserDefaults.standard.set(currentProfile.userId.uuidString, forKey: currentProfileKey)
        }
    }
}

// MARK: - Supporting Classes

/// 適應性閾值
private class AdaptiveThreshold {
    private var baseValue: Double
    private var contextualAdjustments: [String: Double] = [:]
    private let learningRate: Double

    init(initialValue: Double, learningRate: Double) {
        self.baseValue = initialValue
        self.learningRate = learningRate
    }

    func getCurrentValue(for context: GestureContext) -> Double {
        let contextKey = "\(context.instrumentType)_\(context.lightingCondition)"
        let adjustment = contextualAdjustments[contextKey] ?? 0
        return baseValue + adjustment
    }

    func adapt(value: Double, context: String) {
        let currentAdjustment = contextualAdjustments[context] ?? 0
        let error = value - (baseValue + currentAdjustment)
        contextualAdjustments[context] = currentAdjustment + learningRate * error
    }

    var description: String {
        return "Base: \(baseValue), Adjustments: \(contextualAdjustments.count)"
    }
}

/// 上下文模型
private class ContextualModel {
    private let context: GestureContext
    private var weights: [String: Double] = [:]

    init(context: GestureContext) {
        self.context = context
        initializeWeights()
    }

    private func initializeWeights() {
        weights = [
            "faceConfidence": 0.3,
            "gestureStrength": 0.4,
            "environmental": 0.3
        ]
    }

    func predict(_ features: GestureFeatures) -> Double {
        let faceScore = features.faceConfidence * weights["faceConfidence"]!
        let gestureScore = (features.blinkVelocity + features.headMovementVelocity) / 2 * weights["gestureStrength"]!
        let envScore = Double(features.ambientLight) * weights["environmental"]!

        return min(faceScore + gestureScore + envScore, 1.0)
    }

    func update(with data: [GestureTrainingData]) {
        // 簡化的權重更新
        let successRate = Double(data.filter { $0.outcome == .truePositive || $0.outcome == .userConfirmed }.count) / Double(data.count)

        // 根據成功率調整權重
        if successRate > 0.8 {
            // 增強成功因素的權重
            weights["faceConfidence"] = min(weights["faceConfidence"]! * 1.05, 0.5)
        } else {
            // 降低不可靠因素的權重
            weights["environmental"] = max(weights["environmental"]! * 0.95, 0.1)
        }
    }
}

/// 即時手勢分析器
private class RealtimeGestureAnalyzer {
    func analyze(_ data: GestureTrainingData) {
        // 即時分析邏輯
        // 可以用於提供即時反饋或預警
    }
}

/// 手勢模式識別器
private class GesturePatternRecognizer {
    func recognizePattern(in data: [GestureTrainingData]) -> [String] {
        // 識別手勢模式
        return []
    }
}

/// 學習資料導出結構
private struct LearningDataExport: Codable {
    let profile: PersonalGestureProfile
    let trainingData: [GestureTrainingData]
    let thresholds: [String: String]
}

// MARK: - Codable Conformance

extension PersonalGestureProfile: Codable {}
extension PersonalGestureProfile.GesturePreferences: Codable {}
extension PersonalGestureProfile.LearningSession: Codable {}
extension PersonalGestureProfile.PersonalPerformanceMetrics: Codable {}
extension GestureTrainingData: Codable {}
extension GestureContext: Codable {}
extension GestureFeatures: Codable {}
extension GestureTrainingData.GestureType: Codable {}
extension GestureTrainingData.GestureType.MicroGestureType: Codable {}
extension GestureTrainingData.GestureOutcome: Codable {}
extension GestureContext.LightingCondition: Codable {}
extension PersonalGestureProfile.GesturePreferences.SensitivityLevel: Codable {}
extension PersonalGestureProfile.GesturePreferences.AdaptationSpeed: Codable {}