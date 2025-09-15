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
    
    @State private var selectedSport: SportType = .running
    @State private var distance: String = ""
    @State private var selectedType: WorkoutType = .longRun
    @State private var duration: String = ""
    @State private var intensity: String = "Moderate"
    @State private var notes: String = ""
    @State private var workoutDate: Date
    @State private var showingDatePicker = false
    
    // Swimming specific
    @State private var poolLength: Int = 25
    @State private var strokeType: String = "Freestyle"
    
    // Cycling specific
    @State private var elevation: String = ""
    @State private var avgPower: String = ""
    
    private let intensityOptions = ["Easy", "Moderate", "Hard", "Race"]
    private let strokeTypes = ["Freestyle", "Backstroke", "Breaststroke", "Butterfly", "Mixed"]
    
    init(selectedDate: Date) {
        self.selectedDate = selectedDate
        self._workoutDate = State(initialValue: selectedDate)
        
        // Initialize with user's primary sport if available
        if let user = DataManager.shared.currentUser {
            self._selectedSport = State(initialValue: user.primarySport)
            self._selectedType = State(initialValue: WorkoutType.typesFor(sport: user.primarySport).first ?? .longRun)
        }
    }
    
    private var isValidWorkout: Bool {
        !distance.isEmpty && Double(distance) != nil && Double(distance)! > 0
    }
    
    private var distanceLabel: String {
        switch selectedSport {
        case .swimming:
            return "Distancia"
        case .running, .cycling:
            return "Kilómetros"
        case .triathlon:
            return "Distancia Total"
        }
    }
    
    private var distancePlaceholder: String {
        switch selectedSport {
        case .swimming:
            return "1500"
        case .running:
            return "5.0"
        case .cycling:
            return "30.0"
        case .triathlon:
            return "25.0"
        }
    }
    
    private var distanceUnit: String {
        switch selectedSport {
        case .swimming:
            return "m"
        case .running, .cycling, .triathlon:
            return "km"
        }
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
                        
                        // Sport selection
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Deporte")
                                .font(.headline)
                                .fontWeight(.medium)
                            
                            HStack(spacing: 12) {
                                ForEach(SportType.allCases, id: \.self) { sport in
                                    Button(action: {
                                        selectedSport = sport
                                        // Update workout type to match sport
                                        let availableTypes = WorkoutType.typesFor(sport: sport)
                                        if !availableTypes.contains(selectedType) {
                                            selectedType = availableTypes.first ?? .longRun
                                        }
                                    }) {
                                        HStack(spacing: 8) {
                                            Text(sport.emoji)
                                                .font(.title2)
                                            Text(sport.displayName)
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 12)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(selectedSport == sport ? Color.blue : Color(.systemGray6))
                                        )
                                        .foregroundColor(selectedSport == sport ? .white : .primary)
                                    }
                                }
                            }
                        }
                        
                        // Workout type selection
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Tipo de entrenamiento")
                                .font(.headline)
                                .fontWeight(.medium)
                            
                            HStack(spacing: 12) {
                                ForEach(WorkoutType.typesFor(sport: selectedSport), id: \.self) { type in
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
                            Text(distanceLabel)
                                .font(.headline)
                                .fontWeight(.medium)
                            
                            HStack {
                                Image(systemName: "ruler")
                                    .foregroundColor(.secondary)
                                    .frame(width: 20)
                                
                                TextField(distancePlaceholder, text: $distance)
                                    .keyboardType(.decimalPad)
                                    .textFieldStyle(PlainTextFieldStyle())
                                
                                Text(distanceUnit)
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
                        
                        // Duration input
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Duración (opcional)")
                                .font(.headline)
                                .fontWeight(.medium)
                            
                            HStack {
                                Image(systemName: "clock")
                                    .foregroundColor(.secondary)
                                    .frame(width: 20)
                                
                                TextField("60", text: $duration)
                                    .keyboardType(.numberPad)
                                    .textFieldStyle(PlainTextFieldStyle())
                                
                                Text("min")
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
                        
                        // Intensity selection
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Intensidad")
                                .font(.headline)
                                .fontWeight(.medium)
                            
                            HStack(spacing: 8) {
                                ForEach(intensityOptions, id: \.self) { option in
                                    Button(action: {
                                        intensity = option
                                    }) {
                                        Text(option)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                            .background(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(intensity == option ? Color.blue : Color(.systemGray6))
                                            )
                                            .foregroundColor(intensity == option ? .white : .primary)
                                    }
                                }
                            }
                        }
                        
                        // Sport-specific fields
                        if selectedSport == .swimming {
                            VStack(spacing: 16) {
                                // Pool length
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Longitud de piscina")
                                        .font(.headline)
                                        .fontWeight(.medium)
                                    
                                    Picker("Pool Length", selection: $poolLength) {
                                        Text("25m").tag(25)
                                        Text("50m").tag(50)
                                    }
                                    .pickerStyle(SegmentedPickerStyle())
                                }
                                
                                // Stroke type
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Estilo principal")
                                        .font(.headline)
                                        .fontWeight(.medium)
                                    
                                    Picker("Stroke Type", selection: $strokeType) {
                                        ForEach(strokeTypes, id: \.self) { stroke in
                                            Text(stroke).tag(stroke)
                                        }
                                    }
                                    .pickerStyle(MenuPickerStyle())
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color(.systemGray6))
                                    )
                                }
                            }
                        }
                        
                        if selectedSport == .cycling {
                            VStack(spacing: 16) {
                                // Elevation
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Desnivel (opcional)")
                                        .font(.headline)
                                        .fontWeight(.medium)
                                    
                                    HStack {
                                        Image(systemName: "mountain.2")
                                            .foregroundColor(.secondary)
                                            .frame(width: 20)
                                        
                                        TextField("500", text: $elevation)
                                            .keyboardType(.numberPad)
                                            .textFieldStyle(PlainTextFieldStyle())
                                        
                                        Text("m")
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
                                
                                // Average power
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Potencia promedio (opcional)")
                                        .font(.headline)
                                        .fontWeight(.medium)
                                    
                                    HStack {
                                        Image(systemName: "bolt")
                                            .foregroundColor(.secondary)
                                            .frame(width: 20)
                                        
                                        TextField("200", text: $avgPower)
                                            .keyboardType(.numberPad)
                                            .textFieldStyle(PlainTextFieldStyle())
                                        
                                        Text("W")
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
                            }
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
        guard let dist = Double(distance), dist > 0 else { return }
        
        // Convert distance to km for swimming (input is in meters)
        let distanceInKm = selectedSport == .swimming ? dist / 1000 : dist
        
        // Convert duration to seconds
        let durationInSeconds = Double(duration).map { $0 * 60 }
        
        let workout = Workout(
            date: workoutDate,
            type: selectedType,
            distance: distanceInKm,
            duration: durationInSeconds,
            intensity: intensity,
            notes: notes.isEmpty ? nil : notes,
            poolLength: selectedSport == .swimming ? poolLength : nil,
            strokeType: selectedSport == .swimming ? strokeType : nil,
            elevation: selectedSport == .cycling ? Double(elevation) : nil,
            avgPower: selectedSport == .cycling ? Int(avgPower) : nil
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
