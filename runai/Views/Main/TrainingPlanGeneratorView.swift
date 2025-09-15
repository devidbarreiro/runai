//
//  TrainingPlanGeneratorView.swift
//  runai
//
//  Created by David Barreiro on 12/09/25.
//

import SwiftUI
import Combine

enum PlanGenerationStep: Int, CaseIterable {
    case sportSelection = 0
    case raceGoalSelection = 1
    case planCustomization = 2
    case generation = 3
}

struct TrainingPlanGeneratorView: View {
    @ObservedObject var dataManager = DataManager.shared
    @ObservedObject var openAIService = OpenAIService.shared
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var cancellables = Set<AnyCancellable>()
    @Environment(\.presentationMode) var presentationMode
    
    // Sport selection
    @State private var selectedSport: SportType?
    @State private var selectedRaceType: RaceType?
    @State private var planWeeks: Int = 12
    @State private var currentStep: PlanGenerationStep = .sportSelection
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Progress indicator
                ProgressView(value: Double(currentStep.rawValue), total: Double(PlanGenerationStep.allCases.count - 1))
                    .progressViewStyle(LinearProgressViewStyle())
                    .scaleEffect(x: 1, y: 2)
                    .padding(.horizontal)
                    .padding(.top)
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Step content
                        Group {
                            switch currentStep {
                            case .sportSelection:
                                sportSelectionStep
                            case .raceGoalSelection:
                                raceGoalSelectionStep
                            case .planCustomization:
                                planCustomizationStep
                            case .generation:
                                generationStep
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        Spacer(minLength: 100)
                    }
                }
                
                // Navigation buttons
                HStack(spacing: 16) {
                    if currentStep != .sportSelection {
                        Button("Anterior") {
                            withAnimation {
                                previousStep()
                            }
                        }
                        .buttonStyle(SecondaryButtonStyle())
                    }
                    
                    Spacer()
                    
                    Button(nextButtonTitle) {
                        if currentStep == .generation {
                            generatePlan()
                        } else {
                            withAnimation {
                                nextStep()
                            }
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(!canProceed)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
            }
            .navigationTitle("Plan IA")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: Button("Cerrar") {
                presentationMode.wrappedValue.dismiss()
            })
            .alert(isPresented: $showingAlert) {
                Alert(
                    title: Text("Resultado"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK")) {
                        if alertMessage.contains("exitosamente") {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                )
            }
        }
        .onAppear {
            setupInitialState()
        }
    }
    
    // MARK: - Step Views
    
    private var sportSelectionStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("¿Para qué deporte quieres el plan?")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Selecciona el deporte principal para tu plan de entrenamiento")
                    .foregroundColor(.secondary)
                    .font(.subheadline)
            }
            
