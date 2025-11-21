//
//  AdaptiveFrameRateController.swift
//  GazeTurn
//
//  Created by Claude Code on 2025/11/21.
//

import Foundation
import UIKit
import AVFoundation

/// 幀率模式枚舉
enum FrameRateMode {
    case battery        // 節電模式：15-30fps
    case balanced       // 平衡模式：30-45fps
    case performance    // 性能模式：45-60fps

    var targetRange: ClosedRange<Int> {
        switch self {
        case .battery: return 15...30
        case .balanced: return 30...45
        case .performance: return 45...60
        }
    }

    var description: String {
        switch self {
        case .battery: return "節電模式"
        case .balanced: return "平衡模式"
        case .performance: return "性能模式"
        }
    }
}

/// 系統性能狀態
struct SystemPerformanceState {
    let batteryLevel: Float
    let thermalState: ProcessInfo.ThermalState
    let memoryPressure: MemoryPressure
    let processingLoad: Double
    let isLowPowerModeEnabled: Bool

    enum MemoryPressure {
        case normal
        case warning
        case urgent
    }
}

/// 自適應幀率控制器 - GazeTurn v2 性能引擎核心組件
class AdaptiveFrameRateController: NSObject {

    // MARK: - Properties

    /// 當前幀率模式
    @Published var currentMode: FrameRateMode = .balanced

    /// 目標幀率
    @Published var targetFrameRate: Int = 30

    /// 實際幀率（測量值）
    @Published var actualFrameRate: Int = 0

    /// 是否啟用自適應模式
    @Published var isAdaptiveEnabled: Bool = true

    /// 性能指標
    @Published var performanceMetrics: PerformanceMetrics = PerformanceMetrics()

    // MARK: - Private Properties

    /// 幀時間戳記錄（用於計算實際幀率）
    private var frameTimestamps: [CFTimeInterval] = []
    private let frameTimestampLimit = 60 // 保留最近 60 幀

    /// 性能監控計時器
    private var performanceTimer: Timer?

    /// 幀跳過計數器
    private var frameSkipCounter = 0
    private var targetFrameSkipRatio = 0 // 每 N 幀跳過 1 幀

    /// 系統狀態監控
    private var lastSystemCheck = Date()
    private let systemCheckInterval: TimeInterval = 2.0 // 每 2 秒檢查一次系統狀態

    /// 性能歷史記錄（用於趨勢分析）
    private var performanceHistory: [PerformanceSnapshot] = []
    private let historyLimit = 30 // 保留 30 個快照（約 1 分鐘歷史）

    // MARK: - Initialization

    override init() {
        super.init()
        setupPerformanceMonitoring()
        adaptToCurrentConditions()
    }

    deinit {
        stopPerformanceMonitoring()
    }

    // MARK: - Public Methods

    /// 記錄新的幀處理
    func recordFrame() {
        let timestamp = CACurrentMediaTime()

        // 記錄幀時間戳
        frameTimestamps.append(timestamp)
        if frameTimestamps.count > frameTimestampLimit {
            frameTimestamps.removeFirst()
        }

        // 更新實際幀率
        updateActualFrameRate()

        // 更新性能指標
        performanceMetrics.totalFrames += 1

        // 檢查是否需要重新評估幀率
        if shouldReevaluateFrameRate() {
            adaptToCurrentConditions()
        }
    }

    /// 判斷是否應該跳過當前幀
    func shouldSkipFrame() -> Bool {
        guard isAdaptiveEnabled else { return false }

        // 基於目標跳幀率決定
        if targetFrameSkipRatio > 0 {
            frameSkipCounter += 1
            let shouldSkip = frameSkipCounter % (targetFrameSkipRatio + 1) != 0

            if shouldSkip {
                performanceMetrics.skippedFrames += 1
            }

            return shouldSkip
        }

        return false
    }

    /// 手動設置幀率模式
    func setFrameRateMode(_ mode: FrameRateMode) {
        currentMode = mode
        adaptToFrameRateMode()

        // 記錄模式變更
        performanceMetrics.modeChanges += 1
        logPerformanceEvent("Frame rate mode changed to \(mode.description)")
    }

    /// 獲取當前系統性能狀態
    func getCurrentSystemState() -> SystemPerformanceState {
        return SystemPerformanceState(
            batteryLevel: getBatteryLevel(),
            thermalState: ProcessInfo.processInfo.thermalState,
            memoryPressure: getMemoryPressure(),
            processingLoad: getCurrentProcessingLoad(),
            isLowPowerModeEnabled: ProcessInfo.processInfo.isLowPowerModeEnabled
        )
    }

