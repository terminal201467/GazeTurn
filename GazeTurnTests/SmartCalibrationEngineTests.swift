//
//  SmartCalibrationEngineTests.swift
//  GazeTurnTests
//
//  Created by Claude Code on 2024-11-21.
//

import XCTest
import Vision
import Combine
@testable import GazeTurn

@MainActor
class SmartCalibrationEngineTests: XCTestCase {

    var smartCalibrationEngine: SmartCalibrationEngine!
    var mockLearningEngine: MockGestureLearningEngine!
    var mockEnvironmentAnalyzer: MockEnvironmentAnalyzer!
    var cancellables: Set<AnyCancellable>!

    override func setUpWithError() throws {
        mockLearningEngine = MockGestureLearningEngine()
        mockEnvironmentAnalyzer = MockEnvironmentAnalyzer()
        smartCalibrationEngine = SmartCalibrationEngine(
            learningEngine: mockLearningEngine,
            environmentAnalyzer: mockEnvironmentAnalyzer
        )
        cancellables = Set<AnyCancellable>()

        // Clear UserDefaults for testing
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "SmartCalibrationHistory")
        defaults.removeObject(forKey: "ContextualThresholds")
    }

    override func tearDownWithError() throws {
        smartCalibrationEngine = nil
        mockLearningEngine = nil
        mockEnvironmentAnalyzer = nil
        cancellables = nil
    }

    // MARK: - Initialization Tests

    func testInitialization() throws {
        XCTAssertNotNil(smartCalibrationEngine)
        XCTAssertEqual(smartCalibrationEngine.calibrationStatus.count, 6)
        XCTAssertEqual(smartCalibrationEngine.currentAccuracy.count, 6)

        // Check initial status
        for status in smartCalibrationEngine.calibrationStatus.values {
            XCTAssertEqual(status, .notStarted)
        }

        for accuracy in smartCalibrationEngine.currentAccuracy.values {
            XCTAssertEqual(accuracy, 0.0)
        }
    }

    func testInitialCalibrationStatus() {
        let expectedGestureTypes = ["blink", "head_shake", "eyebrow_raise", "smile", "head_nod", "mouth_open"]

        for gestureType in expectedGestureTypes {
            XCTAssertEqual(smartCalibrationEngine.calibrationStatus[gestureType], .notStarted)
            XCTAssertEqual(smartCalibrationEngine.currentAccuracy[gestureType], 0.0)
        }
    }

    // MARK: - One-Shot Calibration Tests

    func testOneshotCalibrationWithGoodSamples() async throws {
        let context = createMockCalibrationContext()
        let samples = createMockGestureSamples(count: 5, baseThreshold: 0.6, variance: 0.05)

        let result = await smartCalibrationEngine.performOnesShotCalibration(
            for: "blink",
            context: context,
            samples: samples
        )

        XCTAssertEqual(result.gestureType, "blink")
        XCTAssertGreaterThan(result.confidence, 0.5)
        XCTAssertEqual(result.sampleSize, 5)
        XCTAssertTrue(result.isReliable)
        XCTAssertEqual(smartCalibrationEngine.calibrationStatus["blink"], .completed)
    }

    func testOneshotCalibrationWithPoorSamples() async throws {
        let context = createMockCalibrationContext()
        let samples = createMockGestureSamples(count: 2, baseThreshold: 0.6, variance: 0.3)

        let result = await smartCalibrationEngine.performOnesShotCalibration(
            for: "blink",
            context: context,
            samples: samples
        )

        XCTAssertEqual(result.gestureType, "blink")
        XCTAssertLessThan(result.confidence, 0.7)
        XCTAssertEqual(result.sampleSize, 2)
        XCTAssertFalse(result.isReliable)
        XCTAssertNotEqual(smartCalibrationEngine.calibrationStatus["blink"], .completed)
    }

    func testOneshotCalibrationContextualAdjustments() async throws {
        // Test poor lighting adjustment
        var context = createMockCalibrationContext(lightingQuality: .poor)
        let samples = createMockGestureSamples(count: 5, baseThreshold: 0.6, variance: 0.05)

        var result = await smartCalibrationEngine.performOnesShotCalibration(
            for: "blink",
            context: context,
            samples: samples
        )

        let poorLightingThreshold = result.recommendedThreshold

        // Test excellent lighting adjustment
        context = createMockCalibrationContext(lightingQuality: .excellent)
        result = await smartCalibrationEngine.performOnesShotCalibration(
            for: "head_shake",
            context: context,
            samples: samples
        )

        let excellentLightingThreshold = result.recommendedThreshold

        // Poor lighting should have higher threshold (less sensitive)
        XCTAssertGreaterThan(poorLightingThreshold, excellentLightingThreshold)
    }

    func testOneshotCalibrationDistanceAdjustments() async throws {
        // Test close distance
        var context = createMockCalibrationContext(userDistance: 30)
        let samples = createMockGestureSamples(count: 5, baseThreshold: 0.6, variance: 0.05)

        var result = await smartCalibrationEngine.performOnesShotCalibration(
            for: "blink",
            context: context,
            samples: samples
        )

        let closeDistanceThreshold = result.recommendedThreshold

        // Test far distance
        context = createMockCalibrationContext(userDistance: 80)
        result = await smartCalibrationEngine.performOnesShotCalibration(
            for: "head_shake",
            context: context,
            samples: samples
        )

        let farDistanceThreshold = result.recommendedThreshold

        // Far distance should have higher threshold (less sensitive)
        XCTAssertGreaterThan(farDistanceThreshold, closeDistanceThreshold)
    }

    func testOneshotCalibrationInstrumentSpecific() async throws {
        // Test vocal instrument with mouth_open gesture
        let vocalContext = createMockCalibrationContext(instrumentType: .vocal)
        let samples = createMockGestureSamples(count: 5, baseThreshold: 0.5, variance: 0.05)

        let vocalResult = await smartCalibrationEngine.performOnesShotCalibration(
            for: "mouth_open",
            context: vocalContext,
            samples: samples
        )

        // Test percussion instrument with head_nod gesture
        let percussionContext = createMockCalibrationContext(instrumentType: .percussion)
        let percussionResult = await smartCalibrationEngine.performOnesShotCalibration(
            for: "head_nod",
            context: percussionContext,
            samples: samples
        )

        // Vocal should have lower threshold for mouth_open (more sensitive)
        // Percussion should have lower threshold for head_nod (more sensitive)
        XCTAssertLessThan(vocalResult.recommendedThreshold, 0.5)
        XCTAssertLessThan(percussionResult.recommendedThreshold, 12.0)
    }

    // MARK: - Adaptive Threshold Tests

    func testGetAdaptiveThresholdExactMatch() {
        let context = createMockCalibrationContext()

        // Perform calibration to set a threshold
        let samples = createMockGestureSamples(count: 5, baseThreshold: 0.7, variance: 0.05)

        Task {
            let result = await smartCalibrationEngine.performOnesShotCalibration(
                for: "blink",
                context: context,
                samples: samples
            )

            // Test getting the same threshold back
            let adaptiveThreshold = smartCalibrationEngine.getAdaptiveThreshold(
                for: "blink",
                context: context
            )

            XCTAssertEqual(adaptiveThreshold, result.recommendedThreshold, accuracy: 0.1)
        }
    }

    func testGetAdaptiveThresholdFallbackToBase() {
        let context = createMockCalibrationContext()

        // Get threshold for uncalibrated gesture
        let threshold = smartCalibrationEngine.getAdaptiveThreshold(
            for: "blink",
            context: context
        )

        // Should return base threshold
        XCTAssertEqual(threshold, 0.6, accuracy: 0.1)
    }

    func testGetAdaptiveThresholdSimilarContext() async {
        // Set up initial context and calibration
        let initialContext = createMockCalibrationContext(
            instrumentType: .keyboard,
            userDistance: 50,
            lightingQuality: .good
        )

        let samples = createMockGestureSamples(count: 5, baseThreshold: 0.7, variance: 0.05)

        let result = await smartCalibrationEngine.performOnesShotCalibration(
            for: "blink",
            context: initialContext,
            samples: samples
        )

        // Test similar context (same instrument, similar distance, same lighting)
        let similarContext = createMockCalibrationContext(
            instrumentType: .keyboard,
            userDistance: 52,
            lightingQuality: .good
        )

        let adaptiveThreshold = smartCalibrationEngine.getAdaptiveThreshold(
            for: "blink",
            context: similarContext
        )

        // Should return similar threshold to the calibrated one
        XCTAssertEqual(adaptiveThreshold, result.recommendedThreshold, accuracy: 0.2)
    }

    // MARK: - Calibration Feedback Tests

    func testRecordCalibrationFeedbackTooSensitive() {
        let context = createMockCalibrationContext()

        smartCalibrationEngine.recordCalibrationFeedback(
            gestureType: "blink",
            feedback: .tooSensitive,
            context: context
        )

        let adjustedThreshold = smartCalibrationEngine.getAdaptiveThreshold(
            for: "blink",
            context: context
        )

        // Threshold should be higher (less sensitive) than base
        let baseThreshold = 0.6
        XCTAssertGreaterThan(adjustedThreshold, baseThreshold)
    }

    func testRecordCalibrationFeedbackTooInsensitive() {
        let context = createMockCalibrationContext()

        smartCalibrationEngine.recordCalibrationFeedback(
            gestureType: "blink",
            feedback: .tooInsensitive,
            context: context
        )

        let adjustedThreshold = smartCalibrationEngine.getAdaptiveThreshold(
            for: "blink",
            context: context
        )

        // Threshold should be lower (more sensitive) than base
        let baseThreshold = 0.6
        XCTAssertLessThan(adjustedThreshold, baseThreshold)
    }

    func testRecordCalibrationFeedbackPerfect() {
        let context = createMockCalibrationContext()

        smartCalibrationEngine.recordCalibrationFeedback(
            gestureType: "blink",
            feedback: .perfect,
            context: context
        )

        let adjustedThreshold = smartCalibrationEngine.getAdaptiveThreshold(
            for: "blink",
            context: context
        )

        // Threshold should remain close to base
        let baseThreshold = 0.6
        XCTAssertEqual(adjustedThreshold, baseThreshold, accuracy: 0.1)
    }

    func testMultipleFeedbackAccumulation() {
        let context = createMockCalibrationContext()

        // Give multiple feedback
        smartCalibrationEngine.recordCalibrationFeedback(
            gestureType: "blink",
            feedback: .tooSensitive,
            context: context
        )

        let firstThreshold = smartCalibrationEngine.getAdaptiveThreshold(
            for: "blink",
            context: context
        )

        smartCalibrationEngine.recordCalibrationFeedback(
            gestureType: "blink",
            feedback: .tooSensitive,
            context: context
        )

        let secondThreshold = smartCalibrationEngine.getAdaptiveThreshold(
            for: "blink",
            context: context
        )

        // Second threshold should be higher than first (more adjustments)
        XCTAssertGreaterThan(secondThreshold, firstThreshold)
    }

    // MARK: - Background Optimization Tests

    func testBackgroundOptimizationToggle() {
        XCTAssertFalse(smartCalibrationEngine.isBackgroundOptimizing)

        smartCalibrationEngine.startBackgroundOptimization()
        XCTAssertTrue(smartCalibrationEngine.isBackgroundOptimizing)

        // Wait for completion
        let expectation = XCTestExpectation(description: "Background optimization completes")
        smartCalibrationEngine.$isBackgroundOptimizing
            .dropFirst() // Skip initial value
            .sink { isOptimizing in
                if !isOptimizing {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 5.0)
        XCTAssertFalse(smartCalibrationEngine.isBackgroundOptimizing)
        XCTAssertNotNil(smartCalibrationEngine.lastOptimizationTime)
    }

    func testBackgroundOptimizationNotStartedWhenAlreadyRunning() {
        smartCalibrationEngine.startBackgroundOptimization()
        XCTAssertTrue(smartCalibrationEngine.isBackgroundOptimizing)

        // Try to start again - should not change state
        smartCalibrationEngine.startBackgroundOptimization()
        XCTAssertTrue(smartCalibrationEngine.isBackgroundOptimizing)
    }

    // MARK: - Contextual Recommendations Tests

    func testContextualRecommendationsPoorLighting() {
        let context = createMockCalibrationContext(lightingQuality: .poor)

        let recommendations = smartCalibrationEngine.getContextualRecommendations(for: context)

        XCTAssertTrue(recommendations.contains { $0.contains("照明環境") })
    }

    func testContextualRecommendationsTooClose() {
        let context = createMockCalibrationContext(userDistance: 25)

        let recommendations = smartCalibrationEngine.getContextualRecommendations(for: context)

        XCTAssertTrue(recommendations.contains { $0.contains("30-60 公分") })
    }

    func testContextualRecommendationsTooFar() {
        let context = createMockCalibrationContext(userDistance: 90)

        let recommendations = smartCalibrationEngine.getContextualRecommendations(for: context)

        XCTAssertTrue(recommendations.contains { $0.contains("離設備較遠") })
    }

    func testContextualRecommendationsUncalibratedGestures() {
        let context = createMockCalibrationContext()

        let recommendations = smartCalibrationEngine.getContextualRecommendations(for: context)

        // Should recommend calibration for uncalibrated gestures
        XCTAssertTrue(recommendations.contains { $0.contains("校準") })
    }

    func testContextualRecommendationsLowAccuracy() {
        let context = createMockCalibrationContext()

        // Simulate low accuracy for blink
        smartCalibrationEngine.currentAccuracy["blink"] = 0.5

        let recommendations = smartCalibrationEngine.getContextualRecommendations(for: context)

        XCTAssertTrue(recommendations.contains { $0.contains("準確度較低") })
    }

    // MARK: - Reset Calibration Tests

    func testResetSpecificGestureCalibration() async {
        let context = createMockCalibrationContext()
        let samples = createMockGestureSamples(count: 5, baseThreshold: 0.7, variance: 0.05)

        // Calibrate blink
        let _ = await smartCalibrationEngine.performOnesShotCalibration(
            for: "blink",
            context: context,
            samples: samples
        )

        XCTAssertEqual(smartCalibrationEngine.calibrationStatus["blink"], .completed)

        // Reset blink calibration
        smartCalibrationEngine.resetCalibration(for: "blink")

        XCTAssertEqual(smartCalibrationEngine.calibrationStatus["blink"], .notStarted)
        XCTAssertEqual(smartCalibrationEngine.currentAccuracy["blink"], 0.0)

        // Other gestures should remain unchanged
        XCTAssertEqual(smartCalibrationEngine.calibrationStatus["head_shake"], .notStarted)
    }

    func testResetAllCalibration() async {
        let context = createMockCalibrationContext()
        let samples = createMockGestureSamples(count: 5, baseThreshold: 0.7, variance: 0.05)

        // Calibrate multiple gestures
        let _ = await smartCalibrationEngine.performOnesShotCalibration(
            for: "blink",
            context: context,
            samples: samples
        )
        let _ = await smartCalibrationEngine.performOnesShotCalibration(
            for: "head_shake",
            context: context,
            samples: samples
        )

        // Reset all calibration
        smartCalibrationEngine.resetCalibration()

        // All should be reset
        for status in smartCalibrationEngine.calibrationStatus.values {
            XCTAssertEqual(status, .notStarted)
        }

        for accuracy in smartCalibrationEngine.currentAccuracy.values {
            XCTAssertEqual(accuracy, 0.0)
        }
    }

    // MARK: - Performance Tests

    func testOneshotCalibrationPerformance() {
        let context = createMockCalibrationContext()
        let samples = createMockGestureSamples(count: 10, baseThreshold: 0.6, variance: 0.05)

        measure {
            Task {
                let _ = await smartCalibrationEngine.performOnesShotCalibration(
                    for: "blink",
                    context: context,
                    samples: samples
                )
            }
        }
    }

    func testGetAdaptiveThresholdPerformance() {
        let context = createMockCalibrationContext()

        measure {
            for _ in 0..<100 {
                let _ = smartCalibrationEngine.getAdaptiveThreshold(
                    for: "blink",
                    context: context
                )
            }
        }
    }

    func testFeedbackRecordingPerformance() {
        let context = createMockCalibrationContext()

        measure {
            for i in 0..<50 {
                let feedback: CalibrationFeedback = i % 2 == 0 ? .tooSensitive : .tooInsensitive
                smartCalibrationEngine.recordCalibrationFeedback(
                    gestureType: "blink",
                    feedback: feedback,
                    context: context
                )
            }
        }
    }

    // MARK: - Thread Safety Tests

    func testConcurrentCalibrationRequests() async {
        let context = createMockCalibrationContext()
        let samples = createMockGestureSamples(count: 5, baseThreshold: 0.6, variance: 0.05)

        // Run multiple calibrations concurrently
        async let result1 = smartCalibrationEngine.performOnesShotCalibration(
            for: "blink",
            context: context,
            samples: samples
        )

        async let result2 = smartCalibrationEngine.performOnesShotCalibration(
            for: "head_shake",
            context: context,
            samples: samples
        )

        let (r1, r2) = await (result1, result2)

        XCTAssertEqual(r1.gestureType, "blink")
        XCTAssertEqual(r2.gestureType, "head_shake")
        XCTAssertTrue(r1.isReliable)
        XCTAssertTrue(r2.isReliable)
    }

    func testConcurrentFeedbackRecording() {
        let context = createMockCalibrationContext()

        // Record feedback concurrently
        let queue = DispatchQueue(label: "test.concurrent", attributes: .concurrent)
        let expectation = XCTestExpectation(description: "Concurrent feedback recording")
        expectation.expectedFulfillmentCount = 10

        for i in 0..<10 {
            queue.async {
                let feedback: CalibrationFeedback = i % 2 == 0 ? .tooSensitive : .perfect
                Task { @MainActor in
                    self.smartCalibrationEngine.recordCalibrationFeedback(
                        gestureType: "blink",
                        feedback: feedback,
                        context: context
                    )
                    expectation.fulfill()
                }
            }
        }

        wait(for: [expectation], timeout: 5.0)

        // Should complete without crashes
        XCTAssertNotNil(smartCalibrationEngine)
    }

    // MARK: - Integration Tests

    func testFullCalibrationWorkflow() async {
        let context = createMockCalibrationContext()

        // 1. Initial state
        XCTAssertEqual(smartCalibrationEngine.calibrationStatus["blink"], .notStarted)

        // 2. One-shot calibration
        let samples = createMockGestureSamples(count: 5, baseThreshold: 0.6, variance: 0.05)
        let result = await smartCalibrationEngine.performOnesShotCalibration(
            for: "blink",
            context: context,
            samples: samples
        )

        XCTAssertTrue(result.isReliable)
        XCTAssertEqual(smartCalibrationEngine.calibrationStatus["blink"], .completed)

        // 3. Get adaptive threshold
        let threshold1 = smartCalibrationEngine.getAdaptiveThreshold(for: "blink", context: context)
        XCTAssertEqual(threshold1, result.recommendedThreshold, accuracy: 0.1)

        // 4. Provide feedback
        smartCalibrationEngine.recordCalibrationFeedback(
            gestureType: "blink",
            feedback: .tooSensitive,
            context: context
        )

        // 5. Verify adjustment
        let threshold2 = smartCalibrationEngine.getAdaptiveThreshold(for: "blink", context: context)
        XCTAssertGreaterThan(threshold2, threshold1)

        // 6. Background optimization
        smartCalibrationEngine.startBackgroundOptimization()
        XCTAssertTrue(smartCalibrationEngine.isBackgroundOptimizing)
    }

    func testMultiContextCalibration() async {
        // Test different contexts for same gesture
        let context1 = createMockCalibrationContext(lightingQuality: .poor)
        let context2 = createMockCalibrationContext(lightingQuality: .excellent)

        let samples = createMockGestureSamples(count: 5, baseThreshold: 0.6, variance: 0.05)

        // Calibrate for both contexts
        let result1 = await smartCalibrationEngine.performOnesShotCalibration(
            for: "blink",
            context: context1,
            samples: samples
        )

        let result2 = await smartCalibrationEngine.performOnesShotCalibration(
            for: "blink",
            context: context2,
            samples: samples
        )

        // Should have different thresholds due to different lighting
        XCTAssertNotEqual(result1.recommendedThreshold, result2.recommendedThreshold, accuracy: 0.01)

        // Verify we can retrieve context-specific thresholds
        let threshold1 = smartCalibrationEngine.getAdaptiveThreshold(for: "blink", context: context1)
        let threshold2 = smartCalibrationEngine.getAdaptiveThreshold(for: "blink", context: context2)

        XCTAssertEqual(threshold1, result1.recommendedThreshold, accuracy: 0.1)
        XCTAssertEqual(threshold2, result2.recommendedThreshold, accuracy: 0.1)
    }

    // MARK: - Helper Methods

    private func createMockCalibrationContext(
        instrumentType: InstrumentType = .keyboard,
        userDistance: Double = 50,
        lightingQuality: LightingQuality = .good
    ) -> CalibrationContext {
        let environmentalCondition = EnvironmentalCondition(
            lighting: lightingQuality,
            noise: .low,
            userDistance: UserDistanceRange.optimal,
            timestamp: Date(),
            confidence: 0.8
        )

        return CalibrationContext(
            environmentalCondition: environmentalCondition,
            instrumentType: instrumentType,
            userDistance: userDistance,
            lightingQuality: lightingQuality,
            timestamp: Date()
        )
    }

    private func createMockGestureSamples(
        count: Int,
        baseThreshold: Double,
        variance: Double
    ) -> [GestureTrainingData] {
        var samples: [GestureTrainingData] = []

        for i in 0..<count {
            let noise = Double.random(in: -variance...variance)
            let threshold = max(0.1, min(1.0, baseThreshold + noise))

            let sample = GestureTrainingData(
                gestureType: "blink",
                threshold: threshold,
                confidence: 0.9,
                timestamp: Date().addingTimeInterval(-Double(i))
            )
            samples.append(sample)
        }

        return samples
    }
}

// MARK: - Mock Classes

class MockGestureLearningEngine: GestureLearningEngine {
    override init() {
        // Override with mock behavior if needed
        super.init()
    }
}

class MockEnvironmentAnalyzer: EnvironmentAnalyzer {
    override init() {
        // Override with mock behavior if needed
        super.init()
    }
}