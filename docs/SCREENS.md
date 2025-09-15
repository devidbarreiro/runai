# RunAI - Pantallas y Vistas

## Visión General

RunAI cuenta con una interfaz de usuario moderna construida en SwiftUI, organizada en flujos lógicos que guían al usuario desde el onboarding hasta el uso avanzado de la aplicación.

## Estructura de Navegación

```
WelcomeView (Landing)
├── LoginView
├── RegisterView
└── EmailVerificationView
    └── OnboardingView
        └── PhysicalOnboardingView
            └── PlanSelectionView
                └── MainView (Dashboard Principal)
                    ├── DailyView / WeeklyView
                    ├── AddWorkoutView
                    ├── TrainingPlanGeneratorView
                    ├── ChatView
                    └── ProfileView
```

## Pantallas por Categoría

### 🔐 **Autenticación y Onboarding**

#### 1. **WelcomeView** - Página de Bienvenida
- **Propósito**: Landing page de la aplicación
- **Características**:
  - Branding de RunAI con badges de distancia
  - Botones de "Crear Cuenta" e "Iniciar Sesión"
  - Diseño responsive con badges animados
  - Tema oscuro/claro automático
- **Navegación**: Punto de entrada principal
- **Estado**: Visible solo para usuarios no autenticados

> **📸 Captura de Pantalla Requerida:**
> - **Acceso**: Abrir app sin usuario logueado
> - **Contenido**: Página completa mostrando badges de distancia animados, logo "RunAI", subtítulo "Tu entrenador personal de running", y botones "Crear Cuenta" e "Iniciar Sesión"
> - **Nombre archivo**: `01_welcome_view.png`

#### 2. **LoginView** - Inicio de Sesión
- **Propósito**: Autenticación de usuarios existentes
- **Características**:
  - Login con username/email
  - Modo registro integrado
  - Validación de campos en tiempo real
  - Manejo de errores de autenticación
- **Navegación**: Desde WelcomeView
- **Estado**: Modal sobre WelcomeView

> **📸 Captura de Pantalla Requerida:**
> - **Acceso**: WelcomeView → Tap "Iniciar Sesión"
> - **Contenido**: Modal con campos de username/email y modo toggle entre Login/Register
> - **Nombre archivo**: `02_login_view.png`

#### 3. **EmailVerificationView** - Verificación de Email
- **Propósito**: Confirmar dirección de email del usuario
- **Características**:
  - Envío automático de código de verificación
  - Input de código con validación
  - Reenvío de código con cooldown
  - Integración con Resend API
- **Navegación**: Después del registro
- **Estado**: Obligatorio para nuevos usuarios

> **📸 Captura de Pantalla Requerida:**
> - **Acceso**: Completar registro → Automático
> - **Contenido**: Pantalla con campo de código de 6 dígitos, botón "Reenviar código" y mensaje de instrucciones
> - **Nombre archivo**: `03_email_verification_view.png`

#### 4. **OnboardingView** - Onboarding Inicial
- **Propósito**: Introducción a la aplicación
- **Características**:
  - Carrusel de páginas informativas
  - Explicación de funcionalidades principales
  - Botón "Comenzar" para continuar
  - Animaciones de transición
- **Navegación**: Después de verificación de email
- **Estado**: Solo para usuarios nuevos

> **📸 Captura de Pantalla Requerida:**
> - **Acceso**: Email verificado → Automático
> - **Contenido**: Primera página del carrusel con "Bienvenido a RunAI" y indicadores de progreso
> - **Nombre archivo**: `04_onboarding_view.png`

#### 5. **PhysicalOnboardingView** - Onboarding Físico
- **Propósito**: Recolección de datos físicos y deportivos
- **Características**:
  - **8 pasos de configuración**:
    1. **Datos Básicos**: Edad, peso, altura
    2. **Selección de Deportes**: Grid visual multi-selección
    3. **Deporte Principal**: Selector horizontal
    4. **Configuración Específica**: Acceso a piscina, bicicleta, etc.
    5. **Datos de Rendimiento**: Por cada deporte seleccionado
    6. **Nivel de Fitness**: Principiante a Experto
    7. **Objetivos de Carrera**: Metas por disciplina
    8. **Términos y Privacidad**: Aceptación de políticas
- **Navegación**: Después de OnboardingView
- **Estado**: Obligatorio, progreso guardado

