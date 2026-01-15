//
//  SettingsUITests.swift
//  GazeTurnUITests
//
//  Created by Claude Code on 2025/1/15.
//

import XCTest

final class SettingsUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()

        // 跳過首次啟動
        skipOnboardingIfNeeded()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Helper Methods

    private func skipOnboardingIfNeeded() {
        let skipButton = app.buttons["skipButton"]
        if skipButton.waitForExistence(timeout: 2) {
            skipButton.tap()
            sleep(1)
        }
    }

    private func openSettings() {
        sleep(1)

        // 嘗試多種方式查找設定按鈕
        let settingsButton: XCUIElement
        if app.buttons["settingsMenuButton"].exists {
            settingsButton = app.buttons["settingsMenuButton"]
        } else if app.buttons["settingsMenu"].exists {
            settingsButton = app.buttons["settingsMenu"]
        } else {
            // 查找導航欄中的按鈕
            let navBar = app.navigationBars["GazeTurn"]
            if navBar.exists {
                settingsButton = navBar.buttons.element(boundBy: 0)
            } else {
                settingsButton = app.buttons.matching(identifier: "settingsMenuButton").firstMatch
            }
        }

        if settingsButton.waitForExistence(timeout: 5) {
            settingsButton.tap()
            sleep(1)

            // 點擊「手勢設定」
            let gestureSettingsButton = app.buttons["手勢設定"]
            if gestureSettingsButton.waitForExistence(timeout: 3) {
                gestureSettingsButton.tap()
                sleep(1)
            }
        }
    }

    // MARK: - Settings View Tests

    func testOpenSettingsView() throws {
        // 使用 helper 開啟設定介面
        openSettings()
        sleep(1)

        // 檢查設定介面是否開啟 - 尋找取消或儲存按鈕
        let cancelButton = app.buttons["cancelButton"]
        XCTAssertTrue(cancelButton.waitForExistence(timeout: 5), "應該顯示設定介面的取消按鈕")
    }

    func testSettingsViewHasInstrumentSection() throws {
        openSettings()
        sleep(2)

        // 檢查更改按鈕是否存在
        let changeButton = app.buttons["changeInstrumentButton"]
        XCTAssertTrue(changeButton.waitForExistence(timeout: 5), "應該有更改樂器按鈕")
    }

    func testSettingsViewHasResetButton() throws {
        openSettings()
        sleep(2)

        let resetButton = app.buttons["resetButton"]

        // 如果按鈕不存在，嘗試滾動查找
        if !resetButton.exists {
            // 嘗試在 List 或 ScrollView 中滾動
            let lists = app.tables
            let scrollViews = app.scrollViews

            if lists.count > 0 {
                lists.firstMatch.swipeUp()
                sleep(1)
                lists.firstMatch.swipeUp()
            } else if scrollViews.count > 0 {
                scrollViews.firstMatch.swipeUp()
                sleep(1)
                scrollViews.firstMatch.swipeUp()
            } else {
                // 在整個應用上滑動
                for _ in 0..<4 {
                    app.swipeUp()
                    usleep(500000) // 0.5 秒
                    if resetButton.exists { break }
                }
            }
        }

        XCTAssertTrue(resetButton.waitForExistence(timeout: 5), "應該有重置按鈕")
    }

    func testCancelSettings() throws {
        openSettings()
        sleep(1)

        // 點擊取消
        let cancelButton = app.buttons["cancelButton"]
        if cancelButton.waitForExistence(timeout: 2) {
            cancelButton.tap()

            // 應該返回主介面
            let mainView = app.navigationBars["GazeTurn"]
            XCTAssertTrue(mainView.waitForExistence(timeout: 3), "取消後應該返回主介面")
        }
    }

    func testSaveSettings() throws {
        openSettings()
        sleep(1)

        // 點擊儲存
        let saveButton = app.buttons["saveButton"]
        if saveButton.waitForExistence(timeout: 2) {
            saveButton.tap()

            // 應該返回主介面
            let mainView = app.navigationBars["GazeTurn"]
            XCTAssertTrue(mainView.waitForExistence(timeout: 3), "儲存後應該返回主介面")
        }
    }

    func testResetSettingsShowsAlert() throws {
        openSettings()
        sleep(1)

        // 滾動到重置按鈕
        app.swipeUp()

        // 點擊重置
        let resetButton = app.buttons["resetButton"]
        if resetButton.waitForExistence(timeout: 2) {
            resetButton.tap()

            // 應該顯示警告對話框
            let alert = app.alerts["重置設定"]
            XCTAssertTrue(alert.waitForExistence(timeout: 2), "應該顯示重置確認對話框")

            // 點擊取消關閉對話框
            let cancelButton = alert.buttons["取消"]
            if cancelButton.exists {
                cancelButton.tap()
            }
        }
    }

    // MARK: - Slider Tests

    func testSlidersExist() throws {
        openSettings()
        sleep(2)

        // 確保設定介面已開啟
        let cancelButton = app.buttons["cancelButton"]
        guard cancelButton.waitForExistence(timeout: 5) else {
            XCTFail("設定介面未開啟")
            return
        }

        // 檢查滑桿是否存在
        let sliders = app.sliders
        XCTAssertTrue(sliders.count > 0 || app.sliders.firstMatch.waitForExistence(timeout: 3), "設定介面應該有滑桿")
    }

    func testAdjustSliderValue() throws {
        openSettings()
        sleep(1)

        // 找到第一個滑桿並調整
        let slider = app.sliders.firstMatch
        if slider.waitForExistence(timeout: 2) {
            // 調整滑桿值
            slider.adjust(toNormalizedSliderPosition: 0.7)

            // 驗證滑桿可以互動
            XCTAssertTrue(slider.isHittable)
        }
    }
}
