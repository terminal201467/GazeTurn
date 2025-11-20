//
//  InstrumentModeTests.swift
//  GazeTurnTests
//
//  Created by Claude Code on 2025/3/20.
//

import XCTest
@testable import GazeTurn

final class InstrumentModeTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // 清除 UserDefaults
        InstrumentMode.clear()
    }

    override func tearDown() {
        InstrumentMode.clear()
        super.tearDown()
    }

    // MARK: - Instrument Type Tests

    func testInstrumentTypeCount() {
        // 應該有 7 種樂器類型
        XCTAssertEqual(InstrumentType.allCases.count, 7)
    }

    func testInstrumentTypeDisplayNames() {
        XCTAssertEqual(InstrumentType.stringInstruments.displayName, "弦樂器")
        XCTAssertEqual(InstrumentType.woodwindBrass.displayName, "管樂器")
        XCTAssertEqual(InstrumentType.keyboard.displayName, "鍵盤樂器")
        XCTAssertEqual(InstrumentType.pluckedStrings.displayName, "撥弦樂器")
        XCTAssertEqual(InstrumentType.percussion.displayName, "打擊樂器")
        XCTAssertEqual(InstrumentType.vocal.displayName, "聲樂")
        XCTAssertEqual(InstrumentType.custom.displayName, "自定義")
    }

    // MARK: - Default Mode Tests

    func testStringInstrumentsMode() {
        let mode = InstrumentMode.stringInstrumentsMode()

        // 應該只啟用眨眼
        XCTAssertTrue(mode.enableBlink)
        XCTAssertFalse(mode.enableHeadShake)
        XCTAssertFalse(mode.requireConfirmation)

        // 檢查眨眼參數
        XCTAssertEqual(mode.requiredBlinkCount, 2) // 雙眨眼
        XCTAssertEqual(mode.longBlinkDuration, 0.5) // 長眨眼 0.5 秒
    }

    func testWoodwindBrassMode() {
        let mode = InstrumentMode.woodwindBrassMode()

        // 應該啟用混合模式
        XCTAssertTrue(mode.enableBlink)
        XCTAssertTrue(mode.enableHeadShake)
        XCTAssertTrue(mode.requireConfirmation) // 需要確認

        // 檢查搖頭參數
        XCTAssertEqual(mode.shakeAngleThreshold, 18.0) // 較小的角度
        XCTAssertEqual(mode.requiredBlinkCount, 1) // 單眨眼確認
    }

    func testKeyboardMode() {
        let mode = InstrumentMode.keyboardMode()

        // 應該只啟用搖頭
        XCTAssertFalse(mode.enableBlink)
        XCTAssertTrue(mode.enableHeadShake)
        XCTAssertFalse(mode.requireConfirmation)

        // 檢查搖頭參數
        XCTAssertEqual(mode.shakeAngleThreshold, 30.0) // 標準角度
    }

    func testPluckedStringsMode() {
        let mode = InstrumentMode.pluckedStringsMode()

        // 應該只啟用搖頭，但有較高閾值
        XCTAssertFalse(mode.enableBlink)
        XCTAssertTrue(mode.enableHeadShake)

        // 較高的閾值避免誤觸發
        XCTAssertEqual(mode.shakeAngleThreshold, 35.0)
        XCTAssertEqual(mode.shakeDuration, 0.5) // 較長持續時間
    }

    func testPercussionMode() {
        let mode = InstrumentMode.percussionMode()

        // 預設使用搖頭
        XCTAssertFalse(mode.enableBlink)
        XCTAssertTrue(mode.enableHeadShake)
    }

    func testVocalMode() {
        let mode = InstrumentMode.vocalMode()

        // 應該只啟用搖頭
        XCTAssertFalse(mode.enableBlink)
        XCTAssertTrue(mode.enableHeadShake)
    }

    func testCustomMode() {
        let mode = InstrumentMode.customMode()

        // 應該啟用所有功能
        XCTAssertTrue(mode.enableBlink)
        XCTAssertTrue(mode.enableHeadShake)
    }

    // MARK: - Persistence Tests

    func testSaveAndLoad() {
        let originalMode = InstrumentMode.keyboardMode()

        // 儲存
        originalMode.save()

        // 載入
        let loadedMode = InstrumentMode.load()

        XCTAssertNotNil(loadedMode)
        XCTAssertEqual(loadedMode?.instrumentType, .keyboard)
        XCTAssertEqual(loadedMode?.enableBlink, originalMode.enableBlink)
        XCTAssertEqual(loadedMode?.enableHeadShake, originalMode.enableHeadShake)
    }

    func testCurrentModeReturnsDefaultWhenNothingSaved() {
        // 清除任何已儲存的模式
        InstrumentMode.clear()

        // 應該返回預設鍵盤模式
        let currentMode = InstrumentMode.current()
        XCTAssertEqual(currentMode.instrumentType, .keyboard)
    }

    func testCurrentModeReturnsLoadedMode() {
        // 儲存弦樂器模式
        let stringMode = InstrumentMode.stringInstrumentsMode()
        stringMode.save()

        // 應該返回弦樂器模式
        let currentMode = InstrumentMode.current()
        XCTAssertEqual(currentMode.instrumentType, .stringInstruments)
    }

    // MARK: - Default Mode Factory Tests

    func testDefaultModeFactory() {
        for instrumentType in InstrumentType.allCases {
            let mode = InstrumentMode.defaultMode(for: instrumentType)
            XCTAssertEqual(mode.instrumentType, instrumentType)
        }
    }

    // MARK: - Detailed Description Tests

    func testDetailedDescription() {
        let mode = InstrumentMode.keyboardMode()
        let description = mode.detailedDescription

        // 應該包含樂器類型
        XCTAssertTrue(description.contains("鍵盤樂器"))

        // 應該包含搖頭控制說明
        XCTAssertTrue(description.contains("搖頭控制已啟用"))
    }

    // MARK: - Configuration Tests

    func testBlinkThresholdRange() {
        // 眨眼閾值應該在合理範圍內
        for instrumentType in InstrumentType.allCases {
            let mode = InstrumentMode.defaultMode(for: instrumentType)
            if mode.enableBlink {
                XCTAssertGreaterThan(mode.blinkThreshold, 0.0)
                XCTAssertLessThan(mode.blinkThreshold, 0.1)
            }
        }
    }

    func testShakeAngleThresholdRange() {
        // 搖頭角度閾值應該在合理範圍內（15-40度）
        for instrumentType in InstrumentType.allCases {
            let mode = InstrumentMode.defaultMode(for: instrumentType)
            if mode.enableHeadShake {
                XCTAssertGreaterThanOrEqual(mode.shakeAngleThreshold, 15.0)
                XCTAssertLessThanOrEqual(mode.shakeAngleThreshold, 40.0)
            }
        }
    }

    func testCooldownDuration() {
        // 冷卻時間應該至少 0.3 秒
        for instrumentType in InstrumentType.allCases {
            let mode = InstrumentMode.defaultMode(for: instrumentType)
            if mode.enableHeadShake {
                XCTAssertGreaterThanOrEqual(mode.shakeCooldown, 0.3)
            }
        }
    }
}