> **📸 Capturas de Pantalla Requeridas:**
> - **05a_physical_onboarding_step1.png**: Paso 1 - Datos básicos (edad, peso, altura)
> - **05b_physical_onboarding_step2.png**: Paso 2 - Grid de selección de deportes
> - **05c_physical_onboarding_step5.png**: Paso 5 - Datos de rendimiento (running seleccionado)
> - **Acceso**: OnboardingView → "Comenzar" → Navegar por los pasos

#### 6. **PlanSelectionView** - Selección de Plan
- **Propósito**: Elección del tipo de suscripción
- **Características**:
  - **Opciones de Plan**:
    - Individual Free/Premium
    - Registro en Gimnasio
    - Creación de Gimnasio (Enterprise)
  - Comparación de características
  - Integración con Apple In-App Purchases
  - Formularios de registro específicos
- **Navegación**: Después de PhysicalOnboardingView
- **Estado**: Obligatorio para activar la cuenta

> **📸 Captura de Pantalla Requerida:**
> - **Acceso**: Completar PhysicalOnboardingView → Automático
> - **Contenido**: Pantalla con las 3 opciones principales (Individual, Unirse a Gym, Crear Gym)
> - **Nombre archivo**: `06_plan_selection_view.png`

### 🏠 **Dashboard Principal**

#### 7. **MainView** - Vista Principal
- **Propósito**: Dashboard central de la aplicación
- **Características**:
  - **Header**: Información del usuario y acceso a perfil
  - **Selector de Modo**: Día vs Semana
  - **Selector de Fecha**: Navegación temporal
  - **Filtro de Deporte**: Para usuarios multi-deporte
  - **Contenido Principal**: DailyView o WeeklyView
  - **FAB**: Botones flotantes para acciones rápidas
- **Navegación**: Vista principal post-onboarding
- **Estado**: Siempre accesible para usuarios autenticados

> **📸 Captura de Pantalla Requerida:**
> - **Acceso**: Completar onboarding completo → Vista principal
> - **Contenido**: Dashboard con header, selector día/semana, fecha actual, y FABs visibles
> - **Nombre archivo**: `07_main_view.png`

#### 8. **DailyView** - Vista Diaria
- **Propósito**: Visualización de entrenamientos del día
- **Características**:
  - **Resumen del Día**: Estadísticas totales
  - **Lista de Entrenamientos**: Cards detallados
  - **Desglose por Deporte**: Cuando hay filtro activo
  - **Estado de Completado**: Marcar entrenamientos realizados
  - **Métricas Específicas**: Distancia, duración, intensidad
- **Navegación**: Desde MainView (modo día)
- **Estado**: Vista por defecto

> **📸 Captura de Pantalla Requerida:**
> - **Acceso**: MainView → Asegurar modo "Día" seleccionado
> - **Contenido**: Vista diaria con resumen del día y lista de entrenamientos (preferible con algunos entrenamientos añadidos)
> - **Nombre archivo**: `08_daily_view.png`

#### 9. **WeeklyView** - Vista Semanal
- **Propósito**: Visualización de entrenamientos de la semana
- **Características**:
  - **Grid Semanal**: 7 días con entrenamientos
  - **Resumen Semanal**: Totales y promedios
  - **Navegación por Semanas**: Anterior/Siguiente
  - **Filtrado por Deporte**: Cuando aplicable
  - **Vista Compacta**: Información condensada
- **Navegación**: Desde MainView (modo semana)
- **Estado**: Alternativa a DailyView

> **📸 Captura de Pantalla Requerida:**
> - **Acceso**: MainView → Tap "Semana"
> - **Contenido**: Grid de 7 días con entrenamientos distribuidos
> - **Nombre archivo**: `09_weekly_view.png`

### ➕ **Gestión de Entrenamientos**

#### 10. **AddWorkoutView** - Añadir Entrenamiento
- **Propósito**: Creación manual de entrenamientos
- **Características**:
  - **Selección de Deporte**: Running, natación, ciclismo, triatlón
  - **Tipo de Entrenamiento**: Específico por deporte
  - **Métricas Generales**: Distancia, duración, intensidad
  - **Métricas Específicas**:
    - **Natación**: Longitud de piscina, tipo de brazada
    - **Ciclismo**: Elevación, potencia promedio
    - **Triatlón**: Segmentos múltiples
  - **Fecha y Notas**: Personalización adicional
