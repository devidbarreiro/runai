//
//  WeeklyView.swift
//  runai
//
//  Created by David Barreiro on 11/09/25.
//

import SwiftUI

struct WeeklyView: View {
    let selectedDate: Date
    let sportFilter: SportType?
    @ObservedObject var dataManager = DataManager.shared
    
    private var workoutsForWeek: [Workout] {
        let allWorkouts = dataManager.getWorkoutsForWeek(containing: selectedDate)
        if let filter = sportFilter {
            return allWorkouts.filter { $0.sport == filter }
        }
        return allWorkouts
    }
    
    private var weekDays: [Date] {
        let calendar = Calendar.current
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: selectedDate) else {
            return []
        }
        
        var days: [Date] = []
        var currentDate = weekInterval.start
        
        for _ in 0..<7 {
            days.append(currentDate)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        return days
    }
    
    private var totalWeeklyKilometers: Double {
        workoutsForWeek.filter { $0.status == .completed }.reduce(0) { $0 + $1.kilometers }
    }
    
    private var totalWeeklyWorkouts: Int {
        workoutsForWeek.count
    }
    
    private var completedWorkouts: Int {
        workoutsForWeek.filter { $0.status == .completed }.count
    }
    
    private var missedWorkouts: Int {
        workoutsForWeek.filter { $0.status == .missed }.count
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Weekly summary
            WeeklySummaryCard(
                totalKilometers: totalWeeklyKilometers,
                workoutCount: totalWeeklyWorkouts,
                completedWorkouts: completedWorkouts,
                missedWorkouts: missedWorkouts,
                activeDays: Set(workoutsForWeek.filter { $0.status == .completed }.map { Calendar.current.startOfDay(for: $0.date) }).count
            )
            
            // Week grid
            WeekGridView(
                weekDays: weekDays,
                workouts: workoutsForWeek
            )
            
            // Workouts list for the week
            if !workoutsForWeek.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Entrenamientos de la semana")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    LazyVStack(spacing: 8) {
                        ForEach(workoutsForWeek.sorted(by: { $0.date > $1.date })) { workout in
                            WeeklyWorkoutRow(workout: workout)
                        }
                    }
                }
            } else {
                EmptyStateView(
                    icon: "calendar",
                    title: "Sin entrenamientos esta semana",
                    subtitle: "Comienza a registrar tus entrenamientos para ver tu progreso semanal"
                )
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }
}

struct WeeklySummaryCard: View {
    let totalKilometers: Double
    let workoutCount: Int
    let completedWorkouts: Int
    let missedWorkouts: Int
    let activeDays: Int
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total semanal")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("\(String(format: "%.1f", totalKilometers)) km")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Días activos")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("\(activeDays)/7")
                        .font(.title2)
                        .fontWeight(.semibold)
                }
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Completados")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Text("✅ \(completedWorkouts)")
                            .font(.title3)
                            .fontWeight(.medium)
                            .foregroundColor(.green)
                        
                        Text("❌ \(missedWorkouts)")
                            .font(.title3)
                            .fontWeight(.medium)
                            .foregroundColor(.red)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Promedio/día")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("\(String(format: "%.1f", totalKilometers / 7)) km")
                        .font(.title3)
                        .fontWeight(.medium)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
        )
    }
}

struct WeekGridView: View {
    let weekDays: [Date]
    let workouts: [Workout]
    
    private let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        formatter.locale = Locale(identifier: "es_ES")
        return formatter
    }()
    
    private let dayNumberFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter
    }()
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Vista semanal")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(weekDays, id: \.self) { day in
                    WeekDayCell(
                        day: day,
                        dayName: dayFormatter.string(from: day).capitalized,
                        dayNumber: dayNumberFormatter.string(from: day),
                        workouts: workoutsForDay(day)
                    )
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
        )
    }
    
    private func workoutsForDay(_ day: Date) -> [Workout] {
        let calendar = Calendar.current
        return workouts.filter { calendar.isDate($0.date, inSameDayAs: day) }
    }
}

struct WeekDayCell: View {
    let day: Date
    let dayName: String
    let dayNumber: String
    let workouts: [Workout]
    
    private var totalKilometers: Double {
        workouts.filter { $0.status == .completed }.reduce(0) { $0 + $1.kilometers }
    }
    
    private var hasCompletedWorkouts: Bool {
        workouts.contains { $0.status == .completed }
    }
    
    private var hasPendingWorkouts: Bool {
        workouts.contains { $0.status == .pending }
    }
    
    private var hasMissedWorkouts: Bool {
        workouts.contains { $0.status == .missed }
    }
    
    private var isToday: Bool {
        Calendar.current.isDateInToday(day)
    }
    
    var body: some View {
        VStack(spacing: 8) {
            Text(dayName)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(dayNumber)
                .font(.body)
                .fontWeight(isToday ? .bold : .medium)
                .foregroundColor(isToday ? .blue : .primary)
            
            if !workouts.isEmpty {
                VStack(spacing: 2) {
                    if totalKilometers > 0 {
                        Text("\(String(format: "%.1f", totalKilometers))km")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(.green)
                    }
                    
                    HStack(spacing: 2) {
                        if hasCompletedWorkouts {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 4, height: 4)
                        }
                        if hasPendingWorkouts {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 4, height: 4)
                        }
                        if hasMissedWorkouts {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 4, height: 4)
                        }
                    }
                }
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 4, height: 4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isToday ? Color.blue.opacity(0.1) : Color.clear)
        )
    }
}

struct WeeklyWorkoutRow: View {
    let workout: Workout
    
    private let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        formatter.locale = Locale(identifier: "es_ES")
        return formatter
    }()
    
    private var statusColor: Color {
        switch workout.status {
        case .pending:
            return .blue
        case .completed:
            return .green
        case .missed:
            return .red
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Status indicator
            Text(workout.status.emoji)
                .font(.body)
            
            Text(workout.type.emoji)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(workout.formattedKilometers)
                        .font(.body)
                        .fontWeight(.medium)
                    
                    Text("• \(workout.type.displayName)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(dayFormatter.string(from: workout.date).capitalized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text(workout.status.displayName)
                        .font(.caption2)
                        .foregroundColor(statusColor)
                        .fontWeight(.medium)
                    
                    if let notes = workout.notes, !notes.isEmpty {
                        Text("• \(notes)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray6))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(statusColor.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

#Preview {
    WeeklyView(selectedDate: Date(), sportFilter: nil)
}
