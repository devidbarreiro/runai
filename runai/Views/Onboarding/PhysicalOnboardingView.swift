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
    
    private let totalSteps = 6
    
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
                            fitnessLevelStep
                        case 2:
                            fiveKTimeStep
                        case 3:
                            raceGoalStep
                        case 4:
                            raceDateStep
                        case 5:
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
    
    private var fiveKTimeStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Tiempo actual en 5K")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Esta información nos ayuda a calibrar tu plan de entrenamiento")
                    .foregroundColor(.secondary)
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
            return fitnessLevel != nil
        case 2:
            return true // Always can proceed from 5K time step
        case 3:
            return targetRace != nil
        case 4:
            return true // Date is always valid
        case 5:
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


#Preview {
    PhysicalOnboardingView()
}
