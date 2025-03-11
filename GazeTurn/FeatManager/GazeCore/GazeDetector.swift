//
//  GazeDetector.swift
//  GazeTurn
//
//  Created by Jhen Mu on 2025/3/9.
//

import Foundation
import Vision
import UIKit

class GazeDetector: NSObject {
    
    private let faceLandMarksRequest: VNDetectFaceLandmarksRequest
    
    private let sequenceHandler = VNSequenceRequestHandler()
    
    /// 記錄最後一次眨眼的時間
    private var lastBlinkTime: Date?
    /// 眨眼計數器
    private var blinkCount = 0
    
    override init() {
        faceLandMarksRequest = VNDetectFaceLandmarksRequest()
        faceLandMarksRequest.revision = VNDetectBarcodesRequestRevision3
        super.init()
    }
    
    /// 處理相機輸入的影像幀，並執行臉部偵測。
    /// - Parameter sampleBuffer: 來自相機的 CMSampleBuffer 影像幀。
    func processFrame(_ sampleBuffer: CMSampleBuffer) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        do {
            try sequenceHandler.perform([faceLandMarksRequest], on: pixelBuffer, orientation: .up)
            
            if let result = faceLandMarksRequest.results, let face = result.first {
                analyzeFaceLandmarks(face)
            }
        } catch {
            print("")
        }
    }
    
    /// 分析臉部特徵，判斷眼睛是否開合。
    /// - Parameter face: Vision 偵測到的臉部觀察物件。
    private func analyzeFaceLandmarks(_ face: VNFaceObservation) {
        guard let leftEye = face.landmarks?.leftEye, let rightEye = face.landmarks?.rightEye else { return }
        
        let leftOpen = isEyeOpen(landmark: leftEye)
        let rightOpen = isEyeOpen(landmark: rightEye)
        
        detectBlink(leftOpen: leftOpen, rightOpen: rightOpen)
    }
    
    /// 判斷眼睛是否張開。
    /// - Parameter landmark: 眼睛的臉部特徵點。
    /// - Returns: `true` 代表眼睛張開，`false` 代表眼睛閉合。
    private func isEyeOpen(landmark: VNFaceLandmarkRegion2D) -> Bool {
        let eyeHeight = abs(landmark.normalizedPoints[1].y - landmark.normalizedPoints[5].y)
        return eyeHeight > 0.03 // 這個閾值可以根據測試微調
    }
    
    /// 偵測眨眼行為，並觸發翻頁事件。
    /// - Parameters:
    ///   - leftOpen: 左眼是否張開。
    ///   - rightOpen: 右眼是否張開。
    private func detectBlink(leftOpen: Bool, rightOpen: Bool) {
        let now = Date()
        
        if !leftOpen && !rightOpen { // 眼睛都閉上時
            if let lastBlink = lastBlinkTime, now.timeIntervalSince(lastBlink) < 0.5 {
                blinkCount += 1
            } else {
                blinkCount = 1
            }
            lastBlinkTime = now
            
            if blinkCount >= 2 { // 快速雙眨眼翻頁
                blinkCount = 0
                NotificationCenter.default.post(name: NSNotification.Name("NextPage"), object: nil)
            }
        }
    }
}
