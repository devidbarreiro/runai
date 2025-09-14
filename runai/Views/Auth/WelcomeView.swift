//
//  WelcomeView.swift
//  runai
//
//  Landing page with RunAI branding and distance badges
//

import SwiftUI

struct WelcomeView: View {
    @ObservedObject var tenantManager = TenantManager.shared
    @State private var showingLogin = false
    @State private var showingRegister = false
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Top section with badges and branding
                VStack(spacing: 20) {
                    Spacer()
                    
                    // Compact distance badges grid
                    CompactDistanceBadgesGrid()
                    
                    // App branding
                    VStack(spacing: 8) {
                        Text("RunAI")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        Text("Tu entrenador personal de running")
                            .font(.title3)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Text("Cualquier distancia. Cualquier objetivo.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    Spacer()
                }
                .frame(height: geometry.size.height * 0.7)
                
                // Bottom section with buttons
                VStack(spacing: 12) {
                    Button(action: {
                        showingRegister = true
                    }) {
                        HStack {
                            Text("Comenzar")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    
                    Button(action: {
                        showingLogin = true
                    }) {
                        HStack {
                            Text("Ya tengo cuenta")
                                .font(.headline)
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.clear)
                        .foregroundColor(.blue)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.blue, lineWidth: 1)
                        )
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, geometry.safeAreaInsets.bottom + 20)
                .frame(height: geometry.size.height * 0.3)
            }
        }
        .background(Color(.systemBackground))
        .sheet(isPresented: $showingRegister) {
            RegisterView()
        }
        .sheet(isPresented: $showingLogin) {
            LoginView()
        }
    }
}

// MARK: - Compact Distance Badges Grid
struct CompactDistanceBadgesGrid: View {
    let distances = [
        DistanceBadge(distance: "5K", color: .blue, position: .center),
        DistanceBadge(distance: "10K", color: .green, position: .topLeading),
        DistanceBadge(distance: "21K", color: .orange, position: .topTrailing),
        DistanceBadge(distance: "42K", color: .red, position: .bottomLeading),
        DistanceBadge(distance: "50K", color: .purple, position: .bottomTrailing)
    ]
    
    var body: some View {
        ZStack {
            ForEach(distances.indices, id: \.self) { index in
                CompactDistanceBadgeView(badge: distances[index])
                    .offset(offsetFor(distances[index].position))
                    .scaleEffect(scaleFor(distances[index].position))
            }
        }
        .frame(height: 180)
        .padding(.horizontal, 20)
    }
    
    private func offsetFor(_ position: BadgePosition) -> CGSize {
        switch position {
        case .topLeading:
            return CGSize(width: -60, height: -50)
        case .topTrailing:
            return CGSize(width: 60, height: -50)
        case .center:
            return CGSize(width: 0, height: -20)
        case .bottomLeading:
            return CGSize(width: -60, height: 40)
        case .bottomTrailing:
            return CGSize(width: 60, height: 40)
        default:
            return CGSize.zero
        }
    }
    
    private func scaleFor(_ position: BadgePosition) -> CGFloat {
        switch position {
        case .center:
            return 1.1
        default:
            return 0.9
        }
    }
}

struct DistanceBadgesGrid: View {
    let distances = [
        DistanceBadge(distance: "1K", color: .gray, position: .topLeading),
        DistanceBadge(distance: "5K", color: .blue, position: .center),
        DistanceBadge(distance: "10K", color: .yellow, position: .topTrailing),
        DistanceBadge(distance: "13.1", color: .green, position: .leading),
        DistanceBadge(distance: "26.2", color: .red, position: .trailing),
        DistanceBadge(distance: "50K", color: .green, position: .bottomLeading),
        DistanceBadge(distance: "10MI", color: .orange, position: .bottom),
        DistanceBadge(distance: "5MI", color: .purple, position: .bottomTrailing)
    ]
    
    var body: some View {
        ZStack {
            ForEach(distances.indices, id: \.self) { index in
                DistanceBadgeView(badge: distances[index])
                    .offset(offsetFor(distances[index].position))
                    .scaleEffect(scaleFor(distances[index].position))
            }
        }
        .frame(height: 300)
        .padding(.horizontal, 20)
    }
    
    private func offsetFor(_ position: BadgePosition) -> CGSize {
        switch position {
        case .topLeading:
            return CGSize(width: -80, height: -80)
        case .topTrailing:
            return CGSize(width: 80, height: -80)
        case .leading:
            return CGSize(width: -100, height: -20)
        case .center:
            return CGSize(width: 0, height: -40)
        case .trailing:
            return CGSize(width: 100, height: -20)
        case .bottomLeading:
            return CGSize(width: -80, height: 60)
        case .bottom:
            return CGSize(width: 0, height: 80)
        case .bottomTrailing:
            return CGSize(width: 80, height: 60)
        }
    }
    
    private func scaleFor(_ position: BadgePosition) -> CGFloat {
        switch position {
        case .center:
            return 1.2
        case .leading, .trailing:
            return 1.0
        default:
            return 0.8
        }
    }
}

// MARK: - Compact Distance Badge View
struct CompactDistanceBadgeView: View {
    let badge: DistanceBadge
    
    var body: some View {
        ZStack {
            // Shield shape background
            ShieldShape()
                .fill(Color(.systemBackground))
                .frame(width: 60, height: 70)
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
            
            ShieldShape()
                .stroke(badge.color, lineWidth: 2)
                .frame(width: 60, height: 70)
            
            VStack(spacing: 2) {
                Text(badge.distance)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Image(systemName: "figure.run")
                    .font(.system(size: 10))
                    .foregroundColor(badge.color)
            }
        }
    }
}

