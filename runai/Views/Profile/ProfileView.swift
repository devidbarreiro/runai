//
//  ProfileView.swift
//  runai
//
//  Created by David Barreiro on 11/09/25.
//

import SwiftUI

struct ProfileView: View {
    @ObservedObject var dataManager = DataManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showingLogoutAlert = false
    @State private var showingPhysicalDataEditor = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Header
                    ProfileHeaderCard()
                    
                    // Settings Sections
                    VStack(spacing: 16) {
                        ProfileSectionCard(
                            title: "Información Personal",
                            items: [
                                ProfileItem(icon: "person.circle", title: "Usuario", value: dataManager.currentUser?.username ?? ""),
                                ProfileItem(icon: "person", title: "Nombre", value: dataManager.currentUser?.name ?? ""),
                                ProfileItem(icon: "envelope", title: "Email", value: dataManager.currentUser?.email ?? "")
                            ]
                        )
                        
                        // Physical Data Section
                        PhysicalDataSectionCard(
                            onEditTapped: {
                                showingPhysicalDataEditor = true
                            }
                        )
                        
                        ProfileSectionCard(
                            title: "Estadísticas",
                            items: [
                                ProfileItem(icon: "calendar", title: "Miembro desde", value: formattedDate(dataManager.currentUser?.createdAt)),
                                ProfileItem(icon: "figure.run", title: "Entrenamientos totales", value: "\(dataManager.workouts.count)"),
                                ProfileItem(icon: "checkmark.circle", title: "Completados", value: "\(completedWorkouts)")
                            ]
                        )
                        
                        ProfileSectionCard(
                            title: "Configuración",
                            items: [
                                ProfileItem(icon: "bell", title: "Notificaciones", value: "Activadas", showChevron: true),
                                ProfileItem(icon: "moon", title: "Modo oscuro", value: "Sistema", showChevron: true),
                                ProfileItem(icon: "globe", title: "Idioma", value: "Español", showChevron: true)
                            ]
                        )
                    }
                    
                    // Logout Button
                    Button(action: {
                        showingLogoutAlert = true
                    }) {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .foregroundColor(.red)
                            
                            Text("Cerrar Sesión")
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(.red)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: AppConstants.UI.cornerRadius)
                                .fill(Color.red.opacity(0.1))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: AppConstants.UI.cornerRadius)
                                .stroke(Color.red.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .padding(.top, 16)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .navigationTitle("Perfil")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") {
                        dismiss()
                    }
                }
            }
        }
        .alert("Cerrar Sesión", isPresented: $showingLogoutAlert) {
            Button("Cancelar", role: .cancel) { }
            Button("Cerrar Sesión", role: .destructive) {
                dataManager.logout()
            }
        } message: {
            Text("¿Estás seguro de que quieres cerrar sesión?")
        }
        .sheet(isPresented: $showingPhysicalDataEditor) {
            PhysicalDataEditorView()
        }
    }
    
    private var completedWorkouts: Int {
        dataManager.workouts.filter { $0.status == .completed }.count
    }
    
    private func formattedDate(_ date: Date?) -> String {
        guard let date = date else { return "N/A" }
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.locale = Locale(identifier: "es_ES")
        return formatter.string(from: date)
    }
}

struct ProfileHeaderCard: View {
    @ObservedObject var dataManager = DataManager.shared
    
    var body: some View {
        VStack(spacing: 16) {
            // Avatar
            Circle()
                .fill(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 80, height: 80)
                .overlay(
                    Text(initials)
                        .font(.title)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                )
            
            // User Info
            VStack(spacing: 4) {
                Text(dataManager.currentUser?.name ?? "Usuario")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("@\(dataManager.currentUser?.username ?? "usuario")")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(
            RoundedRectangle(cornerRadius: AppConstants.UI.cardCornerRadius)
                .fill(Color(.systemBackground))
                .shadow(
                    color: .black.opacity(AppConstants.UI.shadowOpacity),
                    radius: AppConstants.UI.shadowRadius,
                    x: 0, y: 2
                )
        )
    }
    
    private var initials: String {
        let name = dataManager.currentUser?.name ?? "Usuario"
        let components = name.components(separatedBy: " ")
        let firstInitial = components.first?.first ?? "U"
        let lastInitial = components.count > 1 ? components.last?.first : nil
        
        if let lastInitial = lastInitial {
            return "\(firstInitial)\(lastInitial)".uppercased()
        } else {
            return "\(firstInitial)".uppercased()
        }
    }
}

struct ProfileSectionCard: View {
    let title: String
    let items: [ProfileItem]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .padding(.horizontal, 16)
                .padding(.top, 16)
            
            VStack(spacing: 0) {
                ForEach(items.indices, id: \.self) { index in
                    ProfileItemRow(item: items[index])
                    
                    if index < items.count - 1 {
                        Divider()
                            .padding(.leading, 52)
                    }
                }
            }
            .padding(.bottom, 16)
        }
        .background(
            RoundedRectangle(cornerRadius: AppConstants.UI.cardCornerRadius)
                .fill(Color(.systemBackground))
                .shadow(
                    color: .black.opacity(AppConstants.UI.shadowOpacity),
                    radius: AppConstants.UI.shadowRadius,
                    x: 0, y: 2
                )
        )
    }
}

