//
//  DashboardView.swift
//  GazeTurn
//
//  Created by Claude Code on 2025/11/21.
//

import SwiftUI
import Charts

/// 儀表板視圖 - GazeTurn v2 性能監控與分析中心
struct DashboardView: View {

    // MARK: - Properties

    /// 自適應幀率控制器
    @StateObject private var frameRateController = AdaptiveFrameRateController()

    /// 手勢學習引擎
    @StateObject private var learningEngine = GestureLearningEngine()

    /// 微手勢檢測器
    @StateObject private var microGestureDetector = MicroGestureDetector()

    /// 當前選擇的時間範圍
    @State private var selectedTimeRange: TimeRange = .lastHour

    /// 是否顯示詳細統計
    @State private var showDetailedStats: Bool = false

    /// 是否顯示性能建議
    @State private var showPerformanceRecommendations: Bool = false

    /// 當前選擇的檢視模式
    @State private var selectedViewMode: ViewMode = .overview

    /// 是否啟用即時更新
    @State private var isRealTimeEnabled: Bool = true

    /// 更新計時器
    @State private var updateTimer: Timer?

    // MARK: - Enums

    enum TimeRange: String, CaseIterable {
        case lastHour = "最近一小時"
        case last24Hours = "最近24小時"
        case lastWeek = "最近一週"
        case lastMonth = "最近一個月"

        var duration: TimeInterval {
            switch self {
            case .lastHour: return 3600
            case .last24Hours: return 86400
            case .lastWeek: return 604800
            case .lastMonth: return 2629746
            }
        }
    }

    enum ViewMode: String, CaseIterable {
        case overview = "總覽"
        case performance = "性能"
        case gestures = "手勢"
        case learning = "學習"

        var iconName: String {
            switch self {
            case .overview: return "chart.bar.fill"
            case .performance: return "speedometer"
            case .gestures: return "hand.raised.fill"
            case .learning: return "brain.head.profile"
            }
        }
    }

