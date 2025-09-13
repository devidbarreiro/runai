//
//  OnboardingView.swift
//  runai
//
//  Created by David Barreiro on 11/09/25.
//

import SwiftUI

struct OnboardingView: View {
    @State private var currentPage = 0
    @State private var hasAcceptedPrivacy = false
    @State private var showingPrivacyAlert = false
    @ObservedObject var dataManager = DataManager.shared
    
    let pages = [
        OnboardingPage(
            title: "Bienvenido a RunAI",
            subtitle: "Tu compañero inteligente para mejorar como runner",
            imageName: "figure.run.circle",
            description: "Registra tus entrenamientos y sigue tu progreso de manera inteligente"
        ),
        OnboardingPage(
            title: "Planes personalizados",
            subtitle: "IA que crea entrenamientos adaptados a ti",
            imageName: "brain.head.profile",
            description: "Basado en tus datos físicos y objetivos, generamos planes de entrenamiento únicos"
        ),
        OnboardingPage(
            title: "Prepárate para tu carrera",
            subtitle: "Media maratón y maratón",
            imageName: "flag.checkered",
            description: "Te ayudamos a prepararte para tu próxima carrera con planes estructurados"
        ),
        OnboardingPage(
            title: "Privacidad y datos",
            subtitle: "Tu información está segura",
            imageName: "lock.shield",
            description: "Usamos tus datos únicamente para personalizar tu experiencia de entrenamiento"
        )
    ]
    
    var body: some View {
        VStack {
            // Page indicator
            HStack {
                ForEach(0..<pages.count, id: \.self) { index in
                    Circle()
                        .fill(index == currentPage ? Color.blue : Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                        .animation(.easeInOut, value: currentPage)
                }
            }
            .padding(.top, 20)
            
            // Page content
            TabView(selection: $currentPage) {
                ForEach(0..<pages.count, id: \.self) { index in
                    OnboardingPageView(page: pages[index])
                        .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .animation(.easeInOut, value: currentPage)
            
            // Navigation buttons
            VStack(spacing: 16) {
                if currentPage < pages.count - 1 {
                    Button(action: {
                        withAnimation {
                            currentPage += 1
                        }
                    }) {
                        Text("Continuar")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.blue)
                            )
                    }
                    
                    Button(action: {
                        dataManager.completeOnboarding()
                    }) {
                        Text("Omitir")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                } else {
                    // Privacy acceptance checkbox
                    Button(action: {
                        hasAcceptedPrivacy.toggle()
                    }) {
                        HStack {
                            Image(systemName: hasAcceptedPrivacy ? "checkmark.square.fill" : "square")
                                .foregroundColor(hasAcceptedPrivacy ? .blue : .secondary)
                            
                            Text("Acepto las políticas de privacidad y el uso de mis datos para personalizar mi entrenamiento")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.leading)
                            
                            Spacer()
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.horizontal)
                    
                    Button(action: {
                        if hasAcceptedPrivacy {
                            acceptPrivacyAndContinue()
                        } else {
                            showingPrivacyAlert = true
                        }
                    }) {
                        Text("Comenzar")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(hasAcceptedPrivacy ? Color.blue : Color.gray)
                            )
                    }
                    .disabled(!hasAcceptedPrivacy)
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
        }
        .background(Color(.systemBackground))
        .alert("Políticas de Privacidad", isPresented: $showingPrivacyAlert) {
            Button("OK") { }
        } message: {
            Text("Debes aceptar las políticas de privacidad para continuar usando la aplicación.")
        }
    }
    
    private func acceptPrivacyAndContinue() {
        guard var currentUser = dataManager.currentUser else {
            dataManager.completeOnboarding()
            return
        }
        
        // Update user with privacy acceptance
        currentUser.hasAcceptedPrivacyPolicy = true
        currentUser.privacyPolicyAcceptedAt = Date()
        
        dataManager.updateCurrentUser(currentUser)
        dataManager.completeOnboarding()
    }
}

struct OnboardingPage {
    let title: String
    let subtitle: String
    let imageName: String
    let description: String
}

struct OnboardingPageView: View {
    let page: OnboardingPage
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            Image(systemName: page.imageName)
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            VStack(spacing: 16) {
                Text(page.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text(page.subtitle)
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Text(page.description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Spacer()
        }
        .padding()
    }
}

#Preview {
    OnboardingView()
}
