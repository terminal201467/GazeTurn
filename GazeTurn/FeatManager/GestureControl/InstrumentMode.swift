//
//  InstrumentMode.swift
//  GazeTurn
//
//  Created by Claude Code on 2025/3/20.
//

import Foundation

/// 樂器模式配置，定義特定樂器類型的手勢控制參數
struct InstrumentMode: Codable {
    /// 樂器類型
    let instrumentType: InstrumentType

    // MARK: - 眨眼控制參數

    /// 是否啟用眨眼控制
    let enableBlink: Bool

    /// 眨眼檢測閾值（眼睛開合的高度差）
    let blinkThreshold: Double

    /// 眨眼時間窗口（秒）- 用於檢測連續眨眼
    let blinkTimeWindow: TimeInterval

    /// 最小眨眼持續時間（秒）
    let minBlinkDuration: TimeInterval

    /// 需要的眨眼次數（1=單眨眼，2=雙眨眼）
    let requiredBlinkCount: Int

    /// 長眨眼持續時間（秒）- 用於反向翻頁
    let longBlinkDuration: TimeInterval

    // MARK: - 搖頭控制參數

    /// 是否啟用搖頭控制
    let enableHeadShake: Bool

    /// 搖頭角度閾值（度）
    let shakeAngleThreshold: Double

    /// 搖頭持續時間（秒）- 需要維持超過閾值的時間
    let shakeDuration: TimeInterval

    /// 搖頭冷卻時間（秒）- 防止重複觸發
    let shakeCooldown: TimeInterval

    // MARK: - 混合模式參數

    /// 是否需要確認（搖頭後需要眨眼確認）
    let requireConfirmation: Bool

    /// 確認超時時間（秒）- 搖頭後等待確認的最長時間
    let confirmationTimeout: TimeInterval

    // MARK: - 初始化方法

    init(
        instrumentType: InstrumentType,
        enableBlink: Bool,
        blinkThreshold: Double = 0.03,
        blinkTimeWindow: TimeInterval = 0.5,
        minBlinkDuration: TimeInterval = 0.1,
        requiredBlinkCount: Int = 2,
        longBlinkDuration: TimeInterval = 0.5,
        enableHeadShake: Bool,
        shakeAngleThreshold: Double = 30.0,
        shakeDuration: TimeInterval = 0.3,
        shakeCooldown: TimeInterval = 0.5,
        requireConfirmation: Bool = false,
        confirmationTimeout: TimeInterval = 2.0
    ) {
        self.instrumentType = instrumentType
        self.enableBlink = enableBlink
        self.blinkThreshold = blinkThreshold
        self.blinkTimeWindow = blinkTimeWindow
        self.minBlinkDuration = minBlinkDuration
        self.requiredBlinkCount = requiredBlinkCount
        self.longBlinkDuration = longBlinkDuration
        self.enableHeadShake = enableHeadShake
        self.shakeAngleThreshold = shakeAngleThreshold
        self.shakeDuration = shakeDuration
        self.shakeCooldown = shakeCooldown
        self.requireConfirmation = requireConfirmation
        self.confirmationTimeout = confirmationTimeout
    }

    // MARK: - 預設模式配置

    /// 根據樂器類型獲取預設模式
    static func defaultMode(for type: InstrumentType) -> InstrumentMode {
        switch type {
        case .stringInstruments:
            return stringInstrumentsMode()
        case .woodwindBrass:
            return woodwindBrassMode()
        case .keyboard:
            return keyboardMode()
        case .pluckedStrings:
            return pluckedStringsMode()
        case .percussion:
            return percussionMode()
        case .vocal:
            return vocalMode()
        case .custom:
            return customMode()
        }
    }

    /// 根據樂器類型獲取預設模式（別名方法）
    static func modeFor(instrumentType: InstrumentType) -> InstrumentMode {
        return defaultMode(for: instrumentType)
    }

    /// 弦樂器模式：僅眨眼控制
    static func stringInstrumentsMode() -> InstrumentMode {
        return InstrumentMode(
            instrumentType: .stringInstruments,
            enableBlink: true,
            blinkThreshold: 0.03,
            blinkTimeWindow: 0.5,
            minBlinkDuration: 0.1,
            requiredBlinkCount: 2,          // 雙眨眼=下一頁
            longBlinkDuration: 0.5,         // 長眨眼=上一頁
            enableHeadShake: false,
            requireConfirmation: false
        )
    }

