//
//  ChatService.swift
//  runai
//
//  Created by David Barreiro on 11/09/25.
//

import Foundation
import Combine

// MARK: - Chat Models
struct ChatMessage: Identifiable, Codable {
    let id: UUID
    let content: String
    let isFromUser: Bool
    let timestamp: Date
    
    init(content: String, isFromUser: Bool) {
        self.id = UUID()
        self.content = content
        self.isFromUser = isFromUser
        self.timestamp = Date()
    }
}

struct ChatRequest: Codable {
    let message: String
    let context: ChatContext
}

struct ChatContext: Codable {
    let userName: String
    let currentDate: String
    let currentTime: String
    let dayOfWeek: String
    let recentWorkouts: [WorkoutSummary]?
}

struct WorkoutSummary: Codable {
    let date: String
    let kilometers: Double
    let type: String
}

struct ChatResponse: Codable {
    let response: String?
    let error: String?
}

// MARK: - Chat Service
class ChatService: ObservableObject {
    static let shared = ChatService()
    
    @Published var messages: [ChatMessage] = []
    @Published var isLoading: Bool = false
    @Published var isConnected: Bool = true
    
    private let baseURL = AppConstants.API.baseURL + AppConstants.API.chatEndpoint
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        loadMessages()
        // Add welcome message if no messages exist
        if messages.isEmpty {
            addWelcomeMessage()
        }
    }
    
    // MARK: - Public Methods
    func sendMessage(_ content: String) {
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        // Add user message
        let userMessage = ChatMessage(content: content, isFromUser: true)
        messages.append(userMessage)
        saveMessages()
        
        // Send to n8n
        isLoading = true
        sendToN8N(message: content)
    }
    
    func clearChat() {
        messages.removeAll()
        saveMessages()
        addWelcomeMessage()
    }
    
    // MARK: - Private Methods
    private func sendToN8N(message: String) {
        guard let url = URL(string: baseURL) else {
            handleError("URL inválida")
            return
        }
        
        let context = createChatContext()
        let request = ChatRequest(message: message, context: context)
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.timeoutInterval = AppConstants.API.timeout
        
        do {
            urlRequest.httpBody = try JSONEncoder().encode(request)
        } catch {
            handleError("Error al codificar mensaje")
            return
        }
        
        URLSession.shared.dataTaskPublisher(for: urlRequest)
            .map(\.data)
            .decode(type: ChatResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.handleError("Error de conexión: \(error.localizedDescription)")
                    }
                },
                receiveValue: { [weak self] response in
                    if let responseText = response.response, !responseText.isEmpty {
                        let botMessage = ChatMessage(content: responseText, isFromUser: false)
                        self?.messages.append(botMessage)
                        self?.saveMessages()
                    } else if let error = response.error {
                        self?.handleError("Error del servidor: \(error)")
                    } else {
                        self?.handleError("Respuesta vacía del servidor")
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    private func createChatContext() -> ChatContext {
        let now = Date()
        let dateFormatter = DateFormatter()
        
        // Format current date
        dateFormatter.dateStyle = .full
        dateFormatter.locale = Locale(identifier: "es_ES")
        let currentDate = dateFormatter.string(from: now)
        
        // Format current time
        dateFormatter.dateStyle = .none
        dateFormatter.timeStyle = .short
        let currentTime = dateFormatter.string(from: now)
        
        // Day of week
        dateFormatter.dateFormat = "EEEE"
        let dayOfWeek = dateFormatter.string(from: now)
        
        // Get user info
        let dataManager = DataManager.shared
        let userName = dataManager.currentUser?.name ?? "Runner"
        
        // Get recent workouts (last 7 days)
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        let recentWorkouts = dataManager.workouts
            .filter { $0.date >= weekAgo }
            .sorted { $0.date > $1.date }
            .prefix(5)
            .map { workout in
                let workoutDateFormatter = DateFormatter()
                workoutDateFormatter.dateStyle = .medium
                workoutDateFormatter.locale = Locale(identifier: "es_ES")
                
                return WorkoutSummary(
                    date: workoutDateFormatter.string(from: workout.date),
                    kilometers: workout.kilometers,
                    type: workout.type.rawValue
                )
            }
        
        return ChatContext(
            userName: userName,
            currentDate: currentDate,
            currentTime: currentTime,
            dayOfWeek: dayOfWeek,
            recentWorkouts: Array(recentWorkouts)
        )
    }
    
    private func handleError(_ errorMessage: String) {
        isConnected = false
        let errorResponse = ChatMessage(
            content: "Lo siento, no puedo conectar con el entrenador ahora. \(errorMessage)",
            isFromUser: false
        )
        messages.append(errorResponse)
        saveMessages()
        
        // Retry connection after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.isConnected = true
        }
    }
    
    private func addWelcomeMessage() {
        let welcomeMessage = ChatMessage(
            content: "¡Hola! Soy tu entrenador personal de RunAI 🏃‍♂️\n\n¿En qué puedo ayudarte hoy? Puedo darte consejos sobre entrenamientos, motivación, nutrición o resolver cualquier duda que tengas.",
            isFromUser: false
        )
        messages.append(welcomeMessage)
        saveMessages()
    }
    
    // MARK: - Persistence
    private func saveMessages() {
        if let encoded = try? JSONEncoder().encode(messages) {
            UserDefaults.standard.set(encoded, forKey: AppConstants.StorageKeys.chatMessages)
        }
    }
    
    private func loadMessages() {
        if let data = UserDefaults.standard.data(forKey: AppConstants.StorageKeys.chatMessages),
           let decodedMessages = try? JSONDecoder().decode([ChatMessage].self, from: data) {
            messages = decodedMessages
        }
    }
}
