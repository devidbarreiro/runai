//
//  PhysicalOnboardingView.swift
//  runai
//
//  Created by David Barreiro on 12/09/25.
//

import SwiftUI

struct PhysicalOnboardingView: View {
    @ObservedObject var dataManager = DataManager.shared
    @State private var currentStep = 0
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    // User data
    @State private var age = ""
    @State private var weight = ""
    @State private var height = ""
    @State private var fitnessLevel: FitnessLevel?
    @State private var has5kTime = false
    @State private var fiveKMinutes = ""
    @State private var fiveKSeconds = ""
    @State private var targetRace: RaceType?
    @State private var raceDate = Calendar.current.date(byAdding: .month, value: 3, to: Date()) ?? Date()
    
    // Multi-sport data
    @State private var selectedSports: Set<SportType> = [.running]
    @State private var primarySport: SportType = .running
    @State private var swimmingLevel: SwimmingLevel?
    @State private var cyclingLevel: CyclingLevel?
    @State private var hasPoolAccess = false
    @State private var hasBikeAccess = false
    @State private var preferredPoolLength = 25
    
    // Sport-specific performance data
    @State private var sportPerformanceData: [SportType: SportPerformanceData] = [:]
    
    // Performance questions state
    @State private var currentPerformanceStep = 0
    
    private let totalSteps = 8
    
