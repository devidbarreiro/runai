//
//  DailyView.swift
//  runai
//
//  Created by David Barreiro on 11/09/25.
//

import SwiftUI

struct DailyView: View {
    let selectedDate: Date
    @ObservedObject var dataManager = DataManager.shared
    
    private var workoutsForDay: [Workout] {
        dataManager.getWorkoutsForDate(selectedDate)
    }
    
    private var totalKilometers: Double {
        workoutsForDay.reduce(0) { $0 + $1.kilometers }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Daily summary card
            DailySummaryCard(
                totalKilometers: totalKilometers,
                workoutCount: workoutsForDay.count
            )
            
            // Workouts list
            if workoutsForDay.isEmpty {
                EmptyStateView(
                    icon: "figure.run",
                    title: "Sin entrenamientos",
                    subtitle: "No hay entrenamientos registrados para este día"
                )
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(workoutsForDay.sorted(by: { $0.date > $1.date })) { workout in
                        WorkoutCard(workout: workout)
                    }
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }
}

struct DailySummaryCard: View {
    let totalKilometers: Double
    let workoutCount: Int
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total del día")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("\(String(format: "%.1f", totalKilometers)) km")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Entrenamientos")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("\(workoutCount)")
                        .font(.title2)
                        .fontWeight(.semibold)
                }
            }
            
            if workoutCount > 0 {
                Divider()
                
                HStack {
                    Image(systemName: "trophy.fill")
                        .foregroundColor(.orange)
                    
                    Text("¡Buen trabajo hoy!")
                        .font(.body)
                        .foregroundColor(.primary)
                    
                    Spacer()
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

struct WorkoutCard: View {
    let workout: Workout
    @ObservedObject var dataManager = DataManager.shared
    @State private var showingDeleteAlert = false
    @State private var dragOffset = CGSize.zero
    @State private var showingStatusActions = false
    
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
    
    private var backgroundColorForStatus: Color {
        switch workout.status {
        case .pending:
            return Color(.systemBackground)
        case .completed:
            return Color.green.opacity(0.1)
        case .missed:
            return Color.red.opacity(0.1)
        }
    }
    
    @ViewBuilder
    private var statusOverlay: some View {
        if workout.status != .pending {
            HStack(spacing: 4) {
                Text(workout.status.emoji)
                    .font(.caption)
                Text(workout.status.displayName)
                    .font(.caption2)
                    .fontWeight(.semibold)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(statusColor)
            )
            .foregroundColor(.white)
            .padding(8)
        }
    }
    
    var body: some View {
        ZStack {
            // Background actions
            HStack {
                // Left action (Mark as missed)
                if workout.status != .missed {
                    Button(action: {
                        dataManager.markWorkoutAsMissed(workout.id)
                        withAnimation(.spring()) {
                            dragOffset = .zero
                        }
                    }) {
                        VStack {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                            Text("No hecho")
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                        .frame(width: 80)
                        .frame(maxHeight: .infinity)
                        .background(Color.red)
                    }
                }
                
                Spacer()
                
                // Right action (Mark as completed)
                if workout.status != .completed {
                    Button(action: {
                        dataManager.markWorkoutAsCompleted(workout.id)
                        withAnimation(.spring()) {
                            dragOffset = .zero
                        }
                    }) {
                        VStack {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                            Text("Completado")
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                        .frame(width: 80)
                        .frame(maxHeight: .infinity)
                        .background(Color.green)
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // Main card content
            HStack(spacing: 16) {
                // Workout type icon
                VStack {
                    Text(workout.type.emoji)
                        .font(.title)
                    
                    Text(workout.type.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(width: 60)
                
                // Workout details
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(workout.formattedKilometers)
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        Text(formatTime(workout.date))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if let notes = workout.notes, !notes.isEmpty {
                        Text(notes)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    
                    // Show overdue indicator
                    if workout.isOverdue && workout.status == .pending {
                        HStack {
                            Image(systemName: "clock.fill")
                                .foregroundColor(.orange)
                                .font(.caption)
                            Text("Vencido")
                                .font(.caption)
                                .foregroundColor(.orange)
                                .fontWeight(.medium)
                        }
                    }
                }
                
                // Actions menu
                Button(action: {
                    showingDeleteAlert = true
                }) {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.secondary)
                        .font(.body)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(backgroundColorForStatus)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(statusColor.opacity(0.4), lineWidth: 2)
                    )
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            )
            .overlay(
                // Status overlay
                statusOverlay,
                alignment: .topTrailing
            )
            .offset(dragOffset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        dragOffset = value.translation
                    }
                    .onEnded { value in
                        let threshold: CGFloat = 100
                        
                        if value.translation.width > threshold && workout.status != .missed {
                            // Swipe right - mark as missed (matches left side action)
                            dataManager.markWorkoutAsMissed(workout.id)
                        } else if value.translation.width < -threshold && workout.status != .completed {
                            // Swipe left - mark as completed (matches right side action)
                            dataManager.markWorkoutAsCompleted(workout.id)
                        }
                        
                        withAnimation(.spring()) {
                            dragOffset = .zero
                        }
                    }
            )
        }
        .alert("Opciones del entrenamiento", isPresented: $showingDeleteAlert) {
            Button("Cancelar", role: .cancel) { }
            
            if workout.status != .pending {
                Button("Marcar como Pendiente") {
                    dataManager.markWorkoutAsPending(workout.id)
                }
            }
            
            if workout.status != .completed {
                Button("Marcar como Completado") {
                    dataManager.markWorkoutAsCompleted(workout.id)
                }
            }
            
            if workout.status != .missed {
                Button("Marcar como No Realizado") {
                    dataManager.markWorkoutAsMissed(workout.id)
                }
            }
            
            Button("Eliminar", role: .destructive) {
                dataManager.deleteWorkout(workout)
            }
        } message: {
            Text("Selecciona una opción para este entrenamiento")
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.medium)
                
                Text(subtitle)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(40)
    }
}

#Preview {
    DailyView(selectedDate: Date())
}
