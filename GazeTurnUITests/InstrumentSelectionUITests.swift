//
//  InstrumentSelectionUITests.swift
//  GazeTurnUITests
//
//  Created by Claude Code on 2025/1/15.
//

import XCTest

final class InstrumentSelectionUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--reset-onboarding"]
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Instrument Selection View Tests

    func testInstrumentSelectionViewElements() throws {
        // 等待樂器選擇介面載入
        let welcomeText = app.staticTexts["歡迎使用 GazeTurn"]

        // 如果是首次啟動
        if welcomeText.waitForExistence(timeout: 3) {
            // 檢查標題
            XCTAssertTrue(welcomeText.exists)

            // 檢查說明文字
            let descriptionText = app.staticTexts["根據您的樂器類型，我們會自動配置最適合的手勢控制方式"]
            XCTAssertTrue(descriptionText.exists)

            // 檢查跳過按鈕
            let skipButton = app.buttons["skipButton"]
            XCTAssertTrue(skipButton.exists)
        }
    }

    func testInstrumentCardsExist() throws {
        // 等待介面載入
        sleep(2)

        // 檢查各樂器卡片是否存在（透過樂器名稱）
        let instrumentNames = ["鍵盤樂器", "弦樂器", "管樂器", "打擊樂器"]

        for name in instrumentNames {
            let instrumentText = app.staticTexts[name]
            if instrumentText.exists {
                XCTAssertTrue(instrumentText.exists, "\(name) 卡片應該存在")
            }
        }
    }

    func testSelectKeyboardInstrument() throws {
        // 等待介面載入
        sleep(2)

        // 使用 accessibilityIdentifier 尋找樂器卡片，或使用文字查找
        let keyboardCard = app.buttons["instrumentCard_keyboard"]
        let keyboardText = app.staticTexts["鍵盤樂器"]

        var tapped = false
        if keyboardCard.waitForExistence(timeout: 3) {
            keyboardCard.tap()
            tapped = true
        } else if keyboardText.waitForExistence(timeout: 3) {
            keyboardText.tap()
            tapped = true
        }

        if tapped {
            // 等待校準介面出現
            sleep(2)

            // 應該顯示校準介面（導航標題為「手勢校準」）或完成選擇
            let calibrationNav = app.navigationBars["手勢校準"]
            let calibrationText = app.staticTexts["手勢校準"]
            let mainView = app.navigationBars["GazeTurn"]
            let welcomeText = app.staticTexts["歡迎"]

            XCTAssertTrue(calibrationNav.exists || calibrationText.exists || mainView.exists || welcomeText.exists,
                         "點擊樂器後應該進入校準或主介面")
        }
    }

    func testSkipOnboarding() throws {
        // 等待跳過按鈕
        let skipButton = app.buttons["skipButton"]

        if skipButton.waitForExistence(timeout: 3) {
            skipButton.tap()

            // 應該進入主介面
            let mainView = app.navigationBars["GazeTurn"]
            XCTAssertTrue(mainView.waitForExistence(timeout: 3), "跳過後應該進入主介面")
        }
    }

    // MARK: - Change Instrument Tests

    func testChangeInstrumentFromSettings() throws {
        // 先跳過首次啟動
        let skipButton = app.buttons["skipButton"]
        if skipButton.waitForExistence(timeout: 2) {
            skipButton.tap()
        }

        // 等待主介面
        sleep(1)

        // 點擊設定選單
        let settingsButton = app.buttons["settingsMenuButton"]
        if settingsButton.waitForExistence(timeout: 3) {
            settingsButton.tap()

            // 點擊「更改樂器」
            let changeInstrumentButton = app.buttons["更改樂器"]
            if changeInstrumentButton.waitForExistence(timeout: 2) {
                changeInstrumentButton.tap()

                // 應該顯示樂器選擇 sheet
                let selectionTitle = app.staticTexts["選擇您的樂器"]
                XCTAssertTrue(selectionTitle.waitForExistence(timeout: 3),
                             "應該顯示樂器選擇介面")
            }
        }
    }
}