- **Navegación**: Modal desde MainView (FAB)
- **Estado**: Modal con validación de campos

> **📸 Captura de Pantalla Requerida:**
> - **Acceso**: MainView → Tap FAB "+" → Modal se abre
> - **Contenido**: Formulario con selección de deporte, tipo, y campos de métricas
> - **Nombre archivo**: `10_add_workout_view.png`

#### 11. **TrainingPlanGeneratorView** - Generador de Planes IA
- **Propósito**: Generación de planes de entrenamiento con IA
- **Características**:
  - **Selección de Disciplina**: Deporte específico
  - **Configuración de Objetivos**: Tipo de carrera, fecha objetivo
  - **Preguntas Contextuales**: Basadas en el deporte seleccionado
  - **Generación con IA**: Integración con agentes especializados
  - **Preview del Plan**: Resumen antes de confirmar
  - **Integración**: Añade entrenamientos al calendario
- **Navegación**: Modal desde MainView (FAB)
- **Estado**: Modal con flujo paso a paso

> **📸 Capturas de Pantalla Requeridas:**
> - **11a_training_plan_generator_start.png**: Pantalla inicial con selección de disciplina
> - **11b_training_plan_generator_config.png**: Configuración de objetivos (tipo de carrera, fecha)
> - **Acceso**: MainView → Tap FAB "🧠" → Modal de generación

### 💬 **Interacción con IA**

#### 12. **ChatView** - Chat con IA
- **Propósito**: Conversación directa con el entrenador IA
- **Características**:
  - **Interfaz de Chat**: Burbujas de mensaje
  - **Contexto del Usuario**: Información de perfil y entrenamientos
  - **Respuestas Inteligentes**: Consejos personalizados
  - **Historial**: Conversaciones previas guardadas
  - **Estados de Carga**: Indicadores de procesamiento
- **Navegación**: Modal desde MainView (FAB)
- **Estado**: Modal con scroll infinito

> **📸 Captura de Pantalla Requerida:**
> - **Acceso**: MainView → Tap FAB "💬" → Modal de chat
> - **Contenido**: Interfaz de chat con algunas conversaciones previas y campo de input
> - **Nombre archivo**: `12_chat_view.png`

### 👤 **Perfil y Configuración**

#### 13. **ProfileView** - Perfil de Usuario
- **Propósito**: Gestión de datos personales y configuración
- **Características**:
  - **Información Personal**: Nombre, email, datos físicos
  - **Datos de Rendimiento**: Métricas por deporte
  - **Objetivos Actuales**: Carreras y metas
  - **Configuración de Deportes**: Preferencias y niveles
  - **Configuración de la App**: Notificaciones, tema
  - **Gestión de Cuenta**: Logout, eliminación
- **Navegación**: Modal desde MainView (Header)
- **Estado**: Modal con navegación interna

> **📸 Captura de Pantalla Requerida:**
> - **Acceso**: MainView → Tap avatar en header → Modal de perfil
> - **Contenido**: Pantalla principal del perfil con información personal y secciones principales
> - **Nombre archivo**: `13_profile_view.png`

### 🏢 **Administración de Gimnasio**

#### 14. **GymAdminDashboard** - Dashboard de Gimnasio
- **Propósito**: Panel de control para administradores de gimnasio
- **Características**:
  - **Estadísticas del Gimnasio**: Miembros, actividad
  - **Gestión de Usuarios**: Lista y administración
  - **Configuración**: Ajustes del gimnasio
  - **Reportes**: Analytics y métricas
- **Navegación**: Vista principal para admins de gym
- **Estado**: Solo para usuarios con rol admin

> **📸 Captura de Pantalla Requerida:**
> - **Acceso**: Seleccionar "Crear Gimnasio" en onboarding → Completar setup → Dashboard admin
> - **Contenido**: Dashboard con estadísticas, opciones de gestión y navegación
> - **Nombre archivo**: `14_gym_admin_dashboard.png`

#### 15. **GymUserManagementView** - Gestión de Usuarios
- **Propósito**: Administración de miembros del gimnasio
- **Características**:
  - **Lista de Miembros**: Usuarios registrados
  - **Invitaciones**: Sistema de invitación por email
  - **Roles y Permisos**: Gestión de accesos
  - **Estados de Membresía**: Activos, inactivos, pendientes
