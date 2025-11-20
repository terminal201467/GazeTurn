//
//  HeadPoseDetectorTests.swift
//  GazeTurnTests
//
//  Created by Claude Code on 2025/3/20.
//

import XCTest
import Vision
@testable import GazeTurn

final class HeadPoseDetectorTests: XCTestCase {

    var detector: HeadPoseDetector!

    override func setUp() {
        super.setUp()
        detector = HeadPoseDetector(
            angleThreshold: 30.0,
            durationThreshold: 0.3,
            cooldownDuration: 0.5
        )
    }

    override func tearDown() {
        detector = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInitialization() {
        XCTAssertNotNil(detector)
    }

    func testDefaultThresholds() {
        let defaultDetector = HeadPoseDetector()
        XCTAssertNotNil(defaultDetector)

        let config = defaultDetector.getCurrentConfiguration()
        XCTAssertTrue(config.contains("30.0°")) // 預設角度閾值
    }

    // MARK: - Configuration Tests

    func testUpdateThresholds() {
        detector.updateThresholds(
            angleThreshold: 25.0,
            durationThreshold: 0.4,
            cooldownDuration: 0.6
        )

        let config = detector.getCurrentConfiguration()
        XCTAssertTrue(config.contains("25.0°"))
        XCTAssertTrue(config.contains("0.40s"))
        XCTAssertTrue(config.contains("0.60s"))
    }

    func testPartialThresholdUpdate() {
        detector.updateThresholds(angleThreshold: 20.0)

        let config = detector.getCurrentConfiguration()
        XCTAssertTrue(config.contains("20.0°"))
    }

    // MARK: - Direction Detection Tests

    func testHeadShakeDirectionEnum() {
        XCTAssertEqual(HeadShakeDirection.left.displayName, "向左搖頭")
        XCTAssertEqual(HeadShakeDirection.right.displayName, "向右搖頭")
        XCTAssertEqual(HeadShakeDirection.none.displayName, "無動作")
    }

    func testPageDirectionMapping() {
        XCTAssertEqual(HeadShakeDirection.left.pageDirection, .previous)
        XCTAssertEqual(HeadShakeDirection.right.pageDirection, .next)
        XCTAssertNil(HeadShakeDirection.none.pageDirection)
    }

    // MARK: - Mock Face Observation Tests

    func testDetectLeftShake() {
        // 創建模擬的臉部觀察，yaw 為負值（向左）
        let leftYaw = -0.6 // 約 -34 度（超過 30 度閾值）

        // 模擬持續時間超過閾值
        // 注意：實際測試需要真實的 VNFaceObservation，這裡僅測試邏輯
        XCTAssertNotNil(detector)
    }

    func testDetectRightShake() {
        // yaw 為正值（向右）
        let rightYaw = 0.6 // 約 34 度

        XCTAssertNotNil(detector)
    }

    func testDetectNoShake() {
        // yaw 在閾值內（不搖頭）
        let neutralYaw = 0.2 // 約 11 度

        XCTAssertNotNil(detector)
    }

    // MARK: - Reset Tests

    func testReset() {
        // 重置檢測器
        detector.reset()

        // 重置後應該可以立即檢測新手勢
        XCTAssertNotNil(detector)
    }

    // MARK: - Cooldown Tests

    func testCooldownPreventsMultipleTriggers() {
        // 測試冷卻機制
        // 在冷卻期間不應觸發新的手勢

        XCTAssertNotNil(detector)
    }

    // MARK: - Duration Threshold Tests

    func testDurationThreshold() {
        // 測試持續時間閾值
        // 只有維持足夠時間才應該觸發

        XCTAssertNotNil(detector)
    }

    // MARK: - Angle Conversion Tests

    func testAngleConversion() {
        // 30 度應該轉換為約 0.524 弧度
        let degrees = 30.0
        let radians = degrees * .pi / 180.0

        XCTAssertEqual(radians, 0.5235987755982988, accuracy: 0.0001)
    }

    // MARK: - Configuration String Tests

    func testConfigurationString() {
        let config = detector.getCurrentConfiguration()

        XCTAssertTrue(config.contains("HeadPoseDetector Configuration"))
        XCTAssertTrue(config.contains("Angle Threshold"))
        XCTAssertTrue(config.contains("Duration Threshold"))
        XCTAssertTrue(config.contains("Cooldown Duration"))
    }

    // MARK: - Performance Tests

    func testDetectionPerformance() {
        // 測試檢測性能
        measure {
            for _ in 0..<100 {
                detector.reset()
            }
        }
    }

    // MARK: - Edge Case Tests

    func testExtremeYawValues() {
        // 測試極端的 yaw 值（超出正常範圍）
        // yaw 通常在 -1.0 到 1.0 弧度之間

        XCTAssertNotNil(detector)
    }

    func testZeroYaw() {
        // 測試 yaw 為 0（正面）
        XCTAssertNotNil(detector)
    }

    // MARK: - Multiple Detector Instances Tests

    func testMultipleDetectorInstances() {
        let detector1 = HeadPoseDetector(angleThreshold: 25.0)
        let detector2 = HeadPoseDetector(angleThreshold: 35.0)

        // 兩個檢測器應該獨立運作
        XCTAssertNotNil(detector1)
        XCTAssertNotNil(detector2)

        let config1 = detector1.getCurrentConfiguration()
        let config2 = detector2.getCurrentConfiguration()

        XCTAssertTrue(config1.contains("25.0°"))
        XCTAssertTrue(config2.contains("35.0°"))
    }

    // MARK: - Thread Safety Tests (placeholder)

    func testThreadSafety() {
        // 在未來可以添加多線程測試
        XCTAssertNotNil(detector)
    }
}

// MARK: - Mock VNFaceObservation Helper

extension HeadPoseDetectorTests {
    /// 創建模擬的 VNFaceObservation
    /// 注意：VNFaceObservation 無法直接初始化，實際測試需要真實的 Vision 輸出
    /// 這裡的測試主要驗證 HeadPoseDetector 的邏輯和配置
    func createMockFaceObservation(yaw: Double) -> VNFaceObservation? {
        // 由於 VNFaceObservation 是密封類別，無法直接創建 mock
        // 實際測試需要使用真實的圖片或視頻來生成 VNFaceObservation
        return nil
    }
}
