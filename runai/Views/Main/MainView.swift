//
//  MainView.swift
//  runai
//
//  Created by David Barreiro on 11/09/25.
//

import SwiftUI

enum ViewMode: String, CaseIterable {
    case daily = "Día"
    case weekly = "Semana"
    
    var icon: String {
        switch self {
        case .daily:
            return "calendar"
        case .weekly:
            return "calendar.badge.plus"
        }
    }
}

struct MainView: View {
    @ObservedObject var dataManager = DataManager.shared
    @State private var selectedDate = Date()
    @State private var viewMode: ViewMode = .daily
    @State private var selectedSportFilter: SportType? = nil
    @State private var showingAddWorkout = false
    @State private var showingChat = false
    @State private var showingProfile = false
    @State private var showingTrainingPlanGenerator = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with user info
                HeaderView(showingProfile: $showingProfile)
                
                // View mode selector
                ViewModeSelector(selectedMode: $viewMode)
                
                // Date selector
                DateSelectorView(selectedDate: $selectedDate, viewMode: viewMode)
                
                // Sport filter
                if let user = dataManager.currentUser, user.preferredSports.count > 1 {
                    SportFilterView(selectedSport: $selectedSportFilter, userSports: user.preferredSports)
                }
                
                // Content based on view mode
                ScrollView {
                    if viewMode == .daily {
                        DailyView(selectedDate: selectedDate, sportFilter: selectedSportFilter)
                    } else {
                        WeeklyView(selectedDate: selectedDate, sportFilter: selectedSportFilter)
                    }
                }
                .onAppear {
                    // Check for overdue workouts when view appears
                    dataManager.checkAndUpdateOverdueWorkouts()
                }
                .onReceive(Timer.publish(every: 3600, on: .main, in: .common).autoconnect()) { _ in
                    // Check for overdue workouts every hour
                    dataManager.checkAndUpdateOverdueWorkouts()
                }
                .refreshable {
                    // Refresh data if needed
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingAddWorkout) {
                AddWorkoutView(selectedDate: selectedDate)
            }
            .sheet(isPresented: $showingChat) {
                ChatView()
            }
            .sheet(isPresented: $showingProfile) {
                ProfileView()
            }
            .sheet(isPresented: $showingTrainingPlanGenerator) {
                TrainingPlanGeneratorView()
            }
        }
        .overlay(
            // Floating action buttons
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    VStack(spacing: 16) {
                        // Chat button
                        Button(action: {
                            showingChat = true
                        }) {
                            Image(systemName: "message.fill")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(width: 48, height: 48)
                                .background(
                                    Circle()
                                        .fill(Color.green)
                                        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                                )
                        }
                        
                        // AI Training Plan Generator button
                        Button(action: {
                            showingTrainingPlanGenerator = true
                        }) {
                            Image(systemName: "brain.head.profile")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(width: 48, height: 48)
                                .background(
                                    Circle()
                                        .fill(Color.purple)
                                        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                                )
                        }
                        
                        // Add workout button
                        Button(action: {
                            showingAddWorkout = true
                        }) {
                            Image(systemName: "plus")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(width: 56, height: 56)
                                .background(
                                    Circle()
                                        .fill(Color.blue)
                                        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                                )
                        }
                    }
                    .padding(.trailing, 24)
                    .padding(.bottom, 24)
                }
            }
        )
    }
}

struct HeaderView: View {
    @ObservedObject var dataManager = DataManager.shared
    @Binding var showingProfile: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Hola, \(dataManager.currentUser?.name ?? "Runner")")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("¡Hora de entrenar!")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: {
                showingProfile = true
            }) {
                Image(systemName: "person.circle")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
    }
}

struct ViewModeSelector: View {
    @Binding var selectedMode: ViewMode
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(ViewMode.allCases, id: \.self) { mode in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedMode = mode
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: mode.icon)
                        Text(mode.rawValue)
                    }
                    .font(.body)
                    .fontWeight(selectedMode == mode ? .semibold : .regular)
                    .foregroundColor(selectedMode == mode ? .blue : .secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(selectedMode == mode ? Color.blue.opacity(0.1) : Color.clear)
                    )
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
    }
}

struct DateSelectorView: View {
    @Binding var selectedDate: Date
    let viewMode: ViewMode
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_ES")
        
        if viewMode == .daily {
            formatter.dateFormat = "EEEE, d MMMM yyyy"
        } else {
            formatter.dateFormat = "MMMM yyyy"
        }
        
        return formatter
    }
    
    var body: some View {
        HStack {
            Button(action: {
                withAnimation {
                    if viewMode == .daily {
                        selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
                    } else {
                        selectedDate = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: selectedDate) ?? selectedDate
                    }
                }
            }) {
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .foregroundColor(.blue)
            }
            
            Spacer()
            
            Text(dateFormatter.string(from: selectedDate).capitalized)
                .font(.headline)
                .fontWeight(.medium)
            
            Spacer()
            
            Button(action: {
                withAnimation {
                    if viewMode == .daily {
                        selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
                    } else {
                        selectedDate = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: selectedDate) ?? selectedDate
                    }
                }
            }) {
                Image(systemName: "chevron.right")
                    .font(.title3)
                    .foregroundColor(.blue)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }
}

// MARK: - Sport Filter View
struct SportFilterView: View {
    @Binding var selectedSport: SportType?
    let userSports: [SportType]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // All sports option
                Button(action: {
                    selectedSport = nil
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "list.bullet")
                            .font(.caption)
                        Text("Todos")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(selectedSport == nil ? Color.blue : Color(.systemGray6))
                    )
                    .foregroundColor(selectedSport == nil ? .white : .primary)
                }
                
                // Individual sport filters
                ForEach(userSports, id: \.self) { sport in
                    Button(action: {
                        selectedSport = sport
                    }) {
                        HStack(spacing: 6) {
                            Text(sport.emoji)
                                .font(.caption)
                            Text(sport.displayName)
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(selectedSport == sport ? Color.blue : Color(.systemGray6))
                        )
                        .foregroundColor(selectedSport == sport ? .white : .primary)
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }
}

#Preview {
    MainView()
}
