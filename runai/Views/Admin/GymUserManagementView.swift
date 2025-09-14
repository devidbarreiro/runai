//
//  GymUserManagementView.swift
//  runai
//
//  Gym user management with invitation system
//

import SwiftUI

struct GymUserManagementView: View {
    @ObservedObject var tenantManager = TenantManager.shared
    @ObservedObject var emailService = EmailVerificationService.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingInviteUser = false
    @State private var searchText = ""
    @State private var selectedRole: UserRole = .member
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    // Mock users for demo
    @State private var gymUsers: [GymUser] = [
        GymUser(
            id: UUID(),
            name: "María González",
            email: "maria@email.com",
            role: .member,
            status: .active,
            joinDate: Date().addingTimeInterval(-86400 * 30),
            lastActivity: Date().addingTimeInterval(-3600)
        ),
        GymUser(
            id: UUID(),
            name: "Carlos Trainer",
            email: "carlos@email.com",
            role: .trainer,
            status: .active,
            joinDate: Date().addingTimeInterval(-86400 * 60),
            lastActivity: Date().addingTimeInterval(-1800)
        ),
        GymUser(
            id: UUID(),
            name: "Ana Pending",
            email: "ana@email.com",
            role: .member,
            status: .pending,
            joinDate: Date(),
            lastActivity: nil
        )
    ]
    
    var filteredUsers: [GymUser] {
        if searchText.isEmpty {
            return gymUsers
        } else {
            return gymUsers.filter { user in
                user.name.localizedCaseInsensitiveContains(searchText) ||
                user.email.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Stats header
                statsHeader
                
                // Search and filters
                searchAndFilters
                
                // Users list
                usersList
            }
            .navigationTitle("Gestión de Usuarios")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cerrar") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingInviteUser = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showingInviteUser) {
            InviteUserView { email, role, name in
                inviteUser(email: email, role: role, name: name)
            }
        }
        .alert("Gestión de Usuarios", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    // MARK: - Stats Header
    
    private var statsHeader: some View {
        HStack {
            StatItem(
                title: "Total Usuarios",
                value: "\(gymUsers.count)",
                icon: "person.3.fill",
                color: .blue
            )
            
            StatItem(
                title: "Activos",
                value: "\(gymUsers.filter { $0.status == .active }.count)",
                icon: "checkmark.circle.fill",
                color: .green
            )
            
            StatItem(
                title: "Pendientes",
                value: "\(gymUsers.filter { $0.status == .pending }.count)",
                icon: "clock.fill",
                color: .orange
            )
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color(.systemGray6))
    }
    
    // MARK: - Search and Filters
    
    private var searchAndFilters: some View {
        VStack(spacing: 12) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Buscar usuarios...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray6))
            )
            
            // Role filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    FilterChip(
                        title: "Todos",
                        isSelected: selectedRole == .member, // Using as "all" for demo
                        action: { selectedRole = .member }
                    )
                    
                    ForEach(UserRole.allCases, id: \.self) { role in
                        FilterChip(
                            title: role.displayName,
                            isSelected: selectedRole == role,
                            action: { selectedRole = role }
                        )
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
    }
    
    // MARK: - Users List
    
    private var usersList: some View {
        List {
            ForEach(filteredUsers) { user in
                UserRow(
                    user: user,
                    onResendInvite: {
                        resendInvitation(to: user)
                    },
                    onChangeRole: { newRole in
                        changeUserRole(user: user, to: newRole)
                    },
                    onRemoveUser: {
                        removeUser(user)
                    }
                )
            }
        }
        .listStyle(PlainListStyle())
    }
    
    // MARK: - Actions
    
    private func inviteUser(email: String, role: UserRole, name: String) {
        // Generate temporary password
        let tempPassword = generateTemporaryPassword()
        
        // Create temporary user
        let _ = User(
            username: email.components(separatedBy: "@")[0],
            email: email,
            name: name,
            tenantId: tenantManager.currentTenant?.id,
            role: role,
            subscriptionType: .premium // Gym members get premium
        )
        
        // Add to gym users list
        let gymUser = GymUser(
            id: UUID(),
            name: name,
            email: email,
            role: role,
            status: .pending,
            joinDate: Date(),
            lastActivity: nil,
            temporaryPassword: tempPassword
        )
        
        gymUsers.append(gymUser)
        
        // Send invitation email
        sendInvitationEmail(to: email, name: name, tempPassword: tempPassword, role: role)
        
        alertMessage = "Invitación enviada exitosamente a \(email)"
        showingAlert = true
    }
    
    private func sendInvitationEmail(to email: String, name: String, tempPassword: String, role: UserRole) {
        guard let tenant = tenantManager.currentTenant,
              let currentUser = tenantManager.currentUser else { return }
        
        let gymName = tenant.name
        let _ = currentUser.name
        
        // Mock email sending - in production use EmailVerificationService
        print("📧 Sending invitation email to: \(email)")
        print("📧 Gym: \(gymName)")
        print("📧 Temporary Password: \(tempPassword)")
        print("📧 Role: \(role.displayName)")
        
        // In production, this would call emailService.sendGymInvitation
    }
    
    private func resendInvitation(to user: GymUser) {
        if let tempPassword = user.temporaryPassword {
            sendInvitationEmail(to: user.email, name: user.name, tempPassword: tempPassword, role: user.role)
            alertMessage = "Invitación reenviada a \(user.name)"
            showingAlert = true
        }
    }
    
    private func changeUserRole(user: GymUser, to newRole: UserRole) {
        if let index = gymUsers.firstIndex(where: { $0.id == user.id }) {
            gymUsers[index].role = newRole
            alertMessage = "Rol de \(user.name) cambiado a \(newRole.displayName)"
            showingAlert = true
        }
    }
    
    private func removeUser(_ user: GymUser) {
        gymUsers.removeAll { $0.id == user.id }
        alertMessage = "\(user.name) ha sido removido del gimnasio"
        showingAlert = true
    }
    
    private func generateTemporaryPassword() -> String {
        let characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<8).map { _ in characters.randomElement()! })
    }
}

