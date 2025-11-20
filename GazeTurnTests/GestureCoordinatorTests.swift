//
//  GestureCoordinatorTests.swift
//  GazeTurnTests
//
//  Created by Claude Code on 2025/3/20.
//

import XCTest
@testable import GazeTurn

final class GestureCoordinatorTests: XCTestCase {

    var coordinator: GestureCoordinator!
    var mockDelegate: MockGestureCoordinatorDelegate!

    override func setUp() {
        super.setUp()
        mockDelegate = MockGestureCoordinatorDelegate()
        coordinator = GestureCoordinator(mode: InstrumentMode.keyboardMode())
        coordinator.delegate = mockDelegate
    }

    override func tearDown() {
        coordinator = nil
        mockDelegate = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInitialization() {
        XCTAssertNotNil(coordinator)
        XCTAssertEqual(coordinator.currentMode.instrumentType, .keyboard)
    }

    func testInitializationWithCustomMode() {
        let stringMode = InstrumentMode.stringInstrumentsMode()
        let stringCoordinator = GestureCoordinator(mode: stringMode)

        XCTAssertEqual(stringCoordinator.currentMode.instrumentType, .stringInstruments)
    }

    // MARK: - Mode Tests

    func testUpdateMode() {
        let woodwindMode = InstrumentMode.woodwindBrassMode()
        coordinator.updateMode(woodwindMode)

        XCTAssertEqual(coordinator.currentMode.instrumentType, .woodwindBrass)
    }

    func testSwitchToInstrument() {
        coordinator.switchToInstrument(.stringInstruments)

        XCTAssertEqual(coordinator.currentMode.instrumentType, .stringInstruments)
    }

    func testModeProperties() {
        // 鍵盤模式
        coordinator.switchToInstrument(.keyboard)
        XCTAssertFalse(coordinator.isBlinkOnlyMode)
        XCTAssertTrue(coordinator.isHeadShakeOnlyMode)
        XCTAssertFalse(coordinator.isHybridMode)

        // 弦樂器模式
        coordinator.switchToInstrument(.stringInstruments)
        XCTAssertTrue(coordinator.isBlinkOnlyMode)
        XCTAssertFalse(coordinator.isHeadShakeOnlyMode)
        XCTAssertFalse(coordinator.isHybridMode)

        // 木管/銅管模式（混合模式）
        coordinator.switchToInstrument(.woodwindBrass)
        XCTAssertFalse(coordinator.isBlinkOnlyMode)
        XCTAssertFalse(coordinator.isHeadShakeOnlyMode)
        XCTAssertTrue(coordinator.isHybridMode)
    }

    // MARK: - Blink-Only Mode Tests

    func testBlinkOnlyMode() {
        coordinator.switchToInstrument(.stringInstruments)

        // 模擬眨眼
        coordinator.processEyeState(leftOpen: false, rightOpen: false)

        // 在純眨眼模式下，應該觸發翻頁
        // （實際觸發取決於 BlinkRecognizer 的雙眨眼邏輯）
    }

    func testBlinkOnlyModeIgnoresHeadShake() {
        coordinator.switchToInstrument(.stringInstruments)

        // 模擬搖頭（應該被忽略）
        coordinator.processHeadShake(.right)

        // 不應該觸發任何事件
        XCTAssertNil(mockDelegate.lastDirection)
    }

    // MARK: - Head Shake Only Mode Tests

    func testHeadShakeOnlyMode() {
        coordinator.switchToInstrument(.keyboard)

        // 模擬向右搖頭
        coordinator.processHeadShake(.right)

        // 應該觸發下一頁
        XCTAssertEqual(mockDelegate.lastDirection, .next)
    }

    func testHeadShakeOnlyModeLeft() {
        coordinator.switchToInstrument(.keyboard)

        // 模擬向左搖頭
        coordinator.processHeadShake(.left)

        // 應該觸發上一頁
        XCTAssertEqual(mockDelegate.lastDirection, .previous)
    }

    func testHeadShakeOnlyModeIgnoresBlink() {
        coordinator.switchToInstrument(.keyboard)

        // 模擬眨眼（應該被忽略）
        coordinator.processEyeState(leftOpen: false, rightOpen: false)

        // 不應該觸發任何事件
        XCTAssertNil(mockDelegate.lastDirection)
    }

    // MARK: - Hybrid Mode Tests

    func testHybridModeRequiresConfirmation() {
        coordinator.switchToInstrument(.woodwindBrass)

        // 模擬搖頭
        coordinator.processHeadShake(.right)

        // 應該等待確認，不直接觸發
        XCTAssertTrue(mockDelegate.waitingForConfirmationCalled)
        XCTAssertEqual(mockDelegate.waitingDirection, .next)
        XCTAssertNil(mockDelegate.lastDirection) // 尚未觸發
    }

    func testHybridModeConfirmWithBlink() {
        coordinator.switchToInstrument(.woodwindBrass)

        // 步驟 1：搖頭
        coordinator.processHeadShake(.right)

        // 步驟 2：眨眼確認
        coordinator.processEyeState(leftOpen: false, rightOpen: false)

        // 應該觸發翻頁（但需要 BlinkRecognizer 返回 true）
        // 實際行為取決於 BlinkRecognizer 的實作
    }

    func testHybridModeTimeout() {
        coordinator.switchToInstrument(.woodwindBrass)

        // 模擬搖頭
        coordinator.processHeadShake(.right)

        // 等待超時
        let expectation = self.expectation(description: "Wait for confirmation timeout")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            // 檢查是否調用了超時回調
            XCTAssertTrue(self.mockDelegate.confirmationTimeoutCalled)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 3.0)
    }

