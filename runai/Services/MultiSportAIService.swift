//
//  MultiSportAIService.swift
//  runai
//
//  Multi-sport AI coaching service with specialized agents
//

import Foundation
import Combine

class MultiSportAIService: ObservableObject {
    static let shared = MultiSportAIService()
    
    @Published var isLoading = false
    @Published var lastError: String?
    
    private let baseURL = "http://localhost:5678/webhook-test"
    private var cancellables = Set<AnyCancellable>()
    
    private init() {}
    
    // MARK: - Specialized Agents
    
    func generateRunningPlan(for user: User, weeks: Int = 12) -> AnyPublisher<[Workout], Error> {
        let agent = RunningAgent()
        return callAgent(agent: agent, user: user, weeks: weeks)
    }
    
    func generateSwimmingPlan(for user: User, weeks: Int = 12) -> AnyPublisher<[Workout], Error> {
        let agent = SwimmingAgent()
        return callAgent(agent: agent, user: user, weeks: weeks)
    }
    
    func generateCyclingPlan(for user: User, weeks: Int = 12) -> AnyPublisher<[Workout], Error> {
        let agent = CyclingAgent()
        return callAgent(agent: agent, user: user, weeks: weeks)
    }
    
    func generateTriathlonPlan(for user: User, weeks: Int = 12) -> AnyPublisher<[Workout], Error> {
        let orchestrator = TriathlonOrchestrator()
        return callTriathlonOrchestrator(orchestrator: orchestrator, user: user, weeks: weeks)
    }
    
    // MARK: - Agent Communication
    
    private func callAgent(agent: SportAgent, user: User, weeks: Int) -> AnyPublisher<[Workout], Error> {
        isLoading = true
        lastError = nil
        
        let prompt = agent.generatePrompt(for: user, weeks: weeks)
        let endpoint = agent.endpoint
        
        return sendRequest(to: endpoint, prompt: prompt)
            .handleEvents(
                receiveCompletion: { [weak self] _ in
                    self?.isLoading = false
                },
                receiveCancel: { [weak self] in
                    self?.isLoading = false
                }
            )
            .eraseToAnyPublisher()
    }
    
    private func callTriathlonOrchestrator(orchestrator: TriathlonOrchestrator, user: User, weeks: Int) -> AnyPublisher<[Workout], Error> {
        isLoading = true
        lastError = nil
        
        // The orchestrator coordinates with all three specialized agents
        return orchestrator.generateTriathlonPlan(for: user, weeks: weeks, service: self)
            .handleEvents(
                receiveCompletion: { [weak self] _ in
                    self?.isLoading = false
                },
                receiveCancel: { [weak self] in
                    self?.isLoading = false
                }
            )
            .eraseToAnyPublisher()
    }
    
