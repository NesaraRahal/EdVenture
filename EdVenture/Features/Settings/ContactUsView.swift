import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import Combine

struct ContactUsView: View {
    var onBack: (() -> Void)?

    @StateObject private var vm = ContactUsViewModel()

    var body: some View {
        ZStack {
            Color(hex: "0A0F0D").ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    topBar
                        .padding(.top, 52)
                        .padding(.horizontal, 20)

                    Text("Contact Us")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)

                    inputField(title: "Subject", text: $vm.subject)
                        .padding(.horizontal, 20)

                    messageEditor
                        .padding(.horizontal, 20)

                    if let errorMessage = vm.errorMessage {
                        Text(errorMessage)
                            .font(.system(size: 13, design: .rounded))
                            .foregroundColor(Color(hex: "FF453A"))
                            .padding(.horizontal, 20)
                    }

                    if let successMessage = vm.successMessage {
                        Text(successMessage)
                            .font(.system(size: 13, design: .rounded))
                            .foregroundColor(Color(hex: "0EB060"))
                            .padding(.horizontal, 20)
                    }

                    Button {
                        Task {
                            await vm.submitSupportRequest()
                        }
                    } label: {
                        HStack(spacing: 8) {
                            if vm.isSubmitting {
                                ProgressView()
                                    .tint(.black)
                            } else {
                                Image(systemName: "paperplane.fill")
                                    .font(.system(size: 14, weight: .semibold))
                            }

                            Text(vm.isSubmitting ? "Sending..." : "Send Message")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(Color(hex: "0EB060"))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .disabled(vm.isSubmitting)
                    .padding(.horizontal, 20)
                    .padding(.top, 6)

                    Spacer(minLength: 24)
                }
            }
        }
        .navigationBarHidden(true)
    }

    private var topBar: some View {
        HStack {
            Button {
                onBack?()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Back")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                }
                .foregroundColor(.white)
                .frame(height: 44)
                .padding(.horizontal, 14)
                .background(Color.white.opacity(0.1))
                .clipShape(Capsule())
            }

            Spacer()
        }
    }

    private func inputField(title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.65))

            TextField("Enter \(title.lowercased())", text: text)
                .textInputAutocapitalization(.sentences)
                .disableAutocorrection(false)
                .font(.system(size: 15, design: .rounded))
                .foregroundColor(.white)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.white.opacity(0.05))
                )
        }
    }

    private var messageEditor: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Message")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.65))

            TextEditor(text: $vm.message)
                .frame(minHeight: 160)
                .scrollContentBackground(.hidden)
                .foregroundColor(.white)
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.white.opacity(0.05))
                )
        }
    }
}

@MainActor
final class ContactUsViewModel: ObservableObject {
    @Published var subject = ""
    @Published var message = ""
    @Published var isSubmitting = false
    @Published var errorMessage: String?
    @Published var successMessage: String?

    private let db = Firestore.firestore()

    func submitSupportRequest() async {
        let trimmedSubject = subject.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedMessage = message.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedSubject.isEmpty else {
            errorMessage = "Subject is required."
            successMessage = nil
            return
        }

        guard trimmedMessage.count >= 10 else {
            errorMessage = "Please enter at least 10 characters in your message."
            successMessage = nil
            return
        }

        isSubmitting = true
        errorMessage = nil
        successMessage = nil
        defer { isSubmitting = false }

        do {
            let currentUser = Auth.auth().currentUser
            try await db.collection("supportRequests").addDocument(data: [
                "uid": currentUser?.uid ?? "anonymous",
                "email": currentUser?.email ?? "",
                "subject": trimmedSubject,
                "message": trimmedMessage,
                "status": "open",
                "source": "ios_app",
                "createdAt": Timestamp(date: Date())
            ])

            subject = ""
            message = ""
            successMessage = "Your support request was sent. We will get back to you soon."
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    ContactUsView()
}
