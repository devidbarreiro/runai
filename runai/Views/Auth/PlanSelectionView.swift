//
//  PlanSelectionView.swift
//  runai
//
//  Plan selection view for new users and enterprises
//

import SwiftUI

struct PlanSelectionView: View {
    @ObservedObject var tenantManager = TenantManager.shared
    @State private var selectedPlan: SubscriptionPlan = .individual
    @State private var showingRegistration = false
    @State private var showingEnterpriseForm = false
    @State private var showingGymJoin = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "star.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        
                        VStack(spacing: 8) {
                            Text("Elige tu plan")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text("Selecciona el plan que mejor se adapte a tus necesidades")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    
                    // Plan Cards
                    VStack(spacing: 16) {
                        ForEach(SubscriptionPlan.allCases, id: \.self) { plan in
                            PlanCard(
                                plan: plan,
                                isSelected: selectedPlan == plan,
                                onSelect: { selectedPlan = plan }
                            )
                        }
                    }
                    
                    // Gym Member Option
                    GymMemberCard(
                        onJoinGymTapped: {
                            showingGymJoin = true
                        }
                    )
                    
                    // Enterprise Contact
                    EnterpriseContactCard(
                        onContactTapped: {
                            showingEnterpriseForm = true
                        }
                    )
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 32)
            }
            .navigationTitle("Planes")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Continuar") {
                        if selectedPlan == .enterprise {
                            showingEnterpriseForm = true
                        } else {
                            // Mark plan as selected and continue to main app
                            DataManager.shared.completePlanSelection()
                        }
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .sheet(isPresented: $showingRegistration) {
            RegistrationView(selectedPlan: selectedPlan)
        }
        .sheet(isPresented: $showingEnterpriseForm) {
            EnterpriseRegistrationView()
        }
        .sheet(isPresented: $showingGymJoin) {
            GymJoinView()
        }
    }
}

struct PlanCard: View {
    let plan: SubscriptionPlan
    let isSelected: Bool
    let onSelect: () -> Void
    
    private var isPopular: Bool {
        plan == .team
    }
    
    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 20) {
                // Header with price
                VStack(spacing: 8) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(plan.displayName)
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            if plan != .enterprise {
                                HStack(alignment: .bottom, spacing: 4) {
                                    Text("$\(String(format: "%.0f", plan.monthlyPrice))")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.primary)
                                    
                                    Text("/mes")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            } else {
                                Text("Contactar")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                            }
                        }
                        
                        Spacer()
                        
                        if isPopular {
                            Text("Popular")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(Color.orange)
                                )
                        }
                    }
                    
                    if plan != .individual {
                        HStack {
                            Text("Hasta \(plan.maxUsers == Int.max ? "∞" : "\(plan.maxUsers)") usuarios")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                    }
                }
                
                // Features
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(plan.features.prefix(4), id: \.self) { feature in
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.caption)
                            
                            Text(feature.displayName)
                                .font(.body)
                                .foregroundColor(.primary)
                            
                            Spacer()
                        }
                    }
                    
                    if plan.features.count > 4 {
                        HStack {
                            Image(systemName: "plus.circle")
                                .foregroundColor(.blue)
                                .font(.caption)
                            
                            Text("Y \(plan.features.count - 4) funciones más")
                                .font(.caption)
                                .foregroundColor(.blue)
                            
                            Spacer()
                        }
                    }
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color(.systemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isSelected ? Color.blue : Color(.systemGray4),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
            .shadow(
                color: .black.opacity(isSelected ? 0.1 : 0.05),
                radius: isSelected ? 8 : 4,
                x: 0, y: 2
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

struct EnterpriseContactCard: View {
    let onContactTapped: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 8) {
                Text("¿Necesitas algo más?")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("Para empresas con necesidades específicas, ofrecemos soluciones personalizadas")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: onContactTapped) {
                HStack {
                    Image(systemName: "envelope.fill")
                    Text("Contactar Ventas")
                }
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(.blue)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.blue.opacity(0.1))
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
        )
    }
}

