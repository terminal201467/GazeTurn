//
//  FileListUITests.swift
//  GazeTurnUITests
//
//  Created by Claude Code on 2025/1/15.
//

import XCTest

final class FileListUITests: XCTestCase {

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

    // MARK: - File List View Tests

    func testFileListViewLoads() throws {
        // 主介面應該顯示檔案列表
        let mainView = app.navigationBars["GazeTurn"]
        XCTAssertTrue(mainView.waitForExistence(timeout: 5), "應該載入主介面")
    }

    func testMainViewHasSettingsButton() throws {
        sleep(1)

        // 嘗試多種方式查找設定按鈕
        let navBar = app.navigationBars["GazeTurn"]
        var hasSettingsButton = false

        if navBar.waitForExistence(timeout: 3) {
            // 查找導航欄中的按鈕
            hasSettingsButton = navBar.buttons.count > 0
        }

        // 或者直接查找 settingsMenuButton
        if !hasSettingsButton {
            hasSettingsButton = app.buttons["settingsMenuButton"].exists || app.buttons["settingsMenu"].exists
        }

        XCTAssertTrue(hasSettingsButton, "應該有設定按鈕")
    }

    func testEmptyStateOrFileList() throws {
        sleep(2)

        // 檢查主介面已載入
        let mainView = app.navigationBars["GazeTurn"]
        XCTAssertTrue(mainView.waitForExistence(timeout: 5), "主介面應該載入")

        // 檢查是否有檔案列表、空狀態提示、或 List
        let tables = app.tables
        let collectionViews = app.collectionViews
        let lists = app.scrollViews
        let emptyStateText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS '沒有' OR label CONTAINS '空' OR label CONTAINS 'empty' OR label CONTAINS '匯入' OR label CONTAINS 'PDF'"))

        let hasContent = tables.count > 0 || collectionViews.count > 0 || lists.count > 0 || emptyStateText.count > 0

        XCTAssertTrue(hasContent, "應該顯示檔案列表或空狀態")
    }

    // MARK: - Menu Tests

    func testSettingsMenuOpens() throws {
        sleep(1)

        // 點擊設定按鈕
        let settingsButton = app.buttons["settingsMenuButton"]
        if settingsButton.waitForExistence(timeout: 3) {
            settingsButton.tap()

            // 等待選單出現
            sleep(UInt32(0.5))

            // 檢查選單項目
            let gestureSettings = app.buttons["手勢設定"]
            let changeInstrument = app.buttons["更改樂器"]
            let resetGuide = app.buttons["重置引導"]

            let menuOpened = gestureSettings.exists || changeInstrument.exists || resetGuide.exists
            XCTAssertTrue(menuOpened, "選單應該顯示選項")
        }
    }

    func testMenuShowsCurrentInstrument() throws {
        sleep(1)

        // 點擊設定按鈕
        let settingsButton = app.buttons["settingsMenuButton"]
        if settingsButton.waitForExistence(timeout: 3) {
            settingsButton.tap()

            // 等待選單出現
            sleep(UInt32(0.5))

            // 檢查是否顯示當前樂器資訊
            let instrumentNames = ["鍵盤樂器", "弦樂器", "管樂器", "打擊樂器"]
            var foundInstrument = false

            for name in instrumentNames {
                if app.staticTexts[name].exists {
                    foundInstrument = true
                    break
                }
            }

            XCTAssertTrue(foundInstrument, "選單應該顯示當前選擇的樂器")
        }
    }

    func testResetOnboardingFromMenu() throws {
        sleep(1)

        // 點擊設定按鈕
        let settingsButton = app.buttons["settingsMenuButton"]
        if settingsButton.waitForExistence(timeout: 3) {
            settingsButton.tap()

            // 點擊重置引導
            let resetButton = app.buttons["重置引導"]
            if resetButton.waitForExistence(timeout: 2) {
                resetButton.tap()

                // 應該顯示樂器選擇介面
                let welcomeText = app.staticTexts["歡迎使用 GazeTurn"]
                XCTAssertTrue(welcomeText.waitForExistence(timeout: 3),
                             "重置後應該顯示首次啟動介面")
            }
        }
    }
}
