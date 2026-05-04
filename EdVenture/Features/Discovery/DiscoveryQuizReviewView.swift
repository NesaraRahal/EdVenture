import SwiftUI

struct DiscoveryQuizReviewView: View {
    let items: [DiscoveryReviewItem]
    let onDone: () -> Void

    var body: some View {
        ZStack {
            Color(hex: "050B09").ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    header
                        .padding(.top, 52)
                        .padding(.horizontal, 20)

                    if items.isEmpty {
                        Text("No answers available to review.")
                            .font(.system(size: 14, design: .rounded))
                            .foregroundColor(.white.opacity(0.6))
                            .padding(.horizontal, 20)
                    } else {
                        VStack(spacing: 14) {
                            ForEach(items) { item in
                                reviewCard(item)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 30)
                    }
                }
            }
        }
    }

    private var header: some View {
        HStack {
            Button(action: onDone) {
                HStack(spacing: 8) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Back")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                }
                .foregroundColor(.white)
                .frame(height: 44)
                .padding(.horizontal, 16)
                .background(Color.white.opacity(0.12))
                .clipShape(Capsule())
            }

            Spacer()

            Text("Review")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
    }

    private func reviewCard(_ item: DiscoveryReviewItem) -> some View {
        let accent = item.isCorrect ? Color(hex: "0EB060") : Color(hex: "FF5A52")

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Q\(item.order + 1)")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(accent)
                Spacer()
                Image(systemName: item.isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(accent)
            }

            Text(item.question)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
                .fixedSize(horizontal: false, vertical: true)

            answerRow(title: "Your Answer", text: item.options[safe: item.selectedIndex] ?? "", accent: accent)
            if !item.isCorrect {
                answerRow(title: "Correct Answer", text: item.options[safe: item.correctIndex] ?? "", accent: Color(hex: "0EB060"))
            }

            Text(item.explanation)
                .font(.system(size: 13, design: .rounded))
                .foregroundColor(.white.opacity(0.7))
                .lineSpacing(2)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(accent.opacity(0.45), lineWidth: 0.8)
                )
        )
    }

    private func answerRow(title: String, text: String, accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundColor(accent)
                .tracking(1.1)
            Text(text)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(accent.opacity(0.12))
        )
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        guard indices.contains(index) else { return nil }
        return self[index]
    }
}

#Preview {
    DiscoveryQuizReviewView(
        items: [
            DiscoveryReviewItem(
                id: "q1",
                order: 0,
                question: "What is The Trial about?",
                options: ["Adventure", "Bureaucracy", "Cooking", "Space travel"],
                selectedIndex: 1,
                correctIndex: 1,
                explanation: "Kafka’s novel centers on absurd bureaucracy."
            )
        ],
        onDone: {}
    )
}