struct RegistrationView: View {
    let selectedPlan: SubscriptionPlan
    @Environment(\.dismiss) private var dismiss
    
    @State private var username = ""
    @State private var email = ""
    @State private var name = ""
    @State private var isRegistering = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var registrationResult: RegistrationResult?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Plan Summary
                    VStack(spacing: 12) {
                        Text("Registro - \(selectedPlan.displayName)")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        if selectedPlan != .enterprise {
                            Text("$\(String(format: "%.0f", selectedPlan.monthlyPrice))/mes")
                                .font(.title3)
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.top, 20)
                    
                    // Registration Form
                    VStack(spacing: 16) {
                        CustomTextField(
                            placeholder: "Nombre completo",
                            text: $name,
                            icon: "person"
                        )
                        
                        CustomTextField(
                            placeholder: "Nombre de usuario",
                            text: $username,
                            icon: "person.circle"
                        )
                        .autocapitalization(.none)
                        
                        CustomTextField(
                            placeholder: "Correo electrónico",
                            text: $email,
                            icon: "envelope"
                        )
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    }
                    
                    // Terms and Privacy
                    VStack(spacing: 12) {
                        Text("Al registrarte, aceptas nuestros Términos de Servicio y Política de Privacidad")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    // Register Button
                    Button(action: register) {
                        HStack {
                            if isRegistering {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .foregroundColor(.white)
                            }
                            
                            Text(isRegistering ? "Registrando..." : "Crear Cuenta")
                                .font(.headline)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(canRegister ? Color.blue : Color.gray)
                        )
                    }
                    .disabled(!canRegister || isRegistering)
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
            }
            .navigationTitle("Registro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
            }
        }
        .alert("Registro", isPresented: $showingAlert) {
            Button("OK") {
                if registrationResult == .verificationSent {
                    dismiss()
                }
            }
        } message: {
            Text(alertMessage)
        }
    }
    
    private var canRegister: Bool {
        !name.isEmpty && !username.isEmpty && !email.isEmpty && email.contains("@")
    }
    
    private func register() {
        isRegistering = true
        
        TenantManager.shared.registerUser(
            username: username,
            email: email,
            name: name,
            plan: selectedPlan
        )
        .sink { result in
            isRegistering = false
            registrationResult = result
            alertMessage = result.message
            showingAlert = true
        }
        .store(in: &TenantManager.shared.cancellables)
    }
}

struct EnterpriseRegistrationView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var companyName = ""
    @State private var domain = ""
    @State private var contactName = ""
    @State private var contactEmail = ""
    @State private var expectedUsers = ""
    @State private var message = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 12) {
                        Text("Contacto Empresarial")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Nos pondremos en contacto contigo para crear una solución personalizada")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)
                    
                    VStack(spacing: 16) {
                        CustomTextField(
                            placeholder: "Nombre de la empresa",
                            text: $companyName,
                            icon: "building.2"
                        )
                        
                        CustomTextField(
                            placeholder: "Dominio corporativo (ej: empresa.com)",
                            text: $domain,
                            icon: "globe"
                        )
                        .autocapitalization(.none)
                        
                        CustomTextField(
                            placeholder: "Nombre del contacto",
                            text: $contactName,
                            icon: "person"
                        )
                        
                        CustomTextField(
                            placeholder: "Email del contacto",
                            text: $contactEmail,
                            icon: "envelope"
                        )
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        
                        CustomTextField(
                            placeholder: "Número estimado de usuarios",
                            text: $expectedUsers,
                            icon: "person.3"
                        )
                        .keyboardType(.numberPad)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Mensaje adicional (opcional)")
                                .font(.body)
                                .fontWeight(.medium)
                            
                            TextField("Cuéntanos sobre tus necesidades específicas...", text: $message, axis: .vertical)
                                .textFieldStyle(PlainTextFieldStyle())
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(.systemGray6))
                                )
                                .lineLimit(3...6)
                        }
                    }
                    
                    Button("Enviar Solicitud") {
                        // TODO: Send enterprise contact request
                        dismiss()
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(canSubmit ? Color.blue : Color.gray)
                    )
                    .disabled(!canSubmit)
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
            }
            .navigationTitle("Contacto")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var canSubmit: Bool {
        !companyName.isEmpty && !contactName.isEmpty && !contactEmail.isEmpty && contactEmail.contains("@")
    }
}