// MARK: - Supporting Views

struct StatItem: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemBackground))
        )
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.blue : Color(.systemGray5))
                )
        }
    }
}

struct UserRow: View {
    let user: GymUser
    let onResendInvite: () -> Void
    let onChangeRole: (UserRole) -> Void
    let onRemoveUser: () -> Void
    
    @State private var showingActions = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            Circle()
                .fill(user.status == .active ? Color.green : Color.orange)
                .frame(width: 40, height: 40)
                .overlay(
                    Text(user.name.prefix(1))
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                )
            
            // User info
            VStack(alignment: .leading, spacing: 4) {
                Text(user.name)
                    .font(.body)
                    .fontWeight(.medium)
                
                Text(user.email)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack {
                    Text(user.role.displayName)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(Color.blue.opacity(0.1))
                        )
                    
                    Text(user.status.displayName)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(user.status == .active ? .green : .orange)
                }
            }
            
            Spacer()
            
            // Last activity
            if let lastActivity = user.lastActivity {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Última actividad")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text(formatRelativeTime(lastActivity))
                        .font(.caption)
                        .fontWeight(.medium)
                }
            } else if user.status == .pending {
                Text("Pendiente")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
            
            // Actions menu
            Button(action: {
                showingActions = true
            }) {
                Image(systemName: "ellipsis")
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
        .confirmationDialog("Acciones de Usuario", isPresented: $showingActions) {
            if user.status == .pending {
                Button("Reenviar Invitación") {
                    onResendInvite()
                }
            }
            
            Menu("Cambiar Rol") {
                ForEach(UserRole.allCases, id: \.self) { role in
                    Button(role.displayName) {
                        onChangeRole(role)
                    }
                }
            }
            
            Button("Remover Usuario", role: .destructive) {
                onRemoveUser()
            }
            
            Button("Cancelar", role: .cancel) { }
        }
    }
    
    private func formatRelativeTime(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.locale = Locale(identifier: "es_ES")
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Invite User View

struct InviteUserView: View {
    @Environment(\.dismiss) private var dismiss
    let onInvite: (String, UserRole, String) -> Void
    
    @State private var email = ""
    @State private var name = ""
    @State private var selectedRole: UserRole = .member
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    Image(systemName: "envelope.badge.person.crop")
                        .font(.system(size: 50))
                        .foregroundColor(.blue)
                    
                    Text("Invitar Usuario")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Envía una invitación para unirse a tu gimnasio")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Nombre completo")
                            .font(.headline)
                            .fontWeight(.medium)
                        
                        TextField("Ej: María González", text: $name)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .font(.headline)
                            .fontWeight(.medium)
                        
                        TextField("email@ejemplo.com", text: $email)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Rol")
                            .font(.headline)
                            .fontWeight(.medium)
                        
                        Picker("Rol", selection: $selectedRole) {
                            ForEach(UserRole.allCases, id: \.self) { role in
                                Text(role.displayName).tag(role)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                }
                
                Button(action: {
                    onInvite(email, selectedRole, name)
                    dismiss()
                }) {
                    Text("Enviar Invitación")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(canInvite ? Color.blue : Color.gray)
                        )
                }
                .disabled(!canInvite)
                
                Spacer()
            }
            .padding(.horizontal, 24)
            .navigationTitle("Nueva Invitación")
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
    
    private var canInvite: Bool {
        !email.isEmpty && email.contains("@") && !name.isEmpty
    }
}

// MARK: - Data Models

struct GymUser: Identifiable {
    let id: UUID
    var name: String
    let email: String
    var role: UserRole
    var status: UserStatus
    let joinDate: Date
    var lastActivity: Date?
    var temporaryPassword: String?
    
    enum UserStatus: String, CaseIterable {
        case active = "active"
        case pending = "pending"
        case inactive = "inactive"
        
        var displayName: String {
            switch self {
            case .active:
                return "Activo"
            case .pending:
                return "Pendiente"
            case .inactive:
                return "Inactivo"
            }
        }
    }
}

#Preview {
    GymUserManagementView()
}
