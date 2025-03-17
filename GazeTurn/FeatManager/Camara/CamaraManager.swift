//
//  CamaraManager.swift
//  GazeTurn
//
//  Created by Jhen Mu on 2025/3/9.
//

import AVFoundation

/// `CameraManager` 負責管理相機輸入，將影像數據傳遞給 VisionProcessor 進行分析。
class CameraManager: NSObject {
    
    private let captureSession = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let sessionQueue = DispatchQueue(label: "cameraSessionQueue")
    
    weak var delegate: CameraManagerDelegate?
    
    override init() {
        super.init()
        setupCamera()
    }
    
    /// 設定相機輸入與輸出
    private func setupCamera() {
        captureSession.sessionPreset = .high
        
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
            print("相機不可用")
            return
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: camera)
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
            }
            
            videoOutput.setSampleBufferDelegate(self, queue: sessionQueue)
            videoOutput.alwaysDiscardsLateVideoFrames = true
            
            if captureSession.canAddOutput(videoOutput) {
                captureSession.addOutput(videoOutput)
            }
            
        } catch {
            print("無法設置相機輸入: \(error)")
        }
    }
    
    /// 開始相機捕捉
    func startSession() {
        sessionQueue.async {
            if !self.captureSession.isRunning {
                self.captureSession.startRunning()
            }
        }
    }
    
    /// 停止相機捕捉
    func stopSession() {
        sessionQueue.async {
            if self.captureSession.isRunning {
                self.captureSession.stopRunning()
            }
        }
    }
}

/// 相機數據輸出代理，將影像幀傳遞給 `VisionProcessor`
extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        delegate?.didCaptureFrame(sampleBuffer)
    }
}

/// `CameraManager` 的代理協議，讓其他類別獲取影像數據
protocol CameraManagerDelegate: AnyObject {
    func didCaptureFrame(_ sampleBuffer: CMSampleBuffer)
}
