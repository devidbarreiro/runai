//
//  User.swift
//  runai
//
//  Created by David Barreiro on 11/09/25.
//

import Foundation

struct User: Codable, Equatable {
    let id: UUID
    let username: String
    let email: String
    let name: String
    let hasCompletedOnboarding: Bool
    let isFirstTimeUser: Bool
    let createdAt: Date
    
    // Multi-tenant fields
    var tenantId: UUID?
    var role: UserRole
    var isEmailVerified: Bool
    var emailVerifiedAt: Date?
    
    // Subscription fields
    var subscriptionType: SubscriptionType
    var subscriptionStatus: SubscriptionStatus
    var subscriptionExpiryDate: Date?
    var appleSubscriptionId: String? // For Apple In-App Purchases
    var gymMembershipId: String? // If user belongs to a gym
    
    // Physical data
    var age: Int?
    var weight: Double? // in kg
    var height: Double? // in cm
    
    // Fitness data
    var fitnessLevel: FitnessLevel?
    var current5kTime: TimeInterval? // in seconds
    var hasAcceptedPrivacyPolicy: Bool
    var privacyPolicyAcceptedAt: Date?
    
    // Training goals
    var targetRace: RaceType?
    var raceDate: Date?
    var hasCompletedPhysicalOnboarding: Bool
    var hasSelectedPlan: Bool
    
    // Multi-sport preferences
    var preferredSports: [SportType]
    var primarySport: SportType
    
    // Sport-specific data
    var swimmingLevel: SwimmingLevel?
    var cyclingLevel: CyclingLevel?
    var hasPoolAccess: Bool
    var hasBikeAccess: Bool
    var preferredPoolLength: Int? // 25m or 50m
    
    // Sport-specific performance data (JSON)
    var sportSpecificData: [String: SportPerformanceData]
    
    init(username: String, email: String, name: String, hasCompletedOnboarding: Bool = false, isFirstTimeUser: Bool = true, tenantId: UUID? = nil, role: UserRole = .member, subscriptionType: SubscriptionType = .free, primarySport: SportType = .running) {
        self.id = UUID()
        self.username = username
        self.email = email
        self.name = name
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.isFirstTimeUser = isFirstTimeUser
        self.createdAt = Date()
        self.tenantId = tenantId
        self.role = role
        self.isEmailVerified = false
        self.emailVerifiedAt = nil
        self.subscriptionType = subscriptionType
        self.subscriptionStatus = subscriptionType == .free ? .active : .inactive
        self.subscriptionExpiryDate = nil
        self.appleSubscriptionId = nil
        self.gymMembershipId = nil
        self.hasAcceptedPrivacyPolicy = false
        self.hasCompletedPhysicalOnboarding = false
        self.hasSelectedPlan = false
        
        // Multi-sport initialization
        self.primarySport = primarySport
        self.preferredSports = [primarySport]
        self.hasPoolAccess = false
        self.hasBikeAccess = false
        self.preferredPoolLength = 25
        self.sportSpecificData = [:]
    }
    
    // MARK: - User Type Helpers
    var isIndividualUser: Bool {
        return tenantId == nil || (tenantId != nil && gymMembershipId == nil)
    }
    
    var isGymMember: Bool {
        return tenantId != nil && gymMembershipId != nil
    }
    
    var belongsToGym: Bool {
        return tenantId != nil && role != .owner && role != .admin
    }
    
    var canManageSubscription: Bool {
        return isIndividualUser // Solo usuarios individuales gestionan sus suscripciones
    }
}

// MARK: - Supporting Enums
enum FitnessLevel: String, CaseIterable, Codable {
    case beginner = "principiante"
    case intermediate = "intermedio"
    case advanced = "avanzado"
    case expert = "experto"
    
    var description: String {
        switch self {
        case .beginner:
            return "Principiante - Pocas veces por semana o recién empiezo"
        case .intermediate:
            return "Intermedio - 2-3 veces por semana regularmente"
        case .advanced:
            return "Avanzado - 4-5 veces por semana, tengo experiencia"
        case .expert:
            return "Experto - Entreno diariamente, compito regularmente"
        }
    }
}

enum RaceType: String, CaseIterable, Codable {
    // Running races
    case fiveK = "5K"
    case tenK = "10K"
    case halfMarathon = "media_maraton"
    case marathon = "maraton"
    case ultraMarathon = "ultra_maraton"
    
    // Triathlon races
    case sprintTriathlon = "sprint_triathlon"
    case olympicTriathlon = "olympic_triathlon"
    case halfIronman = "half_ironman"
    case ironman = "ironman"
    
