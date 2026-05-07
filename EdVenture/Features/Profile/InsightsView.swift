import SwiftUI

struct InsightsView: View {
    @StateObject private var vm = InsightsViewModel()
    var onBack: (() -> Void)?

    var body: some View {
        ZStack {
            Color(hex: "0A0F0D").ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    topBar
                        .padding(.horizontal, 20)
                        .padding(.top, 52)

                    subjectProficiencyCard
                        .padding(.top, 22)
                        .padding(.horizontal, 20)

                    consistencyCard
                        .padding(.top, 22)
                        .padding(.horizontal, 20)

                    xpPerformanceCard
                        .padding(.top, 22)
                        .padding(.horizontal, 20)

                    dailyRhythmCard
                        .padding(.top, 22)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 34)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            Task { await vm.loadInsights() }
        }
    }

    private var topBar: some View {
        HStack {
            EVBackButton(title: "Back", action: { onBack?() }, compactTitleSize: 16)

            Spacer()

            Text("Insights")
                .font(.system(size: 38, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            Spacer()

            Color.clear
                .frame(width: 88, height: 44)
        }
    }

    private var subjectProficiencyCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Subject Proficiency")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            VStack(spacing: 18) {
                ForEach(vm.proficiencyRows) { item in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(item.name)
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(.white.opacity(0.92))
                            Spacer()
                            Text("\(item.value)%")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(item.value < 50 ? Color(hex: "75DFFF") : Color(hex: "0EB060"))
                        }

                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color.white.opacity(0.08))
                                    .frame(height: 12)

                                Capsule()
                                    .fill(item.value < 50 ? Color(hex: "75DFFF") : Color(hex: "0EB060"))
                                    .frame(width: geo.size.width * CGFloat(item.value) / 100.0, height: 12)
                            }
                        }
                        .frame(height: 12)
                    }
                }
            }
        }
        .padding(20)
        .background(glassCard)
    }

    private var consistencyCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text("Consistency Tracker")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                Spacer()
                Text("LAST 6 MONTHS")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.35))
                    .tracking(1.4)
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 15), spacing: 8) {
                ForEach(0..<vm.consistencyCells.count, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(consistencyColor(for: vm.consistencyCells[index]))
                        .frame(height: 20)
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(Color.white.opacity(0.04))
                    .overlay(
                        RoundedRectangle(cornerRadius: 26, style: .continuous)
                            .stroke(Color.white.opacity(0.06), lineWidth: 0.6)
                    )
            )
        }
    }

    private var xpPerformanceCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("XP Performance")
                .font(.system(size: 42, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.5)

            Text("Weekly progress velocity")
                .font(.system(size: 15, design: .rounded))
                .foregroundColor(.white.opacity(0.5))

            HStack(alignment: .bottom, spacing: 12) {
                ForEach(vm.weeklyXP) { item in
                    VStack(spacing: 10) {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "0EB060").opacity(item.day == highlightDay ? 0.95 : 0.35), Color.clear],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: 42, height: max(40, item.value * 220))

                        Text(item.day)
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(item.day == highlightDay ? Color(hex: "0EB060") : .white.opacity(0.5))
                            .tracking(1)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.top, 14)
        }
        .padding(20)
        .background(glassCard)
    }

    private var dailyRhythmCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(hex: "0EB060").opacity(0.16))
                    .frame(width: 58, height: 58)
                    .overlay(
                        Image(systemName: "sun.max.fill")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(Color(hex: "0EB060"))
                    )

                Spacer()
            }

            Text("Daily Rhythm")
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.5)

            (
                Text("You're a ")
                    .foregroundColor(.white.opacity(0.65))
                + Text(vm.rhythmType)
                    .foregroundColor(Color(hex: "0EB060"))
                    .fontWeight(.bold)
                + Text(". \(vm.afterEightPercent)% of your\nprogress is tracked after 8 PM.")
                    .foregroundColor(.white.opacity(0.65))
            )
            .font(.system(size: 15, weight: .medium, design: .rounded))
            .lineSpacing(3)

            Divider()
                .overlay(Color.white.opacity(0.08))

            HStack {
                Text("PEAK FOCUS")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.5))
                    .tracking(1.6)

                Spacer()

                Text(vm.peakFocusTime)
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: "0EB060"))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
        }
        .padding(20)
        .background(glassCard)
    }

    private var glassCard: some View {
        RoundedRectangle(cornerRadius: 28, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [Color.white.opacity(0.045), Color(hex: "0EB060").opacity(0.025)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(Color(hex: "0EB060").opacity(0.22), lineWidth: 0.6)
            )
    }

    private func consistencyColor(for intensity: Double) -> Color {
        if intensity >= 0.80 { return Color(hex: "0EB060").opacity(0.95) }
        if intensity >= 0.55 { return Color(hex: "0EB060").opacity(0.72) }
        if intensity >= 0.30 { return Color(hex: "0EB060").opacity(0.46) }
        if intensity > 0.00 { return Color(hex: "0EB060").opacity(0.24) }
        return Color.white.opacity(0.08)
    }

    private var highlightDay: String {
        vm.weeklyXP.max(by: { $0.value < $1.value })?.day ?? ""
    }
}

#Preview {
    InsightsView()
}
