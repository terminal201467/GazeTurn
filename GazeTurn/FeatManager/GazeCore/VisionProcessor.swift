//
//  VisionProcessor.swift
//  GazeTurn
//
//  Created by Jhen Mu on 2025/3/9.
//

import Vision
import AVFoundation

/// `VisionProcessor` 負責處理 Vision 框架的影像分析，
/// 包括臉部偵測、眼動追蹤、頭部姿態偵測等。
///
/// 此類返回完整的 VNFaceObservation，其中包含：
/// - landmarks: 臉部特徵點（眼睛、鼻子、嘴巴等）
/// - yaw: 頭部左右旋轉角度
/// - pitch: 頭部上下傾斜角度
/// - roll: 頭部左右傾斜角度
class VisionProcessor {
    /// Vision 請求處理器
    private let sequenceHandler = VNSequenceRequestHandler()
    /// 臉部特徵偵測請求
    private let faceLandmarksRequest: VNDetectFaceLandmarksRequest

    /// 初始化 VisionProcessor
    init() {
        faceLandmarksRequest = VNDetectFaceLandmarksRequest()
        // 使用最新的臉部特徵偵測版本
        faceLandmarksRequest.revision = VNDetectFaceLandmarksRequestRevision3
        // 確保返回頭部姿態資訊 (yaw, pitch, roll)
        // 注意：VNFaceObservation 預設就會包含頭部姿態資訊
    }
    
    /// 處理相機影像幀，並執行臉部偵測。
    /// - Parameter pixelBuffer: 來自相機的影像數據。
    /// - Returns: 偵測到的 `VNFaceObservation`，若無偵測到臉部則回傳 `nil`。
    func processFrame(_ pixelBuffer: CVPixelBuffer) -> VNFaceObservation? {
        do {
            try sequenceHandler.perform([faceLandmarksRequest], on: pixelBuffer, orientation: .up)
            if let results = faceLandmarksRequest.results, let face = results.first {
                return face
            }
        } catch {
            print("Vision request failed: \(error)")
        }
        return nil
    }
}
