import SwiftUI
import VisionKit
import AVFoundation

// MARK: - VisionKit Camera View Controller Wrapper

/// SwiftUI wrapper for VisionKit's DataScannerViewController
/// Allows scanning and capturing images from camera for text recognition
struct CameraViewControllerWrapper: UIViewControllerRepresentable {
    var onImageCaptured: (UIImage) -> Void
    var onError: (Error) -> Void
    var onClose: (() -> Void)? = nil
    
    func makeUIViewController(context: Context) -> UIViewController {
        let controller = CameraViewController()
        controller.onImageCaptured = onImageCaptured
        controller.onError = onError
        controller.onClose = onClose
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // No updates needed
    }
}

// MARK: - Camera View Controller

class CameraViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    var onImageCaptured: ((UIImage) -> Void)?
    var onError: ((Error) -> Void)?
    var onClose: (() -> Void)?
    
    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var outputView: UIView?
    private var isProcessing = false
    private var lastFrameTime: Date = Date()
    
    // UI Elements
    private let captureButton = UIButton()
    private let flashButton = UIButton()
    private let closeButton = UIButton()
    private let focusIndicator = UIView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
        setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startCamera()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopCamera()
    }
    
    // MARK: - Camera Setup
    
    private func setupCamera() {
        captureSession = AVCaptureSession()
        captureSession?.sessionPreset = .high
        
        guard let captureSession = captureSession else { return }
        
        // Get camera device
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera, .builtInUltraWideCamera],
            mediaType: .video,
            position: .back
        )
        
        guard let camera = discoverySession.devices.first else {
            DispatchQueue.main.async { [weak self] in
                self?.onError?(CameraError.cameraNotAvailable)
            }
            return
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: camera)
            
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
            }
            
            // Add video output
            let output = AVCaptureVideoDataOutput()
            output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "video.processing.queue"))
            
            if captureSession.canAddOutput(output) {
                captureSession.addOutput(output)
            }
            
            // Add preview layer
            previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer?.videoGravity = .resizeAspectFill
            
            if let previewLayer = previewLayer {
                view.layer.addSublayer(previewLayer)
            }
            
        } catch {
            DispatchQueue.main.async { [weak self] in
                self?.onError?(error)
            }
        }
    }
    
    private func startCamera() {
        DispatchQueue.global(qos: .background).async { [weak self] in
            self?.captureSession?.startRunning()
        }
    }
    
    private func stopCamera() {
        captureSession?.stopRunning()
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        view.backgroundColor = .black
        
        // Preview layer frame
        if let previewLayer = previewLayer {
            previewLayer.frame = view.bounds
        }
        
        // Close button
        closeButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        closeButton.tintColor = .white
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        view.addSubview(closeButton)
        
        // Capture button
        captureButton.backgroundColor = UIColor(hex: "0EB060")
        captureButton.setImage(UIImage(systemName: "camera.fill"), for: .normal)
        captureButton.tintColor = .white
        captureButton.layer.cornerRadius = 50
        captureButton.addTarget(self, action: #selector(captureTapped), for: .touchUpInside)
        view.addSubview(captureButton)
        
        // Flash button
        flashButton.setImage(UIImage(systemName: "bolt.fill"), for: .normal)
        flashButton.tintColor = .white
        flashButton.addTarget(self, action: #selector(flashTapped), for: .touchUpInside)
        view.addSubview(flashButton)
        
        // Focus indicator
        focusIndicator.layer.borderColor = UIColor(hex: "0EB060").cgColor
        focusIndicator.layer.borderWidth = 2
        focusIndicator.layer.cornerRadius = 25
        focusIndicator.alpha = 0
        view.addSubview(focusIndicator)
        
        // Layout
        setupConstraints()
    }
    
    private func setupConstraints() {
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        captureButton.translatesAutoresizingMaskIntoConstraints = false
        flashButton.translatesAutoresizingMaskIntoConstraints = false
        focusIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // Close button (top-left)
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            closeButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            closeButton.widthAnchor.constraint(equalToConstant: 44),
            closeButton.heightAnchor.constraint(equalToConstant: 44),
            
            // Flash button (top-right)
            flashButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            flashButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            flashButton.widthAnchor.constraint(equalToConstant: 44),
            flashButton.heightAnchor.constraint(equalToConstant: 44),
            
            // Capture button (bottom-center)
            captureButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -32),
            captureButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            captureButton.widthAnchor.constraint(equalToConstant: 100),
            captureButton.heightAnchor.constraint(equalToConstant: 100),
            
            // Focus indicator
            focusIndicator.widthAnchor.constraint(equalToConstant: 50),
            focusIndicator.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    // MARK: - Button Actions
    
    @objc private func closeTapped() {
        onClose?()
    }
    
    @objc private func captureTapped() {
        captureCurrentFrame()
    }
    
    @objc private func flashTapped() {
        toggleFlash()
    }
    
    // MARK: - Capture & Processing
    
    private func captureCurrentFrame() {
        guard let captureSession = captureSession else { return }
        
        let settings = [
            kCVPixelBufferPixelFormatTypeKey as String: NSNumber(value: kCVPixelFormatType_32BGRA)
        ]
        
        let output = AVCaptureVideoDataOutput()
        output.videoSettings = settings
        
        // Create a single frame capture
        var capturedImage: UIImage?
        let semaphore = DispatchSemaphore(value: 0)
        
        output.setSampleBufferDelegate(
            FrameCaptureSampleBufferDelegate { buffer in
                capturedImage = self.imageFromSampleBuffer(buffer)
                semaphore.signal()
            },
            queue: DispatchQueue(label: "frame.capture.queue")
        )
        
        if captureSession.canAddOutput(output) {
            captureSession.addOutput(output)
            semaphore.wait(timeout: .now() + 2)
            captureSession.removeOutput(output)
            
            if let image = capturedImage {
                DispatchQueue.main.async {
                    self.onImageCaptured?(image)
                }
            }
        }
    }
    
    private func imageFromSampleBuffer(_ sampleBuffer: CMSampleBuffer) -> UIImage? {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return nil
        }
        
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }
        
        let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer)
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: baseAddress,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue
        ) else {
            return nil
        }
        
        guard let cgImage = context.makeImage() else {
            return nil
        }
        
        return UIImage(cgImage: cgImage, scale: 1, orientation: .right)
    }
    
    private func toggleFlash() {
        guard let device = AVCaptureDevice.default(for: .video) else { return }
        
        do {
            try device.lockForConfiguration()
            
            if device.torchMode == .on {
                device.torchMode = .off
                flashButton.tintColor = .white
            } else {
                try device.setTorchModeOn(level: 1.0)
                flashButton.tintColor = UIColor(hex: "0EB060")
            }
            
            device.unlockForConfiguration()
        } catch {
            DispatchQueue.main.async { [weak self] in
                self?.onError?(error)
            }
        }
    }
    
    // MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // Process video frames for continuous text detection (optional)
        // Can be used for real-time focus guidance
    }
}

// MARK: - Helper Delegate

class FrameCaptureSampleBufferDelegate: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    var onFrame: (CMSampleBuffer) -> Void
    
    init(_ onFrame: @escaping (CMSampleBuffer) -> Void) {
        self.onFrame = onFrame
        super.init()
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        onFrame(sampleBuffer)
    }
}

// MARK: - Error Handling

enum CameraError: LocalizedError {
    case cameraNotAvailable
    case captureSessionError
    
    var errorDescription: String? {
        switch self {
        case .cameraNotAvailable:
            return "Camera is not available on this device"
        case .captureSessionError:
            return "Error setting up camera session"
        }
    }
}

// MARK: - Color Extension

extension UIColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        let scanner = Scanner(string: hex)
        var color: UInt64 = 0
        scanner.scanHexInt64(&color)
        
        let r = CGFloat((color & 0xff0000) >> 16) / 255.0
        let g = CGFloat((color & 0x00ff00) >> 8) / 255.0
        let b = CGFloat(color & 0x0000ff) / 255.0
        
        self.init(red: r, green: g, blue: b, alpha: 1.0)
    }
}
