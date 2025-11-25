//
//  BrowseView.swift
//  GazeTurn
//
//  Created by Jhen Mu on 2025/3/17.
//

import SwiftUI
import PDFKit

/// 樂譜瀏覽介面 - 顯示並翻閱樂譜
struct BrowseView: View {

    // MARK: - Properties

    /// 要顯示的檔案
    let file: MusicFile

    /// ViewModel（統一管理手勢和頁面控制）
    @StateObject private var viewModel = GazeTurnViewModel()

    /// 當前頁面索引（從 ViewModel 同步）
    @State private var currentPage: Int = 0

    /// 總頁數
    @State private var totalPages: Int = 1

    /// 是否顯示控制按鈕
    @State private var showingControls: Bool = true

    /// 是否顯示手勢狀態（除錯用）
    @State private var showingGestureStatus: Bool = false

    /// 是否顯示詳細的手勢視覺化
    @State private var showingDetailedVisualization: Bool = false

    /// 用於導航返回
    @Environment(\.dismiss) private var dismiss

    // MARK: - Body

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()

                // 內容顯示
                contentView

                // 控制覆蓋層
                if showingControls {
                    controlOverlay
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    HStack(spacing: 12) {
                        Button {
                            showingGestureStatus.toggle()
                            if showingGestureStatus {
                                showingDetailedVisualization = false
                            }
                        } label: {
                            Image(systemName: showingGestureStatus ? "eye.fill" : "eye.slash.fill")
                                .foregroundColor(.white)
                        }

                        Button {
                            showingDetailedVisualization.toggle()
                            if showingDetailedVisualization {
                                showingGestureStatus = false
                            }
                        } label: {
                            Image(systemName: showingDetailedVisualization ? "chart.bar.fill" : "chart.bar")
                                .foregroundColor(.white)
                        }
                    }
                }

                ToolbarItem(placement: .principal) {
                    toolbarTitle
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color.black.opacity(0.8), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .statusBar(hidden: !showingControls)
            .onTapGesture {
                withAnimation {
                    showingControls.toggle()
                }
            }
            .overlay(alignment: .topLeading) {
                if showingGestureStatus {
                    gestureStatusOverlay
                } else if showingDetailedVisualization {
                    detailedVisualizationOverlay
                }
            }
            .onAppear {
                setupViewModel()
                requestCameraPermissionAndStart()
            }
            .onDisappear {
                viewModel.stopCamera()
            }
        }
    }

    // MARK: - Gesture Status Overlay

    private var gestureStatusOverlay: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("手勢狀態")
                .font(.headline)
                .foregroundColor(.white)

            Text(viewModel.gestureStatusMessage)
                .font(.caption)
                .foregroundColor(.white.opacity(0.9))

            if viewModel.isWaitingForConfirmation {
                HStack {
                    ProgressView()
                        .tint(.white)
                    Text("等待眨眼確認...")
                        .font(.caption)
                        .foregroundColor(.yellow)
                }
            }

            Text("相機：\(viewModel.isCameraAvailable ? "運行中" : "未啟動")")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.7))
        )
        .padding()
    }

    // MARK: - Detailed Visualization Overlay

    private var detailedVisualizationOverlay: some View {
        ScrollView {
            GestureVisualizationView(
                data: $viewModel.visualizationData,
                instrumentMode: InstrumentMode.current()
            )
            .padding()
        }
        .frame(maxHeight: UIScreen.main.bounds.height * 0.7)
    }

    // MARK: - Content View

    @ViewBuilder
    private var contentView: some View {
        switch file.fileType {
        case .pdf:
            PDFViewRepresentable(
                file: file,
                currentPage: $currentPage,
                totalPages: $totalPages
            )
        case .image:
            ImageView(file: file)
        }
    }

    // MARK: - Toolbar Title

    private var toolbarTitle: some View {
        VStack(spacing: 2) {
            Text(file.name)
                .font(.headline)
                .foregroundColor(.white)
                .lineLimit(1)

            if totalPages > 1 {
                Text("\(currentPage + 1) / \(totalPages)")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
    }

    // MARK: - Control Overlay

    private var controlOverlay: some View {
        VStack {
            Spacer()

            HStack(spacing: 40) {
                // 上一頁按鈕
                PageControlButton(
                    systemName: "chevron.left",
                    isEnabled: currentPage > 0
                ) {
                    previousPage()
                }

                // 頁面指示器
                VStack(spacing: 4) {
                    Text("\(currentPage + 1)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Text("/ \(totalPages)")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }

                // 下一頁按鈕
                PageControlButton(
                    systemName: "chevron.right",
                    isEnabled: currentPage < totalPages - 1
                ) {
                    nextPage()
                }
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 24)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.black.opacity(0.7))
                    .shadow(radius: 10)
            )
            .padding(.bottom, 50)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    // MARK: - Actions

    private func nextPage() {
        guard currentPage < totalPages - 1 else { return }
        withAnimation {
            currentPage += 1
        }
        hapticFeedback()
    }

    private func previousPage() {
        guard currentPage > 0 else { return }
        withAnimation {
            currentPage -= 1
        }
        hapticFeedback()
    }

    private func hapticFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    // MARK: - ViewModel Setup

    private func setupViewModel() {
        // 設定總頁數
        viewModel.setTotalPages(totalPages)

        // 設定頁面變更回調
        viewModel.onPageChange = { [self] newPage in
            withAnimation {
                currentPage = newPage
            }
        }

        // 同步當前頁面到 ViewModel
        viewModel.currentPage = currentPage
    }

    private func requestCameraPermissionAndStart() {
        switch viewModel.cameraPermissionStatus {
        case .authorized:
            viewModel.startCamera()
        case .notDetermined:
            viewModel.requestCameraPermission { granted in
                if granted {
                    viewModel.startCamera()
                }
            }
        case .denied, .restricted:
            // 顯示權限被拒絕的訊息
            print("相機權限被拒絕，請至設定中開啟")
        @unknown default:
            break
        }
    }
}

// MARK: - Page Control Button

struct PageControlButton: View {
    let systemName: String
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.title)
                .foregroundColor(isEnabled ? .white : .gray)
                .frame(width: 60, height: 60)
                .background(
                    Circle()
                        .fill(isEnabled ? Color.accentColor : Color.gray.opacity(0.3))
                )
        }
        .disabled(!isEnabled)
    }
}

