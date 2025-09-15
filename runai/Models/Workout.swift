//
//  Workout.swift
//  runai
//
//  Created by David Barreiro on 11/09/25.
//

import Foundation

struct TriathlonSegment: Identifiable, Codable {
    let id: UUID
    let sport: SportType
    let distance: Double
    let estimatedDuration: TimeInterval
    let notes: String?
    
    init(sport: SportType, distance: Double, estimatedDuration: TimeInterval, notes: String? = nil) {
        self.id = UUID()
        self.sport = sport
        self.distance = distance
        self.estimatedDuration = estimatedDuration
        self.notes = notes
    }
    
    var formattedDistance: String {
        switch sport {
        case .swimming:
            if distance < 1 {
                return String(format: "%.0f m", distance * 1000)
            } else {
                return String(format: "%.2f km", distance)
            }
        case .cycling, .running:
            return String(format: "%.1f km", distance)
        case .triathlon:
            return "N/A"
        }
    }
    
    var formattedDuration: String {
        let hours = Int(estimatedDuration) / 3600
        let minutes = Int(estimatedDuration) % 3600 / 60
        
        if hours > 0 {
            return String(format: "%dh %dm", hours, minutes)
        } else {
            return String(format: "%dm", minutes)
        }
    }
}

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

enum SportType: String, CaseIterable, Codable {
    case running = "running"
    case swimming = "swimming"
    case cycling = "cycling"
    case triathlon = "triathlon"
    
    var displayName: String {
        switch self {
        case .running:
            return "Running"
        case .swimming:
            return "Natación"
        case .cycling:
            return "Ciclismo"
        case .triathlon:
            return "Triatlón"
        }
    }
    
    var emoji: String {
        switch self {
        case .running:
            return "🏃‍♂️"
        case .swimming:
            return "🏊‍♂️"
        case .cycling:
            return "🚴‍♂️"
        case .triathlon:
            return "🏊‍♂️🚴‍♂️🏃‍♂️"
        }
    }
    
    var color: String {
        switch self {
        case .running:
            return "blue"
        case .swimming:
            return "cyan"
        case .cycling:
            return "orange"
        case .triathlon:
            return "purple"
        }
    }
}

enum WorkoutType: String, CaseIterable, Codable {
    // Running
    case longRun = "Long Run"
    case series = "Series"
    case tempoRun = "Tempo Run"
    case intervalRun = "Interval Run"
    case recoveryRun = "Recovery Run"
    
    // Swimming
    case enduranceSwim = "Endurance Swim"
    case sprintSwim = "Sprint Swim"
    case techniqueSwim = "Technique Swim"
    case intervalSwim = "Interval Swim"
    
    // Cycling
    case enduranceCycle = "Endurance Cycle"
    case intervalCycle = "Interval Cycle"
    case hillCycle = "Hill Cycle"
    case recoveryCycle = "Recovery Cycle"
    
    // Triathlon
    case brickWorkout = "Brick Workout"
    case triathlonRace = "Triathlon Race"
    case transitionPractice = "Transition Practice"
    
    var displayName: String {
        switch self {
        // Running
        case .longRun:
            return "Carrera Larga"
        case .series:
            return "Series"
        case .tempoRun:
            return "Tempo"
        case .intervalRun:
            return "Intervalos"
        case .recoveryRun:
            return "Recuperación"
        // Swimming
        case .enduranceSwim:
            return "Resistencia Natación"
        case .sprintSwim:
            return "Sprint Natación"
        case .techniqueSwim:
            return "Técnica Natación"
        case .intervalSwim:
            return "Intervalos Natación"
        // Cycling
        case .enduranceCycle:
            return "Resistencia Ciclismo"
        case .intervalCycle:
            return "Intervalos Ciclismo"
        case .hillCycle:
            return "Subidas Ciclismo"
        case .recoveryCycle:
            return "Recuperación Ciclismo"
        // Triathlon
        case .brickWorkout:
            return "Entrenamiento Brick"
        case .triathlonRace:
            return "Carrera Triatlón"
        case .transitionPractice:
            return "Práctica Transiciones"
        }
    }
    