- **Navegación**: Desde GymAdminDashboard
- **Estado**: Solo para administradores

#### 16. **GymConfigurationView** - Configuración de Gimnasio
- **Propósito**: Configuración general del gimnasio
- **Características**:
  - **Información Básica**: Nombre, dirección, contacto
  - **Configuración de Membresía**: Límites, características
  - **Integraciones**: Sistemas de pago, membresías
  - **Personalización**: Branding, colores
- **Navegación**: Desde GymAdminDashboard
- **Estado**: Solo para administradores

### 💳 **Suscripciones y Pagos**

#### 17. **SubscriptionView** - Gestión de Suscripciones
- **Propósito**: Administración de planes de suscripción
- **Características**:
  - **Estado Actual**: Plan activo, fecha de vencimiento
  - **Opciones de Upgrade**: Cambio a premium
  - **Historial de Pagos**: Transacciones previas
  - **Gestión**: Cancelación, restauración
- **Navegación**: Desde ProfileView o paywall
- **Estado**: Accesible según tipo de usuario

> **📸 Captura de Pantalla Requerida:**
> - **Acceso**: ProfileView → Sección "Suscripción"
> - **Contenido**: Estado actual del plan, opciones de upgrade y gestión
> - **Nombre archivo**: `17_subscription_view.png`

#### 18. **PaywallView** - Muro de Pago
- **Propósito**: Promoción y venta de suscripciones premium
- **Características**:
  - **Comparación de Planes**: Free vs Premium
  - **Lista de Beneficios**: Funcionalidades premium
  - **Call to Action**: Botones de compra
  - **Testimonios**: Casos de éxito (simulados)
- **Navegación**: Intercepta funciones premium
- **Estado**: Aparece cuando se requiere upgrade

> **📸 Captura de Pantalla Requerida:**
> - **Acceso**: Intentar usar función premium con cuenta free → Paywall aparece
> - **Contenido**: Comparación Free vs Premium con beneficios y botones de compra
> - **Nombre archivo**: `18_paywall_view.png`

## Componentes Reutilizables

### Componentes de UI
- **WorkoutCard**: Tarjeta de entrenamiento con métricas
- **SportBadge**: Badge visual para deportes
- **ProgressIndicator**: Barras de progreso para onboarding
- **DatePicker**: Selector de fecha personalizado
- **StatCard**: Tarjeta de estadística con icono y valor

### Modales y Sheets
- **ConfirmationDialog**: Diálogos de confirmación
- **AlertView**: Alertas de error/éxito
- **LoadingOverlay**: Indicador de carga global
- **ActionSheet**: Menús de acciones contextuales

## Patrones de Diseño

### 1. **Navegación**
- **NavigationView**: Navegación principal
- **Modal Sheets**: Para flujos específicos
- **Tab Navigation**: En vistas principales (futuro)

### 2. **Estado**
- **@ObservedObject**: Para managers compartidos
- **@State**: Para estado local de vistas
- **@Binding**: Para comunicación padre-hijo

### 3. **Responsive Design**
- **GeometryReader**: Para layouts adaptativos
- **Size Classes**: Adaptación a diferentes dispositivos
- **Dynamic Type**: Soporte para accesibilidad

### 4. **Temas**
- **Color Schemes**: Modo oscuro/claro automático
- **Semantic Colors**: Colores que se adaptan al tema
- **Custom Fonts**: Tipografía consistente

## Flujos de Usuario Críticos

### 1. **Primer Uso**
WelcomeView → Register → EmailVerification → Onboarding → PhysicalOnboarding → PlanSelection → MainView

### 2. **Usuario Existente**
WelcomeView → Login → MainView

### 3. **Creación de Plan IA**
MainView → TrainingPlanGenerator → [Flujo multi-paso] → MainView (con nuevos entrenamientos)

### 4. **Gestión de Gimnasio**
MainView → GymAdminDashboard → [Gestión específica] → Dashboard

## Consideraciones de UX

### Accesibilidad
- **VoiceOver**: Labels descriptivos
- **Dynamic Type**: Soporte para texto grande
- **Color Contrast**: Cumple estándares WCAG
- **Keyboard Navigation**: Soporte completo

### Performance
- **Lazy Loading**: Listas grandes optimizadas
- **Image Caching**: Carga eficiente de imágenes
- **Animation Performance**: 60fps constantes
- **Memory Management**: Liberación de recursos

