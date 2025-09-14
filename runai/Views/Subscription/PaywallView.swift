//
//  PaywallView.swift
//  runai
//
//  Paywall view shown when users try to access premium features
//

import SwiftUI

struct PaywallView: View {
    let feature: SubscriptionFeature
    @Environment(\.dismiss) private var dismiss
    @State private var showingSubscriptions = false
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Feature icon and title
            VStack(spacing: 20) {
                featureIcon
                
                VStack(spacing: 12) {
                    Text("Función Premium")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(feature.displayName)
                        .font(.title3)
                        .foregroundColor(.blue)
                    
                    Text("Esta función requiere una suscripción premium para desbloquear todo su potencial")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
            
            // Benefits
            benefitsSection
            
            Spacer()
            
            // Action buttons
            VStack(spacing: 16) {
                Button(action: {
                    showingSubscriptions = true
                }) {
                    Text("Ver Planes Premium")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.blue)
                        )
                }
                
                Button("Continuar con Limitaciones") {
                    dismiss()
                }
                .font(.body)
                .foregroundColor(.secondary)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
        }
        .background(
            LinearGradient(
                colors: [Color(.systemBackground), Color.blue.opacity(0.05)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .sheet(isPresented: $showingSubscriptions) {
            SubscriptionView(requiredFeature: feature, isPaywall: true)
        }
    }
    
    private var featureIcon: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.blue.opacity(0.2), Color.purple.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 120, height: 120)
            
            Image(systemName: iconForFeature(feature))
                .font(.system(size: 50))
                .foregroundColor(.blue)
        }
    }
    
    private var benefitsSection: some View {
        VStack(spacing: 20) {
            Text("Con Premium obtienes:")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 16) {
                BenefitRow(
                    icon: "sparkles",
                    title: "IA Ilimitada",
                    description: "Genera planes de entrenamiento sin límites"
                )
                
                BenefitRow(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Análisis Avanzado",
                    description: "Métricas detalladas de tu progreso"
                )
                
                BenefitRow(
                    icon: "person.2.fill",
                    title: "Funciones Sociales",
                    description: "Comparte y compite con amigos"
                )
                
                BenefitRow(
                    icon: "leaf.fill",
                    title: "Nutrición",
                    description: "Seguimiento completo de alimentación"
                )
            }
        }
        .padding(.horizontal, 32)
    }
    
    private func iconForFeature(_ feature: SubscriptionFeature) -> String {
        switch feature {
        case .unlimitedAICoaching:
            return "brain.head.profile"
        case .advancedAnalytics:
            return "chart.bar.xaxis"
        case .personalizedPlans:
            return "doc.text.fill"
        case .nutritionTracking:
            return "leaf.fill"
        case .socialFeatures:
            return "person.2.fill"
        case .prioritySupport:
            return "headphones"
        case .advancedIntegrations:
            return "link"
        case .customWorkouts:
            return "dumbbell.fill"
        case .exportData:
            return "square.and.arrow.up"
        default:
            return "star.fill"
        }
    }
}

struct BenefitRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

#Preview {
    PaywallView(feature: .advancedAnalytics)
}
