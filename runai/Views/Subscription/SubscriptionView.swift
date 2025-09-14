//
//  SubscriptionView.swift
//  runai
//
//  Subscription selection and management view
//

import SwiftUI
 import Combine

struct SubscriptionView: View {
    @ObservedObject var subscriptionService = SubscriptionService.shared
    @ObservedObject var tenantManager = TenantManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedPeriod: SubscriptionPeriod = .monthly
    @State private var selectedSubscription: SubscriptionType = .premium
    @State private var showingPurchaseAlert = false
    @State private var alertMessage = ""
    @State private var isProcessingPurchase = false
    @State private var cancellables = Set<AnyCancellable>()
    
    // For paywall presentation
    let requiredFeature: SubscriptionFeature?
    let isPaywall: Bool
    
    init(requiredFeature: SubscriptionFeature? = nil, isPaywall: Bool = false) {
        self.requiredFeature = requiredFeature
        self.isPaywall = isPaywall
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    headerSection
                    
                    // Current subscription status (if user has one)
                    if let user = tenantManager.currentUser, user.subscriptionType != .free {
                        currentSubscriptionSection
                    }
                    
                    // Period selector
                    periodSelector
                    
                    // Subscription plans
                    subscriptionPlans
                    
                    // Features comparison
                    featuresComparison
                    
                    // Terms and restore
                    footerSection
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .navigationTitle(isPaywall ? "Desbloquear Función" : "Suscripciones")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if !isPaywall {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Cerrar") {
                            dismiss()
                        }
                    }
                }
            }
        }
        .alert("Suscripción", isPresented: $showingPurchaseAlert) {
            Button("OK") {
                if alertMessage.contains("exitosa") {
                    dismiss()
                }
            }
        } message: {
            Text(alertMessage)
        }
        .onReceive(NotificationCenter.default.publisher(for: .subscriptionUpdated)) { _ in
            dismiss()
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            if isPaywall {
                Image(systemName: "lock.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.orange)
                
                VStack(spacing: 8) {
                    Text("Función Premium")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    if let feature = requiredFeature {
                        Text("Necesitas una suscripción para usar \(feature.displayName)")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
            } else {
                Image(systemName: "crown.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                VStack(spacing: 8) {
                    Text("RunAI Premium")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Desbloquea todo el potencial de tu entrenamiento")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
        }
    }
    
    // MARK: - Current Subscription Section
    
    private var currentSubscriptionSection: some View {
        VStack(spacing: 12) {
            if let user = tenantManager.currentUser {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Suscripción Actual")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text(user.subscriptionType.displayName)
                            .font(.body)
                            .foregroundColor(.blue)
                        
                        Text(user.subscriptionStatus.displayName)
                            .font(.caption)
                            .foregroundColor(user.subscriptionStatus.isValid ? .green : .red)
                    }
                    
                    Spacer()
                    
                    if let expiryDate = user.subscriptionExpiryDate {
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Expira")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(formatDate(expiryDate))
                                .font(.body)
                                .fontWeight(.medium)
                        }
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )
            }
        }
    }
    
    // MARK: - Period Selector
    
    private var periodSelector: some View {
        VStack(spacing: 12) {
            Text("Período de Facturación")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack(spacing: 0) {
                ForEach(SubscriptionPeriod.allCases, id: \.self) { period in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedPeriod = period
                        }
                    }) {
                        VStack(spacing: 4) {
                            Text(period.displayName)
                                .font(.body)
                                .fontWeight(selectedPeriod == period ? .semibold : .regular)
                            
                            if period == .yearly {
                                Text("2 meses gratis")
                                    .font(.caption2)
                                    .foregroundColor(.green)
                            }
                        }
                        .foregroundColor(selectedPeriod == period ? .blue : .secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(selectedPeriod == period ? Color.blue.opacity(0.1) : Color.clear)
                        )
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray6))
            )
        }
    }
    
    // MARK: - Subscription Plans
    
    private var subscriptionPlans: some View {
        VStack(spacing: 16) {
            Text("Elige tu Plan")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                ForEach([SubscriptionType.basic, .premium, .pro], id: \.self) { type in
                    SubscriptionPlanCard(
                        subscriptionType: type,
                        period: selectedPeriod,
                        isSelected: selectedSubscription == type,
                        isRecommended: type == .premium,
                        onSelect: { selectedSubscription = type },
                        onPurchase: { purchaseSubscription(type) }
                    )
                }
            }
        }
    }
    
    // MARK: - Features Comparison
    
    private var featuresComparison: some View {
        VStack(spacing: 16) {
            Text("Comparación de Funciones")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 8) {
                // Header
                HStack {
                    Text("Función")
                        .font(.body)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text("Básico")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .frame(width: 60)
                    
                    Text("Premium")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .frame(width: 60)
                    
                    Text("Pro")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .frame(width: 60)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
                
                // Features
                ForEach(SubscriptionFeature.allCases.prefix(8), id: \.self) { feature in
                    FeatureComparisonRow(feature: feature)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
            )
        }
    }
    
    // MARK: - Footer Section
    
    private var footerSection: some View {
        VStack(spacing: 16) {
            Button("Restaurar Compras") {
                restorePurchases()
            }
            .font(.body)
            .foregroundColor(.blue)
            
            VStack(spacing: 8) {
                Text("• Las suscripciones se renuevan automáticamente")
                Text("• Cancela en cualquier momento desde Configuración")
                Text("• Los precios pueden variar según la región")
            }
            .font(.caption)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Actions
    
    private func purchaseSubscription(_ type: SubscriptionType) {
        guard !isProcessingPurchase else { return }
        
        isProcessingPurchase = true
        
        let productId = selectedPeriod == .monthly ? type.appleProductId : type.appleYearlyProductId
        
        subscriptionService.purchaseProduct(productId)
            .sink { result in
                isProcessingPurchase = false
                
                switch result {
                case .success(_):
                    alertMessage = "¡Suscripción activada exitosamente! Ahora tienes acceso a todas las funciones premium."
                    showingPurchaseAlert = true
                case .failure(let error):
                    alertMessage = "Error en la compra: \(error)"
                    showingPurchaseAlert = true
                case .cancelled:
                    // User cancelled, no need to show alert
                    break
                }
            }
            .store(in: &cancellables)
    }
    
    private func restorePurchases() {
        subscriptionService.restorePurchases()
            .sink { result in
                switch result {
                case .success(let count):
                    if count > 0 {
                        alertMessage = "Se restauraron \(count) compras exitosamente."
                    } else {
                        alertMessage = "No se encontraron compras para restaurar."
                    }
                    showingPurchaseAlert = true
                case .failure(let error):
                    alertMessage = "Error al restaurar compras: \(error)"
                    showingPurchaseAlert = true
                }
            }
            .store(in: &cancellables)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "es_ES")
        return formatter.string(from: date)
    }
}

// MARK: - Subscription Plan Card

struct SubscriptionPlanCard: View {
    let subscriptionType: SubscriptionType
    let period: SubscriptionPeriod
    let isSelected: Bool
    let isRecommended: Bool
    let onSelect: () -> Void
    let onPurchase: () -> Void
    
    private var price: Double {
        return period == .monthly ? subscriptionType.monthlyPrice : subscriptionType.yearlyPrice
    }
    
    private var monthlyEquivalent: Double {
        return period == .yearly ? subscriptionType.yearlyPrice / 12 : subscriptionType.monthlyPrice
    }
    
    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 16) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(subscriptionType.displayName)
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            if isRecommended {
                                Text("Recomendado")
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(
                                        Capsule()
                                            .fill(Color.orange)
                                    )
                            }
                        }
                        
                        HStack(alignment: .bottom, spacing: 4) {
                            Text("$\(String(format: "%.2f", price))")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            Text(period == .monthly ? "/mes" : "/año")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        if period == .yearly {
                            Text("$\(String(format: "%.2f", monthlyEquivalent))/mes")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundColor(isSelected ? .blue : .secondary)
                }
                
                // Features preview
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(subscriptionType.features.prefix(3), id: \.self) { feature in
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark")
                                .font(.caption)
                                .foregroundColor(.green)
                            
                            Text(feature.displayName)
                                .font(.body)
                                .foregroundColor(.primary)
                            
                            Spacer()
                        }
                    }
                    
                    if subscriptionType.features.count > 3 {
                        HStack(spacing: 8) {
                            Image(systemName: "plus")
                                .font(.caption)
                                .foregroundColor(.blue)
                            
                            Text("Y \(subscriptionType.features.count - 3) funciones más")
                                .font(.caption)
                                .foregroundColor(.blue)
                            
                            Spacer()
                        }
                    }
                }
                
                // Purchase button
                if isSelected {
                    Button(action: onPurchase) {
                        Text("Suscribirse Ahora")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.blue)
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color(.systemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isSelected ? Color.blue : Color(.systemGray4),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
            .shadow(
                color: .black.opacity(isSelected ? 0.1 : 0.05),
                radius: isSelected ? 8 : 4,
                x: 0, y: 2
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// MARK: - Feature Comparison Row

struct FeatureComparisonRow: View {
    let feature: SubscriptionFeature
    
    var body: some View {
        HStack {
            Text(feature.displayName)
                .font(.body)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Basic
            Image(systemName: SubscriptionType.basic.features.contains(feature) ? "checkmark" : "xmark")
                .font(.caption)
                .foregroundColor(SubscriptionType.basic.features.contains(feature) ? .green : .red)
                .frame(width: 60)
            
            // Premium
            Image(systemName: SubscriptionType.premium.features.contains(feature) ? "checkmark" : "xmark")
                .font(.caption)
                .foregroundColor(SubscriptionType.premium.features.contains(feature) ? .green : .red)
                .frame(width: 60)
            
            // Pro
            Image(systemName: SubscriptionType.pro.features.contains(feature) ? "checkmark" : "xmark")
                .font(.caption)
                .foregroundColor(SubscriptionType.pro.features.contains(feature) ? .green : .red)
                .frame(width: 60)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }
}

#Preview {
    SubscriptionView()
}
