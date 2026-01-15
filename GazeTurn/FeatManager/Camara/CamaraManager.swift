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

    /// 是否已完成設定
    private var isConfigured = false

    weak var delegate: CameraManagerDelegate?

    override init() {
        super.init()
        // 不在 init 中設定相機，等到 startSession 時再設定
    }

    /// 設定相機輸入與輸出
    private func setupCamera() -> Bool {
        guard !isConfigured else { return true }

        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
            print("相機不可用")
            return false
        }

        // 使用 beginConfiguration/commitConfiguration 批次處理設定
        captureSession.beginConfiguration()
        defer { captureSession.commitConfiguration() }

        captureSession.sessionPreset = .high

        do {
            let input = try AVCaptureDeviceInput(device: camera)
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
            } else {
                print("無法添加相機輸入")
                return false
            }

            videoOutput.setSampleBufferDelegate(self, queue: sessionQueue)
            videoOutput.alwaysDiscardsLateVideoFrames = true
            videoOutput.videoSettings = [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
            ]

            if captureSession.canAddOutput(videoOutput) {
                captureSession.addOutput(videoOutput)

                // 設定視訊連線方向
                if let connection = videoOutput.connection(with: .video) {
                    if connection.isVideoOrientationSupported {
                        connection.videoOrientation = .portrait
                    }
                    if connection.isVideoMirroringSupported {
                        connection.isVideoMirrored = true
                    }
                }
            } else {
                print("無法添加視訊輸出")
                return false
            }

            isConfigured = true
            return true

        } catch {
            print("無法設置相機輸入: \(error)")
            return false
        }
    }

    /// 開始相機捕捉
    func startSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }

            // 確保已設定相機
            guard self.setupCamera() else {
                print("相機設定失敗")
                return
            }

            if !self.captureSession.isRunning {
                self.captureSession.startRunning()
            }
        }
    }

    /// 停止相機捕捉
    func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
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