    internal func sendRequest(to endpoint: String, prompt: String) -> AnyPublisher<[Workout], Error> {
        guard let url = URL(string: "\(baseURL)/\(endpoint)") else {
            return Fail(error: AIServiceError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody = MultiSportChatRequest(message: prompt)
        
        do {
            request.httpBody = try JSONEncoder().encode(requestBody)
        } catch {
            return Fail(error: error)
                .eraseToAnyPublisher()
        }
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: MultiSportChatResponse.self, decoder: JSONDecoder())
            .map { response in
                // Parse the AI response and convert to workouts
                return self.parseWorkoutsFromResponse(response.response)
            }
            .catch { error in
                Just([Workout]())
                    .setFailureType(to: Error.self)
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
    private func parseWorkoutsFromResponse(_ response: String) -> [Workout] {
        // This is a simplified parser - in production you'd want more robust parsing
        // For now, return sample workouts based on the response
        let calendar = Calendar.current
        let today = Date()
        
        var workouts: [Workout] = []
        
        // Generate sample workouts for the next 4 weeks
        for week in 0..<4 {
            for day in [1, 3, 5] { // Mon, Wed, Fri
                let workoutDate = calendar.date(byAdding: .day, value: week * 7 + day, to: today) ?? today
                
                let workout = Workout(
                    date: workoutDate,
                    type: .longRun, // This would be determined by parsing the AI response
                    distance: Double.random(in: 5...15),
                    duration: Double.random(in: 30...90) * 60,
                    intensity: "Moderate",
                    notes: "Generated by AI Coach"
                )
                
                workouts.append(workout)
            }
        }
        
        return workouts
    }
}

// MARK: - Supporting Types

struct MultiSportChatRequest: Codable {
    let message: String
}

struct MultiSportChatResponse: Codable {
    let response: String
}

enum AIServiceError: Error {
    case invalidURL
    case noData
    case parsingError
}

// MARK: - Sport Agents Protocol

protocol SportAgent {
    var sport: SportType { get }
    var endpoint: String { get }
    
    func generatePrompt(for user: User, weeks: Int) -> String
}

// MARK: - Running Agent

struct RunningAgent: SportAgent {
    let sport: SportType = .running
    let endpoint: String = "running-coach"
    
    func generatePrompt(for user: User, weeks: Int) -> String {
        let fitnessLevel = user.fitnessLevel?.rawValue ?? "intermediate"
        let targetRace = user.targetRace?.displayName ?? "10K"
        let current5k = user.current5kTime != nil ? String(format: "%.0f minutos", user.current5kTime! / 60) : "No especificado"
        
        return """
        Eres el mejor entrenador personal de running del mundo especializado ÚNICAMENTE en running. 🏃‍♂️
        
        ## PERFIL DEL ATLETA:
        - Nombre: \(user.name)
        - Nivel de fitness: \(fitnessLevel)
        - Objetivo de carrera: \(targetRace)
        - Tiempo actual 5K: \(current5k)
        - Edad: \(user.age ?? 25) años
        - Peso: \(user.weight ?? 70) kg
        
        ## TU MISIÓN:
        Genera un plan de entrenamiento de running de \(weeks) semanas específicamente para este atleta.
        
        ## TIPOS DE ENTRENAMIENTOS DE RUNNING:
        - Carrera Larga (Long Run): Resistencia aeróbica
        - Series (Intervals): Velocidad y potencia
        - Tempo: Umbral anaeróbico
        - Intervalos: Velocidad y VO2 max
        - Recuperación: Regeneración activa
        
        ## FORMATO DE RESPUESTA:
        Proporciona un plan estructurado con:
        - Semana X, Día Y: [Tipo de entrenamiento]
        - Distancia: X km
        - Intensidad: Fácil/Moderada/Fuerte/Carrera
        - Duración estimada: X minutos
        - Notas específicas del entrenamiento
        
        ## PRINCIPIOS CLAVE:
        - Progresión gradual (10% semanal máximo)
        - Periodización adecuada
        - Días de recuperación obligatorios
        - Adaptación al nivel actual del atleta
        - Preparación específica para el objetivo
        
        Genera SOLO entrenamientos de running. No incluyas natación ni ciclismo.
        """
    }
}

// MARK: - Swimming Agent

struct SwimmingAgent: SportAgent {
    let sport: SportType = .swimming
    let endpoint: String = "swimming-coach"
    
    func generatePrompt(for user: User, weeks: Int) -> String {
        let swimmingLevel = user.swimmingLevel?.displayName ?? "Intermedio"
        let poolLength = user.preferredPoolLength ?? 25
        let hasPoolAccess = user.hasPoolAccess ? "Sí" : "No"
        
        return """
        Eres el mejor entrenador personal de natación del mundo especializado ÚNICAMENTE en natación. 🏊‍♂️
        
        ## PERFIL DEL NADADOR:
        - Nombre: \(user.name)
        - Nivel de natación: \(swimmingLevel)
        - Acceso a piscina: \(hasPoolAccess)
        - Longitud de piscina preferida: \(poolLength)m
        - Edad: \(user.age ?? 25) años
        
        ## TU MISIÓN:
        Genera un plan de entrenamiento de natación de \(weeks) semanas específicamente para este nadador.
        
        ## TIPOS DE ENTRENAMIENTOS DE NATACIÓN:
        - Resistencia Natación: Distancia larga, ritmo constante
        - Sprint Natación: Velocidad máxima, distancias cortas
        - Técnica Natación: Perfeccionamiento de brazada
        - Intervalos Natación: Series de velocidad con descanso
        
        ## ESTILOS DE NATACIÓN:
        - Crol (Freestyle): Estilo principal
        - Espalda (Backstroke): Variación y técnica
        - Braza (Breaststroke): Fuerza y coordinación
        - Mariposa (Butterfly): Potencia (solo niveles avanzados)
        
        ## FORMATO DE RESPUESTA:
        Proporciona un plan estructurado con:
        - Semana X, Día Y: [Tipo de entrenamiento]
        - Distancia: X metros
        - Estilo principal: Crol/Espalda/Braza/Mixto
        - Series: Ej. 8x50m con 15" descanso
        - Intensidad: Fácil/Moderada/Fuerte/Máxima
        - Duración estimada: X minutos
        - Notas técnicas específicas
        
        ## PRINCIPIOS CLAVE:
        - Técnica antes que velocidad
        - Calentamiento y enfriamiento obligatorios
        - Progresión gradual en distancia
        - Variación de estilos según nivel
        - Trabajo específico de respiración
        
        Genera SOLO entrenamientos de natación. No incluyas running ni ciclismo.
        """
    }
}

// MARK: - Cycling Agent

struct CyclingAgent: SportAgent {
    let sport: SportType = .cycling
    let endpoint: String = "cycling-coach"
    
    func generatePrompt(for user: User, weeks: Int) -> String {
        let cyclingLevel = user.cyclingLevel?.displayName ?? "Intermedio"
        let hasBike = user.hasBikeAccess ? "Sí" : "No"
        
        return """
        Eres el mejor entrenador personal de ciclismo del mundo especializado ÚNICAMENTE en ciclismo. 🚴‍♂️
        
        ## PERFIL DEL CICLISTA:
        - Nombre: \(user.name)
        - Nivel de ciclismo: \(cyclingLevel)
        - Acceso a bicicleta: \(hasBike)
        - Edad: \(user.age ?? 25) años
        - Peso: \(user.weight ?? 70) kg
        
        ## TU MISIÓN:
        Genera un plan de entrenamiento de ciclismo de \(weeks) semanas específicamente para este ciclista.
        
        ## TIPOS DE ENTRENAMIENTOS DE CICLISMO:
        - Resistencia Ciclismo: Distancia larga, ritmo aeróbico
        - Intervalos Ciclismo: Series de alta intensidad
        - Subidas Ciclismo: Trabajo específico en pendientes
        - Recuperación Ciclismo: Pedaleo suave regenerativo
        
        ## ZONAS DE ENTRENAMIENTO:
        - Zona 1: Recuperación activa (muy fácil)
        - Zona 2: Resistencia aeróbica (conversacional)
        - Zona 3: Tempo (ritmo sostenido)
        - Zona 4: Umbral (intenso pero sostenible)
        - Zona 5: VO2 max (máxima intensidad)
        
        ## FORMATO DE RESPUESTA:
        Proporciona un plan estructurado con:
        - Semana X, Día Y: [Tipo de entrenamiento]
        - Distancia: X km
        - Desnivel estimado: X metros (si aplica)
        - Zona de entrenamiento: 1-5
        - Duración estimada: X minutos
        - Cadencia objetivo: X rpm
        - Notas específicas del entrenamiento
        
        ## PRINCIPIOS CLAVE:
        - Cadencia eficiente (80-100 rpm)
        - Progresión gradual en distancia e intensidad
        - Trabajo específico de fuerza en subidas
        - Recuperación activa entre sesiones intensas
        - Adaptación al terreno disponible
        
        Genera SOLO entrenamientos de ciclismo. No incluyas running ni natación.
        """
    }
}

// MARK: - Triathlon Orchestrator

struct TriathlonOrchestrator {
    
    func generateTriathlonPlan(for user: User, weeks: Int, service: MultiSportAIService) -> AnyPublisher<[Workout], Error> {
        // The orchestrator coordinates with all three agents
        let runningAgent = RunningAgent()
        let swimmingAgent = SwimmingAgent()
        let cyclingAgent = CyclingAgent()
        
        // Generate plans from each specialized agent
        let runningPlan = service.sendRequest(to: runningAgent.endpoint, prompt: runningAgent.generatePrompt(for: user, weeks: weeks))
        let swimmingPlan = service.sendRequest(to: swimmingAgent.endpoint, prompt: swimmingAgent.generatePrompt(for: user, weeks: weeks))
        let cyclingPlan = service.sendRequest(to: cyclingAgent.endpoint, prompt: cyclingAgent.generatePrompt(for: user, weeks: weeks))
        
        // Combine all plans and add triathlon-specific workouts
        return Publishers.Zip3(runningPlan, swimmingPlan, cyclingPlan)
            .map { running, swimming, cycling in
                return self.orchestrateTriathlonPlan(
                    running: running,
                    swimming: swimming,
                    cycling: cycling,
                    user: user,
                    weeks: weeks
                )
            }
            .eraseToAnyPublisher()
    }
    
    private func orchestrateTriathlonPlan(running: [Workout], swimming: [Workout], cycling: [Workout], user: User, weeks: Int) -> [Workout] {
        var combinedPlan: [Workout] = []
        let calendar = Calendar.current
        let today = Date()
        
        // Distribute workouts across the week
        // Monday: Swimming, Tuesday: Cycling, Wednesday: Running
        // Thursday: Swimming, Friday: Cycling, Saturday: Long workout or Brick
        // Sunday: Recovery or Rest
        
        for week in 0..<weeks {
            let weekStart = calendar.date(byAdding: .weekOfYear, value: week, to: today) ?? today
            
            // Monday - Swimming
            if let swimmingWorkout = swimming.first(where: { calendar.isDate($0.date, inSameDayAs: calendar.date(byAdding: .day, value: 1, to: weekStart) ?? weekStart) }) {
                combinedPlan.append(swimmingWorkout)
            }
            
            // Tuesday - Cycling
            if let cyclingWorkout = cycling.first(where: { calendar.isDate($0.date, inSameDayAs: calendar.date(byAdding: .day, value: 2, to: weekStart) ?? weekStart) }) {
                combinedPlan.append(cyclingWorkout)
            }
            
            // Wednesday - Running
            if let runningWorkout = running.first(where: { calendar.isDate($0.date, inSameDayAs: calendar.date(byAdding: .day, value: 3, to: weekStart) ?? weekStart) }) {
                combinedPlan.append(runningWorkout)
            }
            
            // Saturday - Brick Workout (Cycling + Running)
            let brickDate = calendar.date(byAdding: .day, value: 6, to: weekStart) ?? weekStart
            let brickWorkout = Workout(
                date: brickDate,
                type: .brickWorkout,
                distance: 30 + 10, // 30km bike + 10km run
                duration: 120 * 60, // 2 hours
                intensity: "Moderate",
                notes: "Brick workout: 30km ciclismo + 10km running con transición",
                segments: [
                    TriathlonSegment(sport: .cycling, distance: 30, estimatedDuration: 60 * 60),
                    TriathlonSegment(sport: .running, distance: 10, estimatedDuration: 60 * 60)
                ]
            )
            combinedPlan.append(brickWorkout)
        }
        
        return combinedPlan.sorted { $0.date < $1.date }
    }
}
