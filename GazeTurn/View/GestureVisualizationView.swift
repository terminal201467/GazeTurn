//
//  GestureVisualizationView.swift
//  GazeTurn
//
//  Created by Claude Code on 2025/3/20.
//

import SwiftUI

/// 手勢視覺化數據
struct GestureVisualizationData {
    var leftEyeOpen: Bool = true
    var rightEyeOpen: Bool = true
    var leftEyeHeight: Double = 0.0
    var rightEyeHeight: Double = 0.0
    var headYaw: Double = 0.0
    var headPitch: Double = 0.0
    var headRoll: Double = 0.0
    var lastGesture: String = "無"
    var lastGestureTime: Date?
    var faceDetected: Bool = false
    var blinkThreshold: Double = 0.015
    var shakeThreshold: Double = 25.0
}

/// 手勢視覺化介面 - 顯示即時手勢檢測狀態
struct GestureVisualizationView: View {

    // MARK: - Properties

    @Binding var data: GestureVisualizationData
    var instrumentMode: InstrumentMode

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 標題
            HStack {
                Image(systemName: "eye.circle.fill")
                    .foregroundColor(.blue)
                Text("手勢檢測狀態")
                    .font(.headline)
                Spacer()
                statusIndicator
            }

            Divider()

            // 臉部檢測狀態
            faceDetectionSection

            if data.faceDetected {
                Divider()

                // 眼睛狀態（如果啟用）
                if instrumentMode.enableBlink {
                    eyeStateSection
                    Divider()
                }

                // 頭部姿態（如果啟用）
                if instrumentMode.enableHeadShake {
                    headPoseSection
                    Divider()
                }

                // 最後檢測到的手勢
                lastGestureSection
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(uiColor: .systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
    }

    // MARK: - Status Indicator

    private var statusIndicator: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(data.faceDetected ? Color.green : Color.red)
                .frame(width: 8, height: 8)

            Text(data.faceDetected ? "運行中" : "未偵測")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Face Detection Section

    private var faceDetectionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: data.faceDetected ? "face.smiling.fill" : "face.dashed.fill")
                    .font(.title2)
                    .foregroundColor(data.faceDetected ? .green : .orange)

                VStack(alignment: .leading, spacing: 2) {
                    Text("臉部偵測")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Text(data.faceDetected ? "已偵測到臉部" : "請將臉部置於相機前")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
        }
    }

    // MARK: - Eye State Section

    private var eyeStateSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "eye.fill")
                    .foregroundColor(.blue)
                Text("眼睛狀態")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }

            HStack(spacing: 20) {
                // 左眼
                EyeIndicator(
                    title: "左眼",
                    isOpen: data.leftEyeOpen,
                    height: data.leftEyeHeight,
                    threshold: data.blinkThreshold
                )

                // 右眼
                EyeIndicator(
                    title: "右眼",
                    isOpen: data.rightEyeOpen,
                    height: data.rightEyeHeight,
                    threshold: data.blinkThreshold
                )
            }

            // 眨眼閾值說明
            HStack {
                Text("閾值:")
                    .font(.caption2)
                    .foregroundColor(.secondary)

                Text(String(format: "%.3f", data.blinkThreshold))
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)

                Spacer()

                Text("平均高度:")
                    .font(.caption2)
                    .foregroundColor(.secondary)

                Text(String(format: "%.3f", (data.leftEyeHeight + data.rightEyeHeight) / 2))
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
        }
    }

    // MARK: - Head Pose Section

    private var headPoseSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "arrow.left.and.right")
                    .foregroundColor(.purple)
                Text("頭部姿態")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }

            // Yaw（左右搖頭）
            HeadPoseBar(
                title: "左右 (Yaw)",
                angle: data.headYaw,
                threshold: data.shakeThreshold,
                color: .purple,
                range: -45...45
            )

            // Pitch（上下點頭）
            HeadPoseBar(
                title: "上下 (Pitch)",
                angle: data.headPitch,
                threshold: 999, // 不顯示閾值線
                color: .orange,
                range: -30...30
            )

            // Roll（左右傾斜）
            HeadPoseBar(
                title: "傾斜 (Roll)",
                angle: data.headRoll,
                threshold: 999, // 不顯示閾值線
                color: .green,
                range: -30...30
            )
        }
    }

    // MARK: - Last Gesture Section

    private var lastGestureSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "hand.point.up.fill")
                    .foregroundColor(.orange)
                Text("最後手勢")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }

            HStack {
                Text(data.lastGesture)
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                Spacer()

                if let gestureTime = data.lastGestureTime {
                    Text(timeAgo(from: gestureTime))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.orange.opacity(0.1))
            )
        }
    }

    // MARK: - Helper Methods

    private func timeAgo(from date: Date) -> String {
        let seconds = Int(Date().timeIntervalSince(date))

        if seconds < 1 {
            return "剛剛"
        } else if seconds < 60 {
            return "\(seconds) 秒前"
        } else {
            let minutes = seconds / 60
            return "\(minutes) 分鐘前"
        }
    }
}

// MARK: - Eye Indicator

