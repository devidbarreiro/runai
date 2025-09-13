//
//  TrainingPlanGeneratorView.swift
//  runai
//
//  Created by David Barreiro on 12/09/25.
//

import SwiftUI
import Combine

struct TrainingPlanGeneratorView: View {
    @ObservedObject var dataManager = DataManager.shared
    @ObservedObject var openAIService = OpenAIService.shared
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var cancellables = Set<AnyCancellable>()
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 60))
                        .foregroundColor(.accentColor)
                    
                    Text("Generar Plan de Entrenamiento")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Crearemos un plan personalizado usando IA basado en tu perfil y objetivos")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                // User summary
                if let user = dataManager.currentUser {
                    UserSummaryCard(user: user)
                }
                
                Spacer()
                
                // Generate button
                Button(action: generatePlan) {
                    HStack {
                        if openAIService.isGenerating {
                            ProgressView()
                                .scaleEffect(0.8)
                                .foregroundColor(.white)
                        } else {
                            Image(systemName: "sparkles")
                        }
                        
                        Text(openAIService.isGenerating ? "Generando plan..." : "Generar Plan con IA")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(openAIService.isGenerating ? Color.gray : Color.accentColor)
                    )
                }
                .disabled(openAIService.isGenerating || !canGeneratePlan)
                .padding(.horizontal)
                
                if !canGeneratePlan {
                    Text("⚠️ Completa tu perfil físico para generar un plan personalizado")
                        .font(.caption)
                        .foregroundColor(.orange)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cerrar") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
        .alert("Resultado", isPresented: $showingAlert) {
            Button("OK") {
                if alertMessage.contains("exitosamente") {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        } message: {
            Text(alertMessage)
        }
    }
    
    private var canGeneratePlan: Bool {
        guard let user = dataManager.currentUser else { return false }
        return user.age != nil && 
               user.weight != nil && 
               user.height != nil && 
               user.fitnessLevel != nil && 
               user.targetRace != nil && 
               user.raceDate != nil
    }
    
    private func generatePlan() {
        guard let user = dataManager.currentUser else {
            showAlert("Error: Usuario no encontrado")
            return
        }
        
        openAIService.generateTrainingPlan(for: user)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .failure(let error):
                        self.showAlert("Error generando el plan: \(error.localizedDescription)")
                    case .finished:
                        break
                    }
                },
                receiveValue: { workouts in
                    // Add generated workouts to data manager
                    for workout in workouts {
                        self.dataManager.addWorkout(workout)
                    }
                    
                    self.showAlert("¡Plan generado exitosamente! Se han añadido \(workouts.count) entrenamientos a tu calendario.")
                }
            )
            .store(in: &cancellables)
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

struct UserSummaryCard: View {
    let user: User
    
    private func formatDate(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.locale = Locale(identifier: "es_ES")
        return dateFormatter.string(from: date)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Tu Perfil")
                .font(.headline)
                .foregroundColor(.accentColor)
            
            VStack(spacing: 8) {
                if let age = user.age {
                    SummaryRow(icon: "person.circle", title: "Edad", value: "\(age) años")
                }
                
                if let weight = user.weight {
                    SummaryRow(icon: "scalemass", title: "Peso", value: String(format: "%.1f kg", weight))
                }
                
                if let height = user.height {
                    SummaryRow(icon: "ruler", title: "Altura", value: String(format: "%.0f cm", height))
                }
                
                if let fitnessLevel = user.fitnessLevel {
                    SummaryRow(icon: "figure.run", title: "Nivel", value: fitnessLevel.rawValue.capitalized)
                }
                
                if let current5kTime = user.current5kTime {
                    let minutes = Int(current5kTime) / 60
                    let seconds = Int(current5kTime) % 60
                    SummaryRow(icon: "timer", title: "Tiempo 5K", value: "\(minutes):\(String(format: "%02d", seconds))")
                }
                
                if let targetRace = user.targetRace {
                    SummaryRow(icon: "flag.checkered", title: "Objetivo", value: targetRace.displayName)
                }
                
                if let raceDate = user.raceDate {
                    SummaryRow(icon: "calendar", title: "Fecha carrera", value: formatDate(raceDate))
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
        )
        .padding(.horizontal)
    }
}

private struct SummaryRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.accentColor)
                .frame(width: 20)
            
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
