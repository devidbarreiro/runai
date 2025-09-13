//
//  ContentView.swift
//  runai
//
//  Created by David Barreiro on 11/09/25.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var dataManager = DataManager.shared
    
    var body: some View {
        Group {
            if !dataManager.isLoggedIn {
                LoginView()
            } else if let user = dataManager.currentUser, user.isFirstTimeUser && !user.hasCompletedOnboarding {
                OnboardingView()
            } else if let user = dataManager.currentUser, !user.hasCompletedPhysicalOnboarding {
                PhysicalOnboardingView()
            } else {
                MainView()
            }
        }
        .animation(.easeInOut(duration: 0.5), value: dataManager.isLoggedIn)
        .animation(.easeInOut(duration: 0.5), value: dataManager.currentUser?.hasCompletedOnboarding)
        .animation(.easeInOut(duration: 0.5), value: dataManager.currentUser?.hasCompletedPhysicalOnboarding)
    }
}

#Preview {
    ContentView()
}
