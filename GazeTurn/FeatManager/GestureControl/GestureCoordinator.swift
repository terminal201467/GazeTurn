//
//  GestureCoordinator.swift
//  GazeTurn
//
//  Created by Claude Code on 2025/3/20.
//

import Foundation

/// 手勢協調器代理協議
protocol GestureCoordinatorDelegate: AnyObject {
    /// 當檢測到翻頁手勢時調用
    /// - Parameter direction: 翻頁方向（下一頁或上一頁）
    func didDetectPageTurn(direction: PageDirection)

    /// 當等待確認時調用（混合模式）
    /// - Parameter direction: 等待確認的翻頁方向
    func waitingForConfirmation(direction: PageDirection)

    /// 當確認超時時調用（混合模式）
    func confirmationTimeout()
}

/// 手勢協調器，統一管理眨眼和搖頭手勢
class GestureCoordinator {

    // MARK: - Properties

    /// 當前樂器模式
    var currentMode: InstrumentMode {
        didSet {
            configureDetectors()
            resetState()
        }
    }

    /// 代理
    weak var delegate: GestureCoordinatorDelegate?

    /// 眨眼識別器
    private let blinkRecognizer: BlinkRecognizer

    /// 頭部姿態檢測器
    private let headPoseDetector: HeadPoseDetector

    // MARK: - Hybrid Mode State

    /// 混合模式：等待確認的狀態
    private var waitingForConfirmation: Bool = false

    /// 混合模式：等待確認的方向
    private var pendingDirection: PageDirection?

    /// 混合模式：開始等待確認的時間
    private var confirmationStartTime: Date?

    // MARK: - Blink State (for long blink detection)

    /// 記錄眨眼開始時間（用於檢測長眨眼）
    private var blinkStartTime: Date?

    /// 是否正在眨眼
    private var isBlinking: Bool = false

    // MARK: - Initialization

    /// 初始化手勢協調器
    /// - Parameters:
    ///   - mode: 初始樂器模式
    ///   - blinkRecognizer: 眨眼識別器實例
    ///   - headPoseDetector: 頭部姿態檢測器實例
    init(
        mode: InstrumentMode = .current(),
        blinkRecognizer: BlinkRecognizer = BlinkRecognizer(),
        headPoseDetector: HeadPoseDetector = HeadPoseDetector()
    ) {
        self.currentMode = mode
        self.blinkRecognizer = blinkRecognizer
        self.headPoseDetector = headPoseDetector
        configureDetectors()
    }

    // MARK: - Configuration

    /// 根據當前模式配置檢測器
    private func configureDetectors() {
        // 配置頭部姿態檢測器
        headPoseDetector.updateThresholds(
            angleThreshold: currentMode.shakeAngleThreshold,
            durationThreshold: currentMode.shakeDuration,
            cooldownDuration: currentMode.shakeCooldown
        )
    }

    /// 重置狀態
    private func resetState() {
        waitingForConfirmation = false
        pendingDirection = nil
        confirmationStartTime = nil
        blinkStartTime = nil
        isBlinking = false
        headPoseDetector.reset()
    }

    // MARK: - Gesture Processing

    /// 處理眨眼結果
    /// - Parameters:
    ///   - leftOpen: 左眼是否張開
    ///   - rightOpen: 右眼是否張開
    func processEyeState(leftOpen: Bool, rightOpen: Bool) {
        // 如果當前模式不啟用眨眼，直接返回
        guard currentMode.enableBlink else { return }

        let bothClosed = !leftOpen && !rightOpen
        let bothOpen = leftOpen && rightOpen

        // 處理長眨眼檢測（僅限弦樂器模式）
        if currentMode.instrumentType == .stringInstruments {
            handleLongBlink(bothClosed: bothClosed, bothOpen: bothOpen)
        }

        // 處理標準眨眼檢測
        let blinkDetected = blinkRecognizer.detectBlink(leftOpen: leftOpen, rightOpen: rightOpen)

        if blinkDetected {
            handleBlinkDetected()
        }
    }

    /// 處理搖頭檢測結果
    /// - Parameter direction: 搖頭方向
    func processHeadShake(_ direction: HeadShakeDirection) {
        // 如果當前模式不啟用搖頭，直接返回
        guard currentMode.enableHeadShake else {
            print("GestureCoordinator: 搖頭未啟用")
            return
        }

        // 如果沒有檢測到搖頭，返回
        guard direction != .none else { return }

        print("GestureCoordinator: 收到搖頭 - \(direction.displayName)")

        // 將搖頭方向轉換為翻頁方向
        guard let pageDir = direction.pageDirection else {
            print("GestureCoordinator: 無法轉換為翻頁方向")
            return
        }

        // 處理搖頭手勢
        handleHeadShake(direction: pageDir)
    }

    // MARK: - Private Handlers

    /// 處理眨眼檢測
    private func handleBlinkDetected() {
        if waitingForConfirmation {
            // 混合模式：眨眼作為確認
            confirmPendingDirection()
        } else if !currentMode.requireConfirmation {
            // 純眨眼模式：直接觸發翻頁（下一頁）
            triggerPageTurn(direction: .next)
        }
    }

