//
//  OpenAIService.swift
//  runai
//
//  Created by David Barreiro on 13/09/2025.
//

import Foundation
import Combine
import os.log

class OpenAIService: ObservableObject {
    static let shared = OpenAIService()
    
    private let baseURL = "https://api.openai.com/v1/chat/completions"
    private let logger = Logger(subsystem: "com.runai.app", category: "OpenAI")
    private var apiKey: String {
        // TODO: Configure your OpenAI API key
        // Option 1: Set in Info.plist
        // Option 2: Use environment variable
        // Option 3: Store in secure keychain
        return Bundle.main.object(forInfoDictionaryKey: "OPENAI_API_KEY") as? String ?? "YOUR_OPENAI_API_KEY_HERE"
    }
    
    @Published var isGenerating = false
    @Published var lastError: String?
    
    private init() {}
    
    enum OpenAIError: Error {
        case invalidURL
        case noData
        case decodingError
        case networkError(Error)
        case invalidResponse
        case missingAPIKey
        case insufficientSubscription
        case quotaExceeded
    }
    
    // MARK: - Training Plan Generation
    
    func generateTrainingPlan(for user: User) -> AnyPublisher<[Workout], Error> {
        logger.info("🚀 Starting training plan generation for user: \(user.name), primary sport: \(user.primarySport.displayName)")
        
        // Check if user can use AI coaching
        guard SubscriptionService.shared.canUseFeature(.unlimitedAICoaching) else {
            logger.warning("⚠️ User doesn't have access to unlimited AI coaching")
            return Fail(error: OpenAIError.insufficientSubscription)
                .eraseToAnyPublisher()
        }
        
        // Track AI usage
        guard SubscriptionService.shared.trackAIQuery() else {
            logger.warning("⚠️ User has reached AI query limit")
            return Fail(error: OpenAIError.quotaExceeded)
                .eraseToAnyPublisher()
        }
        
        // Delegate to MultiSportAIService based on user's primary sport and preferences
        let multiSportService = MultiSportAIService.shared
        
        // If user has multiple sports or triathlon as primary, use triathlon orchestrator
        if user.preferredSports.count > 1 || user.primarySport == .triathlon {
            logger.info("🏊‍♂️🚴‍♂️🏃‍♂️ Generating triathlon plan")
            return multiSportService.generateTriathlonPlan(for: user, weeks: 12)
        }
        
        // Otherwise, use specialized agent for primary sport
        switch user.primarySport {
        case .running:
            logger.info("🏃‍♂️ Generating running plan")
            return multiSportService.generateRunningPlan(for: user, weeks: 12)
        case .swimming:
            logger.info("🏊‍♂️ Generating swimming plan")
            return multiSportService.generateSwimmingPlan(for: user, weeks: 12)
        case .cycling:
            logger.info("🚴‍♂️ Generating cycling plan")
            return multiSportService.generateCyclingPlan(for: user, weeks: 12)
        case .triathlon:
            logger.info("🏊‍♂️🚴‍♂️🏃‍♂️ Generating triathlon plan")
            return multiSportService.generateTriathlonPlan(for: user, weeks: 12)
        }
        
        // Legacy fallback (this code should not be reached)
        guard apiKey != "YOUR_OPENAI_API_KEY_HERE" else {
            logger.error("❌ OpenAI API key not configured")
            return Fail(error: OpenAIError.missingAPIKey)
                .eraseToAnyPublisher()
        }
        
        isGenerating = true
        lastError = nil
        
        let prompt = createTrainingPlanPrompt(for: user)
        
        return makeOpenAIRequest(prompt: prompt)
            .map { [weak self] response in
                self?.logger.info("📥 Received response from OpenAI - Status: 200")
                return self?.parseOpenAIResponse(response) ?? []
            }
            .catch { [weak self] error -> AnyPublisher<[Workout], Error> in
                self?.logger.error("❌ OpenAI request failed: \(error.localizedDescription)")
                self?.lastError = error.localizedDescription
                
                return Fail(error: error)
                    .eraseToAnyPublisher()
            }
            .handleEvents(
                receiveCompletion: { [weak self] _ in
                    self?.isGenerating = false
                },
                receiveCancel: { [weak self] in
                    self?.isGenerating = false
                }
            )
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    private func createTrainingPlanPrompt(for user: User) -> String {
        let currentDate = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let todayString = formatter.string(from: currentDate)
        
        let _ = formatter.string(from: Calendar.current.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate)
        
        let systemPrompt = """
        Eres un entrenador personal especializado en running. Tu tarea es crear un plan de entrenamiento personalizado basado en los datos del usuario.
        
        Datos del usuario:
        - Nombre: \(user.name)
        - Edad: \(user.age ?? 25) años
        - Peso: \(user.weight ?? 70.0) kg
        - Altura: \(user.height ?? 175.0) cm
        - Nivel de fitness: \(user.fitnessLevel?.description ?? "Intermedio")
        - Tiempo actual en 5K: \(user.current5kTime != nil ? String(format: "%.0f minutos", (user.current5kTime! / 60)) : "No especificado")
        - Objetivo de carrera: \(user.targetRace?.displayName ?? "Media maratón")
        - Fecha objetivo: \(user.raceDate != nil ? formatter.string(from: user.raceDate!) : "No especificada")
        
        Fecha actual: \(todayString)
        
        Instrucciones:
        1. Crea un plan de entrenamiento progresivo y realista
        2. Incluye variedad: carreras fáciles, largas, intervalos, tempo, recuperación y descansos
        3. Progresión gradual en distancia e intensidad
        4. Considera el nivel actual del usuario
        5. Incluye días de descanso para prevenir lesiones
        
        Genera entrenamientos para las próximas 4 semanas, comenzando desde mañana.
        
        IMPORTANTE: Responde ÚNICAMENTE con un JSON válido en este formato exacto:
        
        {
          "training_plan": [
            {
              "day": "2025-09-15",
              "type": "Easy Run",
              "distance_km": 5,
              "notes": "Ritmo cómodo, enfócate en la forma y respiración."
            },
            {
              "day": "2025-09-16",
              "type": "Rest",
              "distance_km": 0,
              "notes": "Descanso completo o estiramientos suaves."
            }
          ]
        }
        
        Tipos de entrenamiento disponibles:
        - "Easy Run" (carrera fácil)
        - "Long Run" (carrera larga)
        - "Intervals" (intervalos)
        - "Tempo Run" (carrera tempo)
        - "Recovery Run" (carrera de recuperación)
        - "Rest" (descanso)
        - "Race Day" (día de carrera)
        
        Usa distancias realistas según el nivel del usuario y progresión gradual.
        """
        
        return systemPrompt
    }
    
    private func makeOpenAIRequest(prompt: String) -> AnyPublisher<OpenAIResponse, Error> {
        logger.debug("🌐 Preparing OpenAI API request")
        
        guard let url = URL(string: self.baseURL) else {
            logger.error("❌ Invalid OpenAI URL: \(self.baseURL)")
            return Fail(error: OpenAIError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody = OpenAIRequest(
            model: "gpt-4",
            messages: [
                OpenAIMessage(role: "user", content: prompt)
            ],
            temperature: 0.7,
            maxTokens: 2000
        )
        
        do {
            let jsonData = try JSONEncoder().encode(requestBody)
            request.httpBody = jsonData
            
            logger.debug("📋 Request body prepared")
            logger.info("📡 Sending request to OpenAI API")
            
        } catch {
            logger.error("❌ Failed to encode request: \(error.localizedDescription)")
            return Fail(error: OpenAIError.networkError(error))
                .eraseToAnyPublisher()
        }
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: OpenAIResponse.self, decoder: JSONDecoder())
            .mapError { error in
                OpenAIError.networkError(error)
            }
            .eraseToAnyPublisher()
    }
    
    private func parseOpenAIResponse(_ response: OpenAIResponse) -> [Workout] {
        logger.debug("🔍 Parsing OpenAI response")
        
        guard let choice = response.choices.first else {
            logger.warning("⚠️ No content in OpenAI response")
            return []
        }
        
        let content = choice.message.content
        logger.debug("📋 Raw OpenAI response content: \(content)")
        
        // Try to extract JSON from the response
        guard let jsonData = content.data(using: .utf8) else {
            logger.error("❌ Failed to convert response to data")
            return []
        }
        
        do {
            let decoder = JSONDecoder()
            let trainingPlan = try decoder.decode(TrainingPlanResponse.self, from: jsonData)
            
            logger.info("✅ Successfully decoded training plan with \(trainingPlan.trainingPlan.count) entries")
            
            let workouts: [Workout] = trainingPlan.trainingPlan.compactMap { aiWorkout -> Workout? in
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                guard let date = dateFormatter.date(from: aiWorkout.day) else {
                    logger.warning("⚠️ Invalid date format: \(aiWorkout.day)")
                    return nil
                }
                
                // Skip rest days (distance 0)
                guard aiWorkout.distanceKm > 0 else {
                    logger.debug("⏭️ Skipping rest day: \(aiWorkout.day)")
                    return nil
                }
                
                // Map AI workout types to our WorkoutType enum
                let workoutType: WorkoutType
                switch aiWorkout.type.lowercased() {
                case "long run":
                    workoutType = .longRun
                case "intervals", "tempo run", "easy run", "recovery run", "race day":
                    workoutType = .series
                default:
                    workoutType = .longRun // Default fallback
                }
                
                logger.debug("🏃‍♂️ Creating workout: \(aiWorkout.type) - \(aiWorkout.distanceKm)km on \(aiWorkout.day)")
                
                return Workout(
                    date: date,
                    type: workoutType,
                    distance: aiWorkout.distanceKm,
                    notes: aiWorkout.notes
                )
            }
            
            logger.info("🎯 Final result: \(workouts.count) workouts created from training plan")
            logger.info("✅ Successfully parsed \(workouts.count) workouts from OpenAI response")
            logger.info("🎉 Training plan generation completed successfully")
            
            return workouts
            
        } catch {
            logger.error("❌ Failed to decode training plan: \(error.localizedDescription)")
            logger.debug("📋 Raw content that failed to decode: \(content)")
            return []
        }
    }
}

// MARK: - Data Models

struct OpenAIRequest: Codable {
    let model: String
    let messages: [OpenAIMessage]
    let temperature: Double
    let maxTokens: Int
    
    enum CodingKeys: String, CodingKey {
        case model, messages, temperature
        case maxTokens = "max_tokens"
    }
}

struct OpenAIMessage: Codable {
    let role: String
    let content: String
}

struct OpenAIResponse: Codable {
    let choices: [OpenAIChoice]
}

struct OpenAIChoice: Codable {
    let message: OpenAIMessage
}

struct TrainingPlanResponse: Codable {
    let trainingPlan: [AIWorkout]
    
    enum CodingKeys: String, CodingKey {
        case trainingPlan = "training_plan"
    }
}

struct AIWorkout: Codable {
    let day: String
    let type: String
    let distanceKm: Double
    let notes: String
    
    enum CodingKeys: String, CodingKey {
        case day, type, notes
        case distanceKm = "distance_km"
    }
}
