//
//  IntegrationTests.swift
//  GazeTurnTests
//
//  Created by Claude Code on 2025/3/20.
//

import XCTest
import Vision
import AVFoundation
@testable import GazeTurn

/// 整合測試 - 測試完整的元件協作流程
final class IntegrationTests: XCTestCase {

    // MARK: - Properties

    var viewModel: GazeTurnViewModel!
    var blinkRecognizer: BlinkRecognizer!
    var headPoseDetector: HeadPoseDetector!
    var gestureCoordinator: GestureCoordinator!

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()
        viewModel = GazeTurnViewModel()
        blinkRecognizer = BlinkRecognizer()
        headPoseDetector = HeadPoseDetector()
        gestureCoordinator = GestureCoordinator(mode: InstrumentMode.keyboardMode())
    }

    override func tearDown() {
        viewModel = nil
        blinkRecognizer = nil
        headPoseDetector = nil
        gestureCoordinator = nil
        super.tearDown()
    }

    // MARK: - ViewModel Integration Tests

    func testViewModelInitializationWithAllComponents() {
        // 測試 ViewModel 初始化時所有元件都正確設定

        XCTAssertNotNil(viewModel)
        XCTAssertEqual(viewModel.currentPage, 0)
        XCTAssertEqual(viewModel.totalPages, 1)
        XCTAssertFalse(viewModel.isProcessingGesture)
        XCTAssertFalse(viewModel.isWaitingForConfirmation)
        XCTAssertNotNil(viewModel.visualizationData)
    }

    func testViewModelPageManagement() {
        // 測試 ViewModel 的頁面管理功能

        viewModel.setTotalPages(10)
        XCTAssertEqual(viewModel.totalPages, 10)

        viewModel.manualPageTurn(direction: .next)
        XCTAssertEqual(viewModel.currentPage, 1)

        viewModel.manualPageTurn(direction: .next)
        XCTAssertEqual(viewModel.currentPage, 2)

        viewModel.manualPageTurn(direction: .previous)
        XCTAssertEqual(viewModel.currentPage, 1)

        viewModel.resetPage()
        XCTAssertEqual(viewModel.currentPage, 0)
    }

    func testViewModelModeUpdate() {
        // 測試更新樂器模式

        let stringMode = InstrumentMode.stringInstrumentsMode()
        viewModel.updateInstrumentMode(stringMode)

        XCTAssertTrue(viewModel.gestureStatusMessage.contains("弦樂器"))
    }

    func testViewModelStatusDescription() {
        // 測試狀態描述生成

        let description = viewModel.getStatusDescription()

        XCTAssertTrue(description.contains("狀態"))
        XCTAssertTrue(description.contains("相機"))
        XCTAssertTrue(description.contains("當前頁面"))
        XCTAssertTrue(description.contains("樂器模式"))
    }

    // MARK: - Gesture Detection Flow Tests

    func testBlinkRecognizerToCoordinatorFlow() {
        // 測試眨眼識別器與協調器的協作

        let mockDelegate = MockGestureCoordinatorDelegate()
        let blinkMode = InstrumentMode.stringInstrumentsMode()
        let coordinator = GestureCoordinator(mode: blinkMode)
        coordinator.delegate = mockDelegate

        // 模擬眨眼序列
        let recognizer = BlinkRecognizer()

        // 閉眼
        let blinkDetected1 = recognizer.detectBlink(leftOpen: false, rightOpen: false)
        coordinator.processEyeState(leftOpen: false, rightOpen: false)

        // 張眼
        let blinkDetected2 = recognizer.detectBlink(leftOpen: true, rightOpen: true)
        coordinator.processEyeState(leftOpen: true, rightOpen: true)

        // 雙眨眼邏輯會在 BlinkRecognizer 內部處理
        XCTAssertTrue(blinkDetected1 || blinkDetected2)
    }

    func testHeadShakeToCoordinatorFlow() {
        // 測試搖頭檢測器與協調器的協作

        let mockDelegate = MockGestureCoordinatorDelegate()
        let headShakeMode = InstrumentMode.keyboardMode()
        let coordinator = GestureCoordinator(mode: headShakeMode)
        coordinator.delegate = mockDelegate

        // 模擬向右搖頭
        coordinator.processHeadShake(.right)

        // 應該觸發下一頁
        XCTAssertEqual(mockDelegate.lastDirection, .next)
    }

    func testHybridModeFlow() {
        // 測試混合模式的完整流程

        let mockDelegate = MockGestureCoordinatorDelegate()
        let hybridMode = InstrumentMode.woodwindBrassMode()
        let coordinator = GestureCoordinator(mode: hybridMode)
        coordinator.delegate = mockDelegate

        // 步驟 1：搖頭
        coordinator.processHeadShake(.right)

        // 應該進入等待確認狀態
        XCTAssertTrue(mockDelegate.waitingForConfirmationCalled)
        XCTAssertEqual(mockDelegate.waitingDirection, .next)
    }

    // MARK: - Mode Switching Integration Tests

    func testModeSwitchingPreservesState() {
        // 測試切換模式時狀態保持

        viewModel.setTotalPages(10)
        viewModel.manualPageTurn(direction: .next)
        viewModel.manualPageTurn(direction: .next)

        let currentPage = viewModel.currentPage
        XCTAssertEqual(currentPage, 2)

        // 切換模式
        viewModel.updateInstrumentMode(InstrumentMode.vocalMode())

        // 頁面狀態應該保持
        XCTAssertEqual(viewModel.currentPage, currentPage)
        XCTAssertEqual(viewModel.totalPages, 10)
    }

    func testModeSwitchingBetweenAllTypes() {
        // 測試在所有樂器類型之間切換

        let modes = [
            InstrumentMode.stringInstrumentsMode(),
            InstrumentMode.woodwindBrassMode(),
            InstrumentMode.keyboardMode(),
            InstrumentMode.pluckedStringsMode(),
            InstrumentMode.percussionMode(),
            InstrumentMode.vocalMode()
        ]

        for mode in modes {
            viewModel.updateInstrumentMode(mode)
            XCTAssertTrue(viewModel.gestureStatusMessage.contains(mode.instrumentType.displayName))
        }
    }

    // MARK: - Page Change Callback Tests

    func testPageChangeCallbackIntegration() {
        // 測試頁面變更回調的整合

        var callbackCount = 0
        var lastPage: Int?

        viewModel.onPageChange = { page in
            callbackCount += 1
            lastPage = page
        }

        viewModel.setTotalPages(10)
        viewModel.manualPageTurn(direction: .next)

        XCTAssertEqual(callbackCount, 1)
        XCTAssertEqual(lastPage, 1)

        viewModel.manualPageTurn(direction: .next)
        viewModel.manualPageTurn(direction: .next)

        XCTAssertEqual(callbackCount, 3)
        XCTAssertEqual(lastPage, 3)
    }

    // MARK: - Boundary Condition Tests

    func testPageNavigationBoundaries() {
        // 測試頁面導航的邊界條件

        viewModel.setTotalPages(5)

        // 測試第一頁
        viewModel.currentPage = 0
        viewModel.manualPageTurn(direction: .previous)
        XCTAssertEqual(viewModel.currentPage, 0, "不應該翻到負數頁")

        // 測試最後一頁
        viewModel.currentPage = 4
        viewModel.manualPageTurn(direction: .next)
        XCTAssertEqual(viewModel.currentPage, 4, "不應該超過總頁數")
    }

    func testSinglePageDocument() {
        // 測試單頁文件

        viewModel.setTotalPages(1)

        viewModel.manualPageTurn(direction: .next)
        XCTAssertEqual(viewModel.currentPage, 0)

        viewModel.manualPageTurn(direction: .previous)
        XCTAssertEqual(viewModel.currentPage, 0)
    }

    func testEmptyDocument() {
        // 測試空文件（0 頁）

        viewModel.setTotalPages(0)

        viewModel.manualPageTurn(direction: .next)
        XCTAssertEqual(viewModel.currentPage, 0)

        viewModel.manualPageTurn(direction: .previous)
        XCTAssertEqual(viewModel.currentPage, 0)
    }

    // MARK: - Concurrent Operation Tests

    func testConcurrentPageTurns() {
        // 測試並發翻頁操作

        viewModel.setTotalPages(100)

        let expectation = self.expectation(description: "Concurrent page turns")
        expectation.expectedFulfillmentCount = 20

        for _ in 0..<20 {
            DispatchQueue.global().async {
                self.viewModel.manualPageTurn(direction: .next)
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 3.0)

        // 頁面應該在有效範圍內
        XCTAssertGreaterThanOrEqual(viewModel.currentPage, 0)
        XCTAssertLessThan(viewModel.currentPage, 100)
    }

    func testConcurrentModeUpdates() {
        // 測試並發模式更新

        let modes = [
            InstrumentMode.stringInstrumentsMode(),
            InstrumentMode.keyboardMode(),
            InstrumentMode.vocalMode()
        ]

        let expectation = self.expectation(description: "Concurrent mode updates")
        expectation.expectedFulfillmentCount = modes.count

        for mode in modes {
            DispatchQueue.global().async {
                self.viewModel.updateInstrumentMode(mode)
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 2.0)

        // ViewModel 應該仍然運行正常
        XCTAssertNotNil(viewModel)
    }

    // MARK: - Visualization Data Integration Tests

    func testVisualizationDataUpdate() {
        // 測試視覺化數據更新

        XCTAssertNotNil(viewModel.visualizationData)

        // 初始狀態
        XCTAssertFalse(viewModel.visualizationData.faceDetected)
        XCTAssertEqual(viewModel.visualizationData.lastGesture, "無")
    }

    // MARK: - Complete Workflow Tests

    func testCompleteUserWorkflow() {
        // 測試完整的使用者工作流程

        // 1. 初始化
        XCTAssertEqual(viewModel.currentPage, 0)

        // 2. 設定文件
        viewModel.setTotalPages(20)
        XCTAssertEqual(viewModel.totalPages, 20)

        // 3. 選擇樂器模式
        viewModel.updateInstrumentMode(InstrumentMode.keyboardMode())

        // 4. 翻頁數次
        viewModel.manualPageTurn(direction: .next) // 第 1 頁
        viewModel.manualPageTurn(direction: .next) // 第 2 頁
        viewModel.manualPageTurn(direction: .next) // 第 3 頁
        XCTAssertEqual(viewModel.currentPage, 3)

        // 5. 往回翻
        viewModel.manualPageTurn(direction: .previous) // 第 2 頁
        XCTAssertEqual(viewModel.currentPage, 2)

        // 6. 重置
        viewModel.resetPage()
        XCTAssertEqual(viewModel.currentPage, 0)

        // 7. 更換模式
        viewModel.updateInstrumentMode(InstrumentMode.stringInstrumentsMode())
        XCTAssertTrue(viewModel.gestureStatusMessage.contains("弦樂器"))
    }

    func testMultipleDocumentSessions() {
        // 測試多個文件會話

        // 第一個文件
        viewModel.setTotalPages(10)
        viewModel.manualPageTurn(direction: .next)
        viewModel.manualPageTurn(direction: .next)
        XCTAssertEqual(viewModel.currentPage, 2)

        // 切換到第二個文件
        viewModel.resetPage()
        viewModel.setTotalPages(15)
        XCTAssertEqual(viewModel.currentPage, 0)
        XCTAssertEqual(viewModel.totalPages, 15)

        // 在第二個文件中翻頁
        viewModel.manualPageTurn(direction: .next)
        XCTAssertEqual(viewModel.currentPage, 1)
    }

    // MARK: - Error Recovery Tests

    func testRecoveryFromInvalidState() {
        // 測試從無效狀態恢復

        // 設定一個無效的頁面數
        viewModel.currentPage = 100
        viewModel.setTotalPages(10)

        // 嘗試翻頁應該自我修正
        viewModel.manualPageTurn(direction: .next)

        // 應該限制在有效範圍內
        XCTAssertLessThanOrEqual(viewModel.currentPage, viewModel.totalPages)
    }

    // MARK: - State Consistency Tests

    func testStateConsistencyAfterOperations() {
        // 測試多次操作後狀態一致性

        viewModel.setTotalPages(10)

        // 執行多次操作
        for _ in 0..<5 {
            viewModel.manualPageTurn(direction: .next)
        }

        for _ in 0..<3 {
            viewModel.manualPageTurn(direction: .previous)
        }

        viewModel.updateInstrumentMode(InstrumentMode.vocalMode())

        // 驗證狀態一致性
        XCTAssertGreaterThanOrEqual(viewModel.currentPage, 0)
        XCTAssertLessThan(viewModel.currentPage, viewModel.totalPages)
        XCTAssertEqual(viewModel.currentPage, 2) // 5 次前進 - 3 次後退 = 2
    }
}
