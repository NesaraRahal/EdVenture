import SwiftUI
import ARKit
import RealityKit

// MARK: - AR Overlay View

struct AROverlayView: View {
    @ObservedObject var viewModel: DiscoveryViewModel
    @State private var isAnimating = false
    @State private var selectedQuestionIndex = 0
    
    var body: some View {
        ZStack {
            // AR View Background
            ARViewContainer()
                .ignoresSafeArea()
            
            // Overlay Content
            VStack(spacing: 0) {
                // Header with close button
                HStack {
                    Text("AR Discovery")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(action: { viewModel.dismissAROverlay() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.white)
                    }
                }
                .padding(16)
                .background(Color.black.opacity(0.5))
                
                Spacer()
                
                // Content Cards (floating from bottom)
                VStack(spacing: 12) {
                    if let content = viewModel.educationalContent {
                        // Title Card
                        FloatingTitleCard(content: content)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        
                        // Summary Card
                        FloatingSummaryCard(content: content)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        
                        // Keywords Card
                        FloatingKeywordsCard(content: content)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        
                        // Quiz Button
                        FloatingQuizButton {
                            selectedQuestionIndex = 0
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
            .ignoresSafeArea(.keyboard, edges: .all)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                isAnimating = true
            }
        }
    }
}

// MARK: - AR View Container (Placeholder for RealityKit)

struct ARViewContainer: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> ARContainerViewController {
        return ARContainerViewController()
    }
    
    func updateUIViewController(_ uiViewController: ARContainerViewController, context: Context) {}
}

class ARContainerViewController: UIViewController {
    var arView: ARView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        do {
            arView = try ARView(frame: view.bounds)
            if let arView = arView {
                view.addSubview(arView)
            }
        } catch {
            print("Failed to create ARView: \(error)")
        }
    }
}

// MARK: - Floating Card Components

/// Floating Title Card
struct FloatingTitleCard: View {
    let content: EducationalContent
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(content.title)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(2)
                    
                    Text(content.detectedObjectName)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(Color(hex: "0EB060"))
                }
                
                Spacer()
                
                // Difficulty Badge
                ZStack {
                    Circle()
                        .fill(difficultyColor(content.difficultyLevel))
                        .frame(width: 50, height: 50)
                    
                    Text(content.difficultyLevel.prefix(1).uppercased())
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(0.7))
                    .backdrop()
            )
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

/// Floating Summary Card
struct FloatingSummaryCard: View {
    let content: EducationalContent
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Summary")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(Color(hex: "0EB060"))
            
            Text(content.shortSummary)
                .font(.system(size: 13, weight: .regular, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(4)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.7))
                .backdrop()
        )
    }
}

/// Floating Keywords Card
struct FloatingKeywordsCard: View {
    let content: EducationalContent
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Key Learning Points")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(Color(hex: "0EB060"))
            
            EVTagFlowLayout(spacing: 6) {
                ForEach(content.keyLearningPoints.prefix(4), id: \.self) { point in
                    Text(point)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(Color(hex: "0EB060").opacity(0.2))
                        .cornerRadius(8)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.7))
                .backdrop()
        )
    }
}

/// Floating Quiz Button
struct FloatingQuizButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: "questionmark.circle.fill")
                    .font(.system(size: 18))
                
                Text("Take Quiz")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                
                Spacer()
                
                Image(systemName: "arrow.right")
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .padding(.horizontal, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(hex: "0EB060"))
            )
        }
    }
}

// MARK: - Flow Layout Helper

struct EVTagFlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? 300
        var height: CGFloat = 0
        var lineHeight: CGFloat = 0
        var lineWidth: CGFloat = 0
        
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            
            if lineWidth + size.width > maxWidth {
                height += lineHeight + spacing
                lineWidth = size.width
                lineHeight = size.height
            } else {
                lineWidth += size.width + spacing
                lineHeight = max(lineHeight, size.height)
            }
        }
        
        if lineWidth > 0 {
            height += lineHeight
        }
        
        return CGSize(width: maxWidth, height: height)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var lineHeight: CGFloat = 0
        
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            
            if x + size.width > bounds.maxX {
                y += lineHeight + spacing
                x = bounds.minX
                lineHeight = 0
            }
            
            view.place(
                at: CGPoint(x: x, y: y),
                anchor: .topLeading,
                proposal: ProposedViewSize(width: size.width, height: size.height)
            )
            
            x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
    }
}

// MARK: - Backdrop Effect

struct BackdropModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
    }
}

extension View {
    func backdrop() -> some View {
        modifier(BackdropModifier())
    }
}

// MARK: - Preview

#Preview {
    let viewModel = DiscoveryViewModel()
    viewModel.educationalContent = EducationalContent(
        id: "preview",
        title: "The Trial",
        detectedObjectName: "Book Cover",
        shortSummary: "A philosophical novel exploring themes of guilt, absurdity, and bureaucracy through the mysterious prosecution of Josef K.",
        educationalFacts: [
            "Published in 1925",
            "Written by Franz Kafka",
            "Written in German originally",
            "Surrealist narrative style"
        ],
        difficultyLevel: "Advanced",
        keyLearningPoints: [
            "Kafka's surrealist style",
            "Existential philosophy",
            "Bureaucratic systems",
            "Guilt and justice"
        ],
        quizQuestions: [
            EVDiscoveryQuizQuestion(
                id: "q1",
                question: "What is the main theme?",
                options: ["Love story", "Mystery", "Bureaucratic absurdity", "Adventure"],
                correctAnswerIndex: 2,
                explanation: "The novel explores the absurdity of bureaucratic systems."
            )
        ],
        arOverlayCaption: "The Trial by Franz Kafka - A philosophical exploration of justice",
        extractedText: "The Trial",
        generatedAt: Date()
    )
    
    return AROverlayView(viewModel: viewModel)
}
