//
//  GazeDirectionDetector.swift
//  GazeTurn
//
//  Created by Claude Code on 2025/3/20.
//

import Foundation
import Vision

/// 視線方向枚舉
enum GazeDirection: Hashable, Codable {
    case left       // 向左看（上一頁）
    case right      // 向右看（下一頁）
    case center     // 看向中間（無動作）
}

/// 視線方向檢測器，負責識別用戶視線方向
class GazeDirectionDetector {

    // MARK: - Properties

    /// 視線偏移閾值（0.0 ~ 1.0，相對於眼睛寬度的比例）
    private var gazeThreshold: Double

    /// 視線持續時間閾值（秒）- 需要持續看向某方向多久才觸發
    private var durationThreshold: TimeInterval

    /// 視線冷卻時間（秒）- 防止重複觸發
    private var cooldownDuration: TimeInterval

    /// 記錄上次觸發視線動作的時間
    private var lastGazeActionTime: Date?

    /// 記錄開始看向某方向的時間
    private var gazeStartTime: Date?

    /// 記錄當前的視線方向
    private var currentGazeDirection: GazeDirection = .center

    /// 平滑化的視線位置（用於減少抖動）
    private var smoothedGazePosition: Double = 0.5

    /// 平滑化係數（0.0 ~ 1.0，越大越平滑但延遲越高）
    private let smoothingFactor: Double = 0.3

    // MARK: - Initialization

    /// 初始化視線方向檢測器
    /// - Parameters:
    ///   - gazeThreshold: 視線偏移閾值（0.0 ~ 1.0），預設 0.15（15% 偏移）
    ///   - durationThreshold: 視線持續時間閾值（秒），預設 0.8 秒
    ///   - cooldownDuration: 視線冷卻時間（秒），預設 1.0 秒
    init(
        gazeThreshold: Double = 0.15,
        durationThreshold: TimeInterval = 0.8,
        cooldownDuration: TimeInterval = 1.0
    ) {
        self.gazeThreshold = gazeThreshold
        self.durationThreshold = durationThreshold
        self.cooldownDuration = cooldownDuration
    }

    // MARK: - Configuration

    /// 更新視線檢測參數
    /// - Parameters:
    ///   - gazeThreshold: 視線偏移閾值
    ///   - durationThreshold: 視線持續時間閾值
    ///   - cooldownDuration: 視線冷卻時間
    func updateThresholds(
        gazeThreshold: Double? = nil,
        durationThreshold: TimeInterval? = nil,
        cooldownDuration: TimeInterval? = nil
    ) {
        if let threshold = gazeThreshold {
            self.gazeThreshold = threshold
        }
        if let duration = durationThreshold {
            self.durationThreshold = duration
        }
        if let cooldown = cooldownDuration {
            self.cooldownDuration = cooldown
        }
    }

    // MARK: - Detection

    /// 從臉部觀察結果中檢測視線方向
    /// - Parameter face: Vision 框架偵測到的臉部觀察結果
    /// - Returns: 視線方向（left, right, center）和當前視線位置（用於視覺化）
    func detectGaze(from face: VNFaceObservation) -> (direction: GazeDirection, gazePosition: Double) {
        // 計算視線位置
        let gazePosition = calculateGazePosition(from: face)

        // 更新平滑化位置
        smoothedGazePosition = smoothedGazePosition * smoothingFactor + gazePosition * (1.0 - smoothingFactor)

        // 檢查是否在冷卻期間
        if let lastTime = lastGazeActionTime {
            let timeSinceLastAction = Date().timeIntervalSince(lastTime)
            if timeSinceLastAction < cooldownDuration {
                return (.center, smoothedGazePosition)
            }
        }

        // 判斷當前視線方向
        let direction = determineDirection(gazePosition: smoothedGazePosition)

        // 檢測持續時間
        let finalDirection = checkDuration(for: direction)

        return (finalDirection, smoothedGazePosition)
    }

