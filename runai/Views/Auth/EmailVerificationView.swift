//
//  EmailVerificationView.swift
//  runai
//
//  Email verification view for user registration
//

import SwiftUI

struct EmailVerificationView: View {
    @ObservedObject var tenantManager = TenantManager.shared
    @ObservedObject var emailService = EmailVerificationService.shared
    
    @State private var verificationCode = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isVerifying = false
    @State private var timeRemaining = 600 // 10 minutes
    @State private var canResend = false
    
    let email: String
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(spacing: 32) {
            // Header
            VStack(spacing: 16) {
                Image(systemName: "envelope.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                VStack(spacing: 8) {
                    Text("Verifica tu email")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Hemos enviado un código de 6 dígitos a:")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Text(email)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                }
            }
            
            // Verification Code Input
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Código de verificación")
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    HStack {
                        Image(systemName: "number.circle")
                            .foregroundColor(.secondary)
                            .frame(width: 20)
                        
                        TextField("000000", text: $verificationCode)
                            .keyboardType(.numberPad)
                            .textFieldStyle(PlainTextFieldStyle())
                            .font(.title3)
                            .fontWeight(.medium)
                            .multilineTextAlignment(.center)
                            .onChange(of: verificationCode) { _, newValue in
                                // Limit to 6 digits
                                if newValue.count > 6 {
                                    verificationCode = String(newValue.prefix(6))
                                }
                                
                                // Auto-verify when 6 digits are entered
                                if newValue.count == 6 {
                                    verifyCode()
                                }
                            }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(verificationCode.count == 6 ? Color.blue : Color(.systemGray4), lineWidth: 2)
                    )
                }
                
                // Timer and resend
                VStack(spacing: 8) {
                    if timeRemaining > 0 {
                        Text("El código expira en \(formatTime(timeRemaining))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("El código ha expirado")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    
                    if canResend {
                        Button("Reenviar código") {
                            resendCode()
                        }
                        .font(.body)
                        .foregroundColor(.blue)
                    }
                }
            }
            
            Spacer()
            
            // Action Buttons
            VStack(spacing: 16) {
                Button(action: verifyCode) {
                    HStack {
                        if isVerifying {
                            ProgressView()
                                .scaleEffect(0.8)
                                .foregroundColor(.white)
                        }
                        
                        Text(isVerifying ? "Verificando..." : "Verificar")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(canVerify ? Color.blue : Color.gray)
                    )
                }
                .disabled(!canVerify || isVerifying)
                
                Button("Cambiar email") {
                    // Go back to registration
                    tenantManager.userPendingVerification = nil
                }
                .font(.body)
                .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 40)
        .background(Color(.systemBackground))
        .onReceive(timer) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                canResend = true
            }
        }
        .alert("Verificación", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private var canVerify: Bool {
        return verificationCode.count == 6 && timeRemaining > 0
    }
    
    private func verifyCode() {
        guard canVerify else { return }
        
        isVerifying = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let success = tenantManager.verifyEmailAndCompleteRegistration(code: verificationCode)
            
            isVerifying = false
            
            if !success {
                showAlert("Código incorrecto. Por favor, verifica e intenta nuevamente.")
                verificationCode = ""
            }
            // If successful, the app will automatically navigate to the main view
        }
    }
    
    private func resendCode() {
        guard let user = tenantManager.userPendingVerification else { return }
        
        emailService.sendVerificationCode(to: user.email, userName: user.name)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { success in
                    if success {
                        timeRemaining = 600
                        canResend = false
                        showAlert("Código reenviado exitosamente")
                    } else {
                        showAlert("Error al reenviar el código")
                    }
                }
            )
            .store(in: &emailService.cancellables)
    }
    
    private func showAlert(_ message: String) {
        alertMessage = message
        showingAlert = true
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
}

// MARK: - Code Input Field Component

struct CodeInputField: View {
    @Binding var code: String
    let digitCount: Int = 6
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<digitCount, id: \.self) { index in
                DigitBox(
                    digit: digitAt(index: index),
                    isActive: index == code.count
                )
            }
        }
        .onTapGesture {
            // Focus on text field (you'd need to implement this with UIViewRepresentable)
        }
    }
    
    private func digitAt(index: Int) -> String {
        if index < code.count {
            let digitIndex = code.index(code.startIndex, offsetBy: index)
            return String(code[digitIndex])
        }
        return ""
    }
}

struct DigitBox: View {
    let digit: String
    let isActive: Bool
    
    var body: some View {
        Text(digit)
            .font(.title2)
            .fontWeight(.semibold)
            .frame(width: 45, height: 55)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isActive ? Color.blue : Color(.systemGray4), lineWidth: 2)
            )
            .animation(.easeInOut(duration: 0.2), value: isActive)
    }
}

#Preview {
    EmailVerificationView(email: "usuario@ejemplo.com")
}
