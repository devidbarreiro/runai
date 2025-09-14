//
//  SubscriptionService.swift
//  runai
//
//  Apple In-App Purchase subscription service
//  Currently using mock implementation for development
//

import Foundation
import Combine
import StoreKit

class SubscriptionService: NSObject, ObservableObject {
    static let shared = SubscriptionService()
    
    @Published var availableProducts: [SKProduct] = []
    @Published var purchasedProducts: Set<String> = []
    @Published var isLoading = false
    @Published var lastError: String?
    
    // Mock products for development
    @Published var mockProducts: [MockProduct] = []
    
    private var productsRequest: SKProductsRequest?
    private var cancellables = Set<AnyCancellable>()
    
    // Product identifiers following Apple's best practices
    private let productIdentifiers: Set<String> = [
        "com.runai.basic.monthly",
        "com.runai.basic.yearly",
        "com.runai.premium.monthly", 
        "com.runai.premium.yearly",
        "com.runai.pro.monthly",
        "com.runai.pro.yearly"
    ]
    
    override init() {
        super.init()
        setupMockProducts()
        
        // In production, this would initialize StoreKit
        // SKPaymentQueue.default().add(self)
        // requestProducts()
    }
    
    deinit {
        SKPaymentQueue.default().remove(self)
    }
    
    // MARK: - Public Methods
    