// MARK: - PDF View Representable

struct PDFViewRepresentable: UIViewRepresentable {
    let file: MusicFile
    @Binding var currentPage: Int
    @Binding var totalPages: Int

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.backgroundColor = .black
        pdfView.autoScales = true
        pdfView.displayMode = .singlePage
        pdfView.displayDirection = .horizontal
        pdfView.usePageViewController(true, withViewOptions: nil)

        // 載入 PDF
        if let document = PDFDocument(url: file.url) {
            pdfView.document = document
            DispatchQueue.main.async {
                totalPages = document.pageCount
            }
        }

        // 設定通知觀察
        NotificationCenter.default.addObserver(
            forName: .PDFViewPageChanged,
            object: pdfView,
            queue: .main
        ) { _ in
            if let currentPDFPage = pdfView.currentPage,
               let document = pdfView.document {
                let pageIndex = document.index(for: currentPDFPage)
                currentPage = pageIndex
            }
        }

        return pdfView
    }

    func updateUIView(_ pdfView: PDFView, context: Context) {
        // 如果當前頁面改變，更新 PDF 視圖
        if let document = pdfView.document,
           currentPage < document.pageCount,
           let page = document.page(at: currentPage),
           pdfView.currentPage != page {
            pdfView.go(to: page)
        }
    }
}

// MARK: - Image View

struct ImageView: View {
    let file: MusicFile
    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                ProgressView()
                    .tint(.white)
            }
        }
        .onAppear {
            loadImage()
        }
    }

    private func loadImage() {
        DispatchQueue.global(qos: .userInitiated).async {
            if let loadedImage = UIImage(contentsOfFile: file.url.path) {
                DispatchQueue.main.async {
                    image = loadedImage
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("PDF File") {
    // Note: Preview requires an actual PDF file
    BrowseView(
        file: MusicFile(
            name: "Sample Score",
            url: URL(fileURLWithPath: "/tmp/sample.pdf"),
            fileType: .pdf,
            pageCount: 5
        )
    )
}

#Preview("Image File") {
    // Note: Preview requires an actual image file
    BrowseView(
        file: MusicFile(
            name: "Sample Image",
            url: URL(fileURLWithPath: "/tmp/sample.png"),
            fileType: .image
        )
    )
}