    /// 重置檢測器狀態
    func reset() {
        lastGazeActionTime = nil
        gazeStartTime = nil
        currentGazeDirection = .center
        smoothedGazePosition = 0.5
    }

    // MARK: - Private Methods

    /// 計算視線位置（0.0 = 最左, 0.5 = 中間, 1.0 = 最右）
    /// - Parameter face: 臉部觀察結果
    /// - Returns: 視線位置（0.0 ~ 1.0）
    private func calculateGazePosition(from face: VNFaceObservation) -> Double {
        guard let landmarks = face.landmarks else { return 0.5 }

        // 嘗試使用瞳孔位置
        if let leftPupil = landmarks.leftPupil,
           let rightPupil = landmarks.rightPupil,
           let leftEye = landmarks.leftEye,
           let rightEye = landmarks.rightEye {
            return calculateGazeFromPupils(
                leftPupil: leftPupil,
                rightPupil: rightPupil,
                leftEye: leftEye,
                rightEye: rightEye
            )
        }

        // 如果沒有瞳孔數據，嘗試使用眼睛輪廓估計
        if let leftEye = landmarks.leftEye,
           let rightEye = landmarks.rightEye {
            return estimateGazeFromEyeContour(leftEye: leftEye, rightEye: rightEye)
        }

        return 0.5
    }

    /// 從瞳孔位置計算視線方向
    private func calculateGazeFromPupils(
        leftPupil: VNFaceLandmarkRegion2D,
        rightPupil: VNFaceLandmarkRegion2D,
        leftEye: VNFaceLandmarkRegion2D,
        rightEye: VNFaceLandmarkRegion2D
    ) -> Double {
        // 獲取瞳孔中心點
        let leftPupilCenter = getCenter(of: leftPupil)
        let rightPupilCenter = getCenter(of: rightPupil)

        // 獲取眼睛邊界
        let leftEyeBounds = getBounds(of: leftEye)
        let rightEyeBounds = getBounds(of: rightEye)

        // 計算左眼瞳孔相對位置（0.0 = 最左, 1.0 = 最右）
        let leftGaze = (leftPupilCenter.x - leftEyeBounds.minX) / leftEyeBounds.width

        // 計算右眼瞳孔相對位置
        let rightGaze = (rightPupilCenter.x - rightEyeBounds.minX) / rightEyeBounds.width

        // 取平均值
        let averageGaze = (leftGaze + rightGaze) / 2.0

        // 限制在 0.0 ~ 1.0 範圍內
        return min(max(averageGaze, 0.0), 1.0)
    }

    /// 從眼睛輪廓估計視線方向（當瞳孔數據不可用時的備用方案）
    private func estimateGazeFromEyeContour(
        leftEye: VNFaceLandmarkRegion2D,
        rightEye: VNFaceLandmarkRegion2D
    ) -> Double {
        // 使用眼睛輪廓的幾何中心作為估計
        // 這是一個簡化的方法，精確度較低
        let leftPoints = leftEye.normalizedPoints
        let rightPoints = rightEye.normalizedPoints

        guard leftPoints.count >= 6, rightPoints.count >= 6 else { return 0.5 }

        // 計算眼睛內側和外側的點
        // 眼睛輪廓通常從內眼角開始
        let leftInner = leftPoints[0]
        let leftOuter = leftPoints[3]
        let rightInner = rightPoints[0]
        let rightOuter = rightPoints[3]

        // 計算眼睛的開合程度差異（作為視線方向的間接指標）
        let leftOpenness = abs(leftPoints[1].y - leftPoints[5].y)
        let rightOpenness = abs(rightPoints[1].y - rightPoints[5].y)

        // 如果兩眼開合程度差異明顯，可能表示在看某個方向
        let opennessDiff = leftOpenness - rightOpenness

        // 將差異轉換為 0.0 ~ 1.0 的範圍
        // 正值表示左眼開得更大（可能在看右邊）
        // 負值表示右眼開得更大（可能在看左邊）
        let normalizedGaze = 0.5 + (opennessDiff * 5.0) // 放大差異

        return min(max(normalizedGaze, 0.0), 1.0)
    }

