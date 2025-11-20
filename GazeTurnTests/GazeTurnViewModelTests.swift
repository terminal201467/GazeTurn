//
//  GazeTurnViewModelTests.swift
//  GazeTurnTests
//
//  Created by Claude Code on 2025/3/20.
//

import XCTest
import AVFoundation
@testable import GazeTurn

final class GazeTurnViewModelTests: XCTestCase {

    var viewModel: GazeTurnViewModel!

    override func setUp() {
        super.setUp()
        viewModel = GazeTurnViewModel()
    }

    override func tearDown() {
        viewModel = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInitialization() {
        XCTAssertNotNil(viewModel)
        XCTAssertEqual(viewModel.currentPage, 0)
        XCTAssertEqual(viewModel.totalPages, 1)
        XCTAssertFalse(viewModel.isProcessingGesture)
        XCTAssertFalse(viewModel.isWaitingForConfirmation)
    }

    func testInitializationWithCustomMode() {
        let stringMode = InstrumentMode.stringInstrumentsMode()
        let customViewModel = GazeTurnViewModel(instrumentMode: stringMode)

        XCTAssertNotNil(customViewModel)
    }

    // MARK: - Page Management Tests

    func testSetTotalPages() {
        viewModel.setTotalPages(10)
        XCTAssertEqual(viewModel.totalPages, 10)
    }

    func testResetPage() {
        viewModel.currentPage = 5
        viewModel.resetPage()
        XCTAssertEqual(viewModel.currentPage, 0)
    }

    // MARK: - Manual Page Turn Tests

    func testManualPageTurnNext() {
        viewModel.setTotalPages(5)
        viewModel.manualPageTurn(direction: .next)

        XCTAssertEqual(viewModel.currentPage, 1)
    }

    func testManualPageTurnPrevious() {
        viewModel.setTotalPages(5)
        viewModel.currentPage = 2

        viewModel.manualPageTurn(direction: .previous)

        XCTAssertEqual(viewModel.currentPage, 1)
    }

    func testManualPageTurnAtBoundaries() {
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

    // MARK: - Page Change Callback Tests

    func testPageChangeCallback() {
        var callbackCalled = false
        var callbackPage: Int?

        viewModel.onPageChange = { page in
            callbackCalled = true
            callbackPage = page
        }

        viewModel.setTotalPages(5)
        viewModel.manualPageTurn(direction: .next)

        XCTAssertTrue(callbackCalled)
        XCTAssertEqual(callbackPage, 1)
    }

    // MARK: - Instrument Mode Tests

    func testUpdateInstrumentMode() {
        let keyboardMode = InstrumentMode.keyboardMode()
        viewModel.updateInstrumentMode(keyboardMode)

        // 驗證狀態訊息已更新
        XCTAssertTrue(viewModel.gestureStatusMessage.contains("鍵盤樂器"))
    }

    // MARK: - Camera Permission Tests

    func testCheckCameraPermission() {
        viewModel.checkCameraPermission()

        // 權限狀態應該被設定（實際值取決於系統）
        XCTAssertNotNil(viewModel.cameraPermissionStatus)
    }

    // MARK: - Status Description Tests

    func testGetStatusDescription() {
        let description = viewModel.getStatusDescription()

        XCTAssertTrue(description.contains("狀態"))
        XCTAssertTrue(description.contains("相機"))
        XCTAssertTrue(description.contains("當前頁面"))
        XCTAssertTrue(description.contains("樂器模式"))
    }

    // MARK: - Published Properties Tests

    func testPublishedPropertiesUpdate() {
        let expectation = self.expectation(description: "Published property update")

        var observations = 0
        let cancellable = viewModel.$currentPage
            .sink { _ in
                observations += 1
                if observations >= 2 { // 初始值 + 一次更新
                    expectation.fulfill()
                }
            }

        viewModel.setTotalPages(5)
        viewModel.manualPageTurn(direction: .next)

        wait(for: [expectation], timeout: 1.0)
        cancellable.cancel()

        XCTAssertGreaterThanOrEqual(observations, 2)
    }

    // MARK: - Multiple Page Turns Tests

    func testMultiplePageTurns() {
        viewModel.setTotalPages(10)

        // 向前翻頁 5 次
        for _ in 0..<5 {
            viewModel.manualPageTurn(direction: .next)
        }

        XCTAssertEqual(viewModel.currentPage, 5)

        // 向後翻頁 3 次
        for _ in 0..<3 {
            viewModel.manualPageTurn(direction: .previous)
        }

        XCTAssertEqual(viewModel.currentPage, 2)
    }

    // MARK: - Edge Cases Tests

    func testSinglePageDocument() {
        viewModel.setTotalPages(1)

        viewModel.manualPageTurn(direction: .next)
        XCTAssertEqual(viewModel.currentPage, 0)

        viewModel.manualPageTurn(direction: .previous)
        XCTAssertEqual(viewModel.currentPage, 0)
    }

    func testZeroPages() {
        viewModel.setTotalPages(0)

        viewModel.manualPageTurn(direction: .next)
        XCTAssertEqual(viewModel.currentPage, 0)
    }

    // MARK: - Thread Safety Tests

    func testConcurrentPageTurns() {
        viewModel.setTotalPages(100)

        let expectation = self.expectation(description: "Concurrent page turns")
        expectation.expectedFulfillmentCount = 10

        for _ in 0..<10 {
            DispatchQueue.global().async {
                self.viewModel.manualPageTurn(direction: .next)
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 2.0)

        // 頁面應該在合理範圍內
        XCTAssertGreaterThanOrEqual(viewModel.currentPage, 0)
        XCTAssertLessThan(viewModel.currentPage, 100)
    }

    // MARK: - Performance Tests

    func testPageTurnPerformance() {
        viewModel.setTotalPages(1000)

        measure {
            for _ in 0..<100 {
                viewModel.manualPageTurn(direction: .next)
            }
        }
    }

    // MARK: - Integration Tests

    func testCompleteWorkflow() {
        // 模擬完整的工作流程

        // 1. 設定總頁數
        viewModel.setTotalPages(10)

        // 2. 更新樂器模式
        viewModel.updateInstrumentMode(InstrumentMode.keyboardMode())

        // 3. 翻頁幾次
        viewModel.manualPageTurn(direction: .next)
        viewModel.manualPageTurn(direction: .next)
        viewModel.manualPageTurn(direction: .next)

        XCTAssertEqual(viewModel.currentPage, 3)

        // 4. 重置
        viewModel.resetPage()
        XCTAssertEqual(viewModel.currentPage, 0)
    }

    // MARK: - State Management Tests

    func testStateConsistency() {
        viewModel.setTotalPages(5)

        // 確保狀態一致性
        XCTAssertLessThanOrEqual(viewModel.currentPage, viewModel.totalPages - 1)

        viewModel.manualPageTurn(direction: .next)
        XCTAssertLessThanOrEqual(viewModel.currentPage, viewModel.totalPages - 1)

        viewModel.manualPageTurn(direction: .previous)
        XCTAssertGreaterThanOrEqual(viewModel.currentPage, 0)
    }

    // MARK: - Gesture Status Tests

    func testGestureStatusUpdates() {
        let initialMessage = viewModel.gestureStatusMessage

        viewModel.updateInstrumentMode(InstrumentMode.vocalMode())

        XCTAssertNotEqual(viewModel.gestureStatusMessage, initialMessage)
    }

    // MARK: - Camera Lifecycle Tests (Mock)

    func testCameraLifecycle() {
        // 注意：這些測試需要相機權限，在 CI 環境中可能會失敗

        // 測試停止相機
        viewModel.stopCamera()
        XCTAssertFalse(viewModel.isCameraAvailable)
    }
}
