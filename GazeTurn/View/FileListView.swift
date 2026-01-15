//
//  FileListView.swift
//  GazeTurn
//
//  Created by Jhen Mu on 2025/3/17.
//

import SwiftUI
import UniformTypeIdentifiers

/// 檔案列表視圖 - 顯示並管理樂譜檔案
struct FileListView: View {

    // MARK: - Properties

    /// 檔案管理器
    @StateObject private var fileManager = MusicFileManager()

    /// 是否顯示檔案選擇器
    @State private var showingFilePicker = false

    /// 是否顯示瀏覽介面
    @State private var showingBrowseView = false

    /// 當前選擇的檔案
    @State private var selectedFile: MusicFile?

    // MARK: - Body

    var body: some View {
        ZStack {
            if fileManager.files.isEmpty {
                emptyState
            } else {
                fileList
            }
        }
        .sheet(isPresented: $showingFilePicker) {
            DocumentPicker(fileManager: fileManager, isPresented: $showingFilePicker)
        }
        .sheet(item: $selectedFile) { file in
            BrowseView(file: file)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 24) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 80))
                .foregroundColor(.secondary)

            VStack(spacing: 8) {
                Text("尚未匯入樂譜")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("點擊下方按鈕匯入 PDF 或圖片格式的樂譜")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button(action: {
                showingFilePicker = true
            }) {
                Label("匯入樂譜", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 16)
                    .background(Color.accentColor)
                    .cornerRadius(12)
            }
        }
        .padding()
    }

    // MARK: - File List

    private var fileList: some View {
        List {
            ForEach(fileManager.files) { file in
                Button {
                    selectedFile = file
                } label: {
                    FileRow(file: file)
                }
                .buttonStyle(.plain)
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        fileManager.removeFile(file)
                    } label: {
                        Label("刪除", systemImage: "trash")
                    }
                }
            }
        }
        .listStyle(.plain)
        .overlay(alignment: .bottom) {
            addButton
        }
    }

    // MARK: - Add Button

    private var addButton: some View {
        Button(action: {
            showingFilePicker = true
        }) {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
                Text("匯入樂譜")
                    .font(.headline)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.accentColor)
            .cornerRadius(12)
            .shadow(radius: 4)
        }
        .padding()
    }
}

// MARK: - File Row

struct FileRow: View {
    let file: MusicFile

