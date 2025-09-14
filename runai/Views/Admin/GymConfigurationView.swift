//
//  GymConfigurationView.swift
//  runai
//
//  Gym configuration and customization view
//

import SwiftUI
import PhotosUI

struct GymConfigurationView: View {
    @ObservedObject var tenantManager = TenantManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var gymName = ""
    @State private var address = ""
    @State private var phone = ""
    @State private var website = ""
    
    // Branding
    @State private var primaryColor = Color.blue
    @State private var secondaryColor = Color.purple
    @State private var selectedLogoItem: PhotosPickerItem?
    @State private var logoImage: UIImage?
    
    // Operating hours
    @State private var operatingHours: [DaySchedule] = DaySchedule.defaultSchedule
    
    // Features
    @State private var enabledFeatures: Set<GymFeature> = Set(GymFeature.defaultFeatures)
    
    // Settings
    @State private var customWelcomeMessage = ""
    @State private var allowMemberInvites = true
    @State private var requireMemberApproval = false
    @State private var maxMembersPerTrainer = 50
    
    // Notifications
    @State private var notificationSettings = GymNotificationSettings()
    
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                // Basic Information
                Section("Información Básica") {
                    TextField("Nombre del gimnasio", text: $gymName)
                    TextField("Dirección", text: $address)
                    TextField("Teléfono", text: $phone)
                        .keyboardType(.phonePad)
                    TextField("Sitio web (opcional)", text: $website)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                }
                