            // Sport selection grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(availableSports, id: \.self) { sport in
                    SportSelectionButton(
                        sport: sport,
                        isSelected: selectedSport == sport,
                        onTap: {
                            withAnimation(.spring(response: 0.3)) {
                                selectedSport = sport
                            }
                        }
                    )
                }
            }
        }
    }
    
    private var raceGoalSelectionStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("¿Cuál es tu objetivo?")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Selecciona el tipo de carrera para la que quieres entrenar")
                    .foregroundColor(.secondary)
                    .font(.subheadline)
            }
            
            // Race type selection
            VStack(spacing: 12) {
                ForEach(availableRaceTypes, id: \.self) { raceType in
                    RaceTypeSelectionButton(
                        raceType: raceType,
                        isSelected: selectedRaceType == raceType,
                        onTap: {
                            withAnimation(.spring(response: 0.3)) {
                                selectedRaceType = raceType
                            }
                        }
                    )
                }
            }
        }
    }
    
    private var planCustomizationStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Personaliza tu plan")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Ajusta los detalles de tu plan de entrenamiento")
                    .foregroundColor(.secondary)
                    .font(.subheadline)
            }
            
            VStack(spacing: 20) {
                // Plan duration
                VStack(alignment: .leading, spacing: 12) {
                    Text("Duración del plan")
                        .font(.headline)
                    
                    HStack(spacing: 12) {
                        ForEach([8, 12, 16, 20], id: \.self) { weeks in
                            Button(action: {
                                planWeeks = weeks
                            }) {
                                Text("\(weeks) semanas")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 20)
                                            .fill(planWeeks == weeks ? Color.blue : Color(.systemGray6))
                                    )
                                    .foregroundColor(planWeeks == weeks ? .white : .primary)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                
                // User summary
                if let user = dataManager.currentUser {
                    UserSummaryCard(user: user)
                }
            }
        }
    }
    
    private var generationStep: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 12) {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 60))
                    .foregroundColor(.accentColor)
                
                Text("Generar Plan de Entrenamiento")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Crearemos un plan personalizado usando IA")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Plan summary
            VStack(spacing: 16) {
                PlanSummaryRow(title: "Deporte", value: selectedSport?.displayName ?? "")
                PlanSummaryRow(title: "Objetivo", value: selectedRaceType?.displayName ?? "")
                PlanSummaryRow(title: "Duración", value: "\(planWeeks) semanas")
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemGray6))
            )
            
            if openAIService.isGenerating {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.2)
                    
                    Text("Generando tu plan personalizado...")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .padding()
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var availableSports: [SportType] {
        guard let user = dataManager.currentUser else { return SportType.allCases }
        return user.preferredSports.isEmpty ? SportType.allCases : user.preferredSports
    }
    
    private var availableRaceTypes: [RaceType] {
        guard let sport = selectedSport else { return [] }
        return RaceType.allCases.filter { $0.sport == sport }
    }
    
    private var nextButtonTitle: String {
        switch currentStep {
        case .sportSelection:
            return "Siguiente"
        case .raceGoalSelection:
            return "Siguiente"
        case .planCustomization:
            return "Siguiente"
        case .generation:
            return openAIService.isGenerating ? "Generando..." : "Generar Plan con IA"
        }
    }
    
    private var canProceed: Bool {
        switch currentStep {
        case .sportSelection:
            return selectedSport != nil
        case .raceGoalSelection:
            return selectedRaceType != nil
        case .planCustomization:
            return true
        case .generation:
            return !openAIService.isGenerating && canGeneratePlan
        }
    }
    
    private var canGeneratePlan: Bool {
        guard let user = dataManager.currentUser else { return false }
        return user.hasCompletedPhysicalOnboarding
    }
    
    // MARK: - Actions
    
    private func setupInitialState() {
        guard let user = dataManager.currentUser else { return }
        selectedSport = user.primarySport
    }
    
    private func nextStep() {
        guard let nextStep = PlanGenerationStep(rawValue: currentStep.rawValue + 1) else { return }
        currentStep = nextStep
    }
    
    private func previousStep() {
        guard let previousStep = PlanGenerationStep(rawValue: currentStep.rawValue - 1) else { return }
        currentStep = previousStep
    }
    
    private func generatePlan() {
        guard let user = dataManager.currentUser,
              let sport = selectedSport,
              let raceType = selectedRaceType else {
            showAlert("Error: Información incompleta")
            return
        }
        
        // Create a temporary user with selected race type for plan generation
        var tempUser = user
        tempUser.targetRace = raceType
        tempUser.primarySport = sport
        
        openAIService.generateTrainingPlan(for: tempUser)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        self.showAlert("Error generando el plan: \(error.localizedDescription)")
                    }
                },
                receiveValue: { workouts in
                    for workout in workouts {
                        self.dataManager.addWorkout(workout)
                    }
                    self.showAlert("¡Plan generado exitosamente! Se han añadido \(workouts.count) entrenamientos.")
                }
            )
            .store(in: &cancellables)
    }
    
    private func showAlert(_ message: String) {
        alertMessage = message
        showingAlert = true
    }
}

// MARK: - Supporting Views

struct SportSelectionButton: View {
    let sport: SportType
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color(sport.color).opacity(0.2) : Color(.systemGray6))
                        .frame(width: 60, height: 60)
                    
                    Text(sport.emoji)
                        .font(.title)
                }
                
                Text(sport.displayName)
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color(sport.color).opacity(0.1) : Color(.systemGray6))
                    .stroke(isSelected ? Color(sport.color) : Color.clear, lineWidth: 2)
            )
            .overlay(
                VStack {
                    HStack {
                        Spacer()
                        if isSelected {
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

struct RaceTypeSelectionButton: View {
    let raceType: RaceType
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(raceType.emoji)
                            .font(.title2)
                        Text(raceType.displayName)
                            .font(.headline)
                            .fontWeight(.medium)
                        Spacer()
                    }
                    
                    Text("\(raceType.distance, specifier: "%.1f") km")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title3)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct UserSummaryCard: View {
    let user: User
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Tu Perfil")
                .font(.headline)
            
            VStack(spacing: 12) {
                if let age = user.age {
                    PlanSummaryRow(title: "Edad", value: "\(age) años")
                }
                
                if let fitnessLevel = user.fitnessLevel {
                    PlanSummaryRow(title: "Nivel", value: fitnessLevel.rawValue.capitalized)
                }
                
                if let current5k = user.current5kTime {
                    let minutes = Int(current5k) / 60
                    let seconds = Int(current5k) % 60
                    PlanSummaryRow(title: "5K actual", value: String(format: "%d:%02d", minutes, seconds))
                }
                
                PlanSummaryRow(title: "Deportes", value: user.preferredSports.map { $0.displayName }.joined(separator: ", "))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
        )
    }
}

struct PlanSummaryRow: View {
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

#Preview {
    TrainingPlanGeneratorView()
}