    // MARK: - Body

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 20) {
                    // 頂部控制區域
                    topControlsSection

                    // 主要內容區域
                    switch selectedViewMode {
                    case .overview:
                        overviewSection
                    case .performance:
                        performanceSection
                    case .gestures:
                        gesturesSection
                    case .learning:
                        learningSection
                    }

                    // 性能建議
                    if showPerformanceRecommendations {
                        recommendationsSection
                    }
                }
                .padding()
            }
            .navigationTitle("GazeTurn 儀表板")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: exportData) {
                            Label("導出資料", systemImage: "square.and.arrow.up")
                        }

                        Button(action: resetStatistics) {
                            Label("重置統計", systemImage: "trash")
                        }

                        Toggle("即時更新", isOn: $isRealTimeEnabled)
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .onAppear {
            startRealTimeUpdates()
        }
        .onDisappear {
            stopRealTimeUpdates()
        }
    }

    // MARK: - View Components

    /// 頂部控制區域
    private var topControlsSection: some View {
        VStack(spacing: 16) {
            // 檢視模式選擇器
            Picker("檢視模式", selection: $selectedViewMode) {
                ForEach(ViewMode.allCases, id: \.self) { mode in
                    Label(mode.rawValue, systemImage: mode.iconName)
                        .tag(mode)
                }
            }
            .pickerStyle(SegmentedPickerStyle())

            // 時間範圍選擇器
            HStack {
                Text("時間範圍:")
                    .font(.headline)

                Spacer()

                Picker("時間範圍", selection: $selectedTimeRange) {
                    ForEach(TimeRange.allCases, id: \.self) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }

    /// 總覽區域
    private var overviewSection: some View {
        VStack(spacing: 16) {
            // 關鍵指標卡片
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                MetricCard(
                    title: "當前幀率",
                    value: "\(frameRateController.actualFrameRate)",
                    unit: "fps",
                    trend: frameRateController.performanceMetrics.frameRateTrend,
                    color: .blue
                )

                MetricCard(
                    title: "手勢準確率",
                    value: String(format: "%.1f", learningEngine.recentAccuracy * 100),
                    unit: "%",
                    trend: .improving,
                    color: .green
                )

                MetricCard(
                    title: "平均延遲",
                    value: String(format: "%.0f", frameRateController.performanceMetrics.averageFrameTime),
                    unit: "ms",
                    trend: frameRateController.performanceMetrics.frameTimeTrend,
                    color: .orange
                )

                MetricCard(
                    title: "學習進度",
                    value: String(format: "%.0f", learningEngine.adaptationProgress * 100),
                    unit: "%",
                    trend: .improving,
                    color: .purple
                )
            }

            // 即時狀態指示器
            realTimeStatusSection

            // 系統健康度
            systemHealthSection
        }
    }

    /// 性能區域
    private var performanceSection: some View {
        VStack(spacing: 16) {
            // 幀率趨勢圖
            performanceChart

            // 系統資源使用
            systemResourcesSection

            // 性能模式控制
            performanceModeSection
        }
    }

    /// 手勢區域
    private var gesturesSection: some View {
        VStack(spacing: 16) {
            // 手勢類型統計
            gestureTypesChart

            // 微手勢檢測狀態
            microGestureSection

            // 手勢準確率分析
            gestureAccuracySection
        }
    }

    /// 學習區域
    private var learningSection: some View {
        VStack(spacing: 16) {
            // 學習進度
            learningProgressSection

            // 個人化洞察
            personalInsightsSection

            // 適應歷史
            adaptationHistorySection
        }
    }

    /// 即時狀態指示器
    private var realTimeStatusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("即時狀態")
                .font(.headline)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                StatusIndicator(
                    title: "相機",
                    status: .active,
                    icon: "camera.fill"
                )

                StatusIndicator(
                    title: "面部檢測",
                    status: .active,
                    icon: "face.dashed.fill"
                )

                StatusIndicator(
                    title: "手勢識別",
                    status: .active,
                    icon: "hand.raised.fill"
                )

                StatusIndicator(
                    title: "AI學習",
                    status: learningEngine.learningEnabled ? .active : .inactive,
                    icon: "brain.head.profile.fill"
                )

                StatusIndicator(
                    title: "性能優化",
                    status: frameRateController.isAdaptiveEnabled ? .active : .inactive,
                    icon: "speedometer"
                )

                StatusIndicator(
                    title: "微手勢",
                    status: !microGestureDetector.enabledGestureTypes.isEmpty ? .active : .inactive,
                    icon: "eye.fill"
                )
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }

    /// 系統健康度
    private var systemHealthSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("系統健康度")
                .font(.headline)

            let systemState = frameRateController.getCurrentSystemState()

            VStack(spacing: 8) {
                HealthIndicator(
                    title: "電池電量",
                    value: systemState.batteryLevel,
                    format: "%.0f%%",
                    goodThreshold: 0.3,
                    warningThreshold: 0.15
                )

                HealthIndicator(
                    title: "記憶體使用",
                    value: getMemoryUsagePercentage(),
                    format: "%.0f%%",
                    goodThreshold: 0.7,
                    warningThreshold: 0.9
                )

                HealthIndicator(
                    title: "處理負載",
                    value: Float(frameRateController.performanceMetrics.averageFrameTime / 16.67),
                    format: "%.1fx",
                    goodThreshold: 1.5,
                    warningThreshold: 2.0
                )
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }

    /// 性能圖表
    private var performanceChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("性能趨勢")
                .font(.headline)

            // 簡化的圖表視圖（實際實作會使用 Charts 框架）
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.1))
                    .frame(height: 200)

                VStack {
                    Text("幀率: \(frameRateController.actualFrameRate) fps")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("模式: \(frameRateController.currentMode.description)")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    // 簡化的進度條
                    ProgressView(value: Double(frameRateController.actualFrameRate), total: 60)
                        .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                        .frame(width: 200)
                }
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }

    /// 系統資源區域
    private var systemResourcesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("系統資源")
                .font(.headline)

            let systemState = frameRateController.getCurrentSystemState()

            VStack(spacing: 8) {
                ResourceBar(
                    title: "CPU 使用率",
                    value: systemState.processingLoad,
                    maxValue: 2.0,
                    color: .red
                )

                ResourceBar(
                    title: "記憶體壓力",
                    value: getMemoryPressureValue(systemState.memoryPressure),
                    maxValue: 1.0,
                    color: .orange
                )

                ResourceBar(
                    title: "溫度狀態",
                    value: getThermalStateValue(systemState.thermalState),
                    maxValue: 1.0,
                    color: .yellow
                )
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }

    /// 性能模式控制
    private var performanceModeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("性能控制")
                .font(.headline)

            VStack(spacing: 12) {
                HStack {
                    Text("當前模式:")
                    Spacer()
                    Text(frameRateController.currentMode.description)
                        .fontWeight(.semibold)
                }

                HStack {
                    Text("自適應模式:")
                    Spacer()
                    Toggle("", isOn: .constant(frameRateController.isAdaptiveEnabled))
                }

                Picker("手動模式", selection: .constant(frameRateController.currentMode)) {
                    ForEach([FrameRateMode.battery, .balanced, .performance], id: \.self) { mode in
                        Text(mode.description).tag(mode)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .disabled(frameRateController.isAdaptiveEnabled)
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }

    /// 手勢類型圖表
    private var gestureTypesChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("手勢類型分布")
                .font(.headline)

            let statistics = microGestureDetector.getDetectionStatistics()

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ForEach(Array(statistics.keys), id: \.self) { gestureType in
                    if let stats = statistics[gestureType] {
                        GestureTypeCard(
                            type: gestureType,
                            detections: stats.totalDetections,
                            confidence: stats.averageConfidence
                        )
                    }
                }
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }

    /// 微手勢區域
    private var microGestureSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("微手勢控制")
                .font(.headline)

            VStack(spacing: 8) {
                ForEach(MicroGestureType.allCases, id: \.self) { gestureType in
                    MicroGestureToggle(
                        gestureType: gestureType,
                        isEnabled: microGestureDetector.enabledGestureTypes.contains(gestureType),
                        onToggle: { enabled in
                            microGestureDetector.setGestureEnabled(gestureType, enabled: enabled)
                        }
                    )
                }

                Divider()

                HStack {
                    Text("敏感度:")
                    Spacer()
                    Slider(value: .constant(microGestureDetector.sensitivity), in: 0.1...1.0) {
                        Text("敏感度")
                    }
                    .frame(width: 150)
                    Text(String(format: "%.1f", microGestureDetector.sensitivity))
                        .frame(width: 30)
                }
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }

    /// 手勢準確率分析
    private var gestureAccuracySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("準確率分析")
                .font(.headline)

            let profile = learningEngine.currentProfile
            let metrics = profile.performanceMetrics

            VStack(spacing: 8) {
                AccuracyMetric(
                    title: "整體準確率",
                    value: metrics.accuracy,
                    color: .green
                )

                AccuracyMetric(
                    title: "精確率",
                    value: metrics.precision,
                    color: .blue
                )

                AccuracyMetric(
                    title: "召回率",
                    value: metrics.recall,
                    color: .purple
                )
            }

            Divider()

            HStack {
                VStack(alignment: .leading) {
                    Text("總手勢數")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(metrics.totalGestures)")
                        .font(.title3)
                        .fontWeight(.semibold)
                }

                Spacer()

                VStack(alignment: .trailing) {
                    Text("誤觸率")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.1f%%", Double(metrics.falsePositives) / max(Double(metrics.totalGestures), 1) * 100))
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.orange)
                }
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }

    /// 學習進度區域
    private var learningProgressSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("學習進度")
                .font(.headline)

            VStack(spacing: 12) {
                HStack {
                    Text("適應進度")
                    Spacer()
                    Text(String(format: "%.0f%%", learningEngine.adaptationProgress * 100))
                        .fontWeight(.semibold)
                }

                ProgressView(value: learningEngine.adaptationProgress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))

                HStack {
                    Text("學習狀態:")
                    Spacer()
                    Text(learningEngine.learningEnabled ? "啟用" : "關閉")
                        .fontWeight(.semibold)
                        .foregroundColor(learningEngine.learningEnabled ? .green : .red)
                }

                Toggle("啟用學習", isOn: .constant(learningEngine.learningEnabled))
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }

    /// 個人化洞察
    private var personalInsightsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("個人化洞察")
                .font(.headline)

            if learningEngine.learningInsights.isEmpty {
                Text("暫無洞察資料")
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                ForEach(learningEngine.learningInsights, id: \.self) { insight in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "lightbulb.fill")
                            .foregroundColor(.yellow)
                        Text(insight)
                            .font(.body)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }

    /// 適應歷史
    private var adaptationHistorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("適應歷史")
                .font(.headline)

            let sessions = learningEngine.currentProfile.learningHistory

            if sessions.isEmpty {
                Text("暫無歷史記錄")
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                ForEach(Array(sessions.suffix(5).enumerated()), id: \.offset) { index, session in
                    SessionCard(session: session)
                }
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }

    /// 推薦區域
    private var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("性能建議")
                .font(.headline)

            let recommendations = frameRateController.getPerformanceRecommendations() +
                                learningEngine.getPersonalizedRecommendations()

            if recommendations.isEmpty {
                Text("🎉 系統運行良好，暫無建議")
                    .foregroundColor(.green)
            } else {
                ForEach(recommendations, id: \.self) { recommendation in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text(recommendation)
                            .font(.body)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }

    // MARK: - Methods

    private func startRealTimeUpdates() {
        guard isRealTimeEnabled else { return }

        updateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            // 觸發 UI 更新（實際資料會通過 @Published 自動更新）
        }
    }

    private func stopRealTimeUpdates() {
        updateTimer?.invalidate()
        updateTimer = nil
    }

    private func exportData() {
        // 導出功能實作
    }

    private func resetStatistics() {
        // 重置統計功能實作
    }

    // MARK: - Helper Methods

    private func getMemoryUsagePercentage() -> Float {
        // 簡化的記憶體使用率計算
        return 0.6 // 模擬值
    }

    private func getMemoryPressureValue(_ pressure: SystemPerformanceState.MemoryPressure) -> Double {
        switch pressure {
        case .normal: return 0.3
        case .warning: return 0.6
        case .urgent: return 1.0
        }
    }

    private func getThermalStateValue(_ state: ProcessInfo.ThermalState) -> Double {
        switch state {
        case .nominal: return 0.2
        case .fair: return 0.4
        case .serious: return 0.7
        case .critical: return 1.0
        @unknown default: return 0.5
        }
    }
}

