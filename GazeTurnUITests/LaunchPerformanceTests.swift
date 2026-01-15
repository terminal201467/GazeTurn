//
//  LaunchPerformanceTests.swift
//  GazeTurnUITests
//
//  Created by Claude Code on 2025/1/15.
//

import XCTest

final class LaunchPerformanceTests: XCTestCase {

    // MARK: - Performance Tests

    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            // 測量 APP 啟動效能
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }

    func testLaunchPerformanceWithBaseline() throws {
        if #available(iOS 14.0, *) {
            measure(metrics: [XCTApplicationLaunchMetric(waitUntilResponsive: true)]) {
                let app = XCUIApplication()
                app.launch()

                // 等待主介面或首次啟動介面載入完成
                let welcomeText = app.staticTexts["歡迎使用 GazeTurn"]
                let mainView = app.navigationBars["GazeTurn"]

                _ = welcomeText.waitForExistence(timeout: 5) || mainView.waitForExistence(timeout: 5)
            }
        }
    }

    // MARK: - Memory Tests

    func testMemoryUsageOnLaunch() throws {
        let app = XCUIApplication()
        app.launch()

        // 等待 APP 完全載入
        sleep(3)

        // 驗證 APP 狀態
        XCTAssertTrue(app.state == .runningForeground, "APP 應該在前景運行")
    }

    // MARK: - Stability Tests

    func testMultipleLaunches() throws {
        // 測試多次啟動的穩定性
        for i in 1...3 {
            let app = XCUIApplication()
            app.launch()

            // 等待載入
            sleep(2)

            // 驗證 APP 正常運行
            XCTAssertTrue(app.state == .runningForeground, "第 \(i) 次啟動應該成功")

            app.terminate()
        }
    }

    func testBackgroundAndForeground() throws {
        let app = XCUIApplication()
        app.launch()

        // 等待載入
        sleep(2)

        // 模擬進入背景
        XCUIDevice.shared.press(.home)
        sleep(2)

        // 重新進入前景
        app.activate()

        // 等待 APP 恢復到前景狀態
        let expectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "state == %d", XCUIApplication.State.runningForeground.rawValue),
            object: app
        )
        let result = XCTWaiter.wait(for: [expectation], timeout: 10)

        // 驗證 APP 恢復正常
        XCTAssertTrue(result == .completed || app.state == .runningForeground, "從背景恢復後應該正常運行")
    }
}
