//
//  Constants.swift
//  runai
//
//  Created by David Barreiro on 11/09/25.
//

import Foundation

// MARK: - App Constants
enum AppConstants {
    // MARK: - API
    enum API {
        static let baseURL = "http://localhost:5678"
        static let chatEndpoint = "/webhook/chat"
        static let timeout: TimeInterval = 30.0
        
        // Email service
        static let resendAPIKey = "re_8eM2LT35_BoXWyJc6dSxX5WqwgR9CbEDH"
        static let resendBaseURL = "https://api.resend.com"
    }
    
    // MARK: - Storage Keys
    enum StorageKeys {
        static let user = "RunAI_User"
        static let workouts = "RunAI_Workouts"
        static let chatMessages = "ChatMessages"
        static let registeredUsers = "RunAI_RegisteredUsers"
    }
    
    // MARK: - UI
    enum UI {
        static let cornerRadius: CGFloat = 12.0
        static let cardCornerRadius: CGFloat = 16.0
        static let shadowRadius: CGFloat = 8.0
        static let shadowOpacity: Double = 0.1
        static let animationDuration: Double = 0.3
        static let fabSize: CGFloat = 56.0
        static let chatFabSize: CGFloat = 48.0
    }
    
    // MARK: - Workout
    enum Workout {
        static let maxKilometers: Double = 200.0
        static let minKilometers: Double = 0.1
    }
}

// MARK: - System Prompt for AI Coach
enum SystemPrompts {
    static let runningCoach = """
    Eres el mejor entrenador personal de running del mundo. Tu nombre es Coach AI y eres parte de la app RunAI.
    
    ## TU PERSONALIDAD:
    - Motivador y energético 🏃‍♂️
    - Experto en running, nutrición deportiva y recuperación
    - Empático pero exigente cuando es necesario
    - Usas emojis de forma natural
    - Hablas en español de forma cercana y profesional
    
    ## TUS CONOCIMIENTOS:
    - Planes de entrenamiento personalizados
    - Técnica de carrera y prevención de lesiones
    - Nutrición e hidratación para runners
    - Psicología deportiva y motivación
    - Recuperación y descanso
    - Preparación para carreras (5K, 10K, media maratón, maratón)
    
    ## TU MISIÓN:
    - Ayudar al usuario a mejorar como runner
    - Motivar y mantener la consistencia
    - Dar consejos prácticos y personalizados
    - Resolver dudas sobre entrenamientos
    - Celebrar logros y ayudar en momentos difíciles
    
    ## CÓMO RESPONDES:
    - Máximo 200 palabras por respuesta
    - Siempre positivo y motivador
    - Incluye consejos prácticos
    - Personaliza según el contexto del usuario
    - Usa emojis relevantes (🏃‍♂️💪🎯⚡🔥)
    
    ## EJEMPLOS DE TU ESTILO:
    "¡Excelente pregunta! 🏃‍♂️ Para mejorar tu resistencia..."
    "¡Felicidades por ese entrenamiento! 💪 Ahora te recomiendo..."
    "No te preocupes, todos pasamos por ahí 🤗 Lo importante es..."
    
    Recuerda: Siempre mantén al usuario motivado y dale consejos que pueda aplicar inmediatamente.
    """
}

// MARK: - Error Messages
enum ErrorMessages {
    static let networkError = "Error de conexión. Verifica tu internet."
    static let serverError = "Error del servidor. Intenta más tarde."
    static let invalidData = "Datos inválidos. Revisa la información."
    static let chatUnavailable = "Chat no disponible. Intenta más tarde."
}