// MARK: - Supporting Views

/// 指標卡片
struct MetricCard: View {
    let title: String
    let value: String
    let unit: String
    let trend: PerformanceMetrics.TrendDirection
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Image(systemName: trendIcon)
                    .foregroundColor(trendColor)
                    .font(.caption)
            }

            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(color)

                Text(unit)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(8)
        .shadow(radius: 1)
    }

    private var trendIcon: String {
        switch trend {
        case .improving: return "arrow.up"
        case .stable: return "minus"
        case .degrading: return "arrow.down"
        }
    }

    private var trendColor: Color {
        switch trend {
        case .improving: return .green
        case .stable: return .gray
        case .degrading: return .red
        }
    }
}

/// 狀態指示器
struct StatusIndicator: View {
    let title: String
    let status: Status
    let icon: String

    enum Status {
        case active, inactive, warning, error

        var color: Color {
            switch self {
            case .active: return .green
            case .inactive: return .gray
            case .warning: return .orange
            case .error: return .red
            }
        }
    }

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(status.color)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }
}

/// 健康度指示器
struct HealthIndicator: View {
    let title: String
    let value: Float
    let format: String
    let goodThreshold: Float
    let warningThreshold: Float

    var body: some View {
        HStack {
            Text(title)
                .font(.body)

            Spacer()

            Text(String(format: format, value * 100))
                .fontWeight(.semibold)
                .foregroundColor(healthColor)

            Circle()
                .fill(healthColor)
                .frame(width: 8, height: 8)
        }
    }