    /// 處理搖頭手勢
    /// - Parameter direction: 翻頁方向
    private func handleHeadShake(direction: PageDirection) {
        print("GestureCoordinator: 處理搖頭手勢 - \(direction == .next ? "下一頁" : "上一頁")")
        print("GestureCoordinator: requireConfirmation = \(currentMode.requireConfirmation)")

        if currentMode.requireConfirmation {
            // 混合模式：等待眨眼確認
            startWaitingForConfirmation(direction: direction)
        } else {
            // 純搖頭模式：直接觸發翻頁
            print("GestureCoordinator: 觸發翻頁...")
            triggerPageTurn(direction: direction)
        }
    }

    /// 處理長眨眼（用於上一頁）
    /// - Parameters:
    ///   - bothClosed: 雙眼是否都閉合
    ///   - bothOpen: 雙眼是否都張開
    private func handleLongBlink(bothClosed: Bool, bothOpen: Bool) {
        let now = Date()

        if bothClosed && !isBlinking {
            // 開始眨眼
            isBlinking = true
            blinkStartTime = now
        } else if bothOpen && isBlinking {
            // 結束眨眼
            isBlinking = false

            if let startTime = blinkStartTime {
                let duration = now.timeIntervalSince(startTime)
                if duration >= currentMode.longBlinkDuration {
                    // 長眨眼：觸發上一頁
                    triggerPageTurn(direction: .previous)
                }
            }

            blinkStartTime = nil
        }
    }

    /// 開始等待確認（混合模式）
    /// - Parameter direction: 等待確認的方向
    private func startWaitingForConfirmation(direction: PageDirection) {
        waitingForConfirmation = true
        pendingDirection = direction
        confirmationStartTime = Date()

        // 通知代理
        delegate?.waitingForConfirmation(direction: direction)

        // 設置超時檢查
        DispatchQueue.main.asyncAfter(deadline: .now() + currentMode.confirmationTimeout) { [weak self] in
            self?.checkConfirmationTimeout()
        }
    }

    /// 確認待處理的翻頁動作
    private func confirmPendingDirection() {
        guard let direction = pendingDirection else { return }

        waitingForConfirmation = false
        confirmationStartTime = nil

        // 觸發翻頁
        triggerPageTurn(direction: direction)

        pendingDirection = nil
    }

    /// 檢查確認是否超時
    private func checkConfirmationTimeout() {
        guard waitingForConfirmation,
              let startTime = confirmationStartTime else {
            return
        }

        let elapsed = Date().timeIntervalSince(startTime)
        if elapsed >= currentMode.confirmationTimeout {
            // 超時，取消等待
            waitingForConfirmation = false
            pendingDirection = nil
            confirmationStartTime = nil

            delegate?.confirmationTimeout()
        }
    }

    /// 觸發翻頁動作
    /// - Parameter direction: 翻頁方向
    private func triggerPageTurn(direction: PageDirection) {
        print("GestureCoordinator: triggerPageTurn - delegate存在: \(delegate != nil)")
        delegate?.didDetectPageTurn(direction: direction)
        print("GestureCoordinator: 已呼叫 delegate.didDetectPageTurn")
    }

    // MARK: - Public Methods

    /// 更新樂器模式
    /// - Parameter mode: 新的樂器模式
    func updateMode(_ mode: InstrumentMode) {
        self.currentMode = mode
        mode.save()  // 持久化保存
    }

    /// 切換到指定樂器類型的預設模式
    /// - Parameter instrumentType: 樂器類型
    func switchToInstrument(_ instrumentType: InstrumentType) {
        let newMode = InstrumentMode.defaultMode(for: instrumentType)
        updateMode(newMode)
    }

    /// 獲取當前狀態描述（用於除錯）
    func getCurrentStateDescription() -> String {
        var description = "GestureCoordinator State:\n"
        description += "- Instrument: \(currentMode.instrumentType.displayName)\n"
        description += "- Blink Enabled: \(currentMode.enableBlink)\n"
        description += "- Head Shake Enabled: \(currentMode.enableHeadShake)\n"
        description += "- Requires Confirmation: \(currentMode.requireConfirmation)\n"

        if waitingForConfirmation {
            description += "- Status: Waiting for confirmation\n"
            if let direction = pendingDirection {
                description += "- Pending Direction: \(direction == .next ? "Next" : "Previous")\n"
            }
        } else {
            description += "- Status: Ready\n"
        }

        return description
    }
}

// MARK: - Convenience Methods

extension GestureCoordinator {
    /// 是否為混合模式
    var isHybridMode: Bool {
        return currentMode.enableBlink && currentMode.enableHeadShake && currentMode.requireConfirmation
    }

    /// 是否為純眨眼模式
    var isBlinkOnlyMode: Bool {
        return currentMode.enableBlink && !currentMode.enableHeadShake
    }

    /// 是否為純搖頭模式
    var isHeadShakeOnlyMode: Bool {
        return !currentMode.enableBlink && currentMode.enableHeadShake
    }
}
