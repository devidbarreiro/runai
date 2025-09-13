//
//  User.swift
//  runai
//
//  Created by David Barreiro on 11/09/25.
//

import Foundation

struct User: Codable {
    let id: UUID
    let username: String
    let email: String
    let name: String
    let hasCompletedOnboarding: Bool
    let isFirstTimeUser: Bool
    let createdAt: Date
    
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
    
    init(username: String, email: String, name: String, hasCompletedOnboarding: Bool = false, isFirstTimeUser: Bool = true) {
        self.id = UUID()
        self.username = username
        self.email = email
        self.name = name
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.isFirstTimeUser = isFirstTimeUser
        self.createdAt = Date()
        self.hasAcceptedPrivacyPolicy = false
        self.hasCompletedPhysicalOnboarding = false
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
    case halfMarathon = "media_maraton"
    case marathon = "maraton"
    
    var displayName: String {
        switch self {
        case .halfMarathon:
            return "Media Maratón (21K)"
        case .marathon:
            return "Maratón (42K)"
        }
    }
    
    var distance: Double {
        switch self {
        case .halfMarathon:
            return 21.1
        case .marathon:
            return 42.2
        }
    }
}

