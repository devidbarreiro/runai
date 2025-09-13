//
//  AddWorkoutView.swift
//  runai
//
//  Created by David Barreiro on 11/09/25.
//

import SwiftUI

struct AddWorkoutView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var dataManager = DataManager.shared
    
    let selectedDate: Date
    
    @State private var kilometers: String = ""
    @State private var selectedType: WorkoutType = .longRun
    @State private var notes: String = ""
    @State private var workoutDate: Date
    @State private var showingDatePicker = false
    
    init(selectedDate: Date) {
        self.selectedDate = selectedDate
        self._workoutDate = State(initialValue: selectedDate)
    }
    
    private var isValidWorkout: Bool {
        !kilometers.isEmpty && Double(kilometers) != nil && Double(kilometers)! > 0
    }
    
    private var saveButtonText: String {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let selectedDay = calendar.startOfDay(for: workoutDate)
        
        if selectedDay > today {
            return "Planificar Entrenamiento"
        } else if selectedDay == today {
            return "Registrar Entrenamiento"
        } else {
            return "Guardar Entrenamiento"
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.blue)
                        
                        Text("Nuevo Entrenamiento")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Planifica tu próxima sesión o registra una pasada")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)
                    
                    VStack(spacing: 20) {
                        // Date selection
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Fecha")
                                .font(.headline)
                                .fontWeight(.medium)
                            
                            Button(action: {
                                showingDatePicker = true
                            }) {
                                HStack {
                                    Image(systemName: "calendar")
                                        .foregroundColor(.blue)
                                    
                                    Text(formatDate(workoutDate))
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.down")
                                        .foregroundColor(.secondary)
                                        .font(.caption)
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(.systemGray6))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color(.systemGray4), lineWidth: 1)
                                )
                            }
                        }
                        
                        // Workout type selection
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Tipo de entrenamiento")
                                .font(.headline)
                                .fontWeight(.medium)
                            
                            HStack(spacing: 12) {
                                ForEach(WorkoutType.allCases, id: \.self) { type in
                                    WorkoutTypeButton(
                                        type: type,
                                        isSelected: selectedType == type,
                                        action: { selectedType = type }
                                    )
                                }
                                
                                Spacer()
                            }
                        }
                        
                        // Kilometers input
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Kilómetros")
                                .font(.headline)
                                .fontWeight(.medium)
                            
                            HStack {
                                Image(systemName: "ruler")
                                    .foregroundColor(.secondary)
                                    .frame(width: 20)
                                
                                TextField("0.0", text: $kilometers)
                                    .keyboardType(.decimalPad)
                                    .textFieldStyle(PlainTextFieldStyle())
                                
                                Text("km")
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemGray6))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(.systemGray4), lineWidth: 1)
                            )
                        }
                        
                        // Notes input
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notas (opcional)")
                                .font(.headline)
                                .fontWeight(.medium)
                            
                            HStack(alignment: .top) {
                                Image(systemName: "note.text")
                                    .foregroundColor(.secondary)
                                    .frame(width: 20)
                                    .padding(.top, 2)
                                
                                TextField("Cómo te sentiste, condiciones del tiempo, etc.", text: $notes, axis: .vertical)
                                    .textFieldStyle(PlainTextFieldStyle())
                                    .lineLimit(3...6)
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemGray6))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(.systemGray4), lineWidth: 1)
                            )
                        }
                    }
                    
                    // Action buttons
                    VStack(spacing: 12) {
                        Button(action: saveWorkout) {
                            Text(saveButtonText)
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(isValidWorkout ? Color.blue : Color.gray)
                                )
                        }
                        .disabled(!isValidWorkout)
                        
                        Button(action: {
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Text("Cancelar")
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.top, 20)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingDatePicker) {
                DatePickerView(selectedDate: $workoutDate)
            }
        }
    }
    
    private func saveWorkout() {
        guard let km = Double(kilometers), km > 0 else { return }
        
        let workout = Workout(
            date: workoutDate,
            kilometers: km,
            type: selectedType,
            notes: notes.isEmpty ? nil : notes
        )
        
        dataManager.addWorkout(workout)
        presentationMode.wrappedValue.dismiss()
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.locale = Locale(identifier: "es_ES")
        return formatter.string(from: date)
    }
}

struct WorkoutTypeButton: View {
    let type: WorkoutType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(type.emoji)
                    .font(.title2)
                
                Text(type.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .frame(width: 80, height: 80)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color(.systemGray4), lineWidth: isSelected ? 2 : 1)
            )
        }
        .foregroundColor(isSelected ? .blue : .primary)
    }
}

struct DatePickerView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var selectedDate: Date
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(spacing: 8) {
                    Text("Selecciona cualquier fecha")
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    Text("Planifica entrenamientos futuros o registra sesiones pasadas")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top)
                
                DatePicker(
                    "Selecciona la fecha",
                    selection: $selectedDate,
                    displayedComponents: [.date]
                )
                .datePickerStyle(GraphicalDatePickerStyle())
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("¿Cuándo entrenas?")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancelar") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Confirmar") {
                    presentationMode.wrappedValue.dismiss()
                }
                .fontWeight(.semibold)
            )
        }
    }
}

#Preview {
    AddWorkoutView(selectedDate: Date())
}
