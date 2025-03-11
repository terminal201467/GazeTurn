//
//  VisionProcessor.swift
//  GazeTurn
//
//  Created by Jhen Mu on 2025/3/9.
//

import Vision
import AVFoundation

/// `VisionProcessor` 負責處理 Vision 框架的影像分析，
/// 包括臉部偵測、眼動追蹤等。
class VisionProcessor {
    /// Vision 請求處理器
    private let sequenceHandler = VNSequenceRequestHandler()
    /// 臉部特徵偵測請求
    private let faceLandmarksRequest: VNDetectFaceLandmarksRequest
    
    /// 初始化 VisionProcessor
    init() {
        faceLandmarksRequest = VNDetectFaceLandmarksRequest()
        faceLandmarksRequest.revision = VNDetectFaceLandmarksRequestRevision3
    }
    
    /// 處理相機影像幀，並執行臉部偵測。
    /// - Parameter pixelBuffer: 來自相機的影像數據。
    /// - Returns: 偵測到的 `VNFaceObservation`，若無偵測到臉部則回傳 `nil`。
    func processFrame(_ pixelBuffer: CVPixelBuffer) -> VNFaceObservation? {
        do {
            try sequenceHandler.perform([faceLandmarksRequest], on: pixelBuffer, orientation: .up)
            if let results = faceLandmarksRequest.results as? [VNFaceObservation], let face = results.first {
                return face
            }
        } catch {
            print("Vision request failed: \(error)")
        }
        return nil
    }
}
