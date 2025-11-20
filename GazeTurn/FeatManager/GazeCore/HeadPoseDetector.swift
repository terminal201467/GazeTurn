//
//  HeadPoseDetector.swift
//  GazeTurn
//
//  Created by Claude Code on 2025/3/20.
//

import Foundation
import Vision

/// 搖頭方向枚舉
enum HeadShakeDirection {
    case left       // 向左搖頭（上一頁）
    case right      // 向右搖頭（下一頁）
    case none       // 無搖頭動作
}

/// 頭部姿態檢測器，負責識別頭部搖動手勢
class HeadPoseDetector {

    // MARK: - Properties

    /// 搖頭角度閾值（弧度）
    private var angleThreshold: Double

    /// 搖頭持續時間閾值（秒）
    private var durationThreshold: TimeInterval

    /// 搖頭冷卻時間（秒）- 防止重複觸發
    private var cooldownDuration: TimeInterval

    /// 記錄上次檢測到搖頭的時間
    private var lastShakeTime: Date?

    /// 記錄開始超過閾值的時間
    private var thresholdExceededStartTime: Date?

    /// 記錄當前的搖頭方向（用於持續時間檢測）
    private var currentShakeDirection: HeadShakeDirection = .none

    /// 上一次的 yaw 角度（用於趨勢判斷）
    private var previousYaw: Double?

    // MARK: - Initialization

    /// 初始化頭部姿態檢測器
    /// - Parameters:
    ///   - angleThreshold: 搖頭角度閾值（度），預設 30 度
    ///   - durationThreshold: 搖頭持續時間閾值（秒），預設 0.3 秒
    ///   - cooldownDuration: 搖頭冷卻時間（秒），預設 0.5 秒
    init(
        angleThreshold: Double = 30.0,
        durationThreshold: TimeInterval = 0.3,
        cooldownDuration: TimeInterval = 0.5
    ) {
        // 將角度轉換為弧度
        self.angleThreshold = angleThreshold * .pi / 180.0
        self.durationThreshold = durationThreshold
        self.cooldownDuration = cooldownDuration
    }

    // MARK: - Configuration

    /// 更新搖頭檢測參數
    /// - Parameters:
    ///   - angleThreshold: 搖頭角度閾值（度）
    ///   - durationThreshold: 搖頭持續時間閾值（秒）
    ///   - cooldownDuration: 搖頭冷卻時間（秒）
    func updateThresholds(
        angleThreshold: Double? = nil,
        durationThreshold: TimeInterval? = nil,
        cooldownDuration: TimeInterval? = nil
    ) {
        if let angle = angleThreshold {
            self.angleThreshold = angle * .pi / 180.0
        }
        if let duration = durationThreshold {
            self.durationThreshold = duration
        }
        if let cooldown = cooldownDuration {
            self.cooldownDuration = cooldown
        }
    }

    // MARK: - Detection

    /// 從臉部觀察結果中檢測搖頭手勢
    /// - Parameter face: Vision 框架偵測到的臉部觀察結果
    /// - Returns: 搖頭方向（left, right, none）
    func detectShake(from face: VNFaceObservation) -> HeadShakeDirection {
        // 檢查是否在冷卻期間
        if let lastTime = lastShakeTime {
            let timeSinceLastShake = Date().timeIntervalSince(lastTime)
            if timeSinceLastShake < cooldownDuration {
                return .none
            }
        }

        // 取得 yaw 角度（左右旋轉）
        guard let yaw = face.yaw?.doubleValue else {
            resetShakeState()
            return .none
        }

        // 判斷當前搖頭方向
        let direction = determineDirection(yaw: yaw)

        // 檢測持續時間
        return checkDuration(for: direction, currentYaw: yaw)
    }

    /// 重置檢測器狀態
    func reset() {
        lastShakeTime = nil
        thresholdExceededStartTime = nil
        currentShakeDirection = .none
        previousYaw = nil
    }

    // MARK: - Private Methods

