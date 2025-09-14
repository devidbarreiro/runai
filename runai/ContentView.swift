//
//  ContentView.swift
//  runai
//
//  Created by David Barreiro on 11/09/25.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var tenantManager = TenantManager.shared
    
    var body: some View {
        Group {
            if let userPendingVerification = tenantManager.userPendingVerification {
                // User registered but needs email verification
                EmailVerificationView(email: userPendingVerification.email)
            } else if !tenantManager.isLoggedIn {
                // Show welcome/landing page first
                WelcomeView()
            } else if let user = tenantManager.currentUser, user.isFirstTimeUser && !user.hasCompletedOnboarding {
                OnboardingView()
            } else if let user = tenantManager.currentUser, !user.hasCompletedPhysicalOnboarding {
                PhysicalOnboardingView()
            } else if let user = tenantManager.currentUser, !user.hasSelectedPlan {
                // Show plan selection after onboarding
                PlanSelectionView()
            } else if let tenant = tenantManager.currentTenant, tenant.isGym {
                // Show gym admin dashboard for gym owners/managers
                if isGymAdmin() {
                    GymAdminDashboard()
                } else {
                    // Regular gym member view
                    MainView()
                }
            } else {
                // Individual user view
                MainView()
            }
        }
        .animation(.easeInOut(duration: 0.5), value: tenantManager.isLoggedIn)
        .animation(.easeInOut(duration: 0.5), value: tenantManager.currentUser?.hasCompletedOnboarding)
        .animation(.easeInOut(duration: 0.5), value: tenantManager.currentUser?.hasCompletedPhysicalOnboarding)
        .animation(.easeInOut(duration: 0.5), value: tenantManager.userPendingVerification)
    }
    
    private func isGymAdmin() -> Bool {
        // TODO: Check if current user is admin/manager of the gym
        // This would be determined by user roles in the tenant
        return true // For demo purposes
    }
}

#Preview {
    ContentView()
}
