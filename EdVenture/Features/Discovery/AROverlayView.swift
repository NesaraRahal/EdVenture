import SwiftUI
import ARKit
import RealityKit
import UIKit

// MARK: - AR Overlay View

struct AROverlayView: View {
    @ObservedObject var viewModel: DiscoveryViewModel
    let previewImage: UIImage?

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                if let previewImage {
                    Image(uiImage: previewImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .clipped()
                } else {
                    Color.black
                }

                ARViewContainer(content: viewModel.educationalContent)
                    .opacity(0.01)
                    .allowsHitTesting(false)

                LinearGradient(
                    colors: [
                        Color.black.opacity(0.20),
                        Color.clear,
                        Color.black.opacity(0.46)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                VStack(spacing: 0) {
                    HStack(spacing: 10) {
                        Label("AR Mode", systemImage: "arkit")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(Color.black.opacity(0.35))
                            .clipShape(Capsule())

                        Spacer()

                        Button(action: { viewModel.reset() }) {
                            Text("New Scan")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .background(Color.black.opacity(0.35))
                                .clipShape(Capsule())
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 12)

                    Spacer(minLength: 20)

                    if let content = viewModel.educationalContent {
                        ARFocusCard(content: content)
                        .padding(.horizontal, 12)
                        .frame(maxWidth: 460)
                        .shadow(color: .black.opacity(0.35), radius: 16, y: 8)

                        Button(action: { viewModel.startDiscoveryQuiz() }) {
                            HStack(spacing: 10) {
                                Image(systemName: "sparkles")
                                Text("Quick Quiz + XP")
                                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                            }
                            .foregroundColor(.black)
                            .frame(maxWidth: 320)
                            .frame(height: 48)
                            .background(Color(hex: "0EB060"))
                            .clipShape(Capsule())
                            .shadow(color: Color.black.opacity(0.2), radius: 8, y: 4)
                        }
                        .padding(.top, 12)
                    } else {
                        VStack(spacing: 8) {
                            ProgressView()
                                .tint(Color(hex: "0EB060"))
                            Text("Preparing AR educational overlay...")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundColor(.white.opacity(0.9))
                        }
                        .padding(12)
                        .background(Color.black.opacity(0.35))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }

                    Spacer(minLength: max(18, proxy.size.height * 0.16))
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
    }
}

struct ARFocusCard: View {
    let content: EducationalContent

    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(alignment: .leading, spacing: 12) {
                Text("ACTIVE FOCUS")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: "0EB060"))
                    .padding(.vertical, 6)
                    .padding(.horizontal, 12)
                    .background(Color(hex: "0EB060").opacity(0.18))
                    .clipShape(Capsule())

                Text(content.title)
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .lineLimit(3)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)

                Text(content.detectedObjectName)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.72))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Text(content.shortSummary)
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundColor(.white.opacity(0.88))
                    .lineSpacing(3)
                    .multilineTextAlignment(.leading)

                if !content.keyLearningPoints.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(content.keyLearningPoints.prefix(3), id: \.self) { point in
                            HStack(alignment: .top, spacing: 8) {
                                Circle()
                                    .fill(Color(hex: "0EB060"))
                                    .frame(width: 5, height: 5)
                                    .padding(.top, 6)

                                Text(point)
                                    .font(.system(size: 12, weight: .medium, design: .rounded))
                                    .foregroundColor(.white.opacity(0.82))
                                    .multilineTextAlignment(.leading)
                            }
                        }
                    }
                    .padding(.top, 4)
                }
            }
            .padding(16)
        }
        .frame(maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 34, style: .continuous)
                        .stroke(Color.white.opacity(0.16), lineWidth: 1)
                )
        )
    }
}

// MARK: - AR View Container

struct ARViewContainer: UIViewControllerRepresentable {
    let content: EducationalContent?

    func makeUIViewController(context: Context) -> ARContainerViewController {
        ARContainerViewController()
    }

    func updateUIViewController(_ uiViewController: ARContainerViewController, context: Context) {
        uiViewController.updateContent(content)
    }
}