    func requestProducts() {
        guard !productIdentifiers.isEmpty else { return }
        
        isLoading = true
        
        // Mock implementation - in production use real StoreKit
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.isLoading = false
            // Simulate successful product fetch
        }
    }
    
    func purchaseProduct(_ productId: String) -> AnyPublisher<PurchaseResult, Never> {
        isLoading = true
        
        return Future { promise in
            // Mock purchase flow
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.isLoading = false
                
                // Simulate successful purchase
                self.purchasedProducts.insert(productId)
                
                // Update user subscription
                if let subscriptionType = self.subscriptionTypeForProductId(productId) {
                    self.updateUserSubscription(to: subscriptionType, productId: productId)
                    promise(.success(.success(productId)))
                } else {
                    promise(.success(.failure("Producto no encontrado")))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func restorePurchases() -> AnyPublisher<RestoreResult, Never> {
        isLoading = true
        
        return Future { promise in
            // Mock restore
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                self.isLoading = false
                
                // Simulate restored purchases
                let restoredCount = self.purchasedProducts.count
                promise(.success(.success(restoredCount)))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func hasActiveSubscription() -> Bool {
        guard let user = TenantManager.shared.currentUser else { return false }
        
        return user.subscriptionStatus.isValid && 
               (user.subscriptionExpiryDate == nil || user.subscriptionExpiryDate! > Date())
    }
    
    func hasFeature(_ feature: SubscriptionFeature) -> Bool {
        guard let user = TenantManager.shared.currentUser else { return false }
        
        // Gym members get features from their gym's plan
        if user.isGymMember {
            return true // Gym handles feature access
        }
        
        // Individual users check their subscription
        return user.subscriptionType.features.contains(feature) && hasActiveSubscription()
    }
    
    func canUseFeature(_ feature: SubscriptionFeature, showPaywall: Bool = true) -> Bool {
        let hasAccess = hasFeature(feature)
        
        if !hasAccess && showPaywall {
            // Show paywall
            NotificationCenter.default.post(name: .showPaywall, object: feature)
        }
        
        return hasAccess
    }
    
    // MARK: - Usage Tracking
    
    func trackWorkoutCreated() -> Bool {
        guard let user = TenantManager.shared.currentUser else { return false }
        
        if user.isGymMember { return true } // Gym members have unlimited
        
        let currentMonth = Calendar.current.component(.month, from: Date())
        let currentYear = Calendar.current.component(.year, from: Date())
        let key = "workouts_\(currentYear)_\(currentMonth)"
        
        let currentCount = UserDefaults.standard.integer(forKey: key)
        let maxAllowed = user.subscriptionType.maxWorkoutsPerMonth
        
        if currentCount >= maxAllowed {
            return false
        }
        
        UserDefaults.standard.set(currentCount + 1, forKey: key)
        return true
    }
    
    func trackAIQuery() -> Bool {
        guard let user = TenantManager.shared.currentUser else { return false }
        
        if user.isGymMember { return true } // Gym members have unlimited
        
        let currentMonth = Calendar.current.component(.month, from: Date())
        let currentYear = Calendar.current.component(.year, from: Date())
        let key = "ai_queries_\(currentYear)_\(currentMonth)"
        
        let currentCount = UserDefaults.standard.integer(forKey: key)
        let maxAllowed = user.subscriptionType.maxAIQueriesPerMonth
        
        if currentCount >= maxAllowed {
            return false
        }
        
        UserDefaults.standard.set(currentCount + 1, forKey: key)
        return true
    }
    
    func getRemainingUsage(for feature: SubscriptionFeature) -> (used: Int, total: Int) {
        guard let user = TenantManager.shared.currentUser else { return (0, 0) }
        
        if user.isGymMember { return (0, Int.max) }
        
        let currentMonth = Calendar.current.component(.month, from: Date())
        let currentYear = Calendar.current.component(.year, from: Date())
        
        switch feature {
        case .basicWorkoutTracking, .unlimitedAICoaching:
            let key = "workouts_\(currentYear)_\(currentMonth)"
            let used = UserDefaults.standard.integer(forKey: key)
            let total = user.subscriptionType.maxWorkoutsPerMonth
            return (used, total)
            
        case .limitedAICoaching:
            let key = "ai_queries_\(currentYear)_\(currentMonth)"
            let used = UserDefaults.standard.integer(forKey: key)
            let total = user.subscriptionType.maxAIQueriesPerMonth
            return (used, total)
            
        default:
            return (0, Int.max)
        }
    }
    
    // MARK: - Private Methods
    
    private func setupMockProducts() {
        mockProducts = [
            MockProduct(
                id: "com.runai.basic.monthly",
                displayName: "RunAI Básico",
                price: 4.99,
                period: .monthly,
                subscriptionType: .basic
            ),
            MockProduct(
                id: "com.runai.basic.yearly",
                displayName: "RunAI Básico (Anual)",
                price: 49.99,
                period: .yearly,
                subscriptionType: .basic
            ),
            MockProduct(
                id: "com.runai.premium.monthly",
                displayName: "RunAI Premium",
                price: 9.99,
                period: .monthly,
                subscriptionType: .premium
            ),
            MockProduct(
                id: "com.runai.premium.yearly",
                displayName: "RunAI Premium (Anual)",
                price: 99.99,
                period: .yearly,
                subscriptionType: .premium
            ),
            MockProduct(
                id: "com.runai.pro.monthly",
                displayName: "RunAI Pro",
                price: 19.99,
                period: .monthly,
                subscriptionType: .pro
            ),
            MockProduct(
                id: "com.runai.pro.yearly",
                displayName: "RunAI Pro (Anual)",
                price: 199.99,
                period: .yearly,
                subscriptionType: .pro
            )
        ]
    }
    
    private func subscriptionTypeForProductId(_ productId: String) -> SubscriptionType? {
        return mockProducts.first { $0.id == productId }?.subscriptionType
    }
    
    private func updateUserSubscription(to type: SubscriptionType, productId: String) {
        guard var user = TenantManager.shared.currentUser else { return }
        
        user.subscriptionType = type
        user.subscriptionStatus = .active
        user.appleSubscriptionId = productId
        
        // Set expiry date based on subscription period
        let isYearly = productId.contains("yearly")
        let expiryDate = Calendar.current.date(
            byAdding: isYearly ? .year : .month,
            value: 1,
            to: Date()
        )
        user.subscriptionExpiryDate = expiryDate
        
        TenantManager.shared.currentUser = user
        TenantManager.shared.saveCurrentSession()
        
        // Send notification
        NotificationCenter.default.post(name: .subscriptionUpdated, object: type)
    }
}

// MARK: - SKProductsRequestDelegate (for real StoreKit implementation)

extension SubscriptionService: SKProductsRequestDelegate {
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        DispatchQueue.main.async {
            self.availableProducts = response.products
            self.isLoading = false
        }
    }
    
    func request(_ request: SKRequest, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.lastError = error.localizedDescription
            self.isLoading = false
        }
    }
}

// MARK: - SKPaymentTransactionObserver (for real StoreKit implementation)

extension SubscriptionService: SKPaymentTransactionObserver {
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased:
                handlePurchased(transaction)
            case .restored:
                handleRestored(transaction)
            case .failed:
                handleFailed(transaction)
            case .deferred:
                handleDeferred(transaction)
            case .purchasing:
                break
            @unknown default:
                break
            }
        }
    }
    
    private func handlePurchased(_ transaction: SKPaymentTransaction) {
        // Validate receipt with your server
        // Update user subscription
        SKPaymentQueue.default().finishTransaction(transaction)
    }
    
    private func handleRestored(_ transaction: SKPaymentTransaction) {
        // Restore user subscription
        SKPaymentQueue.default().finishTransaction(transaction)
    }
    
    private func handleFailed(_ transaction: SKPaymentTransaction) {
        if let error = transaction.error as? SKError {
            if error.code != .paymentCancelled {
                lastError = error.localizedDescription
            }
        }
        SKPaymentQueue.default().finishTransaction(transaction)
    }
    
    private func handleDeferred(_ transaction: SKPaymentTransaction) {
        // Handle deferred transaction (e.g., parental approval needed)
    }
}

// MARK: - Supporting Types

struct MockProduct: Identifiable {
    let id: String
    let displayName: String
    let price: Double
    let period: SubscriptionPeriod
    let subscriptionType: SubscriptionType
    
    var formattedPrice: String {
        return String(format: "$%.2f", price)
    }
    
    var periodDescription: String {
        switch period {
        case .monthly:
            return "al mes"
        case .yearly:
            return "al año"
        }
    }
}

enum SubscriptionPeriod: String, CaseIterable {
    case monthly = "monthly"
    case yearly = "yearly"
    
    var displayName: String {
        switch self {
        case .monthly:
            return "Mensual"
        case .yearly:
            return "Anual"
        }
    }
}

enum PurchaseResult {
    case success(String)
    case failure(String)
    case cancelled
}

enum RestoreResult {
    case success(Int) // Number of restored purchases
    case failure(String)
}

// MARK: - Notifications

extension Notification.Name {
    static let showPaywall = Notification.Name("showPaywall")
    static let subscriptionUpdated = Notification.Name("subscriptionUpdated")
}