    private var healthColor: Color {
        if value < goodThreshold {
            return .green
        } else if value < warningThreshold {
            return .orange
        } else {
            return .red
        }
    }
}

/// 資源使用條
struct ResourceBar: View {
    let title: String
    let value: Double
    let maxValue: Double
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                Spacer()
                Text(String(format: "%.0f%%", (value / maxValue) * 100))
                    .fontWeight(.semibold)
            }

            ProgressView(value: value, total: maxValue)
                .progressViewStyle(LinearProgressViewStyle(tint: color))
        }
    }
}

/// 手勢類型卡片
struct GestureTypeCard: View {
    let type: MicroGestureType
    let detections: Int
    let confidence: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: type.iconName)
                    .foregroundColor(.blue)

                Text(type.displayName)
                    .font(.caption)
                    .fontWeight(.semibold)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("\(detections)")
                    .font(.title3)
                    .fontWeight(.bold)

                Text(String(format: "%.0f%% 信心", confidence * 100))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

/// 微手勢開關
struct MicroGestureToggle: View {
    let gestureType: MicroGestureType
    let isEnabled: Bool
    let onToggle: (Bool) -> Void

    var body: some View {
        HStack {
            Image(systemName: gestureType.iconName)
                .foregroundColor(.blue)
                .frame(width: 20)

            Text(gestureType.displayName)

            Spacer()

            Text(gestureType.difficulty.description)
                .font(.caption)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(4)

            Toggle("", isOn: .constant(isEnabled))
                .onChange(of: isEnabled) { newValue in
                    onToggle(newValue)
                }
        }
    }
}

/// 準確率指標
struct AccuracyMetric: View {
    let title: String
    let value: Double
    let color: Color

    var body: some View {
        HStack {
            Text(title)

            Spacer()

            Text(String(format: "%.1f%%", value * 100))
                .fontWeight(.semibold)
                .foregroundColor(color)

            ProgressView(value: value)
                .progressViewStyle(LinearProgressViewStyle(tint: color))
                .frame(width: 60)
        }
    }
}

/// 會話卡片
struct SessionCard: View {
    let session: PersonalGestureProfile.LearningSession

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(session.instrumentType.displayName)
                    .font(.body)
                    .fontWeight(.semibold)

                Text(formatDate(session.date))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(session.gesturesProcessed) 手勢")
                    .font(.caption)

                Text(String(format: "+%.1f%%", session.accuracyImprovement * 100))
                    .font(.caption)
                    .foregroundColor(.green)
            }
        }
        .padding(.vertical, 4)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Previews

#Preview {
    DashboardView()
}