final class ARContainerViewController: UIViewController {
    private let arView = ARView(frame: .zero)
    private var activeContentID: String?
    private var activeAnchor: AnchorEntity?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        arView.frame = view.bounds
        arView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(arView)

        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        configuration.environmentTexturing = .automatic
        arView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }

    func updateContent(_ content: EducationalContent?) {
        guard let content else { return }
        guard activeContentID != content.id else { return }
        activeContentID = content.id

        activeAnchor?.removeFromParent()

        let anchor = AnchorEntity(world: SIMD3<Float>(0, 0, -0.75))
        let board = makeBoard(for: content)
        anchor.addChild(board)
        arView.scene.addAnchor(anchor)
        activeAnchor = anchor
    }

    private func makeBoard(for content: EducationalContent) -> Entity {
        let root = Entity()

        let panel = ModelEntity(
            mesh: .generatePlane(width: 0.95, depth: 0.6),
            materials: [SimpleMaterial(color: UIColor.black.withAlphaComponent(0.72), isMetallic: false)]
        )
        root.addChild(panel)

        let title = makeTextEntity(content.title, color: .white, size: 0.09, maxLength: 24)
        title.position = [-0.42, 0.16, 0.02]
        root.addChild(title)

        let subtitle = makeTextEntity(content.detectedObjectName, color: UIColor(red: 0.05, green: 0.78, blue: 0.42, alpha: 1), size: 0.045, maxLength: 26)
        subtitle.position = [-0.42, 0.08, 0.02]
        root.addChild(subtitle)

        let summary = makeTextEntity(content.shortSummary, color: UIColor.white.withAlphaComponent(0.92), size: 0.031, maxLength: 72)
        summary.position = [-0.42, -0.02, 0.02]
        root.addChild(summary)

        let caption = makeTextEntity(content.arOverlayCaption, color: UIColor(red: 0.05, green: 0.78, blue: 0.42, alpha: 1), size: 0.028, maxLength: 42)
        caption.position = [-0.42, -0.18, 0.02]
        root.addChild(caption)

        return root
    }

    private func makeTextEntity(_ text: String, color: UIColor, size: CGFloat, maxLength: Int) -> Entity {
        let clippedText = String(text.prefix(maxLength))
        let mesh = MeshResource.generateText(
            clippedText,
            extrusionDepth: 0.002,
            font: .systemFont(ofSize: size * 100, weight: .semibold),
            containerFrame: .zero,
            alignment: .left,
            lineBreakMode: .byWordWrapping
        )

        let entity = ModelEntity(mesh: mesh, materials: [SimpleMaterial(color: color, isMetallic: false)])
        entity.scale = [0.0012, 0.0012, 0.0012]
        return entity
    }
}

// MARK: - Floating Card Components

struct FloatingTitleCard: View {
    let content: EducationalContent

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(content.title)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    Text(content.detectedObjectName)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(Color(hex: "0EB060"))
                        .lineLimit(1)
                }

                Spacer()

                Text(content.difficultyLevel)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.vertical, 5)
                    .padding(.horizontal, 9)
                    .background(Color(hex: "0EB060").opacity(0.18))
                    .clipShape(Capsule())
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.black.opacity(0.48))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
            )
        }
    }
}

struct FloatingSummaryCard: View {
    let content: EducationalContent

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Summary")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(Color(hex: "0EB060"))

            Text(content.shortSummary)
                .font(.system(size: 12, weight: .regular, design: .rounded))
                .foregroundColor(.white.opacity(0.92))
                .lineLimit(4)
                .lineSpacing(2)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.black.opacity(0.48))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }
}

struct FloatingKeywordsCard: View {
    let content: EducationalContent

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Key Learning Points")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(Color(hex: "0EB060"))

            EVTagFlowLayout(spacing: 6) {
                ForEach(content.keyLearningPoints.prefix(4), id: \.self) { point in
                    Text(point)
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.vertical, 3)
                        .padding(.horizontal, 8)
                        .background(Color(hex: "0EB060").opacity(0.18))
                        .clipShape(Capsule())
                }
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.black.opacity(0.48))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }
}

// MARK: - Layout Helper

struct EVTagFlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? 300
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > maxWidth {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
        }

        return CGSize(width: maxWidth, height: currentY + lineHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var currentX = bounds.minX
        var currentY = bounds.minY
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > bounds.maxX {
                currentX = bounds.minX
                currentY += lineHeight + spacing
                lineHeight = 0
            }

            subview.place(
                at: CGPoint(x: currentX, y: currentY),
                anchor: .topLeading,
                proposal: ProposedViewSize(width: size.width, height: size.height)
            )

            currentX += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
    }
}

// MARK: - Backdrop Effect

struct BackdropModifier: ViewModifier {
    func body(content: Content) -> some View {
        content.shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
    }
}

extension View {
    func backdrop() -> some View {
        modifier(BackdropModifier())
    }
}

// MARK: - Preview

#Preview {
    AROverlayPreviewWrapper()
}

private struct AROverlayPreviewWrapper: View {
    var body: some View {
        let viewModel = DiscoveryViewModel()
        viewModel.educationalContent = EducationalContent(
            id: "preview",
            title: "The Trial",
            detectedObjectName: "Book Cover",
            category: "philosophy",
            shortSummary: "A philosophical novel exploring bureaucracy and guilt.",
            educationalFacts: ["Published in 1925", "Written by Franz Kafka"],
            difficultyLevel: "Advanced",
            keyLearningPoints: ["Existentialism", "Bureaucracy", "Surrealism"],
            quizQuestions: [
                EVDiscoveryQuizQuestion(
                    id: "q1",
                    question: "What is The Trial about?",
                    options: ["Adventure", "Bureaucracy", "Cooking", "Space travel"],
                    correctAnswerIndex: 1,
                    explanation: "Kafka’s novel centers on absurd bureaucracy."
                )
            ],
            arOverlayCaption: "Scan complete — explore the meaning behind the text.",
            extractedText: "The Trial",
            generatedAt: Date()
        )
        return AROverlayView(viewModel: viewModel, previewImage: UIImage(named: "EdVentureLogo"))
    }
}