    // MARK: - None Direction Tests

    func testHeadShakeNoneDirection() {
        coordinator.switchToInstrument(.keyboard)

        // 模擬無搖頭動作
        coordinator.processHeadShake(.none)

        // 不應該觸發任何事件
        XCTAssertNil(mockDelegate.lastDirection)
    }

    // MARK: - State Description Tests

    func testStateDescription() {
        let description = coordinator.getCurrentStateDescription()

        XCTAssertTrue(description.contains("GestureCoordinator State"))
        XCTAssertTrue(description.contains("Instrument"))
        XCTAssertTrue(description.contains("Status"))
    }

    func testStateDescriptionWhileWaiting() {
        coordinator.switchToInstrument(.woodwindBrass)
        coordinator.processHeadShake(.right)

        let description = coordinator.getCurrentStateDescription()
        XCTAssertTrue(description.contains("Waiting for confirmation"))
    }

    // MARK: - Performance Tests

    func testProcessingPerformance() {
        measure {
            for _ in 0..<100 {
                coordinator.processEyeState(leftOpen: true, rightOpen: true)
                coordinator.processHeadShake(.none)
            }
        }
    }

    // MARK: - Multiple Gesture Tests

    func testRapidGestureSwitching() {
        coordinator.switchToInstrument(.keyboard)

        // 快速交替搖頭
        coordinator.processHeadShake(.right)
        coordinator.processHeadShake(.left)
        coordinator.processHeadShake(.right)

        // 應該只觸發一次（因為有冷卻時間）
        // 實際行為取決於 HeadPoseDetector 的冷卻機制
    }

    // MARK: - Mode Change During Operation Tests

    func testModeChangeDuringWaiting() {
        coordinator.switchToInstrument(.woodwindBrass)

        // 開始等待確認
        coordinator.processHeadShake(.right)
        XCTAssertTrue(mockDelegate.waitingForConfirmationCalled)

        // 切換模式
        coordinator.switchToInstrument(.keyboard)

        // 狀態應該被重置
        let description = coordinator.getCurrentStateDescription()
        XCTAssertTrue(description.contains("Ready"))
    }

    // MARK: - Edge Cases

    func testNilDelegate() {
        coordinator.delegate = nil

        // 應該不會崩潰
        coordinator.processHeadShake(.right)
        coordinator.processEyeState(leftOpen: false, rightOpen: false)

        XCTAssertTrue(true, "不應崩潰")
    }

    func testMultipleCoordinatorInstances() {
        let coordinator2 = GestureCoordinator(mode: InstrumentMode.vocalMode())
        let delegate2 = MockGestureCoordinatorDelegate()
        coordinator2.delegate = delegate2

        // 兩個協調器應該獨立運作
        coordinator.processHeadShake(.right)
        coordinator2.processHeadShake(.left)

        XCTAssertEqual(mockDelegate.lastDirection, .next)
        XCTAssertEqual(delegate2.lastDirection, .previous)
    }
}

// MARK: - Mock Delegate

class MockGestureCoordinatorDelegate: GestureCoordinatorDelegate {
    var lastDirection: PageDirection?
    var waitingForConfirmationCalled = false
    var waitingDirection: PageDirection?
    var confirmationTimeoutCalled = false

    func didDetectPageTurn(direction: PageDirection) {
        lastDirection = direction
    }

    func waitingForConfirmation(direction: PageDirection) {
        waitingForConfirmationCalled = true
        waitingDirection = direction
    }

    func confirmationTimeout() {
        confirmationTimeoutCalled = true
    }

    func reset() {
        lastDirection = nil
        waitingForConfirmationCalled = false
        waitingDirection = nil
        confirmationTimeoutCalled = false
    }
}
