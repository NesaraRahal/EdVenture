import SwiftUI

struct DiscoveryQuizSummaryView: View {
    let summary: DiscoveryQuizSummaryPayload
    let onReview: () -> Void
    let onDone: () -> Void

    private var scoreRatio: Double {
        guard summary.totalCount > 0 else { return 0 }
        return min(max(Double(summary.correctCount) / Double(summary.totalCount), 0), 1)
    }

    private var scoreText: String {
        "\(summary.correctCount)/\(summary.totalCount)"
    }

    private var xpText: String {
        summary.xpEarned > 0 ? "+\(summary.xpEarned) XP" : "No XP (already scanned)"
    }

    var body: some View {
        ZStack {
            Color(hex: "050B09").ignoresSafeArea()

            VStack(spacing: 20) {
                Spacer(minLength: 12)

                VStack(spacing: 10) {
                    Text("Discovery Quiz")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(Color(hex: "0EB060"))
                        .tracking(1.2)

                    Text(summary.title)
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }

                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.08), lineWidth: 14)
                        .frame(width: 200, height: 200)

                    Circle()
                        .trim(from: 0, to: scoreRatio)
                        .stroke(
                            Color(hex: "45E38C"),
                            style: StrokeStyle(lineWidth: 14, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .frame(width: 200, height: 200)

                    VStack(spacing: 4) {
                        Text(scoreText)
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Text("CORRECT")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(.white.opacity(0.5))
                            .tracking(1.2)
                    }
                }

                VStack(spacing: 8) {
                    Text(xpText)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(summary.xpEarned > 0 ? Color(hex: "0EB060") : .white.opacity(0.6))

                    if summary.isRepeatScan {
                        Text("You can rescan the same book, but XP is only awarded once per scan.")
                            .font(.system(size: 13, design: .rounded))
                            .foregroundColor(.white.opacity(0.6))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }
                }

                VStack(spacing: 12) {
                    Button(action: onReview) {
                        Text("Review Answers")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(Color.white.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .padding(.horizontal, 24)
                    }
                    .buttonStyle(.plain)

                    Button(action: onDone) {
                        Text("Back to Discovery")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(Color(hex: "0EB060"))
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .padding(.horizontal, 24)
                    }
                    .buttonStyle(.plain)
                }

                Spacer(minLength: 24)
            }
        }
    }
}

#Preview {
    DiscoveryQuizSummaryView(
        summary: DiscoveryQuizSummaryPayload(
            title: "The Trial",
            category: "philosophy",
            correctCount: 4,
            totalCount: 5,
            xpEarned: 40,
            isRepeatScan: false
        ),
        onReview: {},
        onDone: {}
    )
}
