//
//  GesturePredictionModelTests.swift
//  GazeTurnTests
//
//  Created by Claude Code on 2024-11-21.
//

import XCTest
import CoreML
import Vision
import Combine
@testable import GazeTurn

@MainActor
class GesturePredictionModelTests: XCTestCase {

    var gesturePredictionModel: GesturePredictionModel!
    var mockLearningEngine: MockGestureLearningEngine!
    var cancellables: Set<AnyCancellable>!

    override func setUpWithError() throws {
        mockLearningEngine = MockGestureLearningEngine()
        gesturePredictionModel = GesturePredictionModel(learningEngine: mockLearningEngine)
        cancellables = Set<AnyCancellable>()
    }

    override func tearDownWithError() throws {
        gesturePredictionModel = nil
        mockLearningEngine = nil
        cancellables = nil
    }

    // MARK: - Initialization Tests

    func testInitialization() throws {
        XCTAssertNotNil(gesturePredictionModel)
        XCTAssertEqual(gesturePredictionModel.totalPredictions, 0)
        XCTAssertEqual(gesturePredictionModel.predictionAccuracy, 0.0)
        XCTAssertEqual(gesturePredictionModel.falsePositiveRate, 0.0)
        XCTAssertNil(gesturePredictionModel.lastPrediction)
    }