    var displayName: String {
        switch self {
        case .fiveK:
            return "5K"
        case .tenK:
            return "10K"
        case .halfMarathon:
            return "Media Maratón (21K)"
        case .marathon:
            return "Maratón (42K)"
        case .ultraMarathon:
            return "Ultra Maratón (50K+)"
        case .sprintTriathlon:
            return "Triatlón Sprint"
        case .olympicTriathlon:
            return "Triatlón Olímpico"
        case .halfIronman:
            return "Half Ironman 70.3"
        case .ironman:
            return "Ironman 140.6"
        }
    }
    
    var distance: Double {
        switch self {
        case .fiveK:
            return 5.0
        case .tenK:
            return 10.0
        case .halfMarathon:
            return 21.1
        case .marathon:
            return 42.2
        case .ultraMarathon:
            return 50.0
        case .sprintTriathlon:
            return 0.75 + 20 + 5 // 750m swim + 20km bike + 5km run
        case .olympicTriathlon:
            return 1.5 + 40 + 10 // 1.5km swim + 40km bike + 10km run
        case .halfIronman:
            return 1.9 + 90 + 21.1 // 1.9km swim + 90km bike + 21.1km run
        case .ironman:
            return 3.8 + 180 + 42.2 // 3.8km swim + 180km bike + 42.2km run
        }
    }
    
    var sport: SportType {
        switch self {
        case .fiveK, .tenK, .halfMarathon, .marathon, .ultraMarathon:
            return .running
        case .sprintTriathlon, .olympicTriathlon, .halfIronman, .ironman:
            return .triathlon
        }
    }
    
    var emoji: String {
        switch self {
        case .fiveK:
            return "🏃‍♂️"
        case .tenK:
            return "🏃‍♀️"
        case .halfMarathon:
            return "🏃"
        case .marathon:
            return "🏃‍♂️💪"
        case .ultraMarathon:
            return "🏃‍♂️🔥"
        case .sprintTriathlon:
            return "🏊‍♂️🚴‍♂️🏃‍♂️"
        case .olympicTriathlon:
            return "🏊‍♂️🚴‍♂️🏃‍♂️🥇"
        case .halfIronman:
            return "🏊‍♂️🚴‍♂️🏃‍♂️💪"
        case .ironman:
            return "🏊‍♂️🚴‍♂️🏃‍♂️🔥"
        }
    }
}

// MARK: - User Roles
enum UserRole: String, CaseIterable, Codable {
    case member = "member"
    case trainer = "trainer"
    case manager = "manager"
    case admin = "admin"
    case owner = "owner"
    
    var displayName: String {
        switch self {
        case .member:
            return "Miembro"
        case .trainer:
            return "Entrenador"
        case .manager:
            return "Gerente"
        case .admin:
            return "Administrador"
        case .owner:
            return "Propietario"
        }
    }
    
    var permissions: [Permission] {
        switch self {
        case .member:
            return [.viewOwnData, .editOwnProfile, .joinClasses]
        case .trainer:
            return Permission.memberPermissions + [.viewMemberData, .createWorkouts, .manageClasses]
        case .manager:
            return Permission.trainerPermissions + [.viewAnalytics, .manageMemberships, .viewReports]
        case .admin:
            return Permission.managerPermissions + [.manageUsers, .configureGym, .manageIntegrations]
        case .owner:
            return Permission.allPermissions
        }
    }
}

enum Permission: String, CaseIterable, Codable {
    // Member permissions
    case viewOwnData = "view_own_data"
    case editOwnProfile = "edit_own_profile"
    case joinClasses = "join_classes"
    
    // Trainer permissions
    case viewMemberData = "view_member_data"
    case createWorkouts = "create_workouts"
    case manageClasses = "manage_classes"
    
    // Manager permissions
    case viewAnalytics = "view_analytics"
    case manageMemberships = "manage_memberships"
    case viewReports = "view_reports"
    
    // Admin permissions
    case manageUsers = "manage_users"
    case configureGym = "configure_gym"
    case manageIntegrations = "manage_integrations"
    
    // Owner permissions (all)
    case manageBilling = "manage_billing"
    case deleteGym = "delete_gym"
    
    static var memberPermissions: [Permission] {
        return [.viewOwnData, .editOwnProfile, .joinClasses]
    }
    
    static var trainerPermissions: [Permission] {
        return memberPermissions + [.viewMemberData, .createWorkouts, .manageClasses]
    }
    
    static var managerPermissions: [Permission] {
        return trainerPermissions + [.viewAnalytics, .manageMemberships, .viewReports]
    }
    
    static var adminPermissions: [Permission] {
        return managerPermissions + [.manageUsers, .configureGym, .manageIntegrations]
    }
    