    /// 獲取性能建議
    func getPerformanceRecommendations() -> [String] {
        var recommendations: [String] = []
        let state = getCurrentSystemState()

        if state.batteryLevel < 0.2 {
            recommendations.append("建議切換到節電模式以延長使用時間")
        }

        if state.thermalState == .critical {
            recommendations.append("設備過熱，建議降低幀率或暫停使用")
        }

        if state.memoryPressure == .urgent {
            recommendations.append("記憶體不足，建議關閉其他應用程式")
        }

        if performanceMetrics.averageFrameTime > 50 { // 超過 50ms
            recommendations.append("處理延遲較高，建議降低視覺效果或幀率")
        }

        return recommendations
    }

    // MARK: - Private Methods

    /// 設置性能監控
    private func setupPerformanceMonitoring() {
        performanceTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updatePerformanceMetrics()
        }
    }

    /// 停止性能監控
    private func stopPerformanceMonitoring() {
        performanceTimer?.invalidate()
        performanceTimer = nil
    }

    /// 根據當前條件自適應調整
    private func adaptToCurrentConditions() {
        guard isAdaptiveEnabled else { return }

        let systemState = getCurrentSystemState()
        let recommendedMode = determineOptimalMode(for: systemState)

        if recommendedMode != currentMode {
            currentMode = recommendedMode
            logPerformanceEvent("Auto-switched to \(recommendedMode.description) based on system conditions")
        }

        adaptToFrameRateMode()
        updateFrameSkipRatio(for: systemState)
    }

    /// 根據幀率模式調整目標幀率
    private func adaptToFrameRateMode() {
        let range = currentMode.targetRange
        let systemState = getCurrentSystemState()

        // 在模式範圍內根據系統狀態細調
        if systemState.isLowPowerModeEnabled || systemState.batteryLevel < 0.1 {
            targetFrameRate = range.lowerBound
        } else if systemState.thermalState == .nominal && systemState.memoryPressure == .normal {
            targetFrameRate = range.upperBound
        } else {
            targetFrameRate = (range.lowerBound + range.upperBound) / 2
        }

        logPerformanceEvent("Target frame rate adjusted to \(targetFrameRate)fps")
    }

    /// 更新幀跳過率
    private func updateFrameSkipRatio(for systemState: SystemPerformanceState) {
        // 計算目標幀間隔（毫秒）
        let targetFrameInterval = 1000.0 / Double(targetFrameRate)

        // 如果當前處理時間超過目標間隔，增加跳幀
        if performanceMetrics.averageFrameTime > targetFrameInterval * 1.2 {
            targetFrameSkipRatio = min(targetFrameSkipRatio + 1, 4) // 最多每 5 幀跳 4 幀
        } else if performanceMetrics.averageFrameTime < targetFrameInterval * 0.8 {
            targetFrameSkipRatio = max(targetFrameSkipRatio - 1, 0)
        }
    }

    /// 決定最佳幀率模式
    private func determineOptimalMode(for state: SystemPerformanceState) -> FrameRateMode {
        // 緊急情況：強制節電模式
        if state.isLowPowerModeEnabled || state.batteryLevel < 0.15 || state.thermalState == .critical {
            return .battery
        }

        // 警告情況：平衡模式
        if state.batteryLevel < 0.3 || state.thermalState != .nominal || state.memoryPressure != .normal {
            return .balanced
        }

        // 良好條件：性能模式
        if state.batteryLevel > 0.5 && state.thermalState == .nominal && state.memoryPressure == .normal {
            return .performance
        }

        // 預設：平衡模式
        return .balanced
    }

    /// 更新實際幀率計算
    private func updateActualFrameRate() {
        guard frameTimestamps.count >= 10 else { return } // 至少需要 10 幀來計算

        let recentTimestamps = Array(frameTimestamps.suffix(30)) // 使用最近 30 幀
        let timeSpan = recentTimestamps.last! - recentTimestamps.first!

        if timeSpan > 0 {
            actualFrameRate = Int((Double(recentTimestamps.count - 1) / timeSpan).rounded())
        }
    }

    /// 檢查是否需要重新評估幀率
    private func shouldReevaluateFrameRate() -> Bool {
        let now = Date()
        if now.timeIntervalSince(lastSystemCheck) > systemCheckInterval {
            lastSystemCheck = now
            return true
        }
        return false
    }

    /// 更新性能指標
    private func updatePerformanceMetrics() {
        // 計算平均幀時間
        if frameTimestamps.count >= 2 {
            let recentFrames = Array(frameTimestamps.suffix(10))
            var totalFrameTime: Double = 0

            for i in 1..<recentFrames.count {
                totalFrameTime += (recentFrames[i] - recentFrames[i-1]) * 1000 // 轉換為毫秒
            }

            if recentFrames.count > 1 {
                performanceMetrics.averageFrameTime = totalFrameTime / Double(recentFrames.count - 1)
            }
        }

        // 記錄性能快照
        let snapshot = PerformanceSnapshot(
            timestamp: Date(),
            frameRate: actualFrameRate,
            frameTime: performanceMetrics.averageFrameTime,
            mode: currentMode,
            systemState: getCurrentSystemState()
        )

        performanceHistory.append(snapshot)
        if performanceHistory.count > historyLimit {
            performanceHistory.removeFirst()
        }

        // 更新性能趨勢
        performanceMetrics.updateTrends(from: performanceHistory)
    }

    // MARK: - System Monitoring Helpers

    /// 獲取電池電量
    private func getBatteryLevel() -> Float {
        UIDevice.current.isBatteryMonitoringEnabled = true
        return UIDevice.current.batteryLevel
    }

    /// 獲取記憶體壓力狀態
    private func getMemoryPressure() -> SystemPerformanceState.MemoryPressure {
        // 簡化的記憶體壓力檢測
        let availableMemory = getAvailableMemory()
        let totalMemory = ProcessInfo.processInfo.physicalMemory
        let memoryUsageRatio = 1.0 - Double(availableMemory) / Double(totalMemory)

        if memoryUsageRatio > 0.9 {
            return .urgent
        } else if memoryUsageRatio > 0.7 {
            return .warning
        } else {
            return .normal
        }
    }

    /// 獲取可用記憶體
    private func getAvailableMemory() -> UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4

        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }

        if kerr == KERN_SUCCESS {
            return info.resident_size
        } else {
            return 0
        }
    }

    /// 獲取當前處理負載（簡化版）
    private func getCurrentProcessingLoad() -> Double {
        return performanceMetrics.averageFrameTime / 16.67 // 相對於 60fps 的基準
    }

    /// 記錄性能事件
    private func logPerformanceEvent(_ message: String) {
        print("[AdaptiveFrameRateController] \(message)")
        performanceMetrics.events.append("\(Date()): \(message)")

        // 保持事件日誌大小
        if performanceMetrics.events.count > 100 {
            performanceMetrics.events.removeFirst()
        }
    }
}

