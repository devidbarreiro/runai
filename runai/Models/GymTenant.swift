//
//  GymTenant.swift
//  runai
//
//  Gym-specific tenant models and configurations
//

import Foundation
import SwiftUI

// MARK: - Gym Tenant Extensions
extension Tenant {
    var gymConfig: GymConfiguration? {
        get {
            // TODO: Load gym configuration from tenant settings
            return nil
        }
        set {
            // TODO: Save gym configuration to tenant settings
        }
    }
    
    var isGym: Bool {
        return plan == .enterprise && domain != nil
    }
}

// MARK: - Gym Configuration
struct GymConfiguration: Codable {
    let gymName: String
    let address: String
    let phone: String
    let website: String?
    
    // Branding
    let primaryColor: String
    let secondaryColor: String
    let logoURL: String?
    let backgroundImageURL: String?
    
    // Operating hours
    let operatingHours: [DaySchedule]
    
    // Features enabled
    let enabledFeatures: [GymFeature]
    
    // Custom settings
    let customWelcomeMessage: String?
    let allowMemberInvites: Bool
    let requireMemberApproval: Bool
    let maxMembersPerTrainer: Int
    
    // Integration settings
    let membershipSystemIntegration: MembershipIntegration?
    let paymentSystemIntegration: PaymentIntegration?
    
    // Notifications
    let notificationSettings: GymNotificationSettings
    
    init(gymName: String, address: String, phone: String) {
        self.gymName = gymName
        self.address = address
        self.phone = phone
        self.website = nil
        self.primaryColor = "#007AFF"
        self.secondaryColor = "#5856D6"
        self.logoURL = nil
        self.backgroundImageURL = nil
        self.operatingHours = DaySchedule.defaultSchedule
        self.enabledFeatures = GymFeature.defaultFeatures
        self.customWelcomeMessage = "¡Bienvenido a \(gymName)! 💪"
        self.allowMemberInvites = true
        self.requireMemberApproval = false
        self.maxMembersPerTrainer = 50
        self.membershipSystemIntegration = nil
        self.paymentSystemIntegration = nil
        self.notificationSettings = GymNotificationSettings()
    }
}

// MARK: - Day Schedule
struct DaySchedule: Codable, Identifiable {
    let id: UUID
    let dayOfWeek: Int // 1 = Monday, 7 = Sunday
    var isOpen: Bool
    var openTime: Date
    var closeTime: Date
    
    init(dayOfWeek: Int, isOpen: Bool, openTime: Date, closeTime: Date) {
        self.id = UUID()
        self.dayOfWeek = dayOfWeek
        self.isOpen = isOpen
        self.openTime = openTime
        self.closeTime = closeTime
    }
    
    var dayName: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_ES")
        let weekdays = formatter.weekdaySymbols!
        return weekdays[dayOfWeek - 1]
    }
    
    static var defaultSchedule: [DaySchedule] {
        let calendar = Calendar.current
        let defaultOpen = calendar.date(from: DateComponents(hour: 6, minute: 0)) ?? Date()
        let defaultClose = calendar.date(from: DateComponents(hour: 23, minute: 0)) ?? Date()
        let weekendOpen = calendar.date(from: DateComponents(hour: 8, minute: 0)) ?? Date()
        let saturdayClose = calendar.date(from: DateComponents(hour: 20, minute: 0)) ?? Date()
        let sundayClose = calendar.date(from: DateComponents(hour: 18, minute: 0)) ?? Date()
        
        return [
            DaySchedule(dayOfWeek: 1, isOpen: true, openTime: defaultOpen, closeTime: defaultClose), // Lunes
            DaySchedule(dayOfWeek: 2, isOpen: true, openTime: defaultOpen, closeTime: defaultClose), // Martes
            DaySchedule(dayOfWeek: 3, isOpen: true, openTime: defaultOpen, closeTime: defaultClose), // Miércoles
            DaySchedule(dayOfWeek: 4, isOpen: true, openTime: defaultOpen, closeTime: defaultClose), // Jueves
            DaySchedule(dayOfWeek: 5, isOpen: true, openTime: defaultOpen, closeTime: defaultClose), // Viernes
            DaySchedule(dayOfWeek: 6, isOpen: true, openTime: weekendOpen, closeTime: saturdayClose), // Sábado
            DaySchedule(dayOfWeek: 7, isOpen: true, openTime: weekendOpen, closeTime: sundayClose)  // Domingo
        ]
    }
}

