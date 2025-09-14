//
//  Tenant.swift
//  runai
//
//  Multi-tenant architecture models
//

import Foundation

// MARK: - Tenant Models
struct Tenant: Codable, Identifiable {
    let id: UUID
    let name: String
    let domain: String? // Para empresas: "company.com"
    let plan: SubscriptionPlan
    let createdAt: Date
    let isActive: Bool
    let settings: TenantSettings
    let branding: TenantBranding?
    
    init(name: String, plan: SubscriptionPlan, domain: String? = nil) {
        self.id = UUID()
        self.name = name
        self.domain = domain
        self.plan = plan
        self.createdAt = Date()
        self.isActive = true
        self.settings = TenantSettings()
        self.branding = nil
    }
}

struct TenantSettings: Codable {
    var maxUsers: Int
    var featuresEnabled: [Feature]
    var dataRetentionDays: Int
    var customDomainEnabled: Bool
    var ssoEnabled: Bool
    var apiAccessEnabled: Bool
    
    init() {
        self.maxUsers = 1
        self.featuresEnabled = Feature.basicFeatures
        self.dataRetentionDays = 365
        self.customDomainEnabled = false
        self.ssoEnabled = false
        self.apiAccessEnabled = false
    }
}

struct TenantBranding: Codable {
    let primaryColor: String
    let logoURL: String?
    let companyName: String
    let customWelcomeMessage: String?
}

// MARK: - Subscription Plans
enum SubscriptionPlan: String, CaseIterable, Codable {
    case individual = "individual"
    case team = "team"
    case enterprise = "enterprise"
    
    var displayName: String {
        switch self {
        case .individual:
            return "Plan Individual"
        case .team:
            return "Plan Equipos"
        case .enterprise:
            return "Plan Empresarial"
        }
    }
    
    var maxUsers: Int {
        switch self {
        case .individual:
            return 1
        case .team:
            return 50
        case .enterprise:
            return Int.max
        }
    }
    
    var monthlyPrice: Double {
        switch self {
        case .individual:
            return 9.99
        case .team:
            return 29.99
        case .enterprise:
            return 99.99
        }
    }
    
    var features: [Feature] {
        switch self {
        case .individual:
            return Feature.basicFeatures
        case .team:
            return Feature.teamFeatures
        case .enterprise:
            return Feature.enterpriseFeatures
        }
    }
}

// MARK: - Features
enum Feature: String, CaseIterable, Codable {
    // Basic features
    case workoutTracking = "workout_tracking"
    case aiCoaching = "ai_coaching"
    case basicAnalytics = "basic_analytics"
    
    // Team features
    case teamDashboard = "team_dashboard"
    case groupChallenges = "group_challenges"
    case teamAnalytics = "team_analytics"
    case bulkUserManagement = "bulk_user_management"
    
    // Enterprise features
    case ssoIntegration = "sso_integration"
    case customBranding = "custom_branding"
    case advancedAnalytics = "advanced_analytics"
    case apiAccess = "api_access"
    case customReporting = "custom_reporting"
    case dataExport = "data_export"
    case prioritySupport = "priority_support"
    
    var displayName: String {
        switch self {
        case .workoutTracking:
            return "Seguimiento de Entrenamientos"
        case .aiCoaching:
            return "Entrenador IA"
        case .basicAnalytics:
            return "Análisis Básico"
        case .teamDashboard:
            return "Dashboard de Equipo"
        case .groupChallenges:
            return "Desafíos Grupales"
        case .teamAnalytics:
            return "Análisis de Equipo"
        case .bulkUserManagement:
            return "Gestión Masiva de Usuarios"
        case .ssoIntegration:
            return "Integración SSO"
        case .customBranding:
            return "Marca Personalizada"
        case .advancedAnalytics:
            return "Análisis Avanzado"
        case .apiAccess:
            return "Acceso API"
        case .customReporting:
            return "Reportes Personalizados"
        case .dataExport:
            return "Exportación de Datos"
        case .prioritySupport:
            return "Soporte Prioritario"
        }
    }
    
    static var basicFeatures: [Feature] {
        return [.workoutTracking, .aiCoaching, .basicAnalytics]
    }
    
    static var teamFeatures: [Feature] {
        return basicFeatures + [.teamDashboard, .groupChallenges, .teamAnalytics, .bulkUserManagement]
    }
    
    static var enterpriseFeatures: [Feature] {
        return teamFeatures + [.ssoIntegration, .customBranding, .advancedAnalytics, .apiAccess, .customReporting, .dataExport, .prioritySupport]
    }
}

// MARK: - User Extensions for Multi-tenancy
extension User {
    var isEnterpriseUser: Bool {
        return tenantId != nil && role != .member
    }
    
    var availableFeatures: [Feature] {
        // Get features based on tenant plan and subscription
        if isGymMember {
            return Feature.enterpriseFeatures // Gym members get enterprise features
        }
        
        switch subscriptionType {
        case .free:
            return Feature.basicFeatures
        case .basic:
            return Feature.basicFeatures
        case .premium:
            return Feature.teamFeatures
        case .pro:
            return Feature.enterpriseFeatures
        }
    }
}