struct GymMemberCard: View {
    let onJoinGymTapped: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 8) {
                Text("¿Perteneces a un gimnasio?")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("Si tu gimnasio ya tiene RunAI, únete con tu código de invitación")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: onJoinGymTapped) {
                HStack {
                    Image(systemName: "building.2.fill")
                    Text("Tengo un código de gimnasio")
                }
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.green)
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.green.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.green.opacity(0.3), lineWidth: 1)
        )
    }
}

struct GymJoinView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var tenantManager = TenantManager.shared
    
    @State private var gymCode = ""
    @State private var email = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isJoining = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                VStack(spacing: 16) {
                    Image(systemName: "building.2.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.green)
                    
                    VStack(spacing: 8) {
                        Text("Únete a tu gimnasio")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Ingresa el código que te proporcionó tu gimnasio")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Código del gimnasio")
                            .font(.headline)
                            .fontWeight(.medium)
                        
                        TextField("Ej: FITMAX2024", text: $gymCode)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.allCharacters)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tu email")
                            .font(.headline)
                            .fontWeight(.medium)
                        
                        TextField("email@ejemplo.com", text: $email)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                    }
                }
                
                Button(action: joinGym) {
                    HStack {
                        if isJoining {
                            ProgressView()
                                .scaleEffect(0.8)
                                .foregroundColor(.white)
                        }
                        
                        Text(isJoining ? "Verificando..." : "Unirse al Gimnasio")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(canJoin ? Color.green : Color.gray)
                    )
                }
                .disabled(!canJoin || isJoining)
                
                Spacer()
            }
            .padding(.horizontal, 32)
            .navigationTitle("Código de Gimnasio")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
            }
        }
        .alert("Gimnasio", isPresented: $showingAlert) {
            Button("OK") {
                if alertMessage.contains("exitoso") {
                    dismiss()
                }
            }
        } message: {
            Text(alertMessage)
        }
    }
    
    private var canJoin: Bool {
        !gymCode.isEmpty && !email.isEmpty && email.contains("@")
    }
    
    private func joinGym() {
        isJoining = true
        
        // Mock gym join - in production this would validate with backend
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            isJoining = false
            
            // Simulate successful join
            if gymCode.uppercased() == "FITMAX2024" {
                // Create gym member user
                let user = User(
                    username: email.components(separatedBy: "@")[0],
                    email: email,
                    name: "Miembro de Gimnasio",
                    tenantId: UUID(),
                    role: .member,
                    subscriptionType: .premium // Gym members get premium access
                )
                
                var gymUser = user
                gymUser.isEmailVerified = true
                gymUser.emailVerifiedAt = Date()
                gymUser.gymMembershipId = "MEMBER_\(UUID().uuidString.prefix(8))"
                gymUser.subscriptionStatus = .active
                gymUser.hasSelectedPlan = true // Gym members automatically have a plan
                
                tenantManager.currentUser = gymUser
                tenantManager.isLoggedIn = true
                tenantManager.saveCurrentSession()
                
                alertMessage = "¡Te has unido exitosamente a FitMax Gym!"
                showingAlert = true
            } else {
                alertMessage = "Código de gimnasio inválido. Verifica con tu gimnasio."
                showingAlert = true
            }
        }
    }
}

#Preview {
    PlanSelectionView()
}