                // Branding
                Section("Marca y Apariencia") {
                    HStack {
                        Text("Color Principal")
                        Spacer()
                        ColorPicker("", selection: $primaryColor)
                            .labelsHidden()
                    }
                    
                    HStack {
                        Text("Color Secundario")
                        Spacer()
                        ColorPicker("", selection: $secondaryColor)
                            .labelsHidden()
                    }
                    
                    PhotosPicker(
                        selection: $selectedLogoItem,
                        matching: .images,
                        photoLibrary: .shared()
                    ) {
                        HStack {
                            Text("Logo del Gimnasio")
                            Spacer()
                            if let logoImage = logoImage {
                                Image(uiImage: logoImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 40, height: 40)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            } else {
                                Image(systemName: "photo.badge.plus")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .onChange(of: selectedLogoItem) { _, newItem in
                        Task {
                            if let data = try? await newItem?.loadTransferable(type: Data.self),
                               let image = UIImage(data: data) {
                                logoImage = image
                            }
                        }
                    }
                    
                    TextField("Mensaje de bienvenida personalizado", text: $customWelcomeMessage, axis: .vertical)
                        .lineLimit(2...4)
                }
                
                // Operating Hours
                Section("Horarios de Operación") {
                    ForEach($operatingHours, id: \.id) { $schedule in
                        OperatingHourRow(schedule: $schedule)
                    }
                }
                
                // Features
                Section("Funciones Habilitadas") {
                    ForEach(GymFeature.allCases, id: \.self) { feature in
                        HStack {
                            Toggle(isOn: Binding(
                                get: { enabledFeatures.contains(feature) },
                                set: { isEnabled in
                                    if isEnabled {
                                        enabledFeatures.insert(feature)
                                    } else {
                                        enabledFeatures.remove(feature)
                                    }
                                }
                            )) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(feature.displayName)
                                        .font(.body)
                                    
                                    if isPremiumFeature(feature) {
                                        Text("Función Premium")
                                            .font(.caption2)
                                            .foregroundColor(.orange)
                                    }
                                }
                            }
                        }
                    }
                }
                
                // Member Settings
                Section("Configuración de Miembros") {
                    Toggle("Permitir invitaciones de miembros", isOn: $allowMemberInvites)
                    Toggle("Requerir aprobación de nuevos miembros", isOn: $requireMemberApproval)
                    
                    HStack {
                        Text("Máximo miembros por entrenador")
                        Spacer()
                        TextField("50", value: $maxMembersPerTrainer, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                    }
                }
                
                // Notification Settings
                Section("Notificaciones") {
                    Toggle("Email de bienvenida a nuevos miembros", isOn: $notificationSettings.memberWelcomeEmail)
                    Toggle("Recordatorios de entrenamientos", isOn: $notificationSettings.workoutReminders)
                    Toggle("Recordatorios de clases", isOn: $notificationSettings.classReminders)
                    Toggle("Notificación de vencimiento de membresía", isOn: $notificationSettings.membershipExpiry)
                    Toggle("Notificaciones a entrenadores", isOn: $notificationSettings.trainerNotifications)
                    Toggle("Reportes administrativos", isOn: $notificationSettings.adminReports)
                    
                    if notificationSettings.workoutReminders {
                        HStack {
                            Text("Recordar entrenamientos")
                            Spacer()
                            TextField("2", value: $notificationSettings.workoutReminderHours, format: .number)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 40)
                            Text("horas antes")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if notificationSettings.classReminders {
                        HStack {
                            Text("Recordar clases")
                            Spacer()
                            TextField("1", value: $notificationSettings.classReminderHours, format: .number)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 40)
                            Text("horas antes")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if notificationSettings.membershipExpiry {
                        HStack {
                            Text("Avisar vencimiento")
                            Spacer()
                            TextField("7", value: $notificationSettings.membershipExpiryDays, format: .number)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 40)
                            Text("días antes")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Integration Settings (Premium)
                if enabledFeatures.contains(.membershipIntegration) {
                    Section("Integraciones") {
                        NavigationLink("Sistema de Membresías") {
                            MembershipIntegrationView()
                        }
                        
                        if enabledFeatures.contains(.paymentIntegration) {
                            NavigationLink("Sistema de Pagos") {
                                PaymentIntegrationView()
                            }
                        }
                    }
                }
            }
            .navigationTitle("Configuración")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Guardar") {
                        saveConfiguration()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            loadCurrentConfiguration()
        }
        .alert("Configuración", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func isPremiumFeature(_ feature: GymFeature) -> Bool {
        return !GymFeature.defaultFeatures.contains(feature)
    }
    
    private func loadCurrentConfiguration() {
        // Load current gym configuration
        if let tenant = tenantManager.currentTenant {
            gymName = tenant.name
            // Load other settings from tenant.gymConfig
        }
    }
    
    private func saveConfiguration() {
        guard !gymName.isEmpty else {
            showAlert("Por favor ingresa el nombre del gimnasio")
            return
        }
        
        // Create gym configuration
        let _ = GymConfiguration(
            gymName: gymName,
            address: address,
            phone: phone
        )
        
        // TODO: Save configuration to tenant
        // tenantManager.updateGymConfiguration(config)
        
        showAlert("Configuración guardada exitosamente") {
            dismiss()
        }
    }
    
    private func showAlert(_ message: String, completion: (() -> Void)? = nil) {
        alertMessage = message
        showingAlert = true
        
        if let completion = completion {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                completion()
            }
        }
    }
}

struct OperatingHourRow: View {
    @Binding var schedule: DaySchedule
    
    var body: some View {
        HStack {
            Text(schedule.dayName)
                .frame(width: 80, alignment: .leading)
            
            Toggle("", isOn: $schedule.isOpen)
                .labelsHidden()
            
            if schedule.isOpen {
                Spacer()
                
                HStack(spacing: 8) {
                    DatePicker("Apertura", selection: $schedule.openTime, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                        .frame(width: 80)
                    
                    Text("-")
                        .foregroundColor(.secondary)
                    
                    DatePicker("Cierre", selection: $schedule.closeTime, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                        .frame(width: 80)
                }
            } else {
                Spacer()
                Text("Cerrado")
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Integration Views (Placeholder)
struct MembershipIntegrationView: View {
    @State private var selectedSystem = "Seleccionar sistema"
    @State private var apiEndpoint = ""
    @State private var apiKey = ""
    @State private var syncFrequency = MembershipIntegration.SyncFrequency.daily
    
    let availableSystems = ["Glofox", "Mindbody", "ClubReady", "Zen Planner", "Otro"]
    
    var body: some View {
        Form {
            Section("Sistema de Membresías") {
                Picker("Sistema", selection: $selectedSystem) {
                    ForEach(availableSystems, id: \.self) { system in
                        Text(system).tag(system)
                    }
                }
                
                TextField("Endpoint de API", text: $apiEndpoint)
                    .autocapitalization(.none)
                
                SecureField("API Key", text: $apiKey)
                
                Picker("Frecuencia de sincronización", selection: $syncFrequency) {
                    ForEach(MembershipIntegration.SyncFrequency.allCases, id: \.self) { frequency in
                        Text(frequency.displayName).tag(frequency)
                    }
                }
            }
            
            Section("Estado") {
                HStack {
                    Text("Última sincronización")
                    Spacer()
                    Text("Nunca")
                        .foregroundColor(.secondary)
                }
                
                Button("Probar Conexión") {
                    // TODO: Test API connection
                }
                .foregroundColor(.blue)
            }
        }
        .navigationTitle("Integración de Membresías")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct PaymentIntegrationView: View {
    @State private var selectedProvider = "Stripe"
    @State private var merchantId = ""
    @State private var publicKey = ""
    @State private var webhookEndpoint = ""
    
    let providers = ["Stripe", "PayPal", "Square", "Mercado Pago"]
    
    var body: some View {
        Form {
            Section("Proveedor de Pagos") {
                Picker("Proveedor", selection: $selectedProvider) {
                    ForEach(providers, id: \.self) { provider in
                        Text(provider).tag(provider)
                    }
                }
                
                TextField("Merchant ID", text: $merchantId)
                TextField("Public Key", text: $publicKey)
                TextField("Webhook Endpoint", text: $webhookEndpoint)
                    .autocapitalization(.none)
            }
            
            Section("Configuración") {
                Toggle("Pagos automáticos", isOn: .constant(true))
                Toggle("Recordatorios de pago", isOn: .constant(true))
            }
        }
        .navigationTitle("Integración de Pagos")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Supporting Types
// Note: DaySchedule, GymFeature, GymNotificationSettings, and GymConfiguration 
// are defined in GymTenant.swift to avoid duplication

#Preview {
    GymConfigurationView()
}
