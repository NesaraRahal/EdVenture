import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct PaymentSettingsView: View {
    @State private var cardNumber: String = ""
    @State private var nameOnCard: String = ""
    @State private var expiryDate = Date()
    @State private var showDatePicker = false
    @State private var cvv: String = ""
    @State private var description: String = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var successMessage: String?
    @State private var hasCard = false
    @State private var savedCardLast4 = ""
    @State private var savedCardBrand = "creditcard"
    @State private var showRemoveAlert = false

    var onBack: (() -> Void)?

    private let db = Firestore.firestore()

    private var expiryDateFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/yy"
        return formatter.string(from: expiryDate)
    }

    private var expiryDateDisplayText: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: expiryDate)
    }

    private func parsedExpiryDate(from value: String) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "MM/yy"
        return formatter.date(from: value)
    }

    private var cardBrand: String {
        let digits = cardNumber.filter { $0.isNumber }
        if digits.hasPrefix("4") { return "visa" }
        if digits.hasPrefix("5") { return "mastercard" }
        if digits.hasPrefix("3") { return "amex" }
        return "creditcard"
    }

    var body: some View {
        ZStack {
            Color(hex: "0A0F0D").ignoresSafeArea()

            VStack(spacing: 0) {
                // Header with back button, matching the app's other settings screens
                HStack(spacing: 14) {
                    EVBackButton(title: "Back", action: { onBack?() })

                    Text("Payment & Billing")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.9))
                        .lineLimit(1)

                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 24)

                // Form content
                ScrollView {
                    if hasCard {
                        // Show saved card view
                        VStack(spacing: 20) {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Saved Card")
                                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                                    .foregroundColor(.white.opacity(0.7))
                                    .tracking(0.3)
                                
                                HStack {
                                    Image(systemName: savedCardBrand)
                                        .font(.system(size: 24, weight: .semibold))
                                        .foregroundColor(Color(hex: "0EB060"))
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Card ending in \(savedCardLast4)")
                                            .font(.system(size: 16, weight: .medium, design: .rounded))
                                            .foregroundColor(.white)
                                        Text("Card is verified")
                                            .font(.system(size: 13, weight: .regular, design: .rounded))
                                            .foregroundColor(.white.opacity(0.55))
                                    }
                                    
                                    Spacer()
                                    
                                    VStack {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 20))
                                            .foregroundColor(Color(hex: "0EB060"))
                                    }
                                }
                                .padding(16)
                                .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.03)))
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "0EB060").opacity(0.3), lineWidth: 1))
                            }
                            
                            Divider()
                                .background(Color.white.opacity(0.1))
                            
                            // Remove card button
                            Button(action: { showRemoveAlert = true }) {
                                HStack {
                                    Image(systemName: "trash")
                                        .font(.system(size: 14, weight: .semibold))
                                    Text("Remove This Card")
                                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                                }
                                .foregroundColor(Color(hex: "FF453A"))
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color(hex: "FF453A").opacity(0.12))
                                .cornerRadius(14)
                            }
                            
                            // Add another card button
                            Button(action: { clearForm() }) {
                                Text("Add Another Card")
                                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                                    .foregroundColor(Color(hex: "0A0F0D"))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(Color(hex: "0EB060"))
                                    .cornerRadius(14)
                            }
                            
                            Spacer().frame(height: 20)
                        }
                        .padding(20)
                    } else {
                        // Show payment form
                        VStack(spacing: 20) {
                            // Card Holder Name
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Card Holders Name")
                                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                                    .foregroundColor(.white.opacity(0.7))
                                    .tracking(0.3)
                                TextField("Enter your name here", text: $nameOnCard)
                                    .padding(14)
                                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.03)))
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.08), lineWidth: 0.6))
                                    .foregroundColor(.white)
                                    .accentColor(Color(hex: "0EB060"))
                            }

                            // Card Number
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Card Number")
                                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                                    .foregroundColor(.white.opacity(0.7))
                                    .tracking(0.3)
                                HStack {
                                    TextField("1234-34xx-xxxx-xxxx", text: $cardNumber)
                                        .keyboardType(.numberPad)
                                        .padding(14)
                                        .accentColor(Color(hex: "0EB060"))
                                    Image(systemName: cardBrand)
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundColor(Color(hex: "0EB060").opacity(0.6))
                                        .padding(.trailing, 14)
                                }
                                .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.03)))
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.08), lineWidth: 0.6))
                                .foregroundColor(.white)
                            }

                            // Date and CVV on same row
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Expiry Date")
                                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                                        .foregroundColor(.white.opacity(0.7))
                                        .tracking(0.3)
                                    Button(action: { showDatePicker = true }) {
                                        HStack {
                                            Text(expiryDateDisplayText)
                                                .font(.system(size: 15, weight: .medium, design: .rounded))
                                                .foregroundColor(.white)
                                            Spacer()
                                            Image(systemName: "calendar")
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(Color(hex: "0EB060"))
                                        }
                                        .padding(12)
                                        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.03)))
                                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.08), lineWidth: 0.6))
                                    }
                                }

                                VStack(alignment: .leading, spacing: 8) {
                                    Text("CVV")
                                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                                        .foregroundColor(.white.opacity(0.7))
                                        .tracking(0.3)
                                    TextField("2xx", text: $cvv)
                                        .keyboardType(.numberPad)
                                        .padding(12)
                                        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.03)))
                                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.08), lineWidth: 0.6))
                                        .foregroundColor(.white)
                                        .accentColor(Color(hex: "0EB060"))
                                }
                            }
                            .sheet(isPresented: $showDatePicker) {
                                VStack(spacing: 16) {
                                    Text("Select Expiry Date")
                                        .font(.system(size: 18, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                        .padding(.top, 20)

                                    DatePicker(
                                        "Expiry Date",
                                        selection: $expiryDate,
                                        in: Date()...,
                                        displayedComponents: [.date]
                                    )
                                    .datePickerStyle(.graphical)
                                    .labelsHidden()
                                    .tint(Color(hex: "0EB060"))
                                    .foregroundColor(.white)
                                    .padding(20)

                                    Button(action: { showDatePicker = false }) {
                                        Text("Done")
                                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                                            .foregroundColor(Color(hex: "0A0F0D"))
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 50)
                                            .background(Color(hex: "0EB060"))
                                            .cornerRadius(14)
                                    }
                                    .padding(.horizontal, 20)
                                    .padding(.bottom, 20)

                                    Spacer(minLength: 0)
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .background(Color(hex: "0A0F0D").ignoresSafeArea())
                                .preferredColorScheme(.dark)
                                .presentationDetents([.large])
                            }

                            // Description
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Description (Optional)")
                                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                                    .foregroundColor(.white.opacity(0.7))
                                    .tracking(0.3)
                                TextField("Enter your additional details", text: $description)
                                    .padding(14)
                                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.03)))
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.08), lineWidth: 0.6))
                                    .foregroundColor(.white)
                                    .accentColor(Color(hex: "0EB060"))
                                    .lineLimit(3)
                            }

                            // Error message
                            if let errorMessage {
                                Text(errorMessage)
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                    .foregroundColor(Color(hex: "FF453A"))
                                    .padding(12)
                                    .background(Color(hex: "FF453A").opacity(0.12))
                                    .cornerRadius(10)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }

                            // Success message
                            if let successMessage {
                                Text(successMessage)
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                    .foregroundColor(Color(hex: "0EB060"))
                                    .padding(12)
                                    .background(Color(hex: "0EB060").opacity(0.12))
                                    .cornerRadius(10)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }

                            // Save button
                            Button(action: saveCardDetails) {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "0A0F0D")))
                                } else {
                                    Text("Save Card Details")
                                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                                        .foregroundColor(Color(hex: "0A0F0D"))
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color(hex: "0EB060"))
                            .cornerRadius(14)
                            .disabled(isLoading)

                            Spacer().frame(height: 20)
                        }
                        .padding(20)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            loadSavedCard()
        }
        .alert("Remove Card", isPresented: $showRemoveAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Remove", role: .destructive) {
                removeCard()
            }
        } message: {
            Text("Are you sure you want to remove this card?")
        }
    }

    private func saveCardDetails() {
        guard let user = Auth.auth().currentUser else {
            errorMessage = "Please sign in to manage payment."
            return
        }
        guard !cardNumber.trimmingCharacters(in: .whitespaces).isEmpty,
              !nameOnCard.trimmingCharacters(in: .whitespaces).isEmpty,
              expiryDate > Date(),
              !cvv.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Please enter all card details."
            return
        }

        isLoading = true
        errorMessage = nil
        Task {
            do {
                let last4 = String(cardNumber.filter { $0.isNumber }.suffix(4))
                let docRef = db.collection("users").document(user.uid)

                try await docRef.setData([
                    "cardLast4": last4,
                    "cardBrand": cardBrand,
                    "cardholderName": nameOnCard,
                    "cardExpiry": expiryDateFormatted
                ], merge: true)

                await MainActor.run {
                    successMessage = "Payment method saved successfully."
                    isLoading = false
                    savedCardLast4 = last4
                    savedCardBrand = cardBrand
                    hasCard = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        onBack?()
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }

    private func loadSavedCard() {
        guard let user = Auth.auth().currentUser else { return }
        
        Task {
            do {
                let docRef = db.collection("users").document(user.uid)
                let document = try await docRef.getDocument()
                
                if let data = document.data(),
                   let last4 = data["cardLast4"] as? String,
                   !last4.isEmpty {
                    await MainActor.run {
                        if let holder = data["cardholderName"] as? String, !holder.isEmpty {
                            nameOnCard = holder
                        }

                        if let expiry = data["cardExpiry"] as? String,
                           let parsed = parsedExpiryDate(from: expiry) {
                            expiryDate = parsed
                        }

                        cardNumber = last4
                        savedCardLast4 = last4
                        savedCardBrand = (data["cardBrand"] as? String) ?? "creditcard"
                        hasCard = true
                    }
                }
            } catch {
                // Silent fail - card not found is normal
            }
        }
    }

    private func removeCard() {
        guard let user = Auth.auth().currentUser else { return }
        
        isLoading = true
        Task {
            do {
                let docRef = db.collection("users").document(user.uid)
                try await docRef.setData([
                    "cardLast4": FieldValue.delete(),
                    "cardBrand": FieldValue.delete(),
                    "cardholderName": FieldValue.delete(),
                    "cardExpiry": FieldValue.delete()
                ], merge: true)
                
                await MainActor.run {
                    savedCardLast4 = ""
                    savedCardBrand = "creditcard"
                    hasCard = false
                    isLoading = false
                    clearForm()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }

    private func clearForm() {
        cardNumber = ""
        nameOnCard = ""
        expiryDate = Date()
        cvv = ""
        description = ""
        errorMessage = nil
        successMessage = nil
    }
}

#Preview {
    PaymentSettingsView()
}
