//
//  DataManager.swift
//  runai
//
//  Created by David Barreiro on 11/09/25.
//

import Foundation
import SwiftUI

class DataManager: ObservableObject {
    static let shared = DataManager()
    
    @Published var workouts: [Workout] = []
    
    // Delegate to TenantManager for user management
    var currentUser: User? {
        return TenantManager.shared.currentUser
    }
    
    var isLoggedIn: Bool {
        return TenantManager.shared.isLoggedIn
    }
    
    private let userDefaultsKey = AppConstants.StorageKeys.user
    private let workoutsKey = AppConstants.StorageKeys.workouts
    private let registeredUsersKey = AppConstants.StorageKeys.registeredUsers
    
    private init() {
        loadUser()
        loadWorkouts()
        checkAndUpdateOverdueWorkouts()
    }
    
    // MARK: - User Management (Delegated to TenantManager)
    func registerUser(username: String, email: String, name: String) -> Bool {
        // This method is deprecated - use TenantManager.shared.registerUser instead
        return false
    }
    
    func login(username: String) -> Bool {
        // This method is deprecated - use TenantManager.shared.loginUser instead
        return false
    }
    
    func logout() {
        TenantManager.shared.logout()
    }
    
    func updateCurrentUser(_ user: User) {
        // Delegate to TenantManager
        TenantManager.shared.currentUser = user
        TenantManager.shared.saveCurrentSession()
    }
    
    func completeOnboarding() {
        guard let user = currentUser else { return }
        let updatedUser = User(username: user.username, email: user.email, name: user.name, hasCompletedOnboarding: true, isFirstTimeUser: false)
        TenantManager.shared.currentUser = updatedUser
        saveUser()
        updateRegisteredUser(updatedUser)
    }
    
    func completePlanSelection() {
        guard var user = currentUser else { return }
        user.hasSelectedPlan = true
        TenantManager.shared.currentUser = user
        saveUser()
        updateRegisteredUser(user)
    }
    
    func isUsernameExists(_ username: String) -> Bool {
        let registeredUsers = loadRegisteredUsers()
        return registeredUsers.contains { $0.username == username }
    }
    
    // MARK: - Workout Management
    func addWorkout(_ workout: Workout) {
        // Check if user can create more workouts
        guard SubscriptionService.shared.trackWorkoutCreated() else {
            // Show paywall for workout tracking
            NotificationCenter.default.post(name: .showPaywall, object: SubscriptionFeature.basicWorkoutTracking)
            return
        }
        
        workouts.append(workout)
        saveWorkouts()
    }
    
    func deleteWorkout(_ workout: Workout) {
        workouts.removeAll { $0.id == workout.id }
        saveWorkouts()
    }
    
    func getWorkoutsForDate(_ date: Date) -> [Workout] {
        let calendar = Calendar.current
        return workouts.filter { calendar.isDate($0.date, inSameDayAs: date) }
    }
    
    func getWorkoutsForWeek(containing date: Date) -> [Workout] {
        let calendar = Calendar.current
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: date) else {
            return []
        }
        
        return workouts.filter { workout in
            weekInterval.contains(workout.date)
        }
    }
    
    // MARK: - Workout Status Management
    func updateWorkoutStatus(_ workoutId: UUID, to status: WorkoutStatus) {
        if let index = workouts.firstIndex(where: { $0.id == workoutId }) {
            workouts[index].status = status
            saveWorkouts()
        }
    }
    
    func markWorkoutAsCompleted(_ workoutId: UUID) {
        updateWorkoutStatus(workoutId, to: .completed)
    }
    
    func markWorkoutAsMissed(_ workoutId: UUID) {
        updateWorkoutStatus(workoutId, to: .missed)
    }
    
    func markWorkoutAsPending(_ workoutId: UUID) {
        updateWorkoutStatus(workoutId, to: .pending)
    }
    
    func checkAndUpdateOverdueWorkouts() {
        var hasUpdates = false
        
        for index in workouts.indices {
            if workouts[index].shouldAutoMarkMissed {
                workouts[index].status = .missed
                hasUpdates = true
            }
        }
        
        if hasUpdates {
            saveWorkouts()
        }
    }
    
    // MARK: - Persistence
    private func saveUser() {
        if let user = currentUser,
           let encoded = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }
    
    private func loadUser() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let user = try? JSONDecoder().decode(User.self, from: data) {
            TenantManager.shared.currentUser = user
            TenantManager.shared.isLoggedIn = true
        }
    }
    
    private func saveWorkouts() {
        if let encoded = try? JSONEncoder().encode(workouts) {
            UserDefaults.standard.set(encoded, forKey: workoutsKey)
        }
    }
    
    private func loadWorkouts() {
        if let data = UserDefaults.standard.data(forKey: workoutsKey),
           let loadedWorkouts = try? JSONDecoder().decode([Workout].self, from: data) {
            workouts = loadedWorkouts
        }
    }
    
    
    // MARK: - Registered Users Management
    private func addToRegisteredUsers(_ user: User) {
        var registeredUsers = loadRegisteredUsers()
        registeredUsers.append(user)
        saveRegisteredUsers(registeredUsers)
    }
    
    private func updateRegisteredUser(_ updatedUser: User) {
        var registeredUsers = loadRegisteredUsers()
        if let index = registeredUsers.firstIndex(where: { $0.username == updatedUser.username }) {
            registeredUsers[index] = updatedUser
            saveRegisteredUsers(registeredUsers)
        }
    }
    
    private func getRegisteredUser(username: String) -> User? {
        let registeredUsers = loadRegisteredUsers()
        return registeredUsers.first { $0.username == username }
    }
    
    private func loadRegisteredUsers() -> [User] {
        guard let data = UserDefaults.standard.data(forKey: registeredUsersKey),
              let users = try? JSONDecoder().decode([User].self, from: data) else {
            return []
        }
        return users
    }
    
    private func saveRegisteredUsers(_ users: [User]) {
        if let encoded = try? JSONEncoder().encode(users) {
            UserDefaults.standard.set(encoded, forKey: registeredUsersKey)
        }
    }
}
