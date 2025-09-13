# RunAI - Tu Entrenador Personal de Running 🏃‍♂️

Una aplicación iOS moderna para runners que incluye seguimiento de entrenamientos y un asistente personal de entrenamiento con IA.

## 🚀 Características

### ✅ Funcionalidades Implementadas

- **🔐 Autenticación**: Login/registro con diseño estilo shadcn
- **📚 Onboarding**: Flujo de bienvenida de 3 pantallas
- **📊 Seguimiento de Entrenamientos**: 
  - Vista diaria y semanal
  - Añadir entrenamientos (Long Run, Series)
  - Estadísticas automáticas
- **💬 Chat con Entrenador IA**: Asistente personal conectado a n8n
- **💾 Persistencia**: Guardado automático de datos
- **🎨 Diseño Moderno**: Interfaz estilo shadcn en español

## 🛠 Configuración

### Requisitos
- iOS 18.5+
- Xcode 16+
- n8n (para el chat del entrenador)

### Instalación

1. Clona el repositorio
2. Abre `runai.xcodeproj` en Xcode
3. Ejecuta el proyecto en el simulador o dispositivo

### Configuración del Chat con n8n

Para habilitar el chat con el entrenador personal, necesitas configurar n8n:

#### 1. Instala n8n
```bash
npm install -g n8n
```

#### 2. Inicia n8n
```bash
n8n start
```

#### 3. Configura el Webhook
1. Ve a `http://localhost:5678`
2. Crea un nuevo workflow
3. Añade un nodo **Webhook** con:
   - **HTTP Method**: POST
   - **Path**: `chat`
4. Añade un nodo **HTTP Request** para conectar con tu API de IA favorita (OpenAI, Claude, etc.)
5. Configura la respuesta en formato JSON:
   ```json
   {
     "response": "Respuesta del entrenador aquí"
   }
   ```

#### 4. System Prompt Recomendado

Usa este prompt para el mejor entrenador motivador:

```
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
```

#### 5. URL del Webhook
La app se conectará automáticamente a: `http://localhost:5678/webhook-test/chat`

## 🏗 Arquitectura

```
runai/
├── Models/              # Modelos de datos (User, Workout)
├── Services/            # Lógica de negocio (DataManager, ChatService)
├── Views/
│   ├── Auth/           # Login y registro
│   ├── Onboarding/     # Flujo de bienvenida
│   ├── Main/           # Pantalla principal y vistas
│   └── Chat/           # Chat con entrenador
├── Components/         # Componentes reutilizables
├── Extensions/         # Extensiones de Swift/SwiftUI
└── Utils/             # Constantes y utilidades
```

## 🎯 Próximas Funcionalidades

- [ ] Más tipos de entrenamientos (Intervalos, Tempo, etc.)
- [ ] Gráficos de progreso
- [ ] Integración con HealthKit
- [ ] Planes de entrenamiento predefinidos
- [ ] Recordatorios y notificaciones
- [ ] Compartir entrenamientos
- [ ] Modo oscuro

## 🧑‍💻 Desarrollo

### Mejores Prácticas Implementadas

- **Arquitectura MVVM** con ObservableObject
- **Componentes reutilizables** y extensiones
- **Constantes centralizadas** para configuración
- **Manejo de errores** robusto
- **Persistencia** con UserDefaults
- **Diseño responsive** y accesible

### Estructura de Datos

```swift
struct Workout: Identifiable, Codable {
    let id: UUID
    let date: Date
    let kilometers: Double
    let type: WorkoutType
    let notes: String?
}

enum WorkoutType: String, CaseIterable {
    case longRun = "Long Run"
    case series = "Series"
}
```

## 📱 Capturas de Pantalla

La aplicación incluye:
- Pantalla de login con diseño moderno
- Onboarding interactivo
- Vista principal con estadísticas
- Chat integrado con entrenador IA
- Formulario para añadir entrenamientos

## 🤝 Contribuir

1. Fork el proyecto
2. Crea una rama para tu feature (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

## 📄 Licencia

Este proyecto está bajo la Licencia MIT - ver el archivo [LICENSE](LICENSE) para detalles.

## 🙏 Agradecimientos

- Diseño inspirado en shadcn/ui
- Iconos de SF Symbols
- Comunidad de runners por la inspiración

---

¡Disfruta corriendo con RunAI! 🏃‍♂️💨