struct DistanceBadgeView: View {
    let badge: DistanceBadge
    
    var body: some View {
        ZStack {
            // Shield shape background
            ShieldShape()
                .fill(Color.black.opacity(0.7))
                .frame(width: 80, height: 90)
            
            ShieldShape()
                .stroke(badge.color, lineWidth: 3)
                .frame(width: 80, height: 90)
            
            VStack(spacing: 4) {
                Text(badge.distance)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Image(systemName: "figure.run")
                    .font(.system(size: 12))
                    .foregroundColor(badge.color)
            }
        }
    }
}

struct ShieldShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let width = rect.width
        let height = rect.height
        
        // Shield shape path
        path.move(to: CGPoint(x: width * 0.5, y: 0))
        path.addCurve(
            to: CGPoint(x: width * 0.1, y: height * 0.3),
            control1: CGPoint(x: width * 0.1, y: height * 0.1),
            control2: CGPoint(x: width * 0.1, y: height * 0.2)
        )
        path.addLine(to: CGPoint(x: width * 0.1, y: height * 0.7))
        path.addCurve(
            to: CGPoint(x: width * 0.5, y: height),
            control1: CGPoint(x: width * 0.1, y: height * 0.9),
            control2: CGPoint(x: width * 0.3, y: height)
        )
        path.addCurve(
            to: CGPoint(x: width * 0.9, y: height * 0.7),
            control1: CGPoint(x: width * 0.7, y: height),
            control2: CGPoint(x: width * 0.9, y: height * 0.9)
        )
        path.addLine(to: CGPoint(x: width * 0.9, y: height * 0.3))
        path.addCurve(
            to: CGPoint(x: width * 0.5, y: 0),
            control1: CGPoint(x: width * 0.9, y: height * 0.2),
            control2: CGPoint(x: width * 0.9, y: height * 0.1)
        )
        
        return path
    }
}

struct DistanceBadge {
    let distance: String
    let color: Color
    let position: BadgePosition
}

enum BadgePosition {
    case topLeading, topTrailing, leading, center, trailing, bottomLeading, bottom, bottomTrailing
}

// MARK: - Register View
struct RegisterView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var tenantManager = TenantManager.shared
    
    @State private var name = ""
    @State private var username = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showingEmailVerification = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Text("🏃‍♂️")
                            .font(.system(size: 60))
                        
                        Text("Crear cuenta")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("Únete a la comunidad RunAI")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 40)
                    
                    // Form
                    VStack(spacing: 16) {
                        WelcomeTextField(
                            title: "Nombre completo",
                            text: $name,
                            icon: "person"
                        )
                        
                        WelcomeTextField(
                            title: "Usuario",
                            text: $username,
                            icon: "at"
                        )
                        
                        WelcomeTextField(
                            title: "Email",
                            text: $email,
                            icon: "envelope",
                            keyboardType: .emailAddress
                        )
                        
                        WelcomeTextField(
                            title: "Contraseña",
                            text: $password,
                            icon: "lock",
                            isSecure: true
                        )
                        
                        WelcomeTextField(
                            title: "Confirmar contraseña",
                            text: $confirmPassword,
                            icon: "lock.fill",
                            isSecure: true
                        )
                    }
                    .padding(.horizontal, 32)
                    
                    // Error message
                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding(.horizontal, 32)
                    }
                    
                    // Register button
                    Button(action: registerUser) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .foregroundColor(.white)
                            } else {
                                Text("Crear cuenta")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(16)
                    }
                    .disabled(isLoading || !isFormValid)
                    .opacity(isFormValid ? 1.0 : 0.6)
                    .padding(.horizontal, 32)
                    
                    Spacer()
                }
            }
            .background(Color(.systemBackground))
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar(content: {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancelar") {
                        dismiss()
                    }
                    .foregroundColor(.blue)
                }
            })
        }
        .fullScreenCover(isPresented: $showingEmailVerification) {
            EmailVerificationView(email: email)
        }
    }
    
    private var isFormValid: Bool {
        !name.isEmpty &&
        !username.isEmpty &&
        !email.isEmpty &&
        !password.isEmpty &&
        password == confirmPassword &&
        email.contains("@") &&
        password.count >= 6
    }
    
    private func registerUser() {
        errorMessage = ""
        isLoading = true
        
        tenantManager.registerUser(username: username, email: email, name: name)
            .sink { result in
                DispatchQueue.main.async {
                    isLoading = false
                    
                    switch result {
                    case .verificationSent:
                        showingEmailVerification = true
                    case .userAlreadyExists:
                        errorMessage = "Ya existe una cuenta con este email"
                    case .emailSendFailed:
                        errorMessage = "Error al enviar el email de verificación"
                    }
                }
            }
            .store(in: &tenantManager.cancellables)
    }
}

struct WelcomeTextField: View {
    let title: String
    @Binding var text: String
    let icon: String
    var keyboardType: UIKeyboardType = .default
    var isSecure: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.secondary)
                    .frame(width: 20)
                
                if isSecure {
                    SecureField("", text: $text)
                        .textFieldStyle(PlainTextFieldStyle())
                        .foregroundColor(.primary)
                } else {
                    TextField("", text: $text)
                        .keyboardType(keyboardType)
                        .textFieldStyle(PlainTextFieldStyle())
                        .foregroundColor(.primary)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )
        }
    }
}

#Preview {
    WelcomeView()
}