// MARK: - Gym Features
enum GymFeature: String, CaseIterable, Codable {
    // Basic gym features
    case memberTracking = "member_tracking"
    case groupClasses = "group_classes"
    case personalTraining = "personal_training"
    case equipmentReservation = "equipment_reservation"
    
    // Advanced features
    case memberAnalytics = "member_analytics"
    case trainerDashboard = "trainer_dashboard"
    case classScheduling = "class_scheduling"
    case memberChallenges = "member_challenges"
    
    // Premium features
    case customBranding = "custom_branding"
    case membershipIntegration = "membership_integration"
    case paymentIntegration = "payment_integration"
    case advancedReporting = "advanced_reporting"
    case mobileApp = "mobile_app"
    case apiAccess = "api_access"
    
    var displayName: String {
        switch self {
        case .memberTracking:
            return "Seguimiento de Miembros"
        case .groupClasses:
            return "Clases Grupales"
        case .personalTraining:
            return "Entrenamiento Personal"
        case .equipmentReservation:
            return "Reserva de Equipos"
        case .memberAnalytics:
            return "Análisis de Miembros"
        case .trainerDashboard:
            return "Dashboard de Entrenadores"
        case .classScheduling:
            return "Programación de Clases"
        case .memberChallenges:
            return "Desafíos de Miembros"
        case .customBranding:
            return "Marca Personalizada"
        case .membershipIntegration:
            return "Integración de Membresías"
        case .paymentIntegration:
            return "Integración de Pagos"
        case .advancedReporting:
            return "Reportes Avanzados"
        case .mobileApp:
            return "App Móvil Personalizada"
        case .apiAccess:
            return "Acceso API"
        }
    }
    
    static var defaultFeatures: [GymFeature] {
        return [.memberTracking, .groupClasses, .personalTraining, .memberAnalytics]
    }
    
    static var premiumFeatures: [GymFeature] {
        return defaultFeatures + [.trainerDashboard, .classScheduling, .memberChallenges, .customBranding]
    }
    
    static var enterpriseFeatures: [GymFeature] {
        return premiumFeatures + [.membershipIntegration, .paymentIntegration, .advancedReporting, .mobileApp, .apiAccess]
    }
}

// MARK: - Integration Models
struct MembershipIntegration: Codable {
    let systemName: String // "Glofox", "Mindbody", "ClubReady"
    let apiEndpoint: String
    let apiKey: String
    let syncFrequency: SyncFrequency
    let lastSync: Date?
    
    enum SyncFrequency: String, CaseIterable, Codable {
        case realtime = "realtime"
        case hourly = "hourly"
        case daily = "daily"
        case manual = "manual"
        
        var displayName: String {
            switch self {
            case .realtime: return "Tiempo Real"
            case .hourly: return "Cada Hora"
            case .daily: return "Diario"
            case .manual: return "Manual"
            }
        }
    }
}

struct PaymentIntegration: Codable {
    let provider: String // "Stripe", "PayPal", "Square"
    let merchantId: String
    let publicKey: String
    let webhookEndpoint: String?
}

// MARK: - Notification Settings
struct GymNotificationSettings: Codable {
    var memberWelcomeEmail: Bool
    var workoutReminders: Bool
    var classReminders: Bool
    var membershipExpiry: Bool
    var trainerNotifications: Bool
    var adminReports: Bool
    
    // Notification timing
    var workoutReminderHours: Int // Hours before workout
    var classReminderHours: Int // Hours before class
    var membershipExpiryDays: Int // Days before expiry
    
    init() {
        self.memberWelcomeEmail = true
        self.workoutReminders = true
        self.classReminders = true
        self.membershipExpiry = true
        self.trainerNotifications = true
        self.adminReports = true
        self.workoutReminderHours = 2
        self.classReminderHours = 1
        self.membershipExpiryDays = 7
    }
}

