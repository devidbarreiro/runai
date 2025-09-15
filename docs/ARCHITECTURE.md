# RunAI - Arquitectura de la Aplicación

## Visión General

RunAI es una aplicación iOS nativa desarrollada en SwiftUI que proporciona planes de entrenamiento personalizados para múltiples deportes (running, natación, ciclismo y triatlón) utilizando inteligencia artificial.

## Arquitectura General

La aplicación sigue el patrón **MVVM (Model-View-ViewModel)** con **Combine** para programación reactiva y manejo de estado.

```
┌─────────────────────────────────────────────────────────────┐
│                        UI Layer (SwiftUI)                   │
├─────────────────────────────────────────────────────────────┤
│                     Service Layer                           │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────────────────┐ │
│  │ DataManager │ │TenantManager│ │   AI Services           │ │
│  └─────────────┘ └─────────────┘ └─────────────────────────┘ │
├─────────────────────────────────────────────────────────────┤
│                     Model Layer                             │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────────────────┐ │
│  │    User     │ │   Workout   │ │      Tenant             │ │
│  └─────────────┘ └─────────────┘ └─────────────────────────┘ │
├─────────────────────────────────────────────────────────────┤
│                 Persistence Layer                           │
│              UserDefaults + Local Storage                   │
└─────────────────────────────────────────────────────────────┘
```

## Estructura de Carpetas

```
runai/
├── runaiApp.swift              # Punto de entrada de la aplicación
├── ContentView.swift           # Router principal de navegación
├── Models/                     # Modelos de datos
│   ├── User.swift             # Modelo de usuario y datos de rendimiento
│   ├── Workout.swift          # Modelo de entrenamientos multi-deporte
│   ├── Tenant.swift           # Modelo de tenant (individual/gym)
│   └── GymTenant.swift        # Extensión para gimnasios
├── Views/                      # Interfaz de usuario
│   ├── Auth/                  # Autenticación y onboarding
│   ├── Main/                  # Funcionalidades principales
│   ├── Admin/                 # Panel administrativo de gimnasios
│   ├── Profile/               # Perfil de usuario
│   ├── Chat/                  # Chat con IA
│   ├── Onboarding/           # Proceso de incorporación
│   └── Subscription/         # Gestión de suscripciones
├── Services/                   # Lógica de negocio
│   ├── DataManager.swift     # Gestión de datos locales
│   ├── TenantManager.swift   # Gestión multi-tenant
│   ├── OpenAIService.swift   # Integración con OpenAI
│   ├── MultiSportAIService.swift # Agentes especializados por deporte
│   ├── SubscriptionService.swift # Gestión de suscripciones
│   ├── ChatService.swift     # Servicio de chat
│   └── EmailVerificationService.swift # Verificación de email
├── Components/                # Componentes reutilizables
│   └── ReusableComponents.swift
├── Extensions/                # Extensiones de SwiftUI
│   └── View+Extensions.swift
└── Utils/                     # Utilidades y constantes
    └── Constants.swift
```

## Componentes Principales

### 1. **ContentView** - Router Principal
- **Propósito**: Controla la navegación principal basada en el estado del usuario
- **Responsabilidades**:
  - Verificación de email pendiente
  - Estado de login
  - Progreso de onboarding
  - Selección de plan
  - Determinación de tipo de tenant (individual/gym)

### 2. **TenantManager** - Gestión Multi-Tenant
- **Propósito**: Maneja la lógica multi-tenant (usuarios individuales vs gimnasios)
- **Funcionalidades**:
  - Autenticación de usuarios
  - Gestión de sesiones
  - Determinación de contexto (individual/gym)
  - Estado de verificación de email

### 3. **DataManager** - Gestión de Datos
- **Propósito**: Maneja toda la persistencia local de datos
- **Funcionalidades**:
  - CRUD de entrenamientos
  - Gestión de perfil de usuario
  - Almacenamiento local con UserDefaults
  - Sincronización de datos

### 4. **Servicios de IA**

#### OpenAIService
- **Propósito**: Coordinador principal para generación de planes
- **Funcionalidades**:
  - Delegación a servicios especializados
  - Fallback para casos no cubiertos
  - Manejo de errores de API

#### MultiSportAIService
- **Propósito**: Agentes especializados por deporte
- **Agentes**:
  - **RunningAgent**: Planes de running personalizados
  - **SwimmingAgent**: Planes de natación con técnica
  - **CyclingAgent**: Planes de ciclismo con potencia/cadencia
  - **TriathlonOrchestrator**: Coordina los tres deportes para triatlón

### 5. **SubscriptionService** - Monetización
- **Propósito**: Gestiona suscripciones y paywall
- **Funcionalidades**:
  - Integración con Apple In-App Purchases
  - Modelo freemium
  - Feature gating
  - Gestión de membresías de gimnasio

## Flujo de Datos

### Patrón Reactivo con Combine
```swift
@ObservedObject var dataManager = DataManager.shared
@ObservedObject var tenantManager = TenantManager.shared
```

### Estado Global
- **TenantManager**: Estado de autenticación y tenant
- **DataManager**: Estado de datos de entrenamientos y usuario
- **SubscriptionService**: Estado de suscripciones

### Comunicación Entre Componentes
1. **Views** → **Services**: Llamadas directas a métodos
2. **Services** → **Views**: Notificaciones via `@Published` properties
3. **Services** ↔ **Services**: Dependency injection y singletons

## Persistencia

### UserDefaults
- Datos de usuario y configuración
- Estado de onboarding
- Preferencias de la aplicación
- Cache de suscripciones

### Estructura de Datos
```swift
// Ejemplo de estructura de datos persistidos
{
  "currentUser": User,
  "workouts": [Workout],
  "subscriptionData": SubscriptionData,
  "onboardingState": OnboardingState
}
```

## Seguridad y Privacidad

### Datos Sensibles
- API keys almacenadas en constantes (no en código)
- Datos de usuario encriptados localmente
- No almacenamiento de contraseñas

### Verificación de Email
- Integración con Resend API
- Flujo de verificación obligatorio
- Tokens de verificación temporales

## Escalabilidad

### Multi-Tenant Architecture
- Soporte para usuarios individuales
- Soporte para gimnasios con múltiples usuarios
- Roles y permisos diferenciados
- Facturación separada por tenant

### Extensibilidad
- Nuevos deportes: Agregar agente en `MultiSportAIService`
- Nuevas funcionalidades: Patrón de servicios modulares
- Nuevas integraciones: Interfaces bien definidas

## Dependencias Principales

### Frameworks iOS
- **SwiftUI**: UI declarativa
- **Combine**: Programación reactiva
- **StoreKit**: In-App Purchases
- **Foundation**: Funcionalidades base

### APIs Externas
- **OpenAI API**: Generación de planes con IA
- **Resend API**: Envío de emails de verificación

## Consideraciones de Rendimiento

### Optimizaciones
- Lazy loading de vistas pesadas
- Cache de respuestas de IA
- Batch operations para múltiples entrenamientos
- Debouncing en inputs de usuario

### Memoria
- Uso de `@ObservedObject` para objetos compartidos
- `@StateObject` para objetos propios de la vista
- Weak references en closures para evitar retain cycles

## Testing

### Estructura de Tests
- **runaiTests**: Unit tests
- **runaiUITests**: UI tests
- Mocking de servicios externos
- Tests de flujos críticos (onboarding, payment)

## Deployment

### Configuración
- **Debug**: Desarrollo local con APIs de prueba
- **Release**: Producción con APIs reales
- Environment variables para diferentes entornos
- Configuración de certificados para App Store

---

*Documentación actualizada: Septiembre 2025*