    /// 根據 yaw 角度判斷搖頭方向
    /// - Parameter yaw: 頭部 yaw 角度（弧度）
    /// - Returns: 搖頭方向
    private func determineDirection(yaw: Double) -> HeadShakeDirection {
        if yaw < -angleThreshold {
            return .left
        } else if yaw > angleThreshold {
            return .right
        } else {
            return .none
        }
    }

    /// 檢查搖頭持續時間是否達到閾值
    /// - Parameters:
    ///   - direction: 當前搖頭方向
    ///   - currentYaw: 當前 yaw 角度
    /// - Returns: 搖頭方向（若持續時間足夠）
    private func checkDuration(for direction: HeadShakeDirection, currentYaw: Double) -> HeadShakeDirection {
        let now = Date()

        // 如果方向改變或回到中立位置，重置計時
        if direction != currentShakeDirection {
            currentShakeDirection = direction
            thresholdExceededStartTime = (direction != .none) ? now : nil
            previousYaw = currentYaw
            return .none
        }

        // 如果沒有搖頭動作，不處理
        if direction == .none {
            resetShakeState()
            return .none
        }

        // 檢查是否已經開始計時
        guard let startTime = thresholdExceededStartTime else {
            thresholdExceededStartTime = now
            previousYaw = currentYaw
            return .none
        }

        // 檢查持續時間是否達到閾值
        let duration = now.timeIntervalSince(startTime)
        if duration >= durationThreshold {
            // 觸發搖頭手勢
            lastShakeTime = now
            resetShakeState()
            return direction
        }

        previousYaw = currentYaw
        return .none
    }

    /// 重置搖頭狀態（不重置冷卻時間）
    private func resetShakeState() {
        thresholdExceededStartTime = nil
        currentShakeDirection = .none
        previousYaw = nil
    }

    // MARK: - Debugging

    /// 獲取當前頭部姿態資訊（用於除錯）
    /// - Parameter face: Vision 框架偵測到的臉部觀察結果
    /// - Returns: 包含 yaw, pitch, roll 的字典
    func getHeadPoseInfo(from face: VNFaceObservation) -> [String: Double] {
        return [
            "yaw": face.yaw?.doubleValue ?? 0.0,
            "pitch": face.pitch?.doubleValue ?? 0.0,
            "roll": face.roll?.doubleValue ?? 0.0,
            "yawDegrees": (face.yaw?.doubleValue ?? 0.0) * 180.0 / .pi,
            "pitchDegrees": (face.pitch?.doubleValue ?? 0.0) * 180.0 / .pi,
            "rollDegrees": (face.roll?.doubleValue ?? 0.0) * 180.0 / .pi
        ]
    }

    /// 獲取當前配置資訊
    func getCurrentConfiguration() -> String {
        let angleDegrees = angleThreshold * 180.0 / .pi
        return """
        HeadPoseDetector Configuration:
        - Angle Threshold: \(String(format: "%.1f", angleDegrees))°
        - Duration Threshold: \(String(format: "%.2f", durationThreshold))s
        - Cooldown Duration: \(String(format: "%.2f", cooldownDuration))s
        """
    }
}

// MARK: - Extension for Direction Description

extension HeadShakeDirection {
    /// 方向的顯示名稱
    var displayName: String {
        switch self {
        case .left:
            return "向左搖頭"
        case .right:
            return "向右搖頭"
        case .none:
            return "無動作"
        }
    }

    /// 方向的英文名稱
    var displayNameEN: String {
        switch self {
        case .left:
            return "Shake Left"
        case .right:
            return "Shake Right"
        case .none:
            return "None"
        }
    }

    /// 對應的翻頁方向
    var pageDirection: PageDirection? {
        switch self {
        case .left:
            return .previous
        case .right:
            return .next
        case .none:
            return nil
        }
    }
}

/// 翻頁方向枚舉
enum PageDirection {
    case next       // 下一頁
    case previous   // 上一頁
}
