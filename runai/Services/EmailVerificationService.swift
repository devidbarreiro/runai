//
//  EmailVerificationService.swift
//  runai
//
//  Email verification service using Resend API
//

import Foundation
import Combine

class EmailVerificationService: ObservableObject {
    static let shared = EmailVerificationService()
    
    private let baseURL = AppConstants.API.resendBaseURL
    private let apiKey = AppConstants.API.resendAPIKey
    
    @Published var isLoading = false
    @Published var lastError: String?
    
    var cancellables = Set<AnyCancellable>()
    
    private init() {}
    
    // MARK: - Email Verification
    
    func sendVerificationCode(to email: String, userName: String) -> AnyPublisher<Bool, Error> {
        // En modo desarrollo, Resend solo permite enviar a dev.idbarreiro@gmail.com
        let isDevelopmentMode = true // Cambiar a false cuando se verifique el dominio
        let finalEmail = isDevelopmentMode ? "dev.idbarreiro@gmail.com" : email
        
        print("📧 [EmailService] DEVELOPMENT MODE - Sending verification code")
        print("📧 [EmailService] Original email: \(email)")
        print("📧 [EmailService] Final email: \(finalEmail)")
        print("📧 [EmailService] Using Resend API: \(baseURL)")
        print("📧 [EmailService] API Key configured: \(apiKey.prefix(10))...")
        
        if isDevelopmentMode && email != "dev.idbarreiro@gmail.com" {
            print("⚠️ [EmailService] DEVELOPMENT MODE: Redirecting email to authorized address")
            print("⚠️ [EmailService] To send to any email, verify domain at resend.com/domains")
        }
        
        isLoading = true
        lastError = nil
        
        let verificationCode = generateVerificationCode()
        print("📧 [EmailService] Generated verification code: \(verificationCode)")
        
        // Store verification code temporarily (in production, use secure storage)
        UserDefaults.standard.set(verificationCode, forKey: "verification_code_\(email)")
        UserDefaults.standard.set(Date().addingTimeInterval(600), forKey: "verification_expiry_\(email)") // 10 minutes
        print("📧 [EmailService] Stored verification code with 10 minute expiry")
        
        let emailRequest = EmailRequest(
            from: "RunAI <onboarding@resend.dev>",
            to: [finalEmail],
            subject: "Verifica tu cuenta de RunAI",
            html: createVerificationEmailHTML(userName: userName, code: verificationCode)
        )
        
        print("📧 [EmailService] Email request prepared:")
        print("📧 [EmailService] - From: \(emailRequest.from)")
        print("📧 [EmailService] - To: \(emailRequest.to)")
        print("📧 [EmailService] - Subject: \(emailRequest.subject)")
        
        return sendEmail(emailRequest)
            .handleEvents(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    switch completion {
                    case .finished:
                        print("📧 [EmailService] ✅ Email sent successfully!")
                    case .failure(let error):
                        print("📧 [EmailService] ❌ Email failed: \(error)")
                    }
                },
                receiveCancel: { [weak self] in
                    self?.isLoading = false
                    print("📧 [EmailService] ⚠️ Email sending cancelled")
                }
            )
            .eraseToAnyPublisher()
    }
    
    func verifyCode(_ code: String, for email: String) -> Bool {
        guard let storedCode = UserDefaults.standard.string(forKey: "verification_code_\(email)"),
              let expiryDate = UserDefaults.standard.object(forKey: "verification_expiry_\(email)") as? Date else {
            return false
        }
        
        // Check if code has expired
        if Date() > expiryDate {
            // Clean up expired code
            UserDefaults.standard.removeObject(forKey: "verification_code_\(email)")
            UserDefaults.standard.removeObject(forKey: "verification_expiry_\(email)")
            return false
        }
        
        let isValid = storedCode == code
        
        if isValid {
            // Clean up used code
            UserDefaults.standard.removeObject(forKey: "verification_code_\(email)")
            UserDefaults.standard.removeObject(forKey: "verification_expiry_\(email)")
        }
        
        return isValid
    }
    
    // MARK: - Welcome Emails
    
    func sendWelcomeEmail(to user: User, tenant: Tenant? = nil) -> AnyPublisher<Bool, Error> {
        let emailRequest = EmailRequest(
            from: "RunAI <onboarding@resend.dev>",
            to: [user.email],
            subject: "¡Bienvenido a RunAI! 🏃‍♂️",
            html: createWelcomeEmailHTML(user: user, tenant: tenant)
        )
        
        return sendEmail(emailRequest)
    }
    
    func sendEnterpriseInvitation(to email: String, tenant: Tenant, invitedBy: User) -> AnyPublisher<Bool, Error> {
        let emailRequest = EmailRequest(
            from: "RunAI <onboarding@resend.dev>",
            to: [email],
            subject: "Invitación a unirse a \(tenant.name) en RunAI",
            html: createInvitationEmailHTML(email: email, tenant: tenant, invitedBy: invitedBy)
        )
        
        return sendEmail(emailRequest)
    }
    
    // MARK: - Private Methods
    
    private func sendEmail(_ request: EmailRequest) -> AnyPublisher<Bool, Error> {
        guard let url = URL(string: "\(baseURL)/emails") else {
            print("📧 [EmailService] ❌ Invalid URL: \(baseURL)/emails")
            return Fail(error: EmailError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        print("📧 [EmailService] 🚀 Making request to: \(url)")
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.timeoutInterval = 30.0
        
        do {
            let jsonData = try JSONEncoder().encode(request)
            urlRequest.httpBody = jsonData
            print("📧 [EmailService] 📦 Request body size: \(jsonData.count) bytes")
        } catch {
            print("📧 [EmailService] ❌ Encoding error: \(error)")
            return Fail(error: EmailError.encodingError)
                .eraseToAnyPublisher()
        }
        
        return URLSession.shared.dataTaskPublisher(for: urlRequest)
            .handleEvents(receiveOutput: { data, response in
                if let httpResponse = response as? HTTPURLResponse {
                    print("📧 [EmailService] 📡 HTTP Status: \(httpResponse.statusCode)")
                    print("📧 [EmailService] 📡 Response headers: \(httpResponse.allHeaderFields)")
                    
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("📧 [EmailService] 📡 Response body: \(responseString)")
                    }
                    
                    if httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 {
                        print("📧 [EmailService] ✅ Resend API responded successfully")
                    } else {
                        print("📧 [EmailService] ⚠️ Resend API returned status: \(httpResponse.statusCode)")
                    }
                }
            })
            .map { data, response -> Bool in
                if let httpResponse = response as? HTTPURLResponse {
                    return httpResponse.statusCode >= 200 && httpResponse.statusCode < 300
                }
                return false
            }
            .mapError { error in
                print("📧 [EmailService] ❌ Network error: \(error)")
                return EmailError.networkError(error)
            }
            .catch { [weak self] error -> AnyPublisher<Bool, Error> in
                self?.lastError = error.localizedDescription
                print("📧 [EmailService] ❌ Final error: \(error.localizedDescription)")
                return Just(false)
                    .setFailureType(to: Error.self)
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
    private func generateVerificationCode() -> String {
        return String(format: "%06d", Int.random(in: 100000...999999))
    }
    
    private func createVerificationEmailHTML(userName: String, code: String) -> String {
        return """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>Verifica tu cuenta</title>
            <style>
                body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; margin: 0; padding: 20px; background-color: #f5f5f7; }
                .container { max-width: 600px; margin: 0 auto; background: white; border-radius: 12px; overflow: hidden; box-shadow: 0 4px 12px rgba(0,0,0,0.1); }
                .header { background: linear-gradient(135deg, #007AFF, #5856D6); padding: 40px 20px; text-align: center; }
                .header h1 { color: white; margin: 0; font-size: 28px; font-weight: 600; }
                .content { padding: 40px 20px; text-align: center; }
                .code { font-size: 36px; font-weight: bold; color: #007AFF; letter-spacing: 8px; margin: 30px 0; padding: 20px; background: #f0f8ff; border-radius: 8px; border: 2px dashed #007AFF; }
                .footer { padding: 20px; background: #f8f9fa; text-align: center; color: #666; font-size: 14px; }
            </style>
        </head>
        <body>
            <div class="container">
                <div class="header">
                    <h1>🏃‍♂️ RunAI</h1>
                </div>
                <div class="content">
                    <h2>¡Hola \(userName)!</h2>
                    <p>Gracias por registrarte en RunAI. Para completar tu registro, por favor verifica tu dirección de email con el siguiente código:</p>
                    
                    <div class="code">\(code)</div>
                    
                    <p>Este código expirará en 10 minutos.</p>
                    <p>Si no solicitaste este código, puedes ignorar este email.</p>
                </div>
                <div class="footer">
                    <p>© 2024 RunAI. Tu compañero de entrenamiento inteligente.</p>
                </div>
            </div>
        </body>
        </html>
        """
    }
    
    private func createWelcomeEmailHTML(user: User, tenant: Tenant?) -> String {
        let companySection = tenant != nil ? """
            <p>Te has unido a <strong>\(tenant!.name)</strong> con el plan <strong>\(tenant!.plan.displayName)</strong>.</p>
        """ : ""
        
        return """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="utf-8">
            <title>¡Bienvenido a RunAI!</title>
            <style>
                body { font-family: -apple-system, BlinkMacSystemFont, sans-serif; margin: 0; padding: 20px; background-color: #f5f5f7; }
                .container { max-width: 600px; margin: 0 auto; background: white; border-radius: 12px; overflow: hidden; }
                .header { background: linear-gradient(135deg, #007AFF, #5856D6); padding: 40px 20px; text-align: center; color: white; }
                .content { padding: 40px 20px; }
                .feature { margin: 20px 0; padding: 15px; background: #f8f9fa; border-radius: 8px; }
            </style>
        </head>
        <body>
            <div class="container">
                <div class="header">
                    <h1>🏃‍♂️ ¡Bienvenido a RunAI!</h1>
                </div>
                <div class="content">
                    <h2>¡Hola \(user.name)!</h2>
                    <p>¡Estamos emocionados de tenerte en RunAI! Tu cuenta ha sido verificada exitosamente.</p>
                    
                    \(companySection)
                    
                    <h3>¿Qué puedes hacer ahora?</h3>
                    <div class="feature">
                        <strong>🤖 Entrenador IA Personal</strong><br>
                        Genera planes de entrenamiento personalizados usando inteligencia artificial
                    </div>
                    <div class="feature">
                        <strong>📊 Seguimiento Avanzado</strong><br>
                        Registra y analiza todos tus entrenamientos
                    </div>
                    <div class="feature">
                        <strong>🎯 Objetivos Inteligentes</strong><br>
                        Prepárate para tu próxima carrera con planes específicos
                    </div>
                    
                    <p>¡Comienza tu viaje hacia una mejor versión de ti mismo!</p>
                </div>
            </div>
        </body>
        </html>
        """
    }
    
    private func createInvitationEmailHTML(email: String, tenant: Tenant, invitedBy: User) -> String {
        return """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="utf-8">
            <title>Invitación a RunAI</title>
            <style>
                body { font-family: -apple-system, BlinkMacSystemFont, sans-serif; margin: 0; padding: 20px; background-color: #f5f5f7; }
                .container { max-width: 600px; margin: 0 auto; background: white; border-radius: 12px; overflow: hidden; }
                .header { background: linear-gradient(135deg, #007AFF, #5856D6); padding: 40px 20px; text-align: center; color: white; }
                .content { padding: 40px 20px; }
                .cta { text-align: center; margin: 30px 0; }
                .button { display: inline-block; padding: 15px 30px; background: #007AFF; color: white; text-decoration: none; border-radius: 8px; font-weight: 600; }
            </style>
        </head>
        <body>
            <div class="container">
                <div class="header">
                    <h1>🏃‍♂️ Invitación a RunAI</h1>
                </div>
                <div class="content">
                    <h2>¡Has sido invitado!</h2>
                    <p><strong>\(invitedBy.name)</strong> te ha invitado a unirte a <strong>\(tenant.name)</strong> en RunAI.</p>
                    
                    <p>Con el plan <strong>\(tenant.plan.displayName)</strong> tendrás acceso a:</p>
                    <ul>
                        \(tenant.plan.features.map { "<li>\($0.displayName)</li>" }.joined())
                    </ul>
                    
                    <div class="cta">
                        <a href="runai://invite?tenant=\(tenant.id)&email=\(email)" class="button">
                            Aceptar Invitación
                        </a>
                    </div>
                    
                    <p><small>Si no puedes hacer clic en el botón, copia y pega este enlace en tu navegador:<br>
                    https://app.runai.com/invite?tenant=\(tenant.id)&email=\(email)</small></p>
                </div>
            </div>
        </body>
        </html>
        """
    }
}

// MARK: - Data Models

struct EmailRequest: Codable {
    let from: String
    let to: [String]
    let subject: String
    let html: String
}

enum EmailError: Error, LocalizedError {
    case invalidURL
    case encodingError
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "URL inválida para el servicio de email"
        case .encodingError:
            return "Error al codificar el email"
        case .networkError(let error):
            return "Error de red: \(error.localizedDescription)"
        }
    }
}