struct ProfileItem {
    let icon: String
    let title: String
    let value: String
    let showChevron: Bool
    
    init(icon: String, title: String, value: String, showChevron: Bool = false) {
        self.icon = icon
        self.title = title
        self.value = value
        self.showChevron = showChevron
    }
}

struct ProfileItemRow: View {
    let item: ProfileItem
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: item.icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.body)
                    .foregroundColor(.primary)
                
                Text(item.value)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if item.showChevron {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }
}

struct PhysicalDataSectionCard: View {
    @ObservedObject var dataManager = DataManager.shared
    let onEditTapped: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Datos Físicos")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("Editar") {
                    onEditTapped()
                }
                .font(.body)
                .foregroundColor(.blue)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            
            VStack(spacing: 0) {
                if let user = dataManager.currentUser {
                    if let age = user.age {
                        PhysicalDataRow(icon: "person.circle", title: "Edad", value: "\(age) años")
                        Divider().padding(.leading, 52)
                    }
                    
                    if let weight = user.weight {
                        PhysicalDataRow(icon: "scalemass", title: "Peso", value: String(format: "%.1f kg", weight))
                        Divider().padding(.leading, 52)
                    }
                    
                    if let height = user.height {
                        PhysicalDataRow(icon: "ruler", title: "Altura", value: String(format: "%.0f cm", height))
                        Divider().padding(.leading, 52)
                    }
                    
                    if let fitnessLevel = user.fitnessLevel {
                        PhysicalDataRow(icon: "figure.run", title: "Nivel", value: fitnessLevel.rawValue.capitalized)
                        Divider().padding(.leading, 52)
                    }
                    
                    if let current5kTime = user.current5kTime {
                        let minutes = Int(current5kTime) / 60
                        let seconds = Int(current5kTime) % 60
                        PhysicalDataRow(icon: "stopwatch", title: "Tiempo 5K", value: String(format: "%d:%02d", minutes, seconds))
                        Divider().padding(.leading, 52)
                    }
                    
                    if let targetRace = user.targetRace {
                        PhysicalDataRow(icon: "flag.checkered", title: "Objetivo", value: targetRace.displayName)
                        if user.raceDate != nil {
                            Divider().padding(.leading, 52)
                        }
                    }
                    
                    if let raceDate = user.raceDate {
                        PhysicalDataRow(icon: "calendar", title: "Fecha carrera", value: formatDate(raceDate))
                    }
                    
                    // Show message if no data
                    if user.age == nil && user.weight == nil && user.height == nil && 
                       user.fitnessLevel == nil && user.current5kTime == nil && 
                       user.targetRace == nil && user.raceDate == nil {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundColor(.secondary)
                            Text("No hay datos físicos registrados")
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                }
            }
            .padding(.bottom, 16)
        }
        .background(
            RoundedRectangle(cornerRadius: AppConstants.UI.cardCornerRadius)
                .fill(Color(.systemBackground))
                .shadow(
                    color: .black.opacity(AppConstants.UI.shadowOpacity),
                    radius: AppConstants.UI.shadowRadius,
                    x: 0, y: 2
                )
        )
    }
    
    private func formatDate(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.locale = Locale(identifier: "es_ES")
        return dateFormatter.string(from: date)
    }
}

struct PhysicalDataRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .foregroundColor(.primary)
                
                Text(value)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

