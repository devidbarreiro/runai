 //
//  LoginView.swift
//  runai
//
//  Created by David Barreiro on 11/09/25.
//

import SwiftUI

struct LoginView: View {
    @State private var username: String = ""
    @State private var email: String = ""
    @State private var name: String = ""
    @State private var isShowingSignUp: Bool = false
    @State private var showingAlert: Bool = false
    @State private var alertMessage: String = ""
    @ObservedObject var dataManager = DataManager.shared
    
    // Validation states
    @State private var usernameError: String? = nil
    @State private var emailError: String? = nil
    @State private var nameError: String? = nil
    
    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 16) {
                     Image(systemName: "figure.run")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    VStack(spacing: 8) {
                        Text("RunAI")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Tu compañero de entrenamiento inteligente")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.top, 40)
                
                // Form
                VStack(spacing: 20) {
                    // Username field (always visible)
                    VStack(alignment: .leading, spacing: 4) {
                        CustomTextField(
                            placeholder: "Nombre de usuario",
                            text: $username,
                            icon: "person.circle",
                            hasError: usernameError != nil
                        )
                        .autocapitalization(.none)
                        .onChange(of: username) { _ in
                            validateUsername()
                        }
                        
                        if let error = usernameError {
                            ErrorText(error)
                        }
                    }
                    
                    // Registration-only fields
                    if isShowingSignUp {
                        VStack(alignment: .leading, spacing: 4) {
                            CustomTextField(
                                placeholder: "Nombre completo",
                                text: $name,
                                icon: "person",
                                hasError: nameError != nil
                            )
                            .onChange(of: name) { _ in
                                validateName()
                            }
                            
                            if let error = nameError {
                                ErrorText(error)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            CustomTextField(
                                placeholder: "Correo electrónico",
                                text: $email,
                                icon: "envelope",
                                hasError: emailError != nil
                            )
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .onChange(of: email) { _ in
                                validateEmail()
                            }
                            
                            if let error = emailError {
                                ErrorText(error)
                            }
                        }
                    }
                    
                    Button(action: handleAuth) {
                        Text(isShowingSignUp ? "Crear cuenta" : "Iniciar sesión")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.blue)
                            )
                    }
                    .disabled(!isFormValid)
                }
                
                // Toggle between login/signup
                Button(action: {
                    // Clear form first, then toggle with animation
                    clearForm()
                    withAnimation(.easeInOut(duration: 0.4)) {
                        isShowingSignUp.toggle()
                    }
                }) {
                    Text(isShowingSignUp ? "¿Ya tienes cuenta? Inicia sesión" : "¿No tienes cuenta? Regístrate")
                        .font(.body)
                        .foregroundColor(.blue)
                }
                
                Spacer()
            }
            .padding(.horizontal, 32)
            .background(Color(.systemBackground))
        }
        .alert("Error", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private var isFormValid: Bool {
        if isShowingSignUp {
            return !username.isEmpty && !name.isEmpty && !email.isEmpty && 
                   usernameError == nil && nameError == nil && emailError == nil
        } else {
            return !username.isEmpty && usernameError == nil
        }
    }
    
    private func handleAuth() {
        if isShowingSignUp {
            // Register new user
            print("DEBUG: Attempting to register user - Username: \(username), Email: \(email), Name: \(name)")
            print("DEBUG: Form validation - usernameError: \(usernameError ?? "nil"), nameError: \(nameError ?? "nil"), emailError: \(emailError ?? "nil")")
            
            let success = dataManager.registerUser(username: username, email: email, name: name)
            print("DEBUG: Registration result: \(success)")
            if !success {
                showAlert("El nombre de usuario ya existe. Elige otro.")
            }
        } else {
            // Login existing user
            let success = dataManager.login(username: username)
            if !success {
                showAlert("Usuario no encontrado")
            }
        }
    }
    
    private func showAlert(_ message: String) {
        alertMessage = message
        showingAlert = true
    }
    
    private func clearForm() {
        username = ""
        email = ""
        name = ""
        
        // Clear validation errors
        usernameError = nil
        emailError = nil
        nameError = nil
    }
    
    // MARK: - Validation Functions
    private func validateUsername() {
        // Don't validate if empty (user hasn't started typing)
        if username.isEmpty {
            usernameError = nil
            return
        }
        
        // Only validate if user has typed something meaningful
        if username.count < 3 {
            usernameError = "Mínimo 3 caracteres"
        } else if username.count > 20 {
            usernameError = "Máximo 20 caracteres"
        } else if !username.allSatisfy({ $0.isLetter || $0.isNumber || $0 == "_" }) {
            usernameError = "Solo letras, números y _"
        } else {
            usernameError = nil
        }
    }
    
    private func validateName() {
        if name.isEmpty {
            nameError = nil
            return
        }
        
        if name.count < 2 {
            nameError = "Mínimo 2 caracteres"
        } else if name.count > 50 {
            nameError = "Máximo 50 caracteres"
        } else if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            nameError = "El nombre no puede estar vacío"
        } else {
            nameError = nil
        }
    }
    
    private func validateEmail() {
        if email.isEmpty {
            emailError = nil
            return
        }
        
        let emailRegex = "^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        
        if !emailPredicate.evaluate(with: email) {
            emailError = "Formato de email inválido"
        } else {
            emailError = nil
        }
    }
    
}

struct CustomTextField: View {
    let placeholder: String
    @Binding var text: String
    let icon: String
    let hasError: Bool
    
    init(placeholder: String, text: Binding<String>, icon: String, hasError: Bool = false) {
        self.placeholder = placeholder
        self._text = text
        self.icon = icon
        self.hasError = hasError
    }
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(hasError ? .red : .secondary)
                .frame(width: 20)
            
            TextField(placeholder, text: $text)
                .textFieldStyle(PlainTextFieldStyle())
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(hasError ? Color.red : Color(.systemGray4), lineWidth: hasError ? 2 : 1)
        )
    }
}


struct ErrorText: View {
    let message: String
    
    init(_ message: String) {
        self.message = message
    }
    
    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundColor(.red)
                .font(.caption)
            
            Text(message)
                .font(.caption)
                .foregroundColor(.red)
            
            Spacer()
        }
        .padding(.leading, 4)
    }
}

#Preview {
    LoginView()
}