    static var allPermissions: [Permission] {
        return adminPermissions + [.manageBilling, .deleteGym]
    }
}

// MARK: - Subscription Models
enum SubscriptionType: String, CaseIterable, Codable {
    case free = "free"
    case basic = "basic"
    case premium = "premium"
    case pro = "pro"
    
    var displayName: String {
        switch self {
        case .free:
            return "Gratuito"
        case .basic:
            return "Básico"
        case .premium:
            return "Premium"
        case .pro:
            return "Pro"
        }
    }
    
    var monthlyPrice: Double {
        switch self {
        case .free:
            return 0.0
        case .basic:
            return 4.99
        case .premium:
            return 9.99
        case .pro:
            return 19.99
        }
    }
    
    var yearlyPrice: Double {
        return monthlyPrice * 10 // 2 meses gratis
    }
    
    var appleProductId: String {
        switch self {
        case .free:
            return ""
        case .basic:
            return "com.runai.basic.monthly"
        case .premium:
            return "com.runai.premium.monthly"
        case .pro:
            return "com.runai.pro.monthly"
        }
    }
    
    var appleYearlyProductId: String {
        switch self {
        case .free:
            return ""
        case .basic:
            return "com.runai.basic.yearly"
        case .premium:
            return "com.runai.premium.yearly"
        case .pro:
            return "com.runai.pro.yearly"
        }
    }
    
    var features: [SubscriptionFeature] {
        switch self {
        case .free:
            return [.basicWorkoutTracking, .limitedAICoaching]
        case .basic:
            return [.basicWorkoutTracking, .unlimitedAICoaching, .basicAnalytics, .workoutPlans]
        case .premium:
            return SubscriptionFeature.basicFeatures + [.advancedAnalytics, .personalizedPlans, .nutritionTracking, .socialFeatures]
        case .pro:
            return SubscriptionFeature.premiumFeatures + [.prioritySupport, .advancedIntegrations, .customWorkouts, .exportData]
        }
    }
    
    var maxWorkoutsPerMonth: Int {
        switch self {
        case .free:
            return 10
        case .basic:
            return 50
        case .premium, .pro:
            return Int.max
        }
    }
    
    var maxAIQueriesPerMonth: Int {
        switch self {
        case .free:
            return 5
        case .basic:
            return 50
        case .premium:
            return 200
        case .pro:
            return Int.max
        }
    }
}

enum SubscriptionStatus: String, CaseIterable, Codable {
    case active = "active"
    case inactive = "inactive"
    case expired = "expired"
    case cancelled = "cancelled"
    case pendingRenewal = "pending_renewal"
    case inGracePeriod = "in_grace_period"
    
    var displayName: String {
        switch self {
        case .active:
            return "Activa"
        case .inactive:
            return "Inactiva"
        case .expired:
            return "Expirada"
        case .cancelled:
            return "Cancelada"
        case .pendingRenewal:
            return "Pendiente de Renovación"
        case .inGracePeriod:
            return "Período de Gracia"
        }
    }
    
    var isValid: Bool {
        return self == .active || self == .pendingRenewal || self == .inGracePeriod
    }
}

enum SubscriptionFeature: String, CaseIterable, Codable {
    // Free features
    case basicWorkoutTracking = "basic_workout_tracking"
    case limitedAICoaching = "limited_ai_coaching"
    
    // Basic features
    case unlimitedAICoaching = "unlimited_ai_coaching"
    case basicAnalytics = "basic_analytics"
    case workoutPlans = "workout_plans"
    
    // Premium features
    case advancedAnalytics = "advanced_analytics"
    case personalizedPlans = "personalized_plans"
    case nutritionTracking = "nutrition_tracking"
    case socialFeatures = "social_features"
    
    // Pro features
    case prioritySupport = "priority_support"
    case advancedIntegrations = "advanced_integrations"
    case customWorkouts = "custom_workouts"
    case exportData = "export_data"
    
    var displayName: String {
        switch self {
        case .basicWorkoutTracking:
            return "Seguimiento Básico de Entrenamientos"
        case .limitedAICoaching:
            return "Entrenador IA (Limitado)"
        case .unlimitedAICoaching:
            return "Entrenador IA Ilimitado"
        case .basicAnalytics:
            return "Análisis Básico"
        case .workoutPlans:
            return "Planes de Entrenamiento"
        case .advancedAnalytics:
            return "Análisis Avanzado"
        case .personalizedPlans:
            return "Planes Personalizados"
        case .nutritionTracking:
            return "Seguimiento Nutricional"
        case .socialFeatures:
            return "Funciones Sociales"
        case .prioritySupport:
            return "Soporte Prioritario"
        case .advancedIntegrations:
            return "Integraciones Avanzadas"
        case .customWorkouts:
            return "Entrenamientos Personalizados"
        case .exportData:
            return "Exportación de Datos"
        }
    }
    