struct EyeIndicator: View {
    let title: String
    let isOpen: Bool
    let height: Double
    let threshold: Double

    var body: some View {
        VStack(spacing: 8) {
            // 眼睛圖示
            Image(systemName: isOpen ? "eye.fill" : "eye.slash.fill")
                .font(.title)
                .foregroundColor(isOpen ? .blue : .red)
                .frame(height: 40)
                .animation(.easeInOut(duration: 0.2), value: isOpen)

            // 標題
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)

            // 狀態
            Text(isOpen ? "張開" : "閉合")
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundColor(isOpen ? .green : .red)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill((isOpen ? Color.green : Color.red).opacity(0.2))
                )

            // 高度數值
            Text(String(format: "%.3f", height))
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(uiColor: .secondarySystemBackground))
        )
    }
}

// MARK: - Head Pose Bar

struct HeadPoseBar: View {
    let title: String
    let angle: Double
    let threshold: Double
    let color: Color
    let range: ClosedRange<Double>

    private var normalizedPosition: Double {
        let total = range.upperBound - range.lowerBound
        let offset = angle - range.lowerBound
        return min(max(offset / total, 0), 1)
    }

    private var isOverThreshold: Bool {
        abs(angle) > threshold
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // 標題和數值
            HStack {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Text(String(format: "%.1f°", angle))
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(isOverThreshold ? .red : .primary)
            }

            // 進度條
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // 背景
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)
                        .cornerRadius(4)

                    // 中心線
                    Rectangle()
                        .fill(Color.gray.opacity(0.5))
                        .frame(width: 2, height: 12)
                        .position(x: geometry.size.width / 2, y: 4)

                    // 閾值線（左）
                    if threshold < 900 {
                        let leftThresholdPosition = (threshold - range.lowerBound) / (range.upperBound - range.lowerBound)
                        Rectangle()
                            .fill(Color.orange.opacity(0.6))
                            .frame(width: 2, height: 12)
                            .position(x: geometry.size.width * (0.5 - leftThresholdPosition / 2), y: 4)

                        // 閾值線（右）
                        Rectangle()
                            .fill(Color.orange.opacity(0.6))
                            .frame(width: 2, height: 12)
                            .position(x: geometry.size.width * (0.5 + leftThresholdPosition / 2), y: 4)
                    }

                    // 當前位置指示器
                    Circle()
                        .fill(isOverThreshold ? Color.red : color)
                        .frame(width: 16, height: 16)
                        .position(x: geometry.size.width * normalizedPosition, y: 4)
                        .animation(.easeInOut(duration: 0.1), value: normalizedPosition)
                }
            }
            .frame(height: 16)
        }
    }
}

// MARK: - Compact Version

struct GestureVisualizationCompactView: View {
    @Binding var data: GestureVisualizationData

    var body: some View {
        HStack(spacing: 12) {
            // 臉部檢測
            Circle()
                .fill(data.faceDetected ? Color.green : Color.red)
                .frame(width: 8, height: 8)

            // 左眼
            Image(systemName: data.leftEyeOpen ? "eye.fill" : "eye.slash.fill")
                .font(.caption)
                .foregroundColor(data.leftEyeOpen ? .blue : .red)

            // 右眼
            Image(systemName: data.rightEyeOpen ? "eye.fill" : "eye.slash.fill")
                .font(.caption)
                .foregroundColor(data.rightEyeOpen ? .blue : .red)

            // 頭部角度
            Text(String(format: "%.0f°", data.headYaw))
                .font(.caption2)
                .foregroundColor(.secondary)

            Spacer()

            // 最後手勢
            if data.lastGesture != "無" {
                Text(data.lastGesture)
                    .font(.caption2)
                    .foregroundColor(.orange)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.black.opacity(0.7))
        )
    }
}

// MARK: - Preview

#Preview("Full View - Active") {
    GestureVisualizationView(
        data: .constant(GestureVisualizationData(
            leftEyeOpen: true,
            rightEyeOpen: true,
            leftEyeHeight: 0.022,
            rightEyeHeight: 0.021,
            headYaw: 15.5,
            headPitch: -5.2,
            headRoll: 2.1,
            lastGesture: "向右搖頭",
            lastGestureTime: Date().addingTimeInterval(-3),
            faceDetected: true
        )),
        instrumentMode: InstrumentMode.keyboardMode()
    )
    .padding()
    .previewLayout(.sizeThatFits)
}

#Preview("Full View - No Face") {
    GestureVisualizationView(
        data: .constant(GestureVisualizationData()),
        instrumentMode: InstrumentMode.stringInstrumentsMode()
    )
    .padding()
    .previewLayout(.sizeThatFits)
}

#Preview("Compact View") {
    GestureVisualizationCompactView(
        data: .constant(GestureVisualizationData(
            leftEyeOpen: false,
            rightEyeOpen: false,
            headYaw: 25.3,
            lastGesture: "雙眨眼",
            faceDetected: true
        ))
    )
    .padding()
    .previewLayout(.sizeThatFits)
    .background(Color.black)
}