    var body: some View {
        VStack(spacing: 0) {
            // Progress bar
            ProgressView(value: Double(currentStep), total: Double(totalSteps))
                .progressViewStyle(LinearProgressViewStyle())
                .scaleEffect(x: 1, y: 2)
                .padding(.horizontal)
                .padding(.top)
            
            ScrollView {
                VStack(spacing: 32) {
                    // Step indicator
                    HStack {
                        Text("Paso \(currentStep + 1) de \(totalSteps)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    
                    // Step content
                    Group {
                        switch currentStep {
                        case 0:
                            personalDataStep
                        case 1:
                            sportSelectionStep
                        case 2:
                            fitnessLevelStep
                        case 3:
                            sportSpecificStep
                        case 4:
                            sportPerformanceStep
                        case 5:
                            raceGoalStep
                        case 6:
                            raceDateStep
                        case 7:
                            summaryStep
                        default:
                            EmptyView()
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    Spacer()
                }
            }
            
            // Navigation buttons
            HStack(spacing: 16) {
                if currentStep > 0 {
                    Button("Anterior") {
                        withAnimation {
                            currentStep -= 1
                        }
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
                
                Spacer()
                
                Button(currentStep == totalSteps - 1 ? "Finalizar" : "Siguiente") {
                    if currentStep == totalSteps - 1 {
                        completeOnboarding()
                    } else {
                        nextStep()
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(!canProceed)
            }
            .padding(24)
        }
        .navigationBarHidden(true)
        .alert("Información", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    // MARK: - Step Views
    private var personalDataStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Datos personales")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Necesitamos algunos datos básicos para personalizar tu entrenamiento")
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 16) {
                HStack {
                    Text("Edad")
                        .font(.headline)
                    Spacer()
                    TextField("Años", text: $age)
                        .keyboardType(.numberPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 80)
                }
                
                HStack {
                    Text("Peso")
                        .font(.headline)
                    Spacer()
                    HStack {
                        TextField("70", text: $weight)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 80)
                        Text("kg")
                            .foregroundColor(.secondary)
                    }
                }
                
                HStack {
                    Text("Altura")
                        .font(.headline)
                    Spacer()
                    HStack {
                        TextField("170", text: $height)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 80)
                        Text("cm")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
            )
        }
    }
    
    private var sportSelectionStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("¿Qué deportes practicas?")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Selecciona todos los deportes que quieres entrenar. Puedes elegir uno o varios.")
                    .foregroundColor(.secondary)
                    .font(.subheadline)
            }
            
            // Sport selection cards in grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(SportType.allCases, id: \.self) { sport in
                    Button(action: {
                        withAnimation(.spring(response: 0.3)) {
                            if selectedSports.contains(sport) {
                                selectedSports.remove(sport)
                                if primarySport == sport && !selectedSports.isEmpty {
                                    primarySport = selectedSports.first!
                                }
                            } else {
                                selectedSports.insert(sport)
                                if selectedSports.count == 1 {
                                    primarySport = sport
                                }
                            }
                        }
                    }) {
                        VStack(spacing: 12) {
                            // Sport emoji with background
                            ZStack {
                                Circle()
                                    .fill(selectedSports.contains(sport) ? Color(sport.color).opacity(0.2) : Color(.systemGray6))
                                    .frame(width: 60, height: 60)
                                
                                Text(sport.emoji)
                                    .font(.title)
                            }
                            
                            VStack(spacing: 4) {
                                Text(sport.displayName)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                if sport == primarySport && selectedSports.count > 1 {
                                    HStack(spacing: 4) {
                                        Image(systemName: "star.fill")
                                            .font(.caption2)
                                        Text("Principal")
                                            .font(.caption2)
                                    }
                                    .foregroundColor(.yellow)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(selectedSports.contains(sport) ? Color(sport.color).opacity(0.1) : Color(.systemGray6))
                                .stroke(selectedSports.contains(sport) ? Color(sport.color) : Color.clear, lineWidth: 2)
                        )
                        .overlay(
                            // Checkmark overlay
                            VStack {
                                HStack {
                                    Spacer()
                                    if selectedSports.contains(sport) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(Color(sport.color))
                                            .font(.title3)
                                    }
                                }
                                Spacer()
                            }
                            .padding(8)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            
            // Primary sport selection (only if multiple sports selected)
            if selectedSports.count > 1 {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Deporte Principal")
                            .font(.headline)
                        Text("El deporte en el que quieres enfocarte más")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(Array(selectedSports), id: \.self) { sport in
                                Button(action: {
                                    withAnimation(.spring(response: 0.3)) {
                                        primarySport = sport
                                    }
                                }) {
                                    HStack(spacing: 8) {
                                        Text(sport.emoji)
                                            .font(.title3)
                                        Text(sport.displayName)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 20)
                                            .fill(primarySport == sport ? Color(sport.color) : Color(.systemGray6))
                                    )
                                    .foregroundColor(primarySport == sport ? .white : .primary)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(primarySport == sport ? Color(sport.color) : Color.clear, lineWidth: 2)
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal, 1)
                    }
                }
                .padding(.top, 8)
            }
        }
    }
    
    private var fitnessLevelStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Nivel de forma física")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Selecciona el nivel que mejor te describe actualmente")
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 12) {
                ForEach(FitnessLevel.allCases, id: \.self) { level in
                    Button(action: {
                        fitnessLevel = level
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(level.rawValue.capitalized)
                                    .font(.headline)
                                    .foregroundColor(fitnessLevel == level ? .white : .primary)
                                
                                Text(level.description)
                                    .font(.caption)
                                    .foregroundColor(fitnessLevel == level ? .white.opacity(0.8) : .secondary)
                            }
                            
                            Spacer()
                            
                            if fitnessLevel == level {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.white)
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(fitnessLevel == level ? Color.accentColor : Color(.systemGray6))
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
    
    private var sportSpecificStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Información específica")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Cuéntanos más sobre tu experiencia en cada deporte")
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 20) {
                // Swimming specific questions
                if selectedSports.contains(.swimming) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("🏊‍♂️")
                                .font(.title2)
                            Text("Natación")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Nivel de natación:")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            ForEach(SwimmingLevel.allCases, id: \.self) { level in
                                Button(action: { swimmingLevel = level }) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(level.displayName)
                                                .font(.headline)
                                                .foregroundColor(swimmingLevel == level ? .white : .primary)
                                            Text(level.description)
                                                .font(.caption)
                                                .foregroundColor(swimmingLevel == level ? .white.opacity(0.8) : .secondary)
                                        }
                                        
                                        Spacer()
                                        
                                        if swimmingLevel == level {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.white)
                                        }
                                    }
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(swimmingLevel == level ? Color.cyan : Color(.systemGray6))
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Toggle("Tengo acceso a piscina", isOn: $hasPoolAccess)
                                .font(.subheadline)
                            
                            if hasPoolAccess {
                                HStack {
                                    Text("Longitud de piscina:")
                                        .font(.subheadline)
                                    Spacer()
                                    Picker("Pool Length", selection: $preferredPoolLength) {
                                        Text("25m").tag(25)
                                        Text("50m").tag(50)
                                    }
                                    .pickerStyle(SegmentedPickerStyle())
                                    .frame(width: 120)
                                }
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(.systemGray6))
                        )
                    }
                }
                
                // Cycling specific questions
                if selectedSports.contains(.cycling) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("🚴‍♂️")
                                .font(.title2)
                            Text("Ciclismo")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Nivel de ciclismo:")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            ForEach(CyclingLevel.allCases, id: \.self) { level in
                                Button(action: { cyclingLevel = level }) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(level.displayName)
                                                .font(.headline)
                                                .foregroundColor(cyclingLevel == level ? .white : .primary)
                                            Text(level.description)
                                                .font(.caption)
                                                .foregroundColor(cyclingLevel == level ? .white.opacity(0.8) : .secondary)
                                        }
                                        
                                        Spacer()
                                        
                                        if cyclingLevel == level {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.white)
                                        }
                                    }
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(cyclingLevel == level ? Color.orange : Color(.systemGray6))
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        
                        Toggle("Tengo acceso a bicicleta", isOn: $hasBikeAccess)
                            .font(.subheadline)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(.systemGray6))
                            )
                    }
                }
            }
        }
    }
    
    private var sportPerformanceStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Información específica")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Cuéntanos más sobre tu experiencia en cada deporte")
                    .foregroundColor(.secondary)
                    .font(.subheadline)
            }
            
            VStack(spacing: 16) {
                Button(action: {
                    has5kTime.toggle()
                }) {
                    HStack {
                        Image(systemName: has5kTime ? "checkmark.square.fill" : "square")
                            .foregroundColor(has5kTime ? .accentColor : .secondary)
                        Text("Conozco mi tiempo actual en 5K")
                        Spacer()
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                if has5kTime {
                    HStack {
                        Text("Mi tiempo:")
                            .font(.headline)
                        
                        Spacer()
                        
                        HStack(spacing: 8) {
                            TextField("25", text: $fiveKMinutes)
                                .keyboardType(.numberPad)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .frame(width: 60)
                            
                            Text(":")
                                .font(.title2)
                            
                            TextField("30", text: $fiveKSeconds)
                                .keyboardType(.numberPad)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .frame(width: 60)
                            
                            Text("min")
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                    )
                } else {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("💡 Recomendación")
                            .font(.headline)
                            .foregroundColor(.orange)
                        
                        Text("Te sugerimos que hagas una prueba de 5K cuando puedas y actualices esta información en tu perfil. Esto nos permitirá crear un plan más preciso.")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.orange.opacity(0.1))
                    )
                }
            }
        }
    }
    
    private var raceGoalStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Objetivo de carrera")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("¿Para qué distancia quieres entrenar?")
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 12) {
                ForEach(RaceType.allCases, id: \.self) { race in
                    Button(action: {
                        targetRace = race
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(race.displayName)
                                    .font(.headline)
                                    .foregroundColor(targetRace == race ? .white : .primary)
                                
                                Text("\(race.distance, specifier: "%.1f") kilómetros")
                                    .font(.caption)
                                    .foregroundColor(targetRace == race ? .white.opacity(0.8) : .secondary)
                            }
                            
                            Spacer()
                            
                            if targetRace == race {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.white)
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(targetRace == race ? Color.accentColor : Color(.systemGray6))
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
    
    private var raceDateStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Fecha de la carrera")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("¿Cuándo planeas correr tu \(targetRace?.displayName.lowercased() ?? "carrera")?")
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 16) {
                DatePicker(
                    "Fecha de la carrera",
                    selection: $raceDate,
                    in: Calendar.current.date(byAdding: .weekOfYear, value: 4, to: Date())!...,
                    displayedComponents: [.date]
                )
                .datePickerStyle(GraphicalDatePickerStyle())
                
                let weeksUntilRace = Calendar.current.dateComponents([.weekOfYear], from: Date(), to: raceDate).weekOfYear ?? 0
                
                if weeksUntilRace > 0 {
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(.accentColor)
                        Text("Tienes \(weeksUntilRace) semanas para entrenar")
                            .font(.headline)
                            .foregroundColor(.accentColor)
                        Spacer()
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.accentColor.opacity(0.1))
                    )
                }
            }
        }
    }
    
    private var summaryStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("¡Perfecto!")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Aquí tienes un resumen de tu información:")
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 16) {
                SummaryRow(title: "Edad", value: "\(age) años")
                SummaryRow(title: "Peso", value: "\(weight) kg")
                SummaryRow(title: "Altura", value: "\(height) cm")
                SummaryRow(title: "Nivel de fitness", value: fitnessLevel?.rawValue.capitalized ?? "")
                
                if has5kTime && !fiveKMinutes.isEmpty && !fiveKSeconds.isEmpty {
                    SummaryRow(title: "Tiempo 5K", value: "\(fiveKMinutes):\(fiveKSeconds)")
                } else {
                    SummaryRow(title: "Tiempo 5K", value: "Pendiente de medir")
                }
                
                SummaryRow(title: "Objetivo", value: targetRace?.displayName ?? "")
                
                SummaryRow(title: "Fecha de carrera", value: formatDate(raceDate))
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
            )
            
            VStack(alignment: .leading, spacing: 8) {
                Text("🎯 Próximo paso")
                    .font(.headline)
                    .foregroundColor(.accentColor)
                
                Text("Crearemos un plan de entrenamiento personalizado usando inteligencia artificial, adaptado específicamente a tu perfil y objetivos.")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.accentColor.opacity(0.1))
            )
        }
    }
    
    // MARK: - Helper Views
    private struct SummaryRow: View {
        let title: String
        let value: String
        
        var body: some View {
            HStack {
                Text(title)
                    .foregroundColor(.secondary)
                Spacer()
                Text(value)
                    .fontWeight(.medium)
            }
        }
    }
    
    // MARK: - Computed Properties
    private var canProceed: Bool {
        switch currentStep {
        case 0:
            return !age.isEmpty && !weight.isEmpty && !height.isEmpty
        case 1:
            return !selectedSports.isEmpty
        case 2:
            return fitnessLevel != nil
        case 3:
            // Validate sport-specific requirements
            if selectedSports.contains(.swimming) && swimmingLevel == nil {
                return false
            }
            if selectedSports.contains(.cycling) && cyclingLevel == nil {
                return false
            }
            return true
        case 4:
            return true // Always can proceed from 5K time step
        case 5:
            return targetRace != nil
        case 6:
            return true // Date is always valid
        case 7:
            return true // Summary step
        default:
            return false
        }
    }
    
    // MARK: - Actions
    private func nextStep() {
        guard canProceed else {
            showAlert("Por favor completa todos los campos requeridos")
            return
        }
        
        withAnimation {
            currentStep += 1
        }
    }
    
    private func completeOnboarding() {
        guard var currentUser = dataManager.currentUser else {
            showAlert("Error: Usuario no encontrado")
            return
        }
        
        // Update user with physical data
        currentUser.age = Int(age)
        currentUser.weight = Double(weight)
        currentUser.height = Double(height)
        currentUser.fitnessLevel = fitnessLevel
        currentUser.targetRace = targetRace
        currentUser.raceDate = raceDate
        currentUser.hasCompletedPhysicalOnboarding = true
        
        // Set 5K time if provided
        if has5kTime, let minutes = Int(fiveKMinutes), let seconds = Int(fiveKSeconds) {
            currentUser.current5kTime = TimeInterval(minutes * 60 + seconds)
        }
        
        // Update multi-sport data
        currentUser.preferredSports = Array(selectedSports)
        currentUser.primarySport = primarySport
        currentUser.swimmingLevel = swimmingLevel
        currentUser.cyclingLevel = cyclingLevel
        currentUser.hasPoolAccess = hasPoolAccess
        currentUser.hasBikeAccess = hasBikeAccess
        currentUser.preferredPoolLength = preferredPoolLength
        
        // Update sport-specific performance data
        var sportDataDict: [String: SportPerformanceData] = [:]
        for (sport, data) in sportPerformanceData {
            sportDataDict[sport.rawValue] = data
        }
        currentUser.sportSpecificData = sportDataDict
        
        // Update user in data manager
        dataManager.updateCurrentUser(currentUser)
        
        showAlert("¡Perfil completado! Ahora generaremos tu plan de entrenamiento personalizado.")
    }
    
    private func showAlert(_ message: String) {
        alertMessage = message
        showingAlert = true
    }
    
    private func formatDate(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.locale = Locale(identifier: "es_ES")
        return dateFormatter.string(from: date)
    }
}

