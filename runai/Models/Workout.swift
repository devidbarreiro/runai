//
//  Workout.swift
//  runai
//
//  Created by David Barreiro on 11/09/25.
//

import Foundation

enum WorkoutStatus: String, CaseIterable, Codable {
    case pending = "pending"
    case completed = "completed"
    case missed = "missed"
    
    var displayName: String {
        switch self {
        case .pending:
            return "Pendiente"
        case .completed:
            return "Completado"
        case .missed:
            return "No Realizado"
        }
    }
    
    var emoji: String {
        switch self {
        case .pending:
            return "⏳"
        case .completed:
            return "✅"
        case .missed:
            return "❌"
        }
    }
    
    var color: String {
        switch self {
        case .pending:
            return "blue"
        case .completed:
            return "green"
        case .missed:
            return "red"
        }
    }
}

enum WorkoutType: String, CaseIterable, Codable {
    case longRun = "Long Run"
    case series = "Series"
    
    var displayName: String {
        switch self {
        case .longRun:
            return "Carrera Larga"
        case .series:
            return "Series"
        }
    }
    
    var emoji: String {
        switch self {
        case .longRun:
            return "🏃‍♂️"
        case .series:
            return "⚡"
        }
    }
}

struct Workout: Identifiable, Codable {
    let id: UUID
    let date: Date
    let kilometers: Double
    let type: WorkoutType
    let notes: String?
    var status: WorkoutStatus
    
    init(date: Date, kilometers: Double, type: WorkoutType, notes: String? = nil, status: WorkoutStatus = .pending) {
        self.id = UUID()
        self.date = date
        self.kilometers = kilometers
        self.type = type
        self.notes = notes
        self.status = status
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "es_ES")
        return formatter.string(from: date)
    }
    
    var formattedKilometers: String {
        return String(format: "%.1f km", kilometers)
    }
    
    var isOverdue: Bool {
        return Date() > Calendar.current.startOfDay(for: date.addingTimeInterval(24 * 60 * 60)) && status == .pending
    }
    
    var shouldAutoMarkMissed: Bool {
        return isOverdue && status == .pending
    }
    
    mutating func markAsCompleted() {
        status = .completed
    }
    
    mutating func markAsMissed() {
        status = .missed
    }
    
    mutating func markAsPending() {
        status = .pending
    }
}