### Offline Support
- **Local Data**: Funciona sin conexión
- **Sync Indicators**: Estados de sincronización
- **Graceful Degradation**: Funcionalidades reducidas sin internet

## 📸 Resumen de Capturas de Pantalla Requeridas

### Lista Completa de Capturas (18 pantallas principales)

| Archivo | Pantalla | Acceso |
|---------|----------|--------|
| `01_welcome_view.png` | WelcomeView | Abrir app sin usuario logueado |
| `02_login_view.png` | LoginView | WelcomeView → "Iniciar Sesión" |
| `03_email_verification_view.png` | EmailVerificationView | Completar registro |
| `04_onboarding_view.png` | OnboardingView | Email verificado |
| `05a_physical_onboarding_step1.png` | PhysicalOnboarding - Paso 1 | Datos básicos |
| `05b_physical_onboarding_step2.png` | PhysicalOnboarding - Paso 2 | Selección deportes |
| `05c_physical_onboarding_step5.png` | PhysicalOnboarding - Paso 5 | Datos rendimiento |
| `06_plan_selection_view.png` | PlanSelectionView | Completar onboarding físico |
| `07_main_view.png` | MainView | Vista principal completa |
| `08_daily_view.png` | DailyView | MainView modo "Día" |
| `09_weekly_view.png` | WeeklyView | MainView modo "Semana" |
| `10_add_workout_view.png` | AddWorkoutView | MainView → FAB "+" |
| `11a_training_plan_generator_start.png` | TrainingPlanGenerator - Inicio | MainView → FAB "🧠" |
| `11b_training_plan_generator_config.png` | TrainingPlanGenerator - Config | Configuración objetivos |
| `12_chat_view.png` | ChatView | MainView → FAB "💬" |
| `13_profile_view.png` | ProfileView | MainView → Tap avatar |
| `14_gym_admin_dashboard.png` | GymAdminDashboard | Crear gimnasio → Dashboard |
| `17_subscription_view.png` | SubscriptionView | ProfileView → "Suscripción" |
| `18_paywall_view.png` | PaywallView | Función premium con cuenta free |

### Instrucciones para Capturas

#### 📱 **Configuración Recomendada**
- **Dispositivo**: iPhone 16 (simulador)
- **Orientación**: Portrait
- **Tema**: Light mode preferible (mejor contraste para documentación)
- **Resolución**: Nativa del simulador
- **Formato**: PNG con transparencia

#### 🎯 **Mejores Prácticas**
1. **Datos de Ejemplo**: Usar datos realistas pero no personales
2. **Estado Completo**: Mostrar pantallas con contenido, no vacías
3. **Consistencia**: Mismo usuario/datos a través de las capturas
4. **Calidad**: Screenshots nítidos sin compresión
5. **Contexto**: Incluir elementos de navegación (headers, tabs, etc.)

#### 📁 **Organización de Archivos**
```
docs/
├── screenshots/
│   ├── auth/
│   │   ├── 01_welcome_view.png
│   │   ├── 02_login_view.png
│   │   ├── 03_email_verification_view.png
│   │   ├── 04_onboarding_view.png
│   │   ├── 05a_physical_onboarding_step1.png
│   │   ├── 05b_physical_onboarding_step2.png
│   │   ├── 05c_physical_onboarding_step5.png
│   │   └── 06_plan_selection_view.png
│   ├── main/
│   │   ├── 07_main_view.png
│   │   ├── 08_daily_view.png
│   │   ├── 09_weekly_view.png
│   │   ├── 10_add_workout_view.png
│   │   ├── 11a_training_plan_generator_start.png
│   │   ├── 11b_training_plan_generator_config.png
│   │   ├── 12_chat_view.png
│   │   └── 13_profile_view.png
│   └── admin/
│       ├── 14_gym_admin_dashboard.png
│       ├── 17_subscription_view.png
│       └── 18_paywall_view.png
└── SCREENS.md (este archivo)
```

#### 🔄 **Flujo Sugerido para Capturas**
1. **Reset del simulador** para estado limpio
2. **Completar onboarding completo** con datos de ejemplo
3. **Añadir algunos entrenamientos** para mostrar funcionalidad
4. **Tomar capturas en orden** siguiendo el flujo de usuario
5. **Verificar calidad** antes de finalizar

---

*Documentación actualizada: Septiembre 2025*