    var emoji: String {
        switch self {
        // Running
        case .longRun:
            return "🏃‍♂️"
        case .series:
            return "⚡"
        case .tempoRun:
            return "🔥"
        case .intervalRun:
            return "⏱️"
        case .recoveryRun:
            return "😌"
        // Swimming
        case .enduranceSwim:
            return "🏊‍♂️"
        case .sprintSwim:
            return "💨"
        case .techniqueSwim:
            return "🎯"
        case .intervalSwim:
            return "⏱️"
        // Cycling
        case .enduranceCycle:
            return "🚴‍♂️"
        case .intervalCycle:
            return "⚡"
        case .hillCycle:
            return "⛰️"
        case .recoveryCycle:
            return "😌"
        // Triathlon
        case .brickWorkout:
            return "🧱"
        case .triathlonRace:
            return "🏆"
        case .transitionPractice:
            return "🔄"
        }
    }
    
    var sport: SportType {
        switch self {
        case .longRun, .series, .tempoRun, .intervalRun, .recoveryRun:
            return .running
        case .enduranceSwim, .sprintSwim, .techniqueSwim, .intervalSwim:
            return .swimming
        case .enduranceCycle, .intervalCycle, .hillCycle, .recoveryCycle:
            return .cycling
        case .brickWorkout, .triathlonRace, .transitionPractice:
            return .triathlon
        }
    }
    
    static func typesFor(sport: SportType) -> [WorkoutType] {
        return WorkoutType.allCases.filter { $0.sport == sport }
    }
}

struct Workout: Identifiable, Codable {
    let id: UUID
    let date: Date
    let type: WorkoutType
    let notes: String?
    var status: WorkoutStatus
    
    // Sport-specific metrics
    let distance: Double? // km for running/cycling, meters for swimming
    let duration: TimeInterval? // minutes
    let intensity: String? // Easy, Moderate, Hard, Race
    
    // Swimming specific
    let poolLength: Int? // 25m or 50m
    let strokeType: String? // Freestyle, Backstroke, etc.
    
    // Cycling specific
    let elevation: Double? // meters
    let avgPower: Int? // watts
    
    // Triathlon specific
    let segments: [TriathlonSegment]?
    
    init(date: Date, type: WorkoutType, distance: Double? = nil, duration: TimeInterval? = nil, intensity: String? = nil, notes: String? = nil, status: WorkoutStatus = .pending, poolLength: Int? = nil, strokeType: String? = nil, elevation: Double? = nil, avgPower: Int? = nil, segments: [TriathlonSegment]? = nil) {
        self.id = UUID()
        self.date = date
        self.type = type
        self.distance = distance
        self.duration = duration
        self.intensity = intensity
        self.notes = notes
        self.status = status
        self.poolLength = poolLength
        self.strokeType = strokeType
        self.elevation = elevation
        self.avgPower = avgPower
        self.segments = segments
    }
    
    // Legacy support for kilometers
    var kilometers: Double {
        return distance ?? 0.0
    }
    
    var sport: SportType {
        return type.sport
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "es_ES")
        return formatter.string(from: date)
    }
    
    var formattedDistance: String {
        guard let distance = distance else { return "N/A" }
        
        switch sport {
        case .swimming:
            if distance < 1 {
                return String(format: "%.0f m", distance * 1000)
            } else {
                return String(format: "%.2f km", distance)
            }
        case .running, .cycling:
            return String(format: "%.1f km", distance)
        case .triathlon:
            return "Triatlón"
        }
    }
    
    var formattedDuration: String {
        guard let duration = duration else { return "N/A" }
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        
        if hours > 0 {
            return String(format: "%dh %dm", hours, minutes)
        } else {
            return String(format: "%dm", minutes)
        }
    }
    
    // Legacy support
    var formattedKilometers: String {
        return formattedDistance
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
