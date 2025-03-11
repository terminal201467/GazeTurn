//
//  BlinkRecognizer.swift
//  GazeTurn
//
//  Created by Jhen Mu on 2025/3/9.
//

import Foundation

/// `BlinkRecognizer` 負責分析眨眼行為，判斷是否觸發翻頁。
class BlinkRecognizer {
    /// 記錄最後一次眨眼的時間
    private var lastBlinkTime: Date?
    /// 眨眼計數器
    private var blinkCount = 0
    
    /// 閾值設置（可根據測試調整）
    private let blinkTimeThreshold: TimeInterval = 0.5
    private let minBlinkDuration: TimeInterval = 0.1
    
    /// 偵測眨眼行為，並回傳是否觸發翻頁
    /// - Parameters:
    ///   - leftOpen: 左眼是否張開。
    ///   - rightOpen: 右眼是否張開。
    /// - Returns: `true` 代表觸發翻頁，`false` 則不觸發。
    func detectBlink(leftOpen: Bool, rightOpen: Bool) -> Bool {
        let now = Date()
        if !leftOpen && !rightOpen {
            if let lastBlink = lastBlinkTime {
                let timeSinceLastBlink = now.timeIntervalSince(lastBlink)
                
                if timeSinceLastBlink < blinkTimeThreshold, timeSinceLastBlink > minBlinkDuration {
                    blinkCount += 1
                } else {
                    blinkCount = 1
                }
            } else {
                blinkCount = 1
            }
            
            lastBlinkTime = now
            if blinkCount >= 2 {
                blinkCount = 0
                return true
            }
        }
        return false // 沒有觸發翻頁
    }
}
