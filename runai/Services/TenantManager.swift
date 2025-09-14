//
//  TenantManager.swift
//  runai
//
//  Multi-tenant data and user management
//

import Foundation
import Combine

class TenantManager: ObservableObject {
    static let shared = TenantManager()
    
    @Published var currentTenant: Tenant?
    @Published var currentUser: User?
    @Published var isLoggedIn: Bool = false
    @Published var userPendingVerification: User?
    
    private let emailService = EmailVerificationService.shared
    var cancellables = Set<AnyCancellable>()
    
    private init() {
        loadCurrentSession()
    }
    
    // MARK: - Authentication with Email Verification
    
    func registerUser(username: String, email: String, name: String, plan: SubscriptionPlan = .individual) -> AnyPublisher<RegistrationResult, Never> {
        print("👤 [TenantManager] Registration attempt - Email: \(email), Name: \(name), Plan: \(plan)")
        
        // Check if user already exists
        if isUserExists(email: email) {
            print("❌ [TenantManager] User already exists with email: \(email)")
            return Just(.userAlreadyExists)
                .eraseToAnyPublisher()
        }
        
        print("✅ [TenantManager] Email available, creating user")
        
        // Create user (not logged in yet, pending verification)
        let user = User(username: username, email: email, name: name, tenantId: nil, role: .member)
        userPendingVerification = user
        print("👤 [TenantManager] User created and set as pending verification")
        
        // Create or get tenant
        _ = createOrGetTenant(for: user, plan: plan)
        
        // Send verification email
        return emailService.sendVerificationCode(to: email, userName: name)
            .map { success in
                return success ? .verificationSent : .emailSendFailed
            }
            .catch { _ in
                Just(.emailSendFailed)
            }
            .eraseToAnyPublisher()
    }
    
    func verifyEmailAndCompleteRegistration(code: String) -> Bool {
        guard let user = userPendingVerification else { return false }
        
        let isValid = emailService.verifyCode(code, for: user.email)
        
        if isValid {
            // Complete registration
            var verifiedUser = user
            verifiedUser.isEmailVerified = true
            verifiedUser.emailVerifiedAt = Date()
            
            currentUser = verifiedUser
            isLoggedIn = true
            userPendingVerification = nil
            
            // Create tenant if needed
            if currentTenant == nil {
                currentTenant = createOrGetTenant(for: user, plan: .individual)
            }
            
            saveCurrentSession()
            
            // Send welcome email
            if let tenant = currentTenant {
                emailService.sendWelcomeEmail(to: user, tenant: tenant)
                    .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
                    .store(in: &cancellables)
            }
            
            return true
        }
        
        return false
    }
    
    func loginUser(email: String) -> LoginResult {
        // In a real implementation, this would validate against a backend
        // For now, we'll check local storage
        guard let userData = getUserData(email: email) else {
            return .userNotFound
        }
        
        currentUser = userData.user
        currentTenant = userData.tenant
        isLoggedIn = true
        
        saveCurrentSession()
        return .success
    }
    
    func logout() {
        currentUser = nil
        currentTenant = nil
        isLoggedIn = false
        userPendingVerification = nil
        clearCurrentSession()
    }
    
    // MARK: - Tenant Management
    
    func createEnterpriseTenant(name: String, domain: String, adminUser: User) -> Tenant {
        let tenant = Tenant(name: name, plan: .enterprise, domain: domain)
        
        // Save tenant
        saveTenant(tenant)
        
        // Update user to be admin of this tenant
        let updatedUser = adminUser
        // TODO: Add tenant admin role to user
        
        currentTenant = tenant
        currentUser = updatedUser
        
        return tenant
    }
    
    func inviteUserToTenant(_ email: String, tenant: Tenant) -> AnyPublisher<Bool, Never> {
        guard let currentUser = currentUser else {
            return Just(false).eraseToAnyPublisher()
        }
        
        return emailService.sendEnterpriseInvitation(to: email, tenant: tenant, invitedBy: currentUser)
            .catch { _ in Just(false) }
            .eraseToAnyPublisher()
    }
    
    func acceptTenantInvitation(tenantId: UUID, userEmail: String) -> Bool {
        guard let tenant = getTenant(id: tenantId),
              let _ = currentUser else {
            return false
        }
        
        // Add user to tenant
        currentTenant = tenant
        saveCurrentSession()
        
        return true
    }
    
    // MARK: - Feature Access Control
    
    func hasFeature(_ feature: Feature) -> Bool {
        guard let tenant = currentTenant else {
            return Feature.basicFeatures.contains(feature)
        }
        
        return tenant.settings.featuresEnabled.contains(feature)
    }
    
    func canAddMoreUsers() -> Bool {
        guard let tenant = currentTenant else { return false }
        
        let currentUserCount = getUserCount(for: tenant)
        return currentUserCount < tenant.settings.maxUsers
    }
    