    /// 獲取 landmark 區域的中心點
    private func getCenter(of landmark: VNFaceLandmarkRegion2D) -> CGPoint {
        let points = landmark.normalizedPoints
        guard !points.isEmpty else { return CGPoint(x: 0.5, y: 0.5) }

        let sumX = points.reduce(0.0) { $0 + $1.x }
        let sumY = points.reduce(0.0) { $0 + $1.y }

        return CGPoint(
            x: sumX / Double(points.count),
            y: sumY / Double(points.count)
        )
    }

    /// 獲取 landmark 區域的邊界
    private func getBounds(of landmark: VNFaceLandmarkRegion2D) -> CGRect {
        let points = landmark.normalizedPoints
        guard !points.isEmpty else { return CGRect(x: 0, y: 0, width: 1, height: 1) }

        let minX = points.map { $0.x }.min() ?? 0
        let maxX = points.map { $0.x }.max() ?? 1
        let minY = points.map { $0.y }.min() ?? 0
        let maxY = points.map { $0.y }.max() ?? 1

        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }

    /// 根據視線位置判斷方向
    private func determineDirection(gazePosition: Double) -> GazeDirection {
        // 0.5 是中間位置
        // 小於 (0.5 - threshold) 表示看向左邊
        // 大於 (0.5 + threshold) 表示看向右邊
        if gazePosition < (0.5 - gazeThreshold) {
            return .left
        } else if gazePosition > (0.5 + gazeThreshold) {
            return .right
        } else {
            return .center
        }
    }

    /// 檢查視線持續時間是否達到閾值
    private func checkDuration(for direction: GazeDirection) -> GazeDirection {
        let now = Date()

        // 如果方向改變或回到中心，重置計時
        if direction != currentGazeDirection {
            currentGazeDirection = direction
            gazeStartTime = (direction != .center) ? now : nil
            return .center
        }

        // 如果是中心位置，不處理
        if direction == .center {
            resetGazeState()
            return .center
        }

        // 檢查是否已經開始計時
        guard let startTime = gazeStartTime else {
            gazeStartTime = now
            return .center
        }

        // 檢查持續時間是否達到閾值
        let duration = now.timeIntervalSince(startTime)
        if duration >= durationThreshold {
            // 觸發視線動作
            lastGazeActionTime = now
            resetGazeState()
            return direction
        }

        return .center
    }

    /// 重置視線狀態（不重置冷卻時間）
    private func resetGazeState() {
        gazeStartTime = nil
        currentGazeDirection = .center
    }

    // MARK: - Public Properties

    /// 獲取當前視線位置（用於視覺化）
    var currentGazePosition: Double {
        return smoothedGazePosition
    }

    /// 獲取當前配置資訊
    func getCurrentConfiguration() -> String {
        return """
        GazeDirectionDetector Configuration:
        - Gaze Threshold: \(String(format: "%.2f", gazeThreshold))
        - Duration Threshold: \(String(format: "%.2f", durationThreshold))s
        - Cooldown Duration: \(String(format: "%.2f", cooldownDuration))s
        """
    }
}

// MARK: - Extension for Direction Description

extension GazeDirection {
    /// 方向的顯示名稱
    var displayName: String {
        switch self {
        case .left:
            return "向左看"
        case .right:
            return "向右看"
        case .center:
            return "看向中間"
        }
    }

    /// 方向的英文名稱
    var displayNameEN: String {
        switch self {
        case .left:
            return "Look Left"
        case .right:
            return "Look Right"
        case .center:
            return "Center"
        }
    }

    /// 對應的翻頁方向
    var pageDirection: PageDirection? {
        switch self {
        case .left:
            return .previous
        case .right:
            return .next
        case .center:
            return nil
        }
    }
}