    /// 木管/銅管樂器模式：混合控制（搖頭 + 眨眼確認）
    static func woodwindBrassMode() -> InstrumentMode {
        return InstrumentMode(
            instrumentType: .woodwindBrass,
            enableBlink: true,
            blinkThreshold: 0.03,
            blinkTimeWindow: 0.5,
            minBlinkDuration: 0.1,
            requiredBlinkCount: 1,          // 單眨眼確認即可
            longBlinkDuration: 0.5,
            enableHeadShake: true,
            shakeAngleThreshold: 18.0,      // 較小的角度（15-20度）
            shakeDuration: 0.3,
            shakeCooldown: 0.5,
            requireConfirmation: true,       // 需要眨眼確認
            confirmationTimeout: 2.0
        )
    }

    /// 鍵盤樂器模式：僅搖頭控制
    static func keyboardMode() -> InstrumentMode {
        return InstrumentMode(
            instrumentType: .keyboard,
            enableBlink: false,
            enableHeadShake: true,
            shakeAngleThreshold: 30.0,      // 標準角度
            shakeDuration: 0.3,
            shakeCooldown: 0.5,
            requireConfirmation: false
        )
    }

    /// 撥弦樂器模式：搖頭控制（較高閾值避免誤觸發）
    static func pluckedStringsMode() -> InstrumentMode {
        return InstrumentMode(
            instrumentType: .pluckedStrings,
            enableBlink: false,
            enableHeadShake: true,
            shakeAngleThreshold: 35.0,      // 較高的角度閾值
            shakeDuration: 0.5,              // 較長的持續時間
            shakeCooldown: 0.8,              // 較長的冷卻時間
            requireConfirmation: false
        )
    }

    /// 打擊樂器模式：預設使用搖頭（用戶可切換）
    static func percussionMode() -> InstrumentMode {
        return InstrumentMode(
            instrumentType: .percussion,
            enableBlink: false,
            enableHeadShake: true,
            shakeAngleThreshold: 30.0,
            shakeDuration: 0.3,
            shakeCooldown: 0.5,
            requireConfirmation: false
        )
    }

    /// 聲樂模式：僅搖頭控制
    static func vocalMode() -> InstrumentMode {
        return InstrumentMode(
            instrumentType: .vocal,
            enableBlink: false,
            enableHeadShake: true,
            shakeAngleThreshold: 30.0,
            shakeDuration: 0.3,
            shakeCooldown: 0.5,
            requireConfirmation: false
        )
    }

    /// 自定義模式：預設啟用所有功能（用戶可自行調整）
    static func customMode() -> InstrumentMode {
        return InstrumentMode(
            instrumentType: .custom,
            enableBlink: true,
            blinkThreshold: 0.03,
            blinkTimeWindow: 0.5,
            minBlinkDuration: 0.1,
            requiredBlinkCount: 2,
            longBlinkDuration: 0.5,
            enableHeadShake: true,
            shakeAngleThreshold: 30.0,
            shakeDuration: 0.3,
            shakeCooldown: 0.5,
            requireConfirmation: false,
            confirmationTimeout: 2.0
        )
    }

    // MARK: - 描述方法

    /// 獲取模式的簡短描述
    var description: String {
        return instrumentType.controlModeDescription
    }

    /// 獲取模式的詳細描述
    var detailedDescription: String {
        var description = "樂器類型: \(instrumentType.displayName)\n"

        if enableBlink {
            description += "✓ 眨眼控制已啟用\n"
            description += "  - 需要眨眼次數: \(requiredBlinkCount)\n"
            description += "  - 眨眼閾值: \(blinkThreshold)\n"
            description += "  - 長眨眼時間: \(longBlinkDuration)秒\n"
        }

        if enableHeadShake {
            description += "✓ 搖頭控制已啟用\n"
            description += "  - 搖頭角度: \(shakeAngleThreshold)度\n"
            description += "  - 持續時間: \(shakeDuration)秒\n"
            description += "  - 冷卻時間: \(shakeCooldown)秒\n"
        }

        if requireConfirmation {
            description += "✓ 需要確認（混合模式）\n"
            description += "  - 確認超時: \(confirmationTimeout)秒\n"
        }

        return description
    }
}

// MARK: - UserDefaults 持久化擴展

extension InstrumentMode {
    private static let userDefaultsKey = "selectedInstrumentMode"

    /// 儲存模式到 UserDefaults
    func save() {
        if let encoded = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(encoded, forKey: InstrumentMode.userDefaultsKey)
        }
    }

    /// 從 UserDefaults 載入模式
    static func load() -> InstrumentMode? {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let mode = try? JSONDecoder().decode(InstrumentMode.self, from: data) else {
            return nil
        }
        return mode
    }

    /// 刪除已儲存的模式
    static func clear() {
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
    }

    /// 獲取當前模式（若無則返回預設鍵盤模式）
    static func current() -> InstrumentMode {
        return load() ?? defaultMode(for: .keyboard)
    }
}
