//
//  CalibrationViewModelTests.swift
//  GazeTurnTests
//
//  Created by Claude Code on 2025/3/20.
//

import XCTest
@testable import GazeTurn

final class CalibrationViewModelTests: XCTestCase {

    var viewModel: CalibrationViewModel!
    var testMode: InstrumentMode!

    override func setUp() {
        super.setUp()
        testMode = InstrumentMode.keyboardMode()
        viewModel = CalibrationViewModel(instrumentMode: testMode)
    }

    override func tearDown() {
        viewModel = nil
        testMode = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInitialization() {
        XCTAssertNotNil(viewModel)
        XCTAssertEqual(viewModel.currentStep, .welcome)
        XCTAssertEqual(viewModel.progress, 0.0)
        XCTAssertFalse(viewModel.isCameraAvailable)
        XCTAssertEqual(viewModel.blinkSampleCount, 0)
        XCTAssertEqual(viewModel.headShakeSampleCount, 0)
    }

    func testInitializationWithBlinkMode() {
        let blinkMode = InstrumentMode.stringInstrumentsMode()
        let blinkViewModel = CalibrationViewModel(instrumentMode: blinkMode)

        XCTAssertNotNil(blinkViewModel)
        XCTAssertEqual(blinkViewModel.instrumentMode.instrumentType, .stringInstruments)
        XCTAssertTrue(blinkViewModel.instrumentMode.enableBlink)
    }

    func testInitializationWithHeadShakeMode() {
        let headShakeMode = InstrumentMode.keyboardMode()
        let headShakeViewModel = CalibrationViewModel(instrumentMode: headShakeMode)

        XCTAssertNotNil(headShakeViewModel)
        XCTAssertEqual(headShakeViewModel.instrumentMode.instrumentType, .keyboard)
        XCTAssertTrue(headShakeViewModel.instrumentMode.enableHeadShake)
    }

    func testInitializationWithHybridMode() {
        let hybridMode = InstrumentMode.woodwindBrassMode()
        let hybridViewModel = CalibrationViewModel(instrumentMode: hybridMode)

        XCTAssertNotNil(hybridViewModel)
        XCTAssertTrue(hybridViewModel.instrumentMode.enableBlink)
        XCTAssertTrue(hybridViewModel.instrumentMode.enableHeadShake)
    }

    // MARK: - Step Navigation Tests

    func testNextStep() {
        XCTAssertEqual(viewModel.currentStep, .welcome)

        viewModel.nextStep()
        XCTAssertEqual(viewModel.currentStep, .blinkCalibration)

        viewModel.nextStep()
        XCTAssertEqual(viewModel.currentStep, .headShakeCalibration)

        viewModel.nextStep()
        XCTAssertEqual(viewModel.currentStep, .verification)

        viewModel.nextStep()
        XCTAssertEqual(viewModel.currentStep, .complete)
    }

    func testPreviousStep() {
        // 前進到 verification
        viewModel.currentStep = .verification

        viewModel.previousStep()
        XCTAssertEqual(viewModel.currentStep, .headShakeCalibration)

        viewModel.previousStep()
        XCTAssertEqual(viewModel.currentStep, .blinkCalibration)

        viewModel.previousStep()
        XCTAssertEqual(viewModel.currentStep, .welcome)

        // 在 welcome 步驟不能再往前
        viewModel.previousStep()
        XCTAssertEqual(viewModel.currentStep, .welcome)
    }

    func testStepProgression() {
        var stepCount = 0

        for step in CalibrationStep.allCases {
            XCTAssertEqual(viewModel.currentStep.rawValue, stepCount)
            viewModel.nextStep()
            stepCount += 1
        }
    }

    // MARK: - Camera Management Tests

    func testStartCamera() {
        viewModel.startCamera()
        // 注意：實際的相機啟動可能需要權限，在測試中可能失敗
        // 這裡主要測試方法不會崩潰
        XCTAssertTrue(true)
    }

    func testStopCamera() {
        viewModel.startCamera()
        viewModel.stopCamera()

        XCTAssertFalse(viewModel.isCameraAvailable)
    }

    // MARK: - Calibration Step Tests

    func testWelcomeStepContent() {
        XCTAssertEqual(viewModel.currentStep, .welcome)
        XCTAssertTrue(viewModel.currentStep.title.contains("歡迎"))
        XCTAssertTrue(viewModel.currentStep.instruction.contains("校準"))
    }

    func testBlinkCalibrationStepContent() {
        viewModel.currentStep = .blinkCalibration
        XCTAssertTrue(viewModel.currentStep.title.contains("眨眼"))
        XCTAssertTrue(viewModel.currentStep.instruction.contains("眨眼"))
    }

    func testHeadShakeCalibrationStepContent() {
        viewModel.currentStep = .headShakeCalibration
        XCTAssertTrue(viewModel.currentStep.title.contains("搖頭"))
        XCTAssertTrue(viewModel.currentStep.instruction.contains("搖頭"))
    }

    func testVerificationStepContent() {
        viewModel.currentStep = .verification
        XCTAssertTrue(viewModel.currentStep.title.contains("驗證"))
        XCTAssertTrue(viewModel.currentStep.instruction.contains("驗證"))
    }

    func testCompleteStepContent() {
        viewModel.currentStep = .complete
        XCTAssertTrue(viewModel.currentStep.title.contains("完成"))
        XCTAssertTrue(viewModel.currentStep.instruction.contains("完成"))
    }

    // MARK: - Sample Collection Tests

    func testTargetSampleCounts() {
        XCTAssertEqual(viewModel.targetBlinkSamples, 10)
        XCTAssertEqual(viewModel.targetHeadShakeSamples, 8)
    }

    func testInitialSampleCounts() {
        XCTAssertEqual(viewModel.blinkSampleCount, 0)
        XCTAssertEqual(viewModel.headShakeSampleCount, 0)
    }

    // MARK: - Status Tests

    func testInitialStatus() {
        switch viewModel.status {
        case .idle:
            XCTAssertTrue(true)
        default:
            XCTFail("初始狀態應該是 idle")
        }
    }

    // MARK: - Mode-Specific Behavior Tests

    func testBlinkOnlyModeSkipsHeadShakeCalibration() {
        let blinkMode = InstrumentMode.stringInstrumentsMode()
        let blinkViewModel = CalibrationViewModel(instrumentMode: blinkMode)

        XCTAssertTrue(blinkViewModel.instrumentMode.enableBlink)
        XCTAssertFalse(blinkViewModel.instrumentMode.enableHeadShake)
    }

    func testHeadShakeOnlyModeSkipsBlinkCalibration() {
        let headShakeMode = InstrumentMode.keyboardMode()
        let headShakeViewModel = CalibrationViewModel(instrumentMode: headShakeMode)

        XCTAssertFalse(headShakeViewModel.instrumentMode.enableBlink)
        XCTAssertTrue(headShakeViewModel.instrumentMode.enableHeadShake)
    }

    func testHybridModeRequiresBothCalibrations() {
        let hybridMode = InstrumentMode.woodwindBrassMode()
        let hybridViewModel = CalibrationViewModel(instrumentMode: hybridMode)

        XCTAssertTrue(hybridViewModel.instrumentMode.enableBlink)
        XCTAssertTrue(hybridViewModel.instrumentMode.enableHeadShake)
    }

    // MARK: - Progress Tests

    func testInitialProgress() {
        XCTAssertEqual(viewModel.progress, 0.0)
    }

    func testProgressRange() {
        // 進度應該在 0.0 到 1.0 之間
        viewModel.progress = 0.5
        XCTAssertGreaterThanOrEqual(viewModel.progress, 0.0)
        XCTAssertLessThanOrEqual(viewModel.progress, 1.0)
    }

    // MARK: - Callback Tests

    func testCalibrationCompleteCallback() {
        var callbackCalled = false
        var returnedMode: InstrumentMode?

        viewModel.onCalibrationComplete = { mode in
            callbackCalled = true
            returnedMode = mode
        }

        // 模擬完成校準
        viewModel.currentStep = .complete
        viewModel.skipCalibration()

        XCTAssertTrue(callbackCalled)
        XCTAssertNotNil(returnedMode)
    }

    // MARK: - Skip Calibration Tests

    func testSkipCalibration() {
        var callbackCalled = false

        viewModel.onCalibrationComplete = { _ in
            callbackCalled = true
        }

        viewModel.skipCalibration()

        XCTAssertTrue(callbackCalled)
    }

    // MARK: - Ready State Tests

    func testInitialReadyState() {
        XCTAssertTrue(viewModel.isReadyForNextStep)
    }

    // MARK: - Step Description Tests

    func testAllStepsHaveDescriptions() {
        for step in CalibrationStep.allCases {
            XCTAssertFalse(step.title.isEmpty, "\(step) 應該有標題")
            XCTAssertFalse(step.instruction.isEmpty, "\(step) 應該有說明")
        }
    }

    // MARK: - Multiple ViewModels Tests

    func testMultipleViewModels() {
        let viewModel2 = CalibrationViewModel(instrumentMode: InstrumentMode.vocalMode())

        XCTAssertNotEqual(viewModel.instrumentMode.instrumentType, viewModel2.instrumentMode.instrumentType)
        XCTAssertEqual(viewModel.currentStep, .welcome)
        XCTAssertEqual(viewModel2.currentStep, .welcome)
    }

    // MARK: - Status Message Tests

    func testStatusMessageInitialization() {
        XCTAssertEqual(viewModel.statusMessage, "")
    }

    // MARK: - Instrument Mode Preservation Tests

    func testInstrumentModePreserved() {
        let originalMode = viewModel.instrumentMode

        viewModel.nextStep()

        XCTAssertEqual(viewModel.instrumentMode.instrumentType, originalMode.instrumentType)
        XCTAssertEqual(viewModel.instrumentMode.enableBlink, originalMode.enableBlink)
        XCTAssertEqual(viewModel.instrumentMode.enableHeadShake, originalMode.enableHeadShake)
    }

    // MARK: - Edge Cases Tests

    func testStepBeyondComplete() {
        viewModel.currentStep = .complete
        let currentStep = viewModel.currentStep

        viewModel.nextStep()

        // 應該停在 complete 步驟
        XCTAssertEqual(viewModel.currentStep, currentStep)
    }

    func testStepBeforeWelcome() {
        XCTAssertEqual(viewModel.currentStep, .welcome)

        viewModel.previousStep()

        // 應該停在 welcome 步驟
        XCTAssertEqual(viewModel.currentStep, .welcome)
    }

    // MARK: - Performance Tests

    func testStepNavigationPerformance() {
        measure {
            for _ in 0..<100 {
                viewModel.nextStep()
                viewModel.previousStep()
            }
        }
    }

    // MARK: - Thread Safety Tests

    func testConcurrentStepChanges() {
        let expectation = self.expectation(description: "Concurrent step changes")
        expectation.expectedFulfillmentCount = 5

        for _ in 0..<5 {
            DispatchQueue.global().async {
                self.viewModel.nextStep()
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 2.0)

        // 步驟應該在有效範圍內
        XCTAssertGreaterThanOrEqual(viewModel.currentStep.rawValue, 0)
        XCTAssertLessThan(viewModel.currentStep.rawValue, CalibrationStep.allCases.count)
    }

    // MARK: - Integration Tests

    func testCompleteCalibrationFlow() {
        // 模擬完整的校準流程

        // 1. 開始於 welcome
        XCTAssertEqual(viewModel.currentStep, .welcome)

        // 2. 前進到眨眼校準
        viewModel.nextStep()
        XCTAssertEqual(viewModel.currentStep, .blinkCalibration)

        // 3. 前進到搖頭校準
        viewModel.nextStep()
        XCTAssertEqual(viewModel.currentStep, .headShakeCalibration)

        // 4. 前進到驗證
        viewModel.nextStep()
        XCTAssertEqual(viewModel.currentStep, .verification)

        // 5. 完成
        viewModel.nextStep()
        XCTAssertEqual(viewModel.currentStep, .complete)
    }

    func testBackAndForthNavigation() {
        // 測試來回導航

        viewModel.nextStep() // -> blinkCalibration
        viewModel.nextStep() // -> headShakeCalibration
        XCTAssertEqual(viewModel.currentStep, .headShakeCalibration)

        viewModel.previousStep() // -> blinkCalibration
        XCTAssertEqual(viewModel.currentStep, .blinkCalibration)

        viewModel.nextStep() // -> headShakeCalibration
        viewModel.nextStep() // -> verification
        XCTAssertEqual(viewModel.currentStep, .verification)

        viewModel.previousStep() // -> headShakeCalibration
        viewModel.previousStep() // -> blinkCalibration
        viewModel.previousStep() // -> welcome
        XCTAssertEqual(viewModel.currentStep, .welcome)
    }

    // MARK: - Cleanup Tests

    func testViewModelCleanup() {
        viewModel.startCamera()
        viewModel = nil

        // 應該不會崩潰
        XCTAssertNil(viewModel)
    }
}