    var body: some View {
        HStack(spacing: 16) {
            // 檔案圖示
            Image(systemName: file.fileType.iconName)
                .font(.title)
                .foregroundColor(.accentColor)
                .frame(width: 44, height: 44)
                .background(Color.accentColor.opacity(0.1))
                .cornerRadius(8)

            // 檔案資訊
            VStack(alignment: .leading, spacing: 4) {
                Text(file.name)
                    .font(.headline)
                    .lineLimit(2)

                HStack {
                    Label(file.fileType.displayName, systemImage: file.fileType.iconName)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if let pageCount = file.pageCount, pageCount > 1 {
                        Text("•")
                            .foregroundColor(.secondary)
                        Text("\(pageCount) 頁")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            // 右箭頭
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Document Picker

struct DocumentPicker: UIViewControllerRepresentable {
    @ObservedObject var fileManager: MusicFileManager
    @Binding var isPresented: Bool

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(
            forOpeningContentTypes: [
                .pdf,
                .png,
                .jpeg,
                .image
            ],
            asCopy: true
        )
        picker.allowsMultipleSelection = true
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPicker

        init(parent: DocumentPicker) {
            self.parent = parent
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            for url in urls {
                parent.fileManager.addFile(from: url)
            }
            parent.isPresented = false
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            parent.isPresented = false
        }
    }
}

// MARK: - Music File Model

/// 樂譜檔案模型
struct MusicFile: Identifiable, Codable {
    let id: UUID
    let name: String
    let url: URL
    let fileType: MusicFileType
    let dateAdded: Date
    var pageCount: Int?

    init(name: String, url: URL, fileType: MusicFileType, pageCount: Int? = nil) {
        self.id = UUID()
        self.name = name
        self.url = url
        self.fileType = fileType
        self.dateAdded = Date()
        self.pageCount = pageCount
    }
}

/// 樂譜檔案類型
enum MusicFileType: String, Codable {
    case pdf
    case image

    var displayName: String {
        switch self {
        case .pdf: return "PDF"
        case .image: return "圖片"
        }
    }

    var iconName: String {
        switch self {
        case .pdf: return "doc.text.fill"
        case .image: return "photo.fill"
        }
    }

    static func from(url: URL) -> MusicFileType {
        let pathExtension = url.pathExtension.lowercased()
        switch pathExtension {
        case "pdf":
            return .pdf
        case "png", "jpg", "jpeg", "heic":
            return .image
        default:
            return .image
        }
    }
}

// MARK: - Music File Manager

/// 樂譜檔案管理器
class MusicFileManager: ObservableObject {
    @Published var files: [MusicFile] = []

    private let filesKey = "savedMusicFiles"

    init() {
        loadFiles()
    }

    /// 新增檔案
    func addFile(from url: URL) {
        // 開始存取安全範圍資源
        guard url.startAccessingSecurityScopedResource() else {
            print("無法存取檔案: \(url)")
            return
        }
        defer { url.stopAccessingSecurityScopedResource() }

        // 複製檔案到應用程式目錄
        guard let destinationURL = copyFileToDocumentsDirectory(from: url) else {
            print("複製檔案失敗")
            return
        }

        let fileType = MusicFileType.from(url: url)
        let fileName = url.deletingPathExtension().lastPathComponent

        // 如果是 PDF，計算頁數
        var pageCount: Int?
        if fileType == .pdf {
            pageCount = getPDFPageCount(from: destinationURL)
        }

        let musicFile = MusicFile(
            name: fileName,
            url: destinationURL,
            fileType: fileType,
            pageCount: pageCount
        )

        files.append(musicFile)
        saveFiles()
    }

    /// 移除檔案
    func removeFile(_ file: MusicFile) {
        // 刪除實際檔案
        try? FileManager.default.removeItem(at: file.url)

        // 從列表移除
        files.removeAll { $0.id == file.id }
        saveFiles()
    }

    // MARK: - Private Methods

    private func copyFileToDocumentsDirectory(from sourceURL: URL) -> URL? {
        let fileManager = FileManager.default
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }

        let fileName = sourceURL.lastPathComponent
        let destinationURL = documentsURL.appendingPathComponent(fileName)

        // 如果檔案已存在，先刪除
        if fileManager.fileExists(atPath: destinationURL.path) {
            try? fileManager.removeItem(at: destinationURL)
        }

        do {
            try fileManager.copyItem(at: sourceURL, to: destinationURL)
            return destinationURL
        } catch {
            print("複製檔案錯誤: \(error)")
            return nil
        }
    }

    private func getPDFPageCount(from url: URL) -> Int? {
        guard let document = CGPDFDocument(url as CFURL) else {
            return nil
        }
        return document.numberOfPages
    }

    private func saveFiles() {
        if let encoded = try? JSONEncoder().encode(files) {
            UserDefaults.standard.set(encoded, forKey: filesKey)
        }
    }

    private func loadFiles() {
        guard let data = UserDefaults.standard.data(forKey: filesKey),
              let decoded = try? JSONDecoder().decode([MusicFile].self, from: data) else {
            return
        }

        // 過濾掉不存在的檔案
        files = decoded.filter { FileManager.default.fileExists(atPath: $0.url.path) }
    }
}

// MARK: - Preview

#Preview("Empty State") {
    NavigationStack {
        FileListView()
            .navigationTitle("GazeTurn")
    }
}

#Preview("With Files") {
    NavigationStack {
        FileListView()
            .navigationTitle("GazeTurn")
    }
}
