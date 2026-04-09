import SwiftUI
import PhotosUI

// MARK: - Discovery View
// Main screen for AR-based discovery of educational content

struct DiscoveryView: View {
    @StateObject private var viewModel = DiscoveryViewModel()
    @State private var appeared = false
    @State private var selectedQuestionIndex = 0
    @State private var quizAnswers: [Int: Int] = [:]
    @State private var selectedPhotoItem: PhotosPickerItem?
    
    var onHome: (() -> Void)?
    var onLessons: (() -> Void)?
    var onRank: (() -> Void)?
    var onSettings: (() -> Void)?
    var onNotifications: (() -> Void)?
    var onProfile: (() -> Void)?

    var body: some View {
        ZStack {
            Color(hex: "0A0F0D").ignoresSafeArea()

            VStack(spacing: 0) {
                EVScreenTopBar(onProfile: onProfile, onNotifications: onNotifications)

                ZStack {
                    if viewModel.scannedImage != nil {
                        AROverlayView(viewModel: viewModel, previewImage: viewModel.scannedImage)
                    } else {
                        discoveryIdleView
                    }

                    if case .scanning = viewModel.state {
                        cameraOverlay
                    } else if isProcessingState {
                        processingOverlay
                    }

                    if case .error(let message) = viewModel.state {
                        errorOverlay(message: message)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationBarHidden(true)
        .onAppear { appeared = true }
        .fullScreenCover(isPresented: $viewModel.isShowingCamera) {
            CameraViewControllerWrapper(
                onImageCaptured: { image in
                    handleCapturedImage(image)
                },
                onError: { error in
                    handleCameraError(error)
                },
                onClose: {
                    handleCameraClose()
                }
            )
            .ignoresSafeArea()
        }
        .onChange(of: selectedPhotoItem) { _, newItem in
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    await MainActor.run {
                        viewModel.processLocalImage(image)
                    }
                }
                await MainActor.run {
                    selectedPhotoItem = nil
                }
            }
        }
    }
    
    // MARK: - Idle View (No Content)
    
    private var discoveryIdleView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 22) {
                discoveryHero
                    .padding(.top, 12)

                actionStrip

                featurePreviewCard
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
    }
    
    // MARK: - Content Display View
    
    // MARK: - Camera Overlay
    
    private var cameraOverlay: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Scanning...")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                
                Spacer()
                
                ProgressView()
                    .tint(Color(hex: "0EB060"))
            }
            .padding(16)
            .background(Color.black.opacity(0.8))
            .cornerRadius(12)
            .padding(20)
            
            Spacer()
        }
    }
    
    // MARK: - Processing Overlay
    
    private var processingOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Spacer()
                
                VStack(spacing: 16) {
                    ProgressView(value: viewModel.progress)
                        .tint(Color(hex: "0EB060"))
                    
                    Text(processingStatusText)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("\(Int(viewModel.progress * 100))%")
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding(20)
                .background(Color.black.opacity(0.9))
                .cornerRadius(14)
                .padding(20)
                
                Spacer()
            }
        }
    }
    
    // MARK: - Error Overlay
    
    private func errorOverlay(message: String) -> some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                Spacer()
                
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 44))
                        .foregroundColor(Color(hex: "FF6B6B"))
                    
                    Text("Scan Failed")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text(message)
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                }
                .padding(20)
                .background(Color.black.opacity(0.9))
                .cornerRadius(14)
                .padding(20)
                
                Button(action: { viewModel.clearError() }) {
                    Text("Try Again")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(hex: "0EB060"))
                        .cornerRadius(12)
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
        }
    }
    
    // MARK: - Helpers
    
    private var processingStatusText: String {
        switch viewModel.state {
        case .extractingText:
            return "Extracting text..."
        case .generatingContent:
            return "Generating educational content..."
        case .processingImage:
            return "Processing image..."
        default:
            return "Processing..."
        }
    }

    private var isProcessingState: Bool {
        switch viewModel.state {
        case .processingImage, .extractingText, .generatingContent:
            return true
        default:
            return false
        }
    }

    private func handleCameraError(_ error: Error) {
        Task { @MainActor in
            await Task.yield()
            viewModel.handleCameraError(error)
        }
    }

    private func handleCapturedImage(_ image: UIImage) {
        Task { @MainActor in
            await Task.yield()
            viewModel.handleImageCapture(image)
        }
    }

    private func handleCameraClose() {
        Task { @MainActor in
            await Task.yield()
            viewModel.closeCamera()
        }
    }

    private var discoveryHero: some View {
        VStack(spacing: 14) {
            Image(systemName: "sparkles.rectangle.stack")
                .font(.system(size: 44, weight: .light))
                .foregroundColor(Color(hex: "0EB060"))
                .padding(.bottom, 6)

            Text("Discovery Mode")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            Text("Scan books, posters, labels, or use your gallery to turn real-world text into learning content.")
                .font(.system(size: 15, design: .rounded))
                .foregroundColor(.white.opacity(0.68))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }

    private var actionStrip: some View {
        HStack(spacing: 10) {
            Button(action: { viewModel.openCamera() }) {
                Label("Camera", systemImage: "camera.fill")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color(hex: "0EB060"))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }

            PhotosPicker(selection: $selectedPhotoItem, matching: .images, photoLibrary: .shared()) {
                Label("Gallery", systemImage: "photo.on.rectangle.angled")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
    }

    private var featurePreviewCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("What Discovery gives you")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundColor(.white)

            VStack(alignment: .leading, spacing: 10) {
                featureRow(icon: "text.viewfinder", text: "OCR text extraction")
                featureRow(icon: "barcode.viewfinder", text: "ISBN / barcode detection")
                featureRow(icon: "brain.head.profile", text: "AI summary and quiz")
                featureRow(icon: "arkit", text: "Real AR overlay experience")
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }

    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Color(hex: "0EB060"))
                .frame(width: 22)

            Text(text)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.82))

            Spacer()
        }
    }
    
    private func difficultyColor(_ level: String) -> Color {
        switch level.lowercased() {
        case "beginner":
            return Color(hex: "0EB060")
        case "intermediate":
            return Color(hex: "FFB800")
        case "advanced":
            return Color(hex: "FF6B6B")
        default:
            return Color.gray
        }
    }
}

#Preview {
    DiscoveryView()
}