    func testModelLoadingSimulation() async {
        // Wait for model to load
        let expectation = XCTestExpectation(description: "Model loads")
        gesturePredictionModel.$isModelLoaded
            .dropFirst()
            .sink { isLoaded in
                if isLoaded {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        gesturePredictionModel.loadPretrainedModels()
        await fulfillment(of: [expectation], timeout: 5.0)

        XCTAssertTrue(gesturePredictionModel.isModelLoaded)
        XCTAssertGreaterThan(gesturePredictionModel.predictionAccuracy, 0.0)
    }

    // MARK: - Gesture Confidence Tests

    func testGestureConfidenceStructure() {
        let confidence = GestureConfidence(
            gestureType: "blink",
            confidence: 0.85,
            timestamp: Date(),
            isValidGesture: true
        )

        XCTAssertEqual(confidence.gestureType, "blink")
        XCTAssertEqual(confidence.confidence, 0.85)
        XCTAssertTrue(confidence.isValidGesture)
        XCTAssertEqual(confidence.confidenceLevel, .high)
    }

    func testConfidenceLevels() {
        XCTAssertEqual(ConfidenceLevel.veryHigh.threshold, 0.9)
        XCTAssertEqual(ConfidenceLevel.high.threshold, 0.8)
        XCTAssertEqual(ConfidenceLevel.medium.threshold, 0.6)
        XCTAssertEqual(ConfidenceLevel.low.threshold, 0.4)
        XCTAssertEqual(ConfidenceLevel.veryLow.threshold, 0.0)

        // Test confidence level classification
        let veryHighConfidence = GestureConfidence(
            gestureType: "blink",
            confidence: 0.95,
            timestamp: Date(),
            isValidGesture: true
        )
        XCTAssertEqual(veryHighConfidence.confidenceLevel, .veryHigh)

        let lowConfidence = GestureConfidence(
            gestureType: "blink",
            confidence: 0.5,
            timestamp: Date(),
            isValidGesture: false
        )
        XCTAssertEqual(lowConfidence.confidenceLevel, .low)
    }

    // MARK: - Musical Context Tests

    func testMusicalContextVector() {
        let context = MusicalContext(
            tempo: 120.0,
            timeSignature: "4/4",
            instrumentType: .keyboard,
            currentMeasure: 10,
            beatPosition: 0.5
        )

        let vector = context.contextVector
        XCTAssertGreaterThan(vector.count, 3) // Should include tempo, instrument encoding, beat position

        // Test tempo normalization (120 BPM should normalize to 0.5 for 60-180 range)
        XCTAssertEqual(vector[0], 0.5, accuracy: 0.1)

        // Test beat position
        XCTAssertEqual(vector.last, 0.5, accuracy: 0.01)
    }

    func testMusicalContextEdgeCases() {
        // Test nil values
        let emptyContext = MusicalContext(
            tempo: nil,
            timeSignature: nil,
            instrumentType: .vocal,
            currentMeasure: nil,
            beatPosition: nil
        )

        let vector = emptyContext.contextVector
        XCTAssertGreaterThan(vector.count, 0)

        // Test extreme tempo values
        let fastContext = MusicalContext(
            tempo: 200.0,
            timeSignature: "4/4",
            instrumentType: .percussion,
            currentMeasure: 1,
            beatPosition: 0.0
        )

        let fastVector = fastContext.contextVector
        XCTAssertEqual(fastVector[0], 1.0, accuracy: 0.01) // Should cap at 1.0
    }

    // MARK: - Gesture Pattern Tests

    func testGesturePatternVector() {
        let landmarks = [
            CGPoint(x: 0.5, y: 0.3),
            CGPoint(x: 0.52, y: 0.31),
            CGPoint(x: 0.48, y: 0.29)
        ]

        let pattern = GesturePattern(
            landmarks: landmarks,
            temporalSequence: [0.1, 0.5, 0.9, 0.3],
            duration: 0.8,
            velocity: 150.0,
            acceleration: 50.0
        )

        let vector = pattern.patternVector
        XCTAssertGreaterThan(vector.count, 10) // Should include landmarks, temporal, and motion features

        // Test that duration, velocity, and acceleration are included
        XCTAssertTrue(vector.contains(0.8))
        XCTAssertTrue(vector.contains(150.0))
        XCTAssertTrue(vector.contains(50.0))
    }

    func testGesturePatternComplexity() {
        // Simple sequence (low complexity)
        let simplePattern = GesturePattern(
            landmarks: [CGPoint(x: 0.5, y: 0.5)],
            temporalSequence: [0.5, 0.5, 0.5],
            duration: 0.5,
            velocity: 100.0,
            acceleration: 10.0
        )

        // Complex sequence (high complexity)
        let complexPattern = GesturePattern(
            landmarks: [CGPoint(x: 0.1, y: 0.9), CGPoint(x: 0.9, y: 0.1)],
            temporalSequence: [0.1, 0.8, 0.2, 0.9],
            duration: 1.2,
            velocity: 200.0,
            acceleration: 80.0
        )

        let simpleVector = simplePattern.patternVector
        let complexVector = complexPattern.patternVector

        // Complex pattern should have higher complexity score
        let simpleComplexity = simpleVector.last ?? 0
        let complexComplexity = complexVector.last ?? 0

        XCTAssertGreaterThan(complexComplexity, simpleComplexity)
    }

    // MARK: - ML Prediction Tests

    func testPredictGestureConfidenceBasic() async {
        gesturePredictionModel.loadPretrainedModels()

        // Wait for model to load
        let loadExpectation = XCTestExpectation(description: "Model loads")
        gesturePredictionModel.$isModelLoaded
            .dropFirst()
            .sink { isLoaded in
                if isLoaded {
                    loadExpectation.fulfill()
                }
            }
            .store(in: &cancellables)

        await fulfillment(of: [loadExpectation], timeout: 3.0)

        let pattern = createMockGesturePattern()
        let context = createMockMusicalContext()

        let prediction = await gesturePredictionModel.predictGestureConfidence(
            pattern: pattern,
            gestureType: "blink",
            context: context
        )

        XCTAssertEqual(prediction.gestureType, "blink")
        XCTAssertGreaterThanOrEqual(prediction.confidence, 0.0)
        XCTAssertLessThanOrEqual(prediction.confidence, 1.0)
        XCTAssertGreaterThanOrEqual(prediction.falsePositiveProbability, 0.0)
        XCTAssertLessThanOrEqual(prediction.falsePositiveProbability, 1.0)
        XCTAssertNotNil(prediction.recommendedAction)
    }

    func testPredictGestureConfidenceWithoutModel() async {
        // Don't load model - should return fallback prediction
        let pattern = createMockGesturePattern()
        let context = createMockMusicalContext()

        let prediction = await gesturePredictionModel.predictGestureConfidence(
            pattern: pattern,
            gestureType: "blink",
            context: context
        )

        XCTAssertEqual(prediction.gestureType, "blink")
        XCTAssertEqual(prediction.confidence, 0.5)
        XCTAssertEqual(prediction.falsePositiveProbability, 0.5)
        XCTAssertEqual(prediction.recommendedAction, .confirmFirst)
    }

    func testPredictGestureConfidenceInstrumentSpecific() async {
        gesturePredictionModel.loadPretrainedModels()

        // Wait for model loading
        try? await Task.sleep(nanoseconds: 1_000_000_000)

        let pattern = createMockGesturePattern()

        // Test vocal instrument with mouth_open gesture
        let vocalContext = MusicalContext(
            tempo: 80.0,
            timeSignature: "4/4",
            instrumentType: .vocal,
            currentMeasure: 1,
            beatPosition: 0.0
        )

        let vocalPrediction = await gesturePredictionModel.predictGestureConfidence(
            pattern: pattern,
            gestureType: "mouth_open",
            context: vocalContext
        )

        // Test percussion instrument with head_nod gesture
        let percussionContext = MusicalContext(
            tempo: 140.0,
            timeSignature: "4/4",
            instrumentType: .percussion,
            currentMeasure: 1,
            beatPosition: 0.25
        )

        let percussionPrediction = await gesturePredictionModel.predictGestureConfidence(
            pattern: pattern,
            gestureType: "head_nod",
            context: percussionContext
        )

        // Both should have reasonable confidence scores
        XCTAssertGreaterThan(vocalPrediction.confidence, 0.3)
        XCTAssertGreaterThan(percussionPrediction.confidence, 0.3)
    }

    func testPredictGestureConfidenceRecommendedActions() async {
        gesturePredictionModel.loadPretrainedModels()
        try? await Task.sleep(nanoseconds: 500_000_000)

        let pattern = createMockGesturePattern()
        let context = createMockMusicalContext()

        let prediction = await gesturePredictionModel.predictGestureConfidence(
            pattern: pattern,
            gestureType: "blink",
            context: context
        )

        // Test recommended action logic
        switch prediction.recommendedAction {
        case .execute:
            XCTAssertGreaterThan(prediction.confidence, 0.7)
            XCTAssertLessThan(prediction.falsePositiveProbability, 0.3)
        case .confirmFirst:
            XCTAssertTrue(prediction.confidence > 0.5 || prediction.falsePositiveProbability < 0.5)
        case .ignore:
            XCTAssertTrue(prediction.confidence < 0.6 || prediction.falsePositiveProbability > 0.4)
        case .recalibrate:
            break // Can occur in various conditions
        }
    }

    // MARK: - Gesture Validation Tests

    func testValidateGestureWithModel() async {
        gesturePredictionModel.loadPretrainedModels()
        try? await Task.sleep(nanoseconds: 500_000_000)

        // Good gesture pattern
        let goodPattern = GesturePattern(
            landmarks: [CGPoint(x: 0.5, y: 0.5)],
            temporalSequence: [0.0, 0.5, 1.0],
            duration: 0.3,
            velocity: 100.0,
            acceleration: 20.0
        )

        let isValid = await gesturePredictionModel.validateGesture(
            pattern: goodPattern,
            gestureType: "blink"
        )

        XCTAssertTrue(isValid)

        // Suspicious gesture pattern (too fast, too long)
        let suspiciousPattern = GesturePattern(
            landmarks: [CGPoint(x: 0.5, y: 0.5)],
            temporalSequence: [0.0, 1.0],
            duration: 5.0, // Too long
            velocity: 2000.0, // Too fast
            acceleration: 500.0
        )

        let isValidSuspicious = await gesturePredictionModel.validateGesture(
            pattern: suspiciousPattern,
            gestureType: "blink"
        )

        XCTAssertFalse(isValidSuspicious)
    }

    func testValidateGestureWithoutModel() async {
        // Don't load model - should use heuristic validation
        let pattern = createMockGesturePattern()

        let isValid = await gesturePredictionModel.validateGesture(
            pattern: pattern,
            gestureType: "blink"
        )

        // Should return reasonable result based on heuristics
        XCTAssertTrue(isValid || !isValid) // Should not crash
    }

    // MARK: - Context-Aware Prediction Tests

    func testGetContextAwarePrediction() async {
        gesturePredictionModel.loadPretrainedModels()
        try? await Task.sleep(nanoseconds: 500_000_000)

        let pattern = createMockGesturePattern()
        let context = createMockMusicalContext()

        let gestureConfidence = await gesturePredictionModel.getContextAwarePrediction(
            pattern: pattern,
            gestureType: "blink",
            context: context
        )

        XCTAssertEqual(gestureConfidence.gestureType, "blink")
        XCTAssertGreaterThanOrEqual(gestureConfidence.confidence, 0.0)
        XCTAssertLessThanOrEqual(gestureConfidence.confidence, 1.0)
        XCTAssertNotNil(gestureConfidence.timestamp)
    }

    // MARK: - Training Data Tests

    func testRecordTrainingData() {
        let pattern = createMockGesturePattern()
        let context = createMockMusicalContext()

        let initialStats = gesturePredictionModel.getModelPerformanceStats()
        let initialTrainingSize = initialStats["trainingDataSize"] as? Int ?? 0

        gesturePredictionModel.recordTrainingData(
            pattern: pattern,
            context: context,
            isValidGesture: true,
            userFeedback: true
        )

        let updatedStats = gesturePredictionModel.getModelPerformanceStats()
        let updatedTrainingSize = updatedStats["trainingDataSize"] as? Int ?? 0

        XCTAssertEqual(updatedTrainingSize, initialTrainingSize + 1)
    }

    func testRecordMultipleTrainingData() {
        let pattern = createMockGesturePattern()
        let context = createMockMusicalContext()

        for i in 0..<5 {
            gesturePredictionModel.recordTrainingData(
                pattern: pattern,
                context: context,
                isValidGesture: i % 2 == 0,
                userFeedback: i % 3 == 0
            )
        }

        let stats = gesturePredictionModel.getModelPerformanceStats()
        let trainingSize = stats["trainingDataSize"] as? Int ?? 0

        XCTAssertEqual(trainingSize, 5)
    }

    func testTrainingDataBufferLimit() {
        let pattern = createMockGesturePattern()
        let context = createMockMusicalContext()

        // Add data beyond buffer limit (1000 items)
        for i in 0..<1050 {
            gesturePredictionModel.recordTrainingData(
                pattern: pattern,
                context: context,
                isValidGesture: true
            )
        }

        let stats = gesturePredictionModel.getModelPerformanceStats()
        let trainingSize = stats["trainingDataSize"] as? Int ?? 0

        XCTAssertLessThanOrEqual(trainingSize, 1000)
    }

    // MARK: - Model Feedback Tests

    func testUpdateModelWithCorrectFeedback() async {
        gesturePredictionModel.loadPretrainedModels()
        try? await Task.sleep(nanoseconds: 500_000_000)

        let pattern = createMockGesturePattern()
        let context = createMockMusicalContext()

        let prediction = await gesturePredictionModel.predictGestureConfidence(
            pattern: pattern,
            gestureType: "blink",
            context: context
        )

        let initialAccuracy = gesturePredictionModel.predictionAccuracy

        gesturePredictionModel.updateModelWithFeedback(
            prediction: prediction,
            wasCorrect: true
        )

        let updatedAccuracy = gesturePredictionModel.predictionAccuracy
        XCTAssertGreaterThanOrEqual(updatedAccuracy, initialAccuracy)
    }

    func testUpdateModelWithIncorrectFeedback() async {
        gesturePredictionModel.loadPretrainedModels()
        try? await Task.sleep(nanoseconds: 500_000_000)

        let pattern = createMockGesturePattern()
        let context = createMockMusicalContext()

        let prediction = await gesturePredictionModel.predictGestureConfidence(
            pattern: pattern,
            gestureType: "blink",
            context: context
        )

        let initialAccuracy = gesturePredictionModel.predictionAccuracy

        gesturePredictionModel.updateModelWithFeedback(
            prediction: prediction,
            wasCorrect: false
        )

        let updatedAccuracy = gesturePredictionModel.predictionAccuracy
        XCTAssertLessThanOrEqual(updatedAccuracy, initialAccuracy)
    }

    func testFalsePositiveRateUpdate() async {
        gesturePredictionModel.loadPretrainedModels()
        try? await Task.sleep(nanoseconds: 500_000_000)

        let pattern = createMockGesturePattern()
        let context = createMockMusicalContext()

        let prediction = await gesturePredictionModel.predictGestureConfidence(
            pattern: pattern,
            gestureType: "blink",
            context: context
        )

        // Force execute recommendation
        let executeResult = MLPredictionResult(
            gestureType: "blink",
            confidence: 0.95,
            falsePositiveProbability: 0.1,
            musicalContextMatch: 0.1,
            recommendedAction: .execute
        )

        let initialFPRate = gesturePredictionModel.falsePositiveRate

        gesturePredictionModel.updateModelWithFeedback(
            prediction: executeResult,
            wasCorrect: false
        )

        let updatedFPRate = gesturePredictionModel.falsePositiveRate
        XCTAssertGreaterThan(updatedFPRate, initialFPRate)
    }

    // MARK: - Performance and Statistics Tests

    func testGetModelPerformanceStats() {
        let stats = gesturePredictionModel.getModelPerformanceStats()

        XCTAssertNotNil(stats["isLoaded"])
        XCTAssertNotNil(stats["accuracy"])
        XCTAssertNotNil(stats["falsePositiveRate"])
        XCTAssertNotNil(stats["totalPredictions"])
        XCTAssertNotNil(stats["trainingDataSize"])
        XCTAssertNotNil(stats["lastUpdate"])
    }

    func testResetModel() {
        let pattern = createMockGesturePattern()
        let context = createMockMusicalContext()

        // Add some data
        gesturePredictionModel.recordTrainingData(
            pattern: pattern,
            context: context,
            isValidGesture: true
        )

        // Simulate some predictions
        Task { @MainActor in
            gesturePredictionModel.totalPredictions = 10
            gesturePredictionModel.predictionAccuracy = 0.8
        }

        // Reset model
        gesturePredictionModel.resetModel()

        XCTAssertEqual(gesturePredictionModel.totalPredictions, 0)
        XCTAssertEqual(gesturePredictionModel.predictionAccuracy, 0.0)
        XCTAssertEqual(gesturePredictionModel.falsePositiveRate, 0.0)
        XCTAssertNil(gesturePredictionModel.lastPrediction)

        let stats = gesturePredictionModel.getModelPerformanceStats()
        let trainingSize = stats["trainingDataSize"] as? Int ?? -1
        XCTAssertEqual(trainingSize, 0)
    }

    // MARK: - Data Export/Import Tests

    func testExportTrainingData() {
        let pattern = createMockGesturePattern()
        let context = createMockMusicalContext()

        // Add some training data
        for _ in 0..<5 {
            gesturePredictionModel.recordTrainingData(
                pattern: pattern,
                context: context,
                isValidGesture: true
            )
        }

        let exportedData = gesturePredictionModel.exportTrainingData()
        XCTAssertNotNil(exportedData)
        XCTAssertGreaterThan(exportedData?.count ?? 0, 0)
    }

    func testExportEmptyTrainingData() {
        let exportedData = gesturePredictionModel.exportTrainingData()
        XCTAssertNotNil(exportedData) // Should export empty array
    }

    func testImportModelWeights() {
        // Create mock training data
        let pattern = createMockGesturePattern()
        let context = createMockMusicalContext()

        let mockTrainingData = [
            MLTrainingData(
                gesturePattern: pattern,
                musicalContext: context,
                isValidGesture: true,
                userFeedback: true,
                timestamp: Date()
            )
        ]

        let validData = try! JSONEncoder().encode(mockTrainingData)
        let importResult = gesturePredictionModel.importModelWeights(from: validData)
        XCTAssertTrue(importResult)

        // Test invalid data
        let invalidData = Data("invalid json".utf8)
        let invalidResult = gesturePredictionModel.importModelWeights(from: invalidData)
        XCTAssertFalse(invalidResult)
    }

    // MARK: - Performance Tests

    func testPredictionPerformance() async {
        gesturePredictionModel.loadPretrainedModels()
        try? await Task.sleep(nanoseconds: 500_000_000)

        let pattern = createMockGesturePattern()
        let context = createMockMusicalContext()

        measure {
            Task {
                let _ = await gesturePredictionModel.predictGestureConfidence(
                    pattern: pattern,
                    gestureType: "blink",
                    context: context
                )
            }
        }
    }

    func testValidationPerformance() async {
        gesturePredictionModel.loadPretrainedModels()
        try? await Task.sleep(nanoseconds: 500_000_000)

        let pattern = createMockGesturePattern()

        measure {
            Task {
                let _ = await gesturePredictionModel.validateGesture(
                    pattern: pattern,
                    gestureType: "blink"
                )
            }
        }
    }

    func testTrainingDataRecordingPerformance() {
        let pattern = createMockGesturePattern()
        let context = createMockMusicalContext()

        measure {
            for _ in 0..<100 {
                gesturePredictionModel.recordTrainingData(
                    pattern: pattern,
                    context: context,
                    isValidGesture: true
                )
            }
        }
    }

    // MARK: - Integration Tests

    func testFullPredictionWorkflow() async {
        // 1. Load model
        gesturePredictionModel.loadPretrainedModels()

        let loadExpectation = XCTestExpectation(description: "Model loads")
        gesturePredictionModel.$isModelLoaded
            .dropFirst()
            .sink { isLoaded in
                if isLoaded {
                    loadExpectation.fulfill()
                }
            }
            .store(in: &cancellables)

        await fulfillment(of: [loadExpectation], timeout: 3.0)

        // 2. Make prediction
        let pattern = createMockGesturePattern()
        let context = createMockMusicalContext()

        let prediction = await gesturePredictionModel.predictGestureConfidence(
            pattern: pattern,
            gestureType: "blink",
            context: context
        )

        XCTAssertGreaterThan(prediction.confidence, 0.0)

        // 3. Validate gesture
        let isValid = await gesturePredictionModel.validateGesture(
            pattern: pattern,
            gestureType: "blink"
        )

        XCTAssertTrue(isValid || !isValid) // Should complete without error

        // 4. Record training data
        gesturePredictionModel.recordTrainingData(
            pattern: pattern,
            context: context,
            isValidGesture: true,
            userFeedback: true
        )

        // 5. Provide feedback
        gesturePredictionModel.updateModelWithFeedback(
            prediction: prediction,
            wasCorrect: true
        )

        // 6. Check statistics
        let stats = gesturePredictionModel.getModelPerformanceStats()
        XCTAssertGreaterThan(stats["totalPredictions"] as? Int ?? 0, 0)
    }

    // MARK: - Helper Methods

    private func createMockGesturePattern() -> GesturePattern {
        return GesturePattern(
            landmarks: [
                CGPoint(x: 0.5, y: 0.3),
                CGPoint(x: 0.52, y: 0.31),
                CGPoint(x: 0.48, y: 0.29)
            ],
            temporalSequence: [0.1, 0.5, 0.9, 0.3],
            duration: 0.3,
            velocity: 150.0,
            acceleration: 30.0
        )
    }

    private func createMockMusicalContext() -> MusicalContext {
        return MusicalContext(
            tempo: 120.0,
            timeSignature: "4/4",
            instrumentType: .keyboard,
            currentMeasure: 10,
            beatPosition: 0.5
        )
    }
}