struct PhysicalDataEditorView: View {
    @ObservedObject var dataManager = DataManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var age: String = ""
    @State private var weight: String = ""
    @State private var height: String = ""
    @State private var selectedFitnessLevel: FitnessLevel = .beginner
    @State private var fiveKMinutes: String = ""
    @State private var fiveKSeconds: String = ""
    @State private var selectedTargetRace: RaceType = .halfMarathon
    @State private var raceDate = Date().addingTimeInterval(60 * 60 * 24 * 90) // 3 months from now
    
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Datos Físicos")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        VStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Edad")
                                    .font(.body)
                                    .fontWeight(.medium)
                                
                                TextField("Ej: 25", text: $age)
                                    .keyboardType(.numberPad)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Peso (kg)")
                                    .font(.body)
                                    .fontWeight(.medium)
                                
                                TextField("Ej: 70.5", text: $weight)
                                    .keyboardType(.decimalPad)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Altura (cm)")
                                    .font(.body)
                                    .fontWeight(.medium)
                                
                                TextField("Ej: 175", text: $height)
                                    .keyboardType(.numberPad)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            }
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Nivel de Fitness")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        VStack(spacing: 12) {
                            ForEach(FitnessLevel.allCases, id: \.self) { level in
                                Button(action: {
                                    selectedFitnessLevel = level
                                }) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(level.rawValue.capitalized)
                                                .font(.body)
                                                .fontWeight(.medium)
                                                .foregroundColor(.primary)
                                            
                                            Text(level.description)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                                .multilineTextAlignment(.leading)
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: selectedFitnessLevel == level ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(selectedFitnessLevel == level ? .blue : .secondary)
                                    }
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(selectedFitnessLevel == level ? Color.blue.opacity(0.1) : Color(.systemGray6))
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Tiempo Actual 5K")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Si no conoces tu tiempo, déjalo vacío y podrás medirlo más tarde")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Minutos")
                                    .font(.body)
                                    .fontWeight(.medium)
                                
                                TextField("20", text: $fiveKMinutes)
                                    .keyboardType(.numberPad)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            }
                            
                            Text(":")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .padding(.top, 20)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Segundos")
                                    .font(.body)
                                    .fontWeight(.medium)
                                
                                TextField("30", text: $fiveKSeconds)
                                    .keyboardType(.numberPad)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            }
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Objetivo de Carrera")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        VStack(spacing: 12) {
                            ForEach(RaceType.allCases, id: \.self) { race in
                                Button(action: {
                                    selectedTargetRace = race
                                }) {
                                    HStack {
                                        Text(race.displayName)
                                            .font(.body)
                                            .fontWeight(.medium)
                                            .foregroundColor(.primary)
                                        
                                        Spacer()
                                        
                                        Image(systemName: selectedTargetRace == race ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(selectedTargetRace == race ? .blue : .secondary)
                                    }
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(selectedTargetRace == race ? Color.blue.opacity(0.1) : Color(.systemGray6))
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Fecha objetivo")
                                .font(.body)
                                .fontWeight(.medium)
                            
                            DatePicker("", selection: $raceDate, displayedComponents: .date)
                                .datePickerStyle(CompactDatePickerStyle())
                        }
                        .padding(.top, 8)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .navigationTitle("Editar Datos")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Guardar") {
                        savePhysicalData()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            loadCurrentData()
        }
        .alert("Información", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func loadCurrentData() {
        guard let user = dataManager.currentUser else { return }
        
        if let userAge = user.age {
            age = "\(userAge)"
        }
        
        if let userWeight = user.weight {
            weight = String(format: "%.1f", userWeight)
        }
        
        if let userHeight = user.height {
            height = String(format: "%.0f", userHeight)
        }
        
        if let userFitnessLevel = user.fitnessLevel {
            selectedFitnessLevel = userFitnessLevel
        }
        
        if let userCurrent5kTime = user.current5kTime {
            let minutes = Int(userCurrent5kTime) / 60
            let seconds = Int(userCurrent5kTime) % 60
            fiveKMinutes = "\(minutes)"
            fiveKSeconds = "\(seconds)"
        }
        
        if let userTargetRace = user.targetRace {
            selectedTargetRace = userTargetRace
        }
        
        if let userRaceDate = user.raceDate {
            raceDate = userRaceDate
        }
    }
    
    private func savePhysicalData() {
        guard var currentUser = dataManager.currentUser else {
            showAlert("Error: No se pudo obtener el usuario actual")
            return
        }
        
        // Update age
        if !age.isEmpty, let ageValue = Int(age), ageValue > 0 && ageValue < 120 {
            currentUser.age = ageValue
        } else if !age.isEmpty {
            showAlert("Por favor ingresa una edad válida (1-119 años)")
            return
        }
        
        // Update weight
        if !weight.isEmpty, let weightValue = Double(weight), weightValue > 0 && weightValue < 300 {
            currentUser.weight = weightValue
        } else if !weight.isEmpty {
            showAlert("Por favor ingresa un peso válido (1-300 kg)")
            return
        }
        
        // Update height
        if !height.isEmpty, let heightValue = Double(height), heightValue > 0 && heightValue < 250 {
            currentUser.height = heightValue
        } else if !height.isEmpty {
            showAlert("Por favor ingresa una altura válida (1-250 cm)")
            return
        }
        
        // Update fitness level
        currentUser.fitnessLevel = selectedFitnessLevel
        
        // Update 5K time
        if !fiveKMinutes.isEmpty && !fiveKSeconds.isEmpty {
            if let minutes = Int(fiveKMinutes), let seconds = Int(fiveKSeconds),
               minutes >= 0 && minutes < 60 && seconds >= 0 && seconds < 60 {
                currentUser.current5kTime = TimeInterval(minutes * 60 + seconds)
            } else {
                showAlert("Por favor ingresa un tiempo válido (minutos: 0-59, segundos: 0-59)")
                return
            }
        } else if !fiveKMinutes.isEmpty || !fiveKSeconds.isEmpty {
            showAlert("Por favor completa tanto minutos como segundos para el tiempo 5K")
            return
        }
        
        // Update race goals
        currentUser.targetRace = selectedTargetRace
        currentUser.raceDate = raceDate
        
        // Mark physical onboarding as completed if it wasn't already
        if !currentUser.hasCompletedPhysicalOnboarding {
            currentUser.hasCompletedPhysicalOnboarding = true
        }
        
        // Save the updated user
        dataManager.updateCurrentUser(currentUser)
        
        showAlert("Datos actualizados correctamente") {
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

#Preview {
    ProfileView()
}
