import Foundation
import UIKit
import PDFKit

/// `PageTurnManager` 負責控制樂譜翻頁，
/// 接收來自 GazeDetector/BlinkRecognizer 的訊號來執行翻頁動作。
class PageTurnManager {
    /// 目前的 PDF 視圖（用於 PDF 顯示）
    private weak var pdfView: PDFView?
    /// 目前的圖片樂譜視圖（用於圖片顯示）
    private weak var imageView: UIImageView?
    /// 樂譜頁面列表（可包含 PDF 頁面與圖片）
    private var pages: [Any] = [] // 可以是 PDFPage 或 UIImage
    /// 當前頁面索引
    private var currentPageIndex: Int = 0
    
    /// 初始化 PageTurnManager，綁定 PDFView 或 UIImageView。
    /// - Parameters:
    ///   - pdfView: 樂譜顯示的 PDFView（可選）
    ///   - imageView: 樂譜顯示的 UIImageView（可選）
    init(pdfView: PDFView? = nil, imageView: UIImageView? = nil) {
        self.pdfView = pdfView
        self.imageView = imageView
    }
    
    /// 從本地端載入混合的樂譜內容（PDF 與圖片）
    /// - Parameter fileURLs: PDF 或圖片的本地檔案路徑
    func loadMixedFiles(from fileURLs: [URL]) {
        pages.removeAll()
        
        for fileURL in fileURLs {
            if fileURL.pathExtension.lowercased() == "pdf" {
                if let document = PDFDocument(url: fileURL) {
                    for i in 0..<document.pageCount {
                        if let page = document.page(at: i) {
                            pages.append(page)
                        }
                    }
                }
            } else if let image = UIImage(contentsOfFile: fileURL.path) {
                pages.append(image)
            }
        }
        
        if !pages.isEmpty {
            currentPageIndex = 0
            updateView()
        } else {
            print("無法載入任何有效的樂譜頁面")
        }
    }
    
    /// 執行翻頁動作。
    /// - Parameter next: 翻頁方向（`true` 代表下一頁，`false` 代表上一頁）
    func turnPage(next: Bool) {
        guard !pages.isEmpty else { return }
        
        if next {
            if currentPageIndex < pages.count - 1 {
                currentPageIndex += 1
                updateView()
            }
        } else {
            if currentPageIndex > 0 {
                currentPageIndex -= 1
                updateView()
            }
        }
    }
    
    /// 更新視圖，顯示當前頁面（無論是 PDF 或圖片）
    private func updateView() {
        guard !pages.isEmpty else { return }
        
        if let pdfPage = pages[currentPageIndex] as? PDFPage, let pdfView = pdfView {
            let document = PDFDocument()
            document.insert(pdfPage, at: 0)
            pdfView.document = document
        } else if let image = pages[currentPageIndex] as? UIImage, let imageView = imageView {
            imageView.image = image
        }
    }
}