    static var basicFeatures: [SubscriptionFeature] {
        return [.basicWorkoutTracking, .unlimitedAICoaching, .basicAnalytics, .workoutPlans]
    }
    
    static var premiumFeatures: [SubscriptionFeature] {
        return basicFeatures + [.advancedAnalytics, .personalizedPlans, .nutritionTracking, .socialFeatures]
    }
    
    static var proFeatures: [SubscriptionFeature] {
        return premiumFeatures + [.prioritySupport, .advancedIntegrations, .customWorkouts, .exportData]
    }
}

enum SwimmingLevel: String, CaseIterable, Codable {
    case beginner = "beginner"
    case intermediate = "intermediate"
    case advanced = "advanced"
    case competitive = "competitive"
    
    var displayName: String {
        switch self {
        case .beginner:
            return "Principiante"
        case .intermediate:
            return "Intermedio"
        case .advanced:
            return "Avanzado"
        case .competitive:
            return "Competitivo"
        }
    }
    
    var description: String {
        switch self {
        case .beginner:
            return "Puedo nadar 200-500m sin parar"
        case .intermediate:
            return "Puedo nadar 1000-2000m sin parar"
        case .advanced:
            return "Puedo nadar más de 2000m sin parar"
        case .competitive:
            return "Compito regularmente en natación"
        }
    }
}

enum CyclingLevel: String, CaseIterable, Codable {
    case beginner = "beginner"
    case intermediate = "intermediate"
    case advanced = "advanced"
    case competitive = "competitive"
    
    var displayName: String {
        switch self {
        case .beginner:
            return "Principiante"
        case .intermediate:
            return "Intermedio"
        case .advanced:
            return "Avanzado"
        case .competitive:
            return "Competitivo"
        }
    }
    
    var description: String {
        switch self {
        case .beginner:
            return "Puedo pedalear 10-20km cómodamente"
        case .intermediate:
            return "Puedo pedalear 40-60km sin problemas"
        case .advanced:
            return "Puedo pedalear más de 80km"
        case .competitive:
            return "Compito regularmente en ciclismo"
        }
    }
}

// MARK: - Sport Performance Data
struct SportPerformanceData: Codable, Equatable {
    // Running specific
    var current5kTime: TimeInterval?
    var current10kTime: TimeInterval?
    var currentHalfMarathonTime: TimeInterval?
    var currentMarathonTime: TimeInterval?
    var weeklyRunningKm: Double?
    var longestRun: Double?
    
    // Swimming specific
    var current100mFreeTime: TimeInterval?
    var current400mFreeTime: TimeInterval?
    var current1500mFreeTime: TimeInterval?
    var weeklySwimmingKm: Double?
    var longestSwim: Double?
    var favoriteStroke: String?
    
    // Cycling specific
    var current20kmTime: TimeInterval?
    var current40kmTime: TimeInterval?
    var ftp: Int? // Functional Threshold Power
    var weeklyCyclingKm: Double?
    var longestRide: Double?
    var bikeType: String? // Road, Mountain, TT, etc.
    
    // Triathlon specific
    var currentSprintTriTime: TimeInterval?
    var currentOlympicTriTime: TimeInterval?
    var currentHalfIronmanTime: TimeInterval?
    var currentIronmanTime: TimeInterval?
    
    // Goals by sport
    var raceGoals: [RaceGoal]
    
    init() {
        self.raceGoals = []
    }
}

// MARK: - Race Goal
struct RaceGoal: Codable, Equatable, Identifiable {
    let id: UUID
    let sport: SportType
    let raceType: RaceType
    let targetTime: TimeInterval?
    let raceDate: Date?
    let priority: GoalPriority
    let notes: String?
    
    init(sport: SportType, raceType: RaceType, targetTime: TimeInterval? = nil, raceDate: Date? = nil, priority: GoalPriority = .medium, notes: String? = nil) {
        self.id = UUID()
        self.sport = sport
        self.raceType = raceType
        self.targetTime = targetTime
        self.raceDate = raceDate
        self.priority = priority
        self.notes = notes
    }
}

enum GoalPriority: String, CaseIterable, Codable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    
    var displayName: String {
        switch self {
        case .low:
            return "Baja"
        case .medium:
            return "Media"
        case .high:
            return "Alta"
        }
    }
    
    var color: String {
        switch self {
        case .low:
            return "gray"
        case .medium:
            return "blue"
        case .high:
            return "red"
        }
    }
}