// MARK: - Gym Member Model
struct GymMember: Codable, Identifiable {
    let id: UUID
    let user: User
    let gymId: UUID
    let membershipType: MembershipType
    let joinDate: Date
    let membershipExpiry: Date?
    let isActive: Bool
    let assignedTrainer: UUID? // Trainer's user ID
    let membershipNumber: String?
    let emergencyContact: EmergencyContact?
    let medicalNotes: String?
    
    init(user: User, gymId: UUID, membershipType: MembershipType) {
        self.id = UUID()
        self.user = user
        self.gymId = gymId
        self.membershipType = membershipType
        self.joinDate = Date()
        self.membershipExpiry = membershipType.duration != nil ? 
            Calendar.current.date(byAdding: .month, value: membershipType.duration!, to: Date()) : nil
        self.isActive = true
        self.assignedTrainer = nil
        self.membershipNumber = nil
        self.emergencyContact = nil
        self.medicalNotes = nil
    }
}

struct MembershipType: Codable, Identifiable {
    let id: UUID
    let name: String
    let description: String
    let price: Double
    let duration: Int? // months, nil for unlimited
    let features: [String]
    let maxClassesPerMonth: Int?
    let personalTrainingSessions: Int?
    
    init(name: String, description: String, price: Double, duration: Int? = nil) {
        self.id = UUID()
        self.name = name
        self.description = description
        self.price = price
        self.duration = duration
        self.features = []
        self.maxClassesPerMonth = nil
        self.personalTrainingSessions = nil
    }
    
    static var defaultMemberships: [MembershipType] {
        return [
            MembershipType(name: "Básica", description: "Acceso al gimnasio", price: 29.99, duration: 1),
            MembershipType(name: "Premium", description: "Gimnasio + Clases", price: 49.99, duration: 1),
            MembershipType(name: "VIP", description: "Todo incluido + Entrenador", price: 99.99, duration: 1)
        ]
    }
}

struct EmergencyContact: Codable {
    let name: String
    let relationship: String
    let phone: String
    let email: String?
}

// MARK: - Gym Classes
struct GymClass: Codable, Identifiable {
    let id: UUID
    let name: String
    let description: String
    let instructor: UUID // Trainer's user ID
    let gymId: UUID
    let schedule: ClassSchedule
    let maxParticipants: Int
    let currentParticipants: [UUID] // Member IDs
    let equipment: [String]
    let difficulty: DifficultyLevel
    let duration: Int // minutes
    
    enum DifficultyLevel: String, CaseIterable, Codable {
        case beginner = "principiante"
        case intermediate = "intermedio"
        case advanced = "avanzado"
        
        var displayName: String {
            return rawValue.capitalized
        }
        
        var color: Color {
            switch self {
            case .beginner: return .green
            case .intermediate: return .orange
            case .advanced: return .red
            }
        }
    }
}

struct ClassSchedule: Codable {
    let dayOfWeek: Int
    let startTime: String // "18:00"
    let endTime: String // "19:00"
    let isRecurring: Bool
    let specificDate: Date? // For one-time classes
}

// MARK: - Gym Analytics
struct GymAnalytics: Codable {
    let gymId: UUID
    let period: AnalyticsPeriod
    let totalMembers: Int
    let activeMembers: Int
    let newMembersThisPeriod: Int
    let memberRetentionRate: Double
    let averageWorkoutsPerMember: Double
    let popularWorkoutTimes: [TimeSlot]
    let classAttendanceRates: [ClassAttendance]
    let revenueThisPeriod: Double
    let membershipTypeBreakdown: [MembershipTypeStats]
    
    enum AnalyticsPeriod: String, CaseIterable, Codable {
        case week = "week"
        case month = "month"
        case quarter = "quarter"
        case year = "year"
        
        var displayName: String {
            switch self {
            case .week: return "Esta Semana"
            case .month: return "Este Mes"
            case .quarter: return "Este Trimestre"
            case .year: return "Este Año"
            }
        }
    }
}

struct TimeSlot: Codable {
    let hour: Int
    let memberCount: Int
}

struct ClassAttendance: Codable {
    let className: String
    let attendanceRate: Double
    let averageParticipants: Int
}

struct MembershipTypeStats: Codable {
    let membershipType: String
    let count: Int
    let percentage: Double
    let revenue: Double
}