    // MARK: - Data Isolation
    
    func getWorkouts(for user: User) -> [Workout] {
        guard let tenantId = currentTenant?.id else { return [] }
        
        // In a real implementation, this would query the backend with tenant isolation
        let key = "workouts_\(tenantId)_\(user.id)"
        
        if let data = UserDefaults.standard.data(forKey: key),
           let workouts = try? JSONDecoder().decode([Workout].self, from: data) {
            return workouts
        }
        
        return []
    }
    
    func saveWorkouts(_ workouts: [Workout], for user: User) {
        guard let tenantId = currentTenant?.id else { return }
        
        let key = "workouts_\(tenantId)_\(user.id)"
        
        if let data = try? JSONEncoder().encode(workouts) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
    
    // MARK: - Private Methods
    
    private func createOrGetTenant(for user: User, plan: SubscriptionPlan) -> Tenant {
        // Check if user should join existing tenant (based on email domain for enterprise)
        if plan == .enterprise, let domain = extractDomain(from: user.email) {
            if let existingTenant = getTenantByDomain(domain) {
                return existingTenant
            }
        }
        
        // Create new tenant
        let tenant = Tenant(name: user.name, plan: plan)
        saveTenant(tenant)
        return tenant
    }
    
    private func extractDomain(from email: String) -> String? {
        let components = email.components(separatedBy: "@")
        return components.count == 2 ? components[1] : nil
    }
    
    private func isUserExists(email: String) -> Bool {
        return UserDefaults.standard.object(forKey: "user_\(email)") != nil
    }
    
    private func getUserData(email: String) -> (user: User, tenant: Tenant)? {
        guard let userData = UserDefaults.standard.data(forKey: "user_\(email)"),
              let user = try? JSONDecoder().decode(User.self, from: userData),
              let tenantData = UserDefaults.standard.data(forKey: "tenant_\(user.id)"),
              let tenant = try? JSONDecoder().decode(Tenant.self, from: tenantData) else {
            return nil
        }
        
        return (user, tenant)
    }
    
    private func saveTenant(_ tenant: Tenant) {
        if let data = try? JSONEncoder().encode(tenant) {
            UserDefaults.standard.set(data, forKey: "tenant_\(tenant.id)")
        }
    }
    
    private func getTenant(id: UUID) -> Tenant? {
        guard let data = UserDefaults.standard.data(forKey: "tenant_\(id)"),
              let tenant = try? JSONDecoder().decode(Tenant.self, from: data) else {
            return nil
        }
        return tenant
    }
    
    private func getTenantByDomain(_ domain: String) -> Tenant? {
        // In a real implementation, this would query the backend
        // For now, we'll iterate through stored tenants
        return nil
    }
    
    private func getUserCount(for tenant: Tenant) -> Int {
        // In a real implementation, this would query the backend
        return 1
    }
    
    func saveCurrentSession() {
        if let user = currentUser,
           let userData = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(userData, forKey: "current_user")
        }
        
        if let tenant = currentTenant,
           let tenantData = try? JSONEncoder().encode(tenant) {
            UserDefaults.standard.set(tenantData, forKey: "current_tenant")
        }
        
        UserDefaults.standard.set(isLoggedIn, forKey: "is_logged_in")
    }
    
    private func loadCurrentSession() {
        isLoggedIn = UserDefaults.standard.bool(forKey: "is_logged_in")
        
        if let userData = UserDefaults.standard.data(forKey: "current_user"),
           let user = try? JSONDecoder().decode(User.self, from: userData) {
            currentUser = user
        }
        
        if let tenantData = UserDefaults.standard.data(forKey: "current_tenant"),
           let tenant = try? JSONDecoder().decode(Tenant.self, from: tenantData) {
            currentTenant = tenant
        }
    }
    
    private func clearCurrentSession() {
        UserDefaults.standard.removeObject(forKey: "current_user")
        UserDefaults.standard.removeObject(forKey: "current_tenant")
        UserDefaults.standard.removeObject(forKey: "is_logged_in")
    }
}

// MARK: - Result Types

enum RegistrationResult {
    case verificationSent
    case userAlreadyExists
    case emailSendFailed
    
    var message: String {
        switch self {
        case .verificationSent:
            return "Se ha enviado un código de verificación a tu email"
        case .userAlreadyExists:
            return "Ya existe una cuenta con este email"
        case .emailSendFailed:
            return "Error al enviar el email de verificación"
        }
    }
}

enum LoginResult {
    case success
    case userNotFound
    case invalidCredentials
    
    var message: String {
        switch self {
        case .success:
            return "Inicio de sesión exitoso"
        case .userNotFound:
            return "Usuario no encontrado"
        case .invalidCredentials:
            return "Credenciales inválidas"
        }
    }
}