// MARK: - Supporting Data Structures

/// 性能指標結構
struct PerformanceMetrics {
    var totalFrames: Int = 0
    var skippedFrames: Int = 0
    var averageFrameTime: Double = 0 // 毫秒
    var modeChanges: Int = 0
    var events: [String] = []

    // 性能趨勢
    var frameRateTrend: TrendDirection = .stable
    var frameTimeTrend: TrendDirection = .stable

    enum TrendDirection {
        case improving
        case stable
        case degrading
    }

    mutating func updateTrends(from history: [PerformanceSnapshot]) {
        guard history.count >= 10 else { return }

        let recent = Array(history.suffix(5))
        let earlier = Array(history.prefix(5))

        // 分析幀率趨勢
        let recentAvgFrameRate = recent.map { $0.frameRate }.reduce(0, +) / recent.count
        let earlierAvgFrameRate = earlier.map { $0.frameRate }.reduce(0, +) / earlier.count

        if recentAvgFrameRate > earlierAvgFrameRate + 2 {
            frameRateTrend = .improving
        } else if recentAvgFrameRate < earlierAvgFrameRate - 2 {
            frameRateTrend = .degrading
        } else {
            frameRateTrend = .stable
        }

        // 分析幀時間趨勢
        let recentAvgFrameTime = recent.map { $0.frameTime }.reduce(0, +) / Double(recent.count)
        let earlierAvgFrameTime = earlier.map { $0.frameTime }.reduce(0, +) / Double(earlier.count)

        if recentAvgFrameTime < earlierAvgFrameTime - 2 {
            frameTimeTrend = .improving
        } else if recentAvgFrameTime > earlierAvgFrameTime + 2 {
            frameTimeTrend = .degrading
        } else {
            frameTimeTrend = .stable
        }
    }

    var skipRatio: Double {
        guard totalFrames > 0 else { return 0 }
        return Double(skippedFrames) / Double(totalFrames)
    }
}

/// 性能快照
struct PerformanceSnapshot {
    let timestamp: Date
    let frameRate: Int
    let frameTime: Double
    let mode: FrameRateMode
    let systemState: SystemPerformanceState
}