// MARK: - Sport Performance Card
struct SportPerformanceCard: View {
    let sport: SportType
    @Binding var performanceData: SportPerformanceData
    @State private var isExpanded = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            Button(action: {
                withAnimation(.spring(response: 0.3)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color(sport.color).opacity(0.2))
                                .frame(width: 40, height: 40)
                            Text(sport.emoji)
                                .font(.title3)
                        }
                        
                        Text(sport.displayName)
                            .font(.headline)
                            .foregroundColor(.primary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            if isExpanded {
                VStack(spacing: 16) {
                    switch sport {
                    case .running:
                        RunningPerformanceQuestions(data: $performanceData)
                    case .swimming:
                        SwimmingPerformanceQuestions(data: $performanceData)
                    case .cycling:
                        CyclingPerformanceQuestions(data: $performanceData)
                    case .triathlon:
                        TriathlonPerformanceQuestions(data: $performanceData)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
        )
    }
}

// MARK: - Running Performance Questions
struct RunningPerformanceQuestions: View {
    @Binding var data: SportPerformanceData
    @State private var current5kMinutes = ""
    @State private var current5kSeconds = ""
    @State private var weeklyKm = ""
    @State private var longestRun = ""
    
    var body: some View {
        VStack(spacing: 16) {
            // 5K Time
            VStack(alignment: .leading, spacing: 8) {
                Text("¿Cuál es tu mejor tiempo en 5K?")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                HStack {
                    TextField("25", text: $current5kMinutes)
                        .keyboardType(.numberPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 60)
                    Text(":")
                    TextField("30", text: $current5kSeconds)
                        .keyboardType(.numberPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 60)
                    Text("(min:seg)")
                        .foregroundColor(.secondary)
                        .font(.caption)
                    Spacer()
                }
                .onChange(of: current5kMinutes) { _ in updateRunningTimes() }
                .onChange(of: current5kSeconds) { _ in updateRunningTimes() }
            }
            
            // Weekly distance
            VStack(alignment: .leading, spacing: 8) {
                Text("¿Cuántos km corres por semana normalmente?")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                HStack {
                    TextField("20", text: $weeklyKm)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 80)
                    Text("km/semana")
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .onChange(of: weeklyKm) { _ in
                    if let km = Double(weeklyKm) {
                        data.weeklyRunningKm = km
                    }
                }
            }
            
            // Longest run
            VStack(alignment: .leading, spacing: 8) {
                Text("¿Cuál ha sido tu carrera más larga?")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                HStack {
                    TextField("10", text: $longestRun)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 80)
                    Text("km")
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .onChange(of: longestRun) { _ in
                    if let km = Double(longestRun) {
                        data.longestRun = km
                    }
                }
            }
        }
        .onAppear {
            loadRunningData()
        }
    }
    
    private func updateRunningTimes() {
        guard let minutes = Int(current5kMinutes),
              let seconds = Int(current5kSeconds) else { return }
        data.current5kTime = TimeInterval(minutes * 60 + seconds)
    }
    
    private func loadRunningData() {
        if let time = data.current5kTime {
            current5kMinutes = String(Int(time) / 60)
            current5kSeconds = String(Int(time) % 60)
        }
        if let km = data.weeklyRunningKm {
            weeklyKm = String(km)
        }
        if let longest = data.longestRun {
            longestRun = String(longest)
        }
    }
}

// MARK: - Swimming Performance Questions
struct SwimmingPerformanceQuestions: View {
    @Binding var data: SportPerformanceData
    @State private var current100mMinutes = ""
    @State private var current100mSeconds = ""
    @State private var weeklyKm = ""
    @State private var favoriteStroke = "Libre"
    
    private let strokes = ["Libre", "Espalda", "Braza", "Mariposa"]
    
    var body: some View {
        VStack(spacing: 16) {
            // 100m Free Time
            VStack(alignment: .leading, spacing: 8) {
                Text("¿Cuál es tu tiempo en 100m libre?")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                HStack {
                    TextField("1", text: $current100mMinutes)
                        .keyboardType(.numberPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 60)
                    Text(":")
                    TextField("30", text: $current100mSeconds)
                        .keyboardType(.numberPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 60)
                    Text("(min:seg)")
                        .foregroundColor(.secondary)
                        .font(.caption)
                    Spacer()
                }
                .onChange(of: current100mMinutes) { _ in updateSwimmingTimes() }
                .onChange(of: current100mSeconds) { _ in updateSwimmingTimes() }
            }
            
            // Favorite stroke
            VStack(alignment: .leading, spacing: 8) {
                Text("¿Cuál es tu estilo favorito?")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Picker("Estilo", selection: $favoriteStroke) {
                    ForEach(strokes, id: \.self) { stroke in
                        Text(stroke).tag(stroke)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .onChange(of: favoriteStroke) { _ in
                    data.favoriteStroke = favoriteStroke
                }
            }
            
            // Weekly distance
            VStack(alignment: .leading, spacing: 8) {
                Text("¿Cuántos km nadas por semana?")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                HStack {
                    TextField("3", text: $weeklyKm)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 80)
                    Text("km/semana")
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .onChange(of: weeklyKm) { _ in
                    if let km = Double(weeklyKm) {
                        data.weeklySwimmingKm = km
                    }
                }
            }
        }
        .onAppear {
            loadSwimmingData()
        }
    }
    
    private func updateSwimmingTimes() {
        guard let minutes = Int(current100mMinutes),
              let seconds = Int(current100mSeconds) else { return }
        data.current100mFreeTime = TimeInterval(minutes * 60 + seconds)
    }
    
    private func loadSwimmingData() {
        if let time = data.current100mFreeTime {
            current100mMinutes = String(Int(time) / 60)
            current100mSeconds = String(Int(time) % 60)
        }
        if let km = data.weeklySwimmingKm {
            weeklyKm = String(km)
        }
        favoriteStroke = data.favoriteStroke ?? "Libre"
    }
}

// MARK: - Cycling Performance Questions
struct CyclingPerformanceQuestions: View {
    @Binding var data: SportPerformanceData
    @State private var current20kmMinutes = ""
    @State private var current20kmSeconds = ""
    @State private var weeklyKm = ""
    @State private var ftp = ""
    @State private var bikeType = "Carretera"
    
    private let bikeTypes = ["Carretera", "Montaña", "Triatlón", "Híbrida"]
    
    var body: some View {
        VStack(spacing: 16) {
            // 20km Time
            VStack(alignment: .leading, spacing: 8) {
                Text("¿Cuál es tu tiempo en 20km?")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                HStack {
                    TextField("35", text: $current20kmMinutes)
                        .keyboardType(.numberPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 60)
                    Text(":")
                    TextField("00", text: $current20kmSeconds)
                        .keyboardType(.numberPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 60)
                    Text("(min:seg)")
                        .foregroundColor(.secondary)
                        .font(.caption)
                    Spacer()
                }
                .onChange(of: current20kmMinutes) { _ in updateCyclingTimes() }
                .onChange(of: current20kmSeconds) { _ in updateCyclingTimes() }
            }
            
            // Bike type
            VStack(alignment: .leading, spacing: 8) {
                Text("¿Qué tipo de bicicleta usas?")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Picker("Tipo", selection: $bikeType) {
                    ForEach(bikeTypes, id: \.self) { type in
                        Text(type).tag(type)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .onChange(of: bikeType) { _ in
                    data.bikeType = bikeType
                }
            }
            
            // Weekly distance
            VStack(alignment: .leading, spacing: 8) {
                Text("¿Cuántos km pedaleas por semana?")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                HStack {
                    TextField("100", text: $weeklyKm)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 80)
                    Text("km/semana")
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .onChange(of: weeklyKm) { _ in
                    if let km = Double(weeklyKm) {
                        data.weeklyCyclingKm = km
                    }
                }
            }
        }
        .onAppear {
            loadCyclingData()
        }
    }
    
    private func updateCyclingTimes() {
        guard let minutes = Int(current20kmMinutes),
              let seconds = Int(current20kmSeconds) else { return }
        data.current20kmTime = TimeInterval(minutes * 60 + seconds)
    }
    
    private func loadCyclingData() {
        if let time = data.current20kmTime {
            current20kmMinutes = String(Int(time) / 60)
            current20kmSeconds = String(Int(time) % 60)
        }
        if let km = data.weeklyCyclingKm {
            weeklyKm = String(km)
        }
        bikeType = data.bikeType ?? "Carretera"
    }
}

// MARK: - Triathlon Performance Questions
struct TriathlonPerformanceQuestions: View {
    @Binding var data: SportPerformanceData
    @State private var sprintTriHours = ""
    @State private var sprintTriMinutes = ""
    @State private var hasTriExperience = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Triathlon experience
            Button(action: {
                hasTriExperience.toggle()
            }) {
                HStack {
                    Image(systemName: hasTriExperience ? "checkmark.square.fill" : "square")
                        .foregroundColor(hasTriExperience ? .accentColor : .secondary)
                    Text("He completado un triatlón antes")
                    Spacer()
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            if hasTriExperience {
                VStack(alignment: .leading, spacing: 8) {
                    Text("¿Cuál fue tu tiempo en triatlón sprint?")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    HStack {
                        TextField("1", text: $sprintTriHours)
                            .keyboardType(.numberPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 60)
                        Text("h")
                        TextField("30", text: $sprintTriMinutes)
                            .keyboardType(.numberPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 60)
                        Text("min")
                        Spacer()
                    }
                    .onChange(of: sprintTriHours) { _ in updateTriathlonTimes() }
                    .onChange(of: sprintTriMinutes) { _ in updateTriathlonTimes() }
                }
            }
            
            Text("💡 Para triatlón, también usaremos la información de running, natación y ciclismo que proporciones")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.blue.opacity(0.1))
                )
        }
        .onAppear {
            loadTriathlonData()
        }
    }
    
    private func updateTriathlonTimes() {
        guard let hours = Int(sprintTriHours),
              let minutes = Int(sprintTriMinutes) else { return }
        data.currentSprintTriTime = TimeInterval(hours * 3600 + minutes * 60)
    }
    
    private func loadTriathlonData() {
        if let time = data.currentSprintTriTime {
            sprintTriHours = String(Int(time) / 3600)
            sprintTriMinutes = String((Int(time) % 3600) / 60)
            hasTriExperience = true
        }
    }
}

#Preview {
    PhysicalOnboardingView()
}
