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
    var onProfile: (() -> Void)?

    var body: some View {
        ZStack(alignment: .bottom) {
            Color(hex: "0A0F0D").ignoresSafeArea()

            // Content Layer
            if case .displayingContent = viewModel.state, viewModel.educationalContent != nil {
                discoveryContentView
            } else {
                discoveryIdleView
            }
            
            // Loading/Processing Overlay
            if case .scanning = viewModel.state {
                cameraOverlay
            } else if isProcessingState {
                processingOverlay
            }
            
            // Error Overlay
            if case .error(let message) = viewModel.state {
                errorOverlay(message: message)
            }
            
            // AR Overlay (full screen when active)
            if viewModel.isShowingAROverlay {
                AROverlayView(viewModel: viewModel)
                    .zIndex(100)
            }
            
            // Bottom Navigation
            if !viewModel.isShowingCamera && !viewModel.isShowingAROverlay {
                EVMainTabNavigationBar(
                    activeTab: .discovery,
                    onHome: onHome,
                    onLessons: onLessons,
                    onRank: onRank,
                    onSettings: onSettings
                )
            }
        }
        .ignoresSafeArea(edges: .bottom)
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
        VStack(spacing: 0) {
            EVScreenTopBar(onProfile: onProfile)
            
            Spacer()
            
            VStack(spacing: 20) {
                Image(systemName: "sparkles.rectangle.stack")
                    .font(.system(size: 56, weight: .light))
                    .foregroundColor(Color(hex: "0EB060").opacity(0.9))
                
                Text("Discovery Mode")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("Scan real-world objects like books, posters, or labels to unlock instant learning content.")
                    .font(.system(size: 15, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.horizontal, 32)
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 12)
            .animation(.easeOut(duration: 0.35), value: appeared)
            
            Spacer()
            
            HStack(spacing: 10) {
                // Scan Button
                Button(action: { viewModel.openCamera() }) {
                    HStack(spacing: 10) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 18))
                        
                        Text("Start Scanning")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color(hex: "0EB060"))
                    )
                }
                
                PhotosPicker(selection: $selectedPhotoItem, matching: .images, photoLibrary: .shared()) {
                    HStack(spacing: 8) {
                        Image(systemName: "photo.on.rectangle")
                            .font(.system(size: 18))
                        Text("Gallery")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.white.opacity(0.12))
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 100)
        }
    }
    
    // MARK: - Content Display View
    
    private var discoveryContentView: some View {
        VStack(spacing: 0) {
            EVScreenTopBar(onProfile: onProfile)
            
            ScrollView {
                VStack(spacing: 16) {
                    if let image = viewModel.scannedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 240)
                            .cornerRadius(14)
                            .clipped()
                            .padding(.horizontal, 16)
                    }
                    
                    if let content = viewModel.educationalContent {
                        contentCard(for: content)
                    }
                }
                .padding(.vertical, 16)
            }
            
            Spacer()
            
            // Action Buttons
            VStack(spacing: 10) {
                HStack(spacing: 10) {
                    Button(action: { viewModel.showAROverlay() }) {
                        HStack(spacing: 8) {
                            Image(systemName: "arkit")
                            Text("View AR")
                        }
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(hex: "0EB060"))
                        .cornerRadius(12)
                    }
                    
                    Button(action: { viewModel.openCamera() }) {
                        HStack(spacing: 8) {
                            Image(systemName: "camera.fill")
                            Text("Scan Again")
                        }
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)
                    }
                }
                
                Button(action: { viewModel.reset() }) {
                    Text("← Back to Discovery")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .padding(16)
        }
    }
    
    // MARK: - Content Card
    
    private func contentCard(for content: EducationalContent) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            // Title Section
            VStack(alignment: .leading, spacing: 6) {
                Text(content.title)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                HStack(spacing: 8) {
                    Text(content.detectedObjectName)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(Color(hex: "0EB060"))
                    
                    Spacer()
                    
                    Text(content.difficultyLevel)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(difficultyColor(content.difficultyLevel).opacity(0.2))
                        .cornerRadius(6)
                }
            }
            
            Divider()
                .background(Color.white.opacity(0.1))
            
            // Summary
            VStack(alignment: .leading, spacing: 6) {
                Text("Summary")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(Color(hex: "0EB060"))
                
                Text(content.shortSummary)
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))
                    .lineSpacing(2)
            }
            
            // Key Facts
            if !content.educationalFacts.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Key Facts")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(Color(hex: "0EB060"))
                    
                    ForEach(content.educationalFacts.prefix(3), id: \.self) { fact in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Color(hex: "0EB060"))
                                .frame(width: 4, height: 4)
                            
                            Text(fact)
                                .font(.system(size: 13, weight: .regular, design: .rounded))
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                }
            }
            
            // Learning Points
            if !content.keyLearningPoints.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Learning Points")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(Color(hex: "0EB060"))
                    
                    EVTagFlowLayout(spacing: 6) {
                        ForEach(content.keyLearningPoints.prefix(5), id: \.self) { point in
                            Text(point)
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                                .padding(.vertical, 4)
                                .padding(.horizontal, 8)
                                .background(Color(hex: "0EB060").opacity(0.2))
                                .cornerRadius(6)
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
        .cornerRadius(14)
        .padding(.horizontal, 16)
    }
    
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
