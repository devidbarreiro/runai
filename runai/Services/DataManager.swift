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
    
    @Published var currentUser: User?
    @Published var workouts: [Workout] = []
    @Published var isLoggedIn: Bool = false
    
    private let userDefaultsKey = AppConstants.StorageKeys.user
    private let workoutsKey = AppConstants.StorageKeys.workouts
    private let registeredUsersKey = AppConstants.StorageKeys.registeredUsers
    
    private init() {
        loadUser()
        loadWorkouts()
        checkAndUpdateOverdueWorkouts()
    }
    
    // MARK: - User Management
    func registerUser(username: String, email: String, name: String) -> Bool {
        print("DEBUG DataManager: registerUser called with username: \(username), email: \(email), name: \(name)")
        
        // Check if username already exists
        if isUsernameExists(username) {
            print("DEBUG DataManager: Username \(username) already exists")
            return false
        }
        
        print("DEBUG DataManager: Username is available, creating user")
        
        // Create user
        let user = User(username: username, email: email, name: name)
        
        print("DEBUG DataManager: User created")
        
        // Save user to registered users list
        addToRegisteredUsers(user)
        print("DEBUG DataManager: User added to registered users")
        
        // Login the user
        currentUser = user
        isLoggedIn = true
        saveUser()
        print("DEBUG DataManager: User logged in successfully")
        
        return true
    }
    
    func login(username: String) -> Bool {
        guard let user = getRegisteredUser(username: username) else {
            return false
        }
        
        currentUser = user
        isLoggedIn = true
        saveUser()
        return true
    }
    
    func logout() {
        currentUser = nil
        isLoggedIn = false
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
    }
    
    func updateCurrentUser(_ user: User) {
        currentUser = user
        saveUser()
        
        // Also update in registered users list
        var registeredUsers = loadRegisteredUsers()
        if let index = registeredUsers.firstIndex(where: { $0.username == user.username }) {
            registeredUsers[index] = user
            saveRegisteredUsers(registeredUsers)
        }
    }
    
    func completeOnboarding() {
        guard let user = currentUser else { return }
        let updatedUser = User(username: user.username, email: user.email, name: user.name, hasCompletedOnboarding: true, isFirstTimeUser: false)
        currentUser = updatedUser
        saveUser()
        updateRegisteredUser(updatedUser)
    }
    
    func isUsernameExists(_ username: String) -> Bool {
        let registeredUsers = loadRegisteredUsers()
        return registeredUsers.contains { $0.username == username }
    }
    
    // MARK: - Workout Management
    func addWorkout(_ workout: Workout) {
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
            currentUser = user
            isLoggedIn = true
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
