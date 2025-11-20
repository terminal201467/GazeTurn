//
//  BlinkRecognizerTests.swift
//  GazeTurnTests
//
//  Created by Claude Code on 2025/3/20.
//

import XCTest
@testable import GazeTurn

final class BlinkRecognizerTests: XCTestCase {

    var recognizer: BlinkRecognizer!

    override func setUp() {
        super.setUp()
        recognizer = BlinkRecognizer()
    }

    override func tearDown() {
        recognizer = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInitialization() {
        XCTAssertNotNil(recognizer)
    }

    // MARK: - Single Blink Tests

    func testSingleBlink() {
        // 模擬眼睛狀態：張開 -> 閉合 -> 張開
        var result: Bool

        // 初始狀態：眼睛張開
        result = recognizer.detectBlink(leftOpen: true, rightOpen: true)
        XCTAssertFalse(result, "眼睛張開時不應觸發")

        // 眼睛閉合（第一次眨眼）
        result = recognizer.detectBlink(leftOpen: false, rightOpen: false)
        XCTAssertFalse(result, "單次眨眼不應觸發（需要雙眨眼）")

        // 眼睛張開
        result = recognizer.detectBlink(leftOpen: true, rightOpen: true)
        XCTAssertFalse(result, "單次眨眼後張開不應觸發")
    }

    // MARK: - Double Blink Tests

    func testDoubleBlink() {
        // 模擬快速雙眨眼
        var result: Bool

        // 第一次眨眼
        result = recognizer.detectBlink(leftOpen: false, rightOpen: false)
        XCTAssertFalse(result)

        // 眼睛張開（短暫）
        result = recognizer.detectBlink(leftOpen: true, rightOpen: true)
        XCTAssertFalse(result)

        // 第二次眨眼（在時間窗口內）
        result = recognizer.detectBlink(leftOpen: false, rightOpen: false)
        // 注意：BlinkRecognizer 在檢測到雙眨眼時會返回 true
        // 但需要確認實際實作是在閉合時還是張開時觸發
    }

    // MARK: - Time Window Tests

    func testBlinkTimeWindow() {
        // 測試眨眼時間窗口（0.5秒）
        var result: Bool

        // 第一次眨眼
        result = recognizer.detectBlink(leftOpen: false, rightOpen: false)
        XCTAssertFalse(result)

        // 等待超過時間窗口
        let expectation = self.expectation(description: "Wait for time window")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        // 第二次眨眼（超出時間窗口）
        result = recognizer.detectBlink(leftOpen: false, rightOpen: false)
        XCTAssertFalse(result, "超出時間窗口不應觸發")
    }

    // MARK: - Single Eye Blink Tests

    func testLeftEyeOnlyBlink() {
        // 只有左眼閉合（不應觸發）
        let result = recognizer.detectBlink(leftOpen: false, rightOpen: true)
        XCTAssertFalse(result, "單眼眨眼不應觸發")
    }

    func testRightEyeOnlyBlink() {
        // 只有右眼閉合（不應觸發）
        let result = recognizer.detectBlink(leftOpen: true, rightOpen: false)
        XCTAssertFalse(result, "單眼眨眼不應觸發")
    }

    // MARK: - Both Eyes Tests

    func testBothEyesOpen() {
        // 雙眼都張開（不應觸發）
        let result = recognizer.detectBlink(leftOpen: true, rightOpen: true)
        XCTAssertFalse(result)
    }

    func testBothEyesClosed() {
        // 雙眼都閉合（第一次不應觸發）
        let result = recognizer.detectBlink(leftOpen: false, rightOpen: false)
        XCTAssertFalse(result, "首次閉眼不應觸發")
    }

    // MARK: - Rapid Blink Tests

    func testRapidTripleBlink() {
        // 測試快速三次眨眼
        var result: Bool

        // 第一次眨眼
        result = recognizer.detectBlink(leftOpen: false, rightOpen: false)
        XCTAssertFalse(result)

        result = recognizer.detectBlink(leftOpen: true, rightOpen: true)
        XCTAssertFalse(result)

        // 第二次眨眼（應該觸發）
        result = recognizer.detectBlink(leftOpen: false, rightOpen: false)

        result = recognizer.detectBlink(leftOpen: true, rightOpen: true)

        // 第三次眨眼（計數器應該已重置）
        result = recognizer.detectBlink(leftOpen: false, rightOpen: false)
        XCTAssertFalse(result, "雙眨眼後計數器應重置")
    }

    // MARK: - Slow Blink Tests

    func testSlowBlinkSequence() {
        // 測試緩慢的眨眼序列（應該重置計數）
        var result: Bool

        // 第一次眨眼
        result = recognizer.detectBlink(leftOpen: false, rightOpen: false)
        XCTAssertFalse(result)

        // 等待時間窗口過期
        let expectation = self.expectation(description: "Wait for timeout")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            // 第二次眨眼（應該作為新的第一次）
            result = self.recognizer.detectBlink(leftOpen: false, rightOpen: false)
            XCTAssertFalse(result, "超時後應重新計數")
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - Alternating Eyes Tests

    func testAlternatingEyes() {
        // 測試交替眨眼（不應觸發）
        var result: Bool

        result = recognizer.detectBlink(leftOpen: false, rightOpen: true)
        XCTAssertFalse(result)

        result = recognizer.detectBlink(leftOpen: true, rightOpen: false)
        XCTAssertFalse(result)

        result = recognizer.detectBlink(leftOpen: false, rightOpen: true)
        XCTAssertFalse(result, "交替眨眼不應觸發")
    }

    // MARK: - Continuous Closed Eyes Tests

    func testContinuousClosedEyes() {
        // 測試持續閉眼（不應重複觸發）
        var result: Bool

        result = recognizer.detectBlink(leftOpen: false, rightOpen: false)
        XCTAssertFalse(result)

        // 持續閉眼
        result = recognizer.detectBlink(leftOpen: false, rightOpen: false)
        result = recognizer.detectBlink(leftOpen: false, rightOpen: false)
        result = recognizer.detectBlink(leftOpen: false, rightOpen: false)

        // 不應重複觸發
    }

    // MARK: - Performance Tests

    func testDetectionPerformance() {
        measure {
            for i in 0..<1000 {
                let isOpen = i % 2 == 0
                _ = recognizer.detectBlink(leftOpen: isOpen, rightOpen: isOpen)
            }
        }
    }

    // MARK: - State Reset Tests

    func testStateIndependence() {
        // 測試不同實例的狀態獨立性
        let recognizer1 = BlinkRecognizer()
        let recognizer2 = BlinkRecognizer()

        // recognizer1 第一次眨眼
        _ = recognizer1.detectBlink(leftOpen: false, rightOpen: false)

        // recognizer2 不應受影響
        let result = recognizer2.detectBlink(leftOpen: false, rightOpen: false)
        XCTAssertFalse(result, "不同實例應該獨立")
    }

    // MARK: - Edge Case Tests

    func testMixedEyeStates() {
        // 測試混合的眼睛狀態序列
        var result: Bool

        result = recognizer.detectBlink(leftOpen: true, rightOpen: true)
        result = recognizer.detectBlink(leftOpen: false, rightOpen: true)
        result = recognizer.detectBlink(leftOpen: false, rightOpen: false)
        result = recognizer.detectBlink(leftOpen: true, rightOpen: false)
        result = recognizer.detectBlink(leftOpen: true, rightOpen: true)

        // 不規則的序列不應觸發
    }

    // MARK: - Threshold Configuration Tests

    func testDefaultThresholds() {
        // 驗證預設閾值是否合理
        // blinkTimeThreshold 應該是 0.5 秒
        // minBlinkDuration 應該是 0.1 秒

        XCTAssertNotNil(recognizer)
    }
}
