# RunAI - Estrategia de Base de Datos y Backend

## 📋 Resumen Ejecutivo

La migración desde UserDefaults hacia una solución de base de datos robusta es **crítica** para el éxito de RunAI en producción. Este documento presenta una estrategia completa que incluye arquitectura local, backend escalable, sincronización, y plan de migración.

---

## 🎯 Objetivos de la Migración

### Problemas Actuales con UserDefaults
- ❌ **Limitaciones de Almacenamiento**: No apto para grandes volúmenes
- ❌ **Sin Relaciones**: Imposible modelar relaciones complejas
- ❌ **Performance Degradada**: Serialización completa en cada operación
- ❌ **No Escalable**: Sin queries, filtros, o índices
- ❌ **Pérdida de Datos**: Risk de corrupción y pérdida
- ❌ **Sin Backup**: No hay estrategia de respaldo
- ❌ **No Colaborativo**: Imposible compartir datos entre dispositivos

### Beneficios de la Nueva Solución
- ✅ **Relaciones Complejas**: Modelado robusto de entidades
- ✅ **Performance Optimizada**: Queries eficientes e índices
- ✅ **Sincronización**: Multi-device y tiempo real
- ✅ **Backup Automático**: CloudKit integration
- ✅ **Offline-First**: Funcionalidad completa sin conexión
- ✅ **Escalabilidad**: Millones de registros sin degradación
- ✅ **Analytics**: Queries complejas para insights

---

## 🏗️ Arquitectura de Datos Propuesta

### Capa Local: Core Data + CloudKit
```
┌─────────────────────────────────────────────────────────────┐
│                    SwiftUI Views                            │
├─────────────────────────────────────────────────────────────┤
│                  View Models                                │
├─────────────────────────────────────────────────────────────┤
│               Repository Layer                              │
│  ┌─────────────────┐ ┌─────────────────┐ ┌───────────────┐ │
│  │ WorkoutRepo     │ │ UserRepo        │ │ AIRepo        │ │
│  └─────────────────┘ └─────────────────┘ └───────────────┘ │
├─────────────────────────────────────────────────────────────┤
│                 Core Data Stack                             │
│  ┌─────────────────┐ ┌─────────────────┐ ┌───────────────┐ │
│  │ Local Store     │ │ CloudKit Store  │ │ Cache Store   │ │
│  └─────────────────┘ └─────────────────┘ └───────────────┘ │
├─────────────────────────────────────────────────────────────┤
│                   CloudKit Sync                             │
│              (Automatic Background Sync)                   │
└─────────────────────────────────────────────────────────────┘
```

### Backend API: Node.js + PostgreSQL
```
┌─────────────────────────────────────────────────────────────┐
│                 API Gateway (AWS/Vercel)                   │
├─────────────────────────────────────────────────────────────┤
│                 Authentication Layer                        │
│                (Firebase Auth / Supabase)                  │
├─────────────────────────────────────────────────────────────┤
│                 Business Logic Layer                        │
│  ┌─────────────────┐ ┌─────────────────┐ ┌───────────────┐ │
│  │ User Service    │ │ Workout Service │ │ AI Service    │ │
│  └─────────────────┘ └─────────────────┘ └───────────────┘ │
├─────────────────────────────────────────────────────────────┤
│                    Data Layer                               │
│  ┌─────────────────┐ ┌─────────────────┐ ┌───────────────┐ │
│  │ PostgreSQL      │ │ Redis Cache     │ │ File Storage  │ │
│  │ (Primary DB)    │ │ (Session/Cache) │ │ (S3/Supabase) │ │
│  └─────────────────┘ └─────────────────┘ └───────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

---

## 📊 Modelo de Datos Detallado

### Core Data Schema

#### User Entity
```swift
@Entity(name: "CDUser")
class CDUser: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var username: String
    @NSManaged var email: String
    @NSManaged var name: String
    @NSManaged var createdAt: Date
    @NSManaged var updatedAt: Date
    
    // Physical data
    @NSManaged var age: Int16
    @NSManaged var weight: Double  // kg
    @NSManaged var height: Double  // cm
    
    // Fitness data
    @NSManaged var fitnessLevel: String
    @NSManaged var primarySport: String
    @NSManaged var preferredSports: [String]
    
    // Subscription
    @NSManaged var subscriptionType: String
    @NSManaged var subscriptionStatus: String
    @NSManaged var subscriptionExpiryDate: Date?
    
    // Relationships
    @NSManaged var workouts: NSSet?
    @NSManaged var goals: NSSet?
    @NSManaged var performanceData: NSSet?
    @NSManaged var tenant: CDTenant?
    
    // CloudKit
    @NSManaged var recordName: String?
    @NSManaged var lastCloudKitSync: Date?
}
```

#### Workout Entity
```swift
@Entity(name: "CDWorkout")
class CDWorkout: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var date: Date
    @NSManaged var sport: String
    @NSManaged var type: String
    @NSManaged var status: String
    @NSManaged var createdAt: Date
    @NSManaged var updatedAt: Date
    
    // Metrics
    @NSManaged var distance: Double
    @NSManaged var duration: TimeInterval
    @NSManaged var intensity: String?
    @NSManaged var notes: String?
    
    // Sport-specific data (JSON)
    @NSManaged var sportSpecificData: Data?
    
    // AI generation metadata
    @NSManaged var generatedByAI: Bool
    @NSManaged var aiModel: String?
    @NSManaged var aiPrompt: String?
    
    // Relationships
    @NSManaged var user: CDUser
    @NSManaged var segments: NSSet? // For triathlon
    @NSManaged var plan: CDTrainingPlan?
    
    // CloudKit
    @NSManaged var recordName: String?
    @NSManaged var lastCloudKitSync: Date?
}
```

#### Training Plan Entity
```swift
@Entity(name: "CDTrainingPlan")
class CDTrainingPlan: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var name: String
    @NSManaged var sport: String
    @NSManaged var raceType: String?
    @NSManaged var startDate: Date
    @NSManaged var endDate: Date
    @NSManaged var weeks: Int16
    @NSManaged var createdAt: Date
    @NSManaged var isActive: Bool
    
    // AI metadata
    @NSManaged var generatedByAI: Bool
    @NSManaged var aiModel: String?
    @NSManaged var aiPrompt: String?
    
    // Relationships
    @NSManaged var user: CDUser
    @NSManaged var workouts: NSSet?
    @NSManaged var goal: CDGoal?
    
    // CloudKit
    @NSManaged var recordName: String?
    @NSManaged var lastCloudKitSync: Date?
}
```

#### Performance Data Entity
```swift
@Entity(name: "CDPerformanceData")
class CDPerformanceData: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var sport: String
    @NSManaged var date: Date
    @NSManaged var dataType: String // "5k_time", "weekly_km", etc.
    @NSManaged var value: Double
    @NSManaged var unit: String
    @NSManaged var notes: String?
    
    // Relationships
    @NSManaged var user: CDUser
    
    // CloudKit
    @NSManaged var recordName: String?
    @NSManaged var lastCloudKitSync: Date?
}
```

#### Tenant Entity (Multi-tenant support)
```swift
@Entity(name: "CDTenant")
class CDTenant: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var name: String
    @NSManaged var type: String // "individual", "gym", "enterprise"
    @NSManaged var domain: String?
    @NSManaged var createdAt: Date
    @NSManaged var settings: Data // JSON settings
    
    // Relationships
    @NSManaged var users: NSSet?
    @NSManaged var owner: CDUser?
    
    // CloudKit (shared records for gym tenants)
    @NSManaged var recordName: String?
    @NSManaged var cloudKitShareRecord: String?
}
```

### PostgreSQL Schema (Backend)
```sql
-- Users table
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Physical data
    age INTEGER,
    weight DECIMAL(5,2), -- kg
    height DECIMAL(5,2), -- cm
    
    -- Fitness data
    fitness_level VARCHAR(20),
    primary_sport VARCHAR(20),
    preferred_sports TEXT[], -- Array of sports
    
    -- Subscription
    subscription_type VARCHAR(20) DEFAULT 'free',
    subscription_status VARCHAR(20) DEFAULT 'active',
    subscription_expiry_date TIMESTAMP WITH TIME ZONE,
    apple_subscription_id VARCHAR(255),
    
    -- Multi-tenant
    tenant_id UUID REFERENCES tenants(id),
    role VARCHAR(20) DEFAULT 'member',
    
    -- Verification
    email_verified BOOLEAN DEFAULT FALSE,
    email_verified_at TIMESTAMP WITH TIME ZONE,
    
    -- Indexes
    CONSTRAINT users_email_check CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')
);

-- Workouts table
CREATE TABLE workouts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    training_plan_id UUID REFERENCES training_plans(id) ON DELETE SET NULL,
    
    date DATE NOT NULL,
    sport VARCHAR(20) NOT NULL,
    type VARCHAR(50) NOT NULL,
    status VARCHAR(20) DEFAULT 'pending',
    
    -- Metrics
    distance DECIMAL(8,3), -- km or meters
    duration INTEGER, -- seconds
    intensity VARCHAR(20),
    notes TEXT,
    
    -- Sport-specific data
    sport_specific_data JSONB,
    
    -- AI metadata
    generated_by_ai BOOLEAN DEFAULT FALSE,
    ai_model VARCHAR(50),
    ai_prompt TEXT,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Indexes
    INDEX idx_workouts_user_date (user_id, date),
    INDEX idx_workouts_sport (sport),
    INDEX idx_workouts_status (status)
);

-- Training Plans table
CREATE TABLE training_plans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    goal_id UUID REFERENCES goals(id) ON DELETE SET NULL,
    
    name VARCHAR(255) NOT NULL,
    sport VARCHAR(20) NOT NULL,
    race_type VARCHAR(50),
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    weeks INTEGER NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    
    -- AI metadata
    generated_by_ai BOOLEAN DEFAULT FALSE,
    ai_model VARCHAR(50),
    ai_prompt TEXT,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Indexes
    INDEX idx_training_plans_user (user_id),
    INDEX idx_training_plans_sport (sport),
    INDEX idx_training_plans_active (is_active)
);

-- Performance Data table
CREATE TABLE performance_data (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    sport VARCHAR(20) NOT NULL,
    date DATE NOT NULL,
    data_type VARCHAR(50) NOT NULL, -- "5k_time", "weekly_km", etc.
    value DECIMAL(10,3) NOT NULL,
    unit VARCHAR(10) NOT NULL,
    notes TEXT,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Indexes
    INDEX idx_performance_data_user_sport (user_id, sport),
    INDEX idx_performance_data_type (data_type),
    INDEX idx_performance_data_date (date)
);

-- Goals table
CREATE TABLE goals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    sport VARCHAR(20) NOT NULL,
    race_type VARCHAR(50) NOT NULL,
    target_time INTEGER, -- seconds
    race_date DATE,
    priority VARCHAR(10) DEFAULT 'medium',
    notes TEXT,
    status VARCHAR(20) DEFAULT 'active',
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Indexes
    INDEX idx_goals_user_sport (user_id, sport),
    INDEX idx_goals_status (status)
);

-- Tenants table (Multi-tenant support)
CREATE TABLE tenants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    type VARCHAR(20) NOT NULL, -- 'individual', 'gym', 'enterprise'
    domain VARCHAR(255),
    settings JSONB,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Indexes
    INDEX idx_tenants_type (type),
    INDEX idx_tenants_domain (domain)
);
```

---

## 🔄 Estrategia de Sincronización

### CloudKit Configuration
```swift
// Container setup
class CloudKitManager {
    static let shared = CloudKitManager()
    
    private let container = CKContainer(identifier: "iCloud.com.runai.app")
    private let privateDatabase: CKDatabase
    private let sharedDatabase: CKDatabase
    
    init() {
        privateDatabase = container.privateCloudDatabase
        sharedDatabase = container.sharedCloudDatabase
    }
    
    // Setup record zones
    func setupRecordZones() async throws {
        let userZone = CKRecordZone(zoneName: "UserZone")
        let workoutZone = CKRecordZone(zoneName: "WorkoutZone")
        let planZone = CKRecordZone(zoneName: "PlanZone")
        
        try await privateDatabase.save([userZone, workoutZone, planZone])
    }
}
```

### Sync Strategy
```swift
class SyncManager: ObservableObject {
    @Published var syncStatus: SyncStatus = .idle
    @Published var lastSyncDate: Date?
    
    // Bidirectional sync
    func performSync() async {
        syncStatus = .syncing
        
        do {
            // 1. Push local changes to CloudKit
            await pushLocalChangesToCloudKit()
            
            // 2. Fetch remote changes from CloudKit
            await fetchRemoteChangesFromCloudKit()
            
            // 3. Resolve conflicts
            await resolveConflicts()
            
            // 4. Update local database
            await updateLocalDatabase()
            
            lastSyncDate = Date()
            syncStatus = .completed
            
        } catch {
            syncStatus = .failed(error)
            Logger.sync.error("Sync failed: \(error.localizedDescription)")
        }
    }
    
    // Conflict resolution strategy
    private func resolveConflicts() async {
        // Strategy: Last write wins with user notification for important conflicts
        // For workouts: merge non-conflicting fields
        // For user data: prompt user to choose
        // For AI-generated content: regenerate if needed
    }
}
```

### Offline-First Architecture
```swift
class OfflineFirstRepository<T: NSManagedObject>: Repository {
    private let context: NSManagedObjectContext
    private let syncManager: SyncManager
    
    // Always work with local data first
    func save(_ entity: T) async throws -> T {
        // 1. Save locally immediately
        let savedEntity = try await saveToLocal(entity)
        
        // 2. Mark for sync
        markForSync(savedEntity)
        
        // 3. Attempt background sync
        Task.detached {
            await syncManager.syncIfConnected()
        }
        
        return savedEntity
    }
    
    func fetch() async throws -> [T] {
        // Always return local data
        let localData = try await fetchFromLocal()
        
        // Trigger background refresh
        Task.detached {
            await syncManager.fetchRemoteUpdates()
        }
        
        return localData
    }
}
```

---

## 🚀 Backend API Design

### Authentication & Authorization
```typescript
// JWT-based authentication with refresh tokens
interface AuthTokens {
  accessToken: string;
  refreshToken: string;
  expiresIn: number;
}

// Role-based access control
enum UserRole {
  MEMBER = 'member',
  TRAINER = 'trainer',
  ADMIN = 'admin',
  OWNER = 'owner'
}

// Middleware for route protection
const requireAuth = (requiredRole?: UserRole) => {
  return async (req: Request, res: Response, next: NextFunction) => {
    const token = req.headers.authorization?.replace('Bearer ', '');
    
    if (!token) {
      return res.status(401).json({ error: 'Authentication required' });
    }
    
    try {
      const decoded = jwt.verify(token, process.env.JWT_SECRET!) as JWTPayload;
      req.user = await User.findById(decoded.userId);
      
      if (requiredRole && !hasRole(req.user.role, requiredRole)) {
        return res.status(403).json({ error: 'Insufficient permissions' });
      }
      
      next();
    } catch (error) {
      return res.status(401).json({ error: 'Invalid token' });
    }
  };
};
```

### API Endpoints Structure
```typescript
// Users API
router.get('/api/v1/users/profile', requireAuth(), getUserProfile);
router.put('/api/v1/users/profile', requireAuth(), updateUserProfile);
router.get('/api/v1/users/:id/performance', requireAuth(), getPerformanceData);

// Workouts API
router.get('/api/v1/workouts', requireAuth(), getWorkouts);
router.post('/api/v1/workouts', requireAuth(), createWorkout);
router.put('/api/v1/workouts/:id', requireAuth(), updateWorkout);
router.delete('/api/v1/workouts/:id', requireAuth(), deleteWorkout);

// Training Plans API
router.get('/api/v1/training-plans', requireAuth(), getTrainingPlans);
router.post('/api/v1/training-plans/generate', requireAuth(), generateTrainingPlan);
router.get('/api/v1/training-plans/:id', requireAuth(), getTrainingPlan);

// AI API
router.post('/api/v1/ai/generate-plan', requireAuth(), generateAIPlan);
router.post('/api/v1/ai/chat', requireAuth(), chatWithAI);
router.get('/api/v1/ai/suggestions', requireAuth(), getAISuggestions);

// Tenants API (Multi-tenant)
router.get('/api/v1/tenants/:id', requireAuth(UserRole.ADMIN), getTenant);
router.put('/api/v1/tenants/:id', requireAuth(UserRole.ADMIN), updateTenant);
router.get('/api/v1/tenants/:id/users', requireAuth(UserRole.ADMIN), getTenantUsers);
router.post('/api/v1/tenants/:id/invite', requireAuth(UserRole.ADMIN), inviteUser);

// Analytics API
router.get('/api/v1/analytics/dashboard', requireAuth(), getAnalyticsDashboard);
router.get('/api/v1/analytics/progress', requireAuth(), getProgressAnalytics);
```

### Real-time Features with WebSockets
```typescript
// WebSocket setup for real-time updates
import { Server as SocketIOServer } from 'socket.io';

class RealtimeManager {
  private io: SocketIOServer;
  
  constructor(server: any) {
    this.io = new SocketIOServer(server, {
      cors: { origin: "*" }
    });
    
    this.setupEventHandlers();
  }
  
  private setupEventHandlers() {
    this.io.on('connection', (socket) => {
      // Join user-specific room
      socket.on('join-user-room', (userId: string) => {
        socket.join(`user-${userId}`);
      });
      
      // Join tenant room (for gym members)
      socket.on('join-tenant-room', (tenantId: string) => {
        socket.join(`tenant-${tenantId}`);
      });
    });
  }
  
  // Notify user of workout updates
  notifyWorkoutUpdate(userId: string, workout: Workout) {
    this.io.to(`user-${userId}`).emit('workout-updated', workout);
  }
  
  // Notify tenant of member activity
  notifyTenantActivity(tenantId: string, activity: Activity) {
    this.io.to(`tenant-${tenantId}`).emit('member-activity', activity);
  }
}
```

---

## 📱 Implementación en iOS

### Core Data Stack Setup
```swift
class CoreDataManager: ObservableObject {
    static let shared = CoreDataManager()
    
    lazy var persistentContainer: NSPersistentCloudKitContainer = {
        let container = NSPersistentCloudKitContainer(name: "RunAI")
        
        // Configure CloudKit
        let privateStoreDescription = container.persistentStoreDescriptions.first!
        privateStoreDescription.setOption(true as NSNumber, 
                                         forKey: NSPersistentHistoryTrackingKey)
        privateStoreDescription.setOption(true as NSNumber, 
                                         forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        
        // Setup CloudKit container
        privateStoreDescription.cloudKitContainerOptions = 
            NSPersistentCloudKitContainerOptions(containerIdentifier: "iCloud.com.runai.app")
        
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Core Data error: \(error)")
            }
        }
        
        // Enable automatic merging
        container.viewContext.automaticallyMergesChangesFromParent = true
        
        return container
    }()
    
    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    func save() {
        if context.hasChanges {
            do {
                try context.save()
                Logger.coreData.info("Context saved successfully")
            } catch {
                Logger.coreData.error("Failed to save context: \(error)")
            }
        }
    }
}
```

### Repository Implementation
```swift
protocol WorkoutRepository {
    func getWorkouts(for user: User, from startDate: Date, to endDate: Date) -> AnyPublisher<[Workout], Error>
    func saveWorkout(_ workout: Workout) -> AnyPublisher<Workout, Error>
    func deleteWorkout(id: UUID) -> AnyPublisher<Void, Error>
    func getWorkoutsForDate(_ date: Date, user: User) -> AnyPublisher<[Workout], Error>
}

class CoreDataWorkoutRepository: WorkoutRepository {
    private let context: NSManagedObjectContext
    private let syncManager: SyncManager
    
    init(context: NSManagedObjectContext = CoreDataManager.shared.context,
         syncManager: SyncManager = SyncManager.shared) {
        self.context = context
        self.syncManager = syncManager
    }
    
    func getWorkouts(for user: User, from startDate: Date, to endDate: Date) -> AnyPublisher<[Workout], Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(RepositoryError.contextUnavailable))
                return
            }
            
            let request: NSFetchRequest<CDWorkout> = CDWorkout.fetchRequest()
            request.predicate = NSPredicate(format: "user.id == %@ AND date >= %@ AND date <= %@", 
                                          user.id as CVarArg, startDate as CVarArg, endDate as CVarArg)
            request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]
            
            do {
                let cdWorkouts = try self.context.fetch(request)
                let workouts = cdWorkouts.map { $0.toDomainModel() }
                promise(.success(workouts))
            } catch {
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func saveWorkout(_ workout: Workout) -> AnyPublisher<Workout, Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(RepositoryError.contextUnavailable))
                return
            }
            
            let cdWorkout = CDWorkout(context: self.context)
            cdWorkout.updateFromDomainModel(workout)
            
            do {
                try self.context.save()
                
                // Mark for CloudKit sync
                self.syncManager.markForSync(cdWorkout)
                
                promise(.success(cdWorkout.toDomainModel()))
            } catch {
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }
}
```

### Data Migration Strategy
```swift
class DataMigrationManager {
    static let shared = DataMigrationManager()
    
    func migrateFromUserDefaults() async throws {
        Logger.migration.info("Starting migration from UserDefaults to Core Data")
        
        // 1. Check if migration is needed
        guard needsMigration() else {
            Logger.migration.info("Migration not needed")
            return
        }
        
        // 2. Create backup
        try await createBackup()
        
        // 3. Migrate user data
        try await migrateUserData()
        
        // 4. Migrate workouts
        try await migrateWorkouts()
        
        // 5. Migrate registered users
        try await migrateRegisteredUsers()
        
        // 6. Mark migration as complete
        markMigrationComplete()
        
        // 7. Clean up old data (optional)
        cleanupOldData()
        
        Logger.migration.info("Migration completed successfully")
    }
    
    private func migrateUserData() async throws {
        if let userData = UserDefaults.standard.data(forKey: "RunAI_User"),
           let user = try? JSONDecoder().decode(User.self, from: userData) {
            
            let context = CoreDataManager.shared.context
            let cdUser = CDUser(context: context)
            cdUser.updateFromDomainModel(user)
            
            try context.save()
            Logger.migration.info("User data migrated successfully")
        }
    }
    
    private func migrateWorkouts() async throws {
        if let workoutsData = UserDefaults.standard.data(forKey: "RunAI_Workouts"),
           let workouts = try? JSONDecoder().decode([Workout].self, from: workoutsData) {
            
            let context = CoreDataManager.shared.context
            
            for workout in workouts {
                let cdWorkout = CDWorkout(context: context)
                cdWorkout.updateFromDomainModel(workout)
            }
            
            try context.save()
            Logger.migration.info("Migrated \(workouts.count) workouts successfully")
        }
    }
}
```

---

## 🔧 Plan de Implementación

### Fase 1: Foundation (2-3 semanas)
1. **Core Data Setup**
   - [ ] Crear modelo de datos (.xcdatamodeld)
   - [ ] Configurar CloudKit container
   - [ ] Implementar CoreDataManager
   - [ ] Setup básico de sincronización

2. **Repository Pattern**
   - [ ] Definir protocolos de repositorio
   - [ ] Implementar repositorios para entidades principales
   - [ ] Crear capa de abstracción

3. **Data Migration**
   - [ ] Implementar migración desde UserDefaults
   - [ ] Testing exhaustivo de migración
   - [ ] Backup y rollback strategy

### Fase 2: Sync & Offline (2-3 semanas)
1. **CloudKit Integration**
   - [ ] Configurar record zones
   - [ ] Implementar sync bidireccional
   - [ ] Manejo de conflictos
   - [ ] Testing de sincronización

2. **Offline Support**
   - [ ] Implementar queue de operaciones offline
   - [ ] Manejo de estados de conectividad
   - [ ] Sincronización automática al reconectar

### Fase 3: Backend API (3-4 semanas)
1. **API Development**
   - [ ] Setup Node.js + PostgreSQL
   - [ ] Implementar authentication
   - [ ] Crear endpoints principales
   - [ ] Testing de APIs

2. **Real-time Features**
   - [ ] WebSocket setup
   - [ ] Real-time notifications
   - [ ] Multi-tenant support

### Fase 4: Advanced Features (2-3 semanas)
1. **Analytics & Insights**
   - [ ] Complex queries para analytics
   - [ ] Performance tracking
   - [ ] Reporting dashboard

2. **Optimization**
   - [ ] Performance tuning
   - [ ] Caching strategies
   - [ ] Memory optimization

### Fase 5: Production Ready (1-2 semanas)
1. **Security & Compliance**
   - [ ] Data encryption
   - [ ] GDPR compliance
   - [ ] Security audit

2. **Monitoring & Logging**
   - [ ] Error tracking
   - [ ] Performance monitoring
   - [ ] Usage analytics

---

## 💰 Estimación de Costos

### Desarrollo (10-12 semanas)
- **Senior iOS Developer**: $8,000/semana × 8 semanas = $64,000
- **Backend Developer**: $7,000/semana × 6 semanas = $42,000
- **DevOps Engineer**: $6,000/semana × 2 semanas = $12,000
- **QA Engineer**: $4,000/semana × 4 semanas = $16,000

**Total Desarrollo**: ~$134,000

### Infraestructura (Mensual)
- **Database Hosting** (Supabase/AWS RDS): $200-500/mes
- **API Hosting** (Vercel/AWS): $100-300/mes
- **CloudKit**: Incluido con Apple Developer Program
- **Monitoring & Analytics**: $100-200/mes
- **CDN & Storage**: $50-150/mes

**Total Infraestructura**: ~$450-1,150/mes

### Alternativas Económicas
1. **Supabase**: Backend-as-a-Service que reduce costos de desarrollo
2. **Firebase**: Alternativa de Google con pricing escalable
3. **AWS Amplify**: Full-stack platform con GraphQL automático

---

## 🎯 Métricas de Éxito

### Performance
- **Query Response Time**: < 100ms para queries locales
- **Sync Time**: < 30 segundos para sync completo
- **App Launch Time**: < 2 segundos cold start
- **Memory Usage**: < 150MB con datasets grandes

### Reliability
- **Data Loss Rate**: < 0.01%
- **Sync Success Rate**: > 99.5%
- **Offline Functionality**: 95% de features disponibles
- **Crash Rate**: < 0.1%

### User Experience
- **Migration Success Rate**: > 99%
- **Sync Transparency**: Usuario no nota sincronización
- **Conflict Resolution**: < 1% requiere intervención manual
- **Multi-device Consistency**: 100% de datos sincronizados

---

## 🚨 Riesgos y Mitigaciones

### Riesgos Técnicos
1. **CloudKit Limitations**
   - *Riesgo*: Limitaciones de CloudKit para casos complejos
   - *Mitigación*: Implementar fallback a API backend

2. **Data Migration Complexity**
   - *Riesgo*: Pérdida de datos durante migración
   - *Mitigación*: Testing exhaustivo + backup strategy

3. **Sync Conflicts**
   - *Riesgo*: Conflictos de sincronización complejos
   - *Mitigación*: Estrategia de resolución clara + logging

### Riesgos de Negocio
1. **Development Time**
   - *Riesgo*: Proyecto se extiende más de lo esperado
   - *Mitigación*: Desarrollo por fases + MVPs

2. **User Adoption**
   - *Riesgo*: Usuarios no adoptan nuevas features
   - *Mitigación*: A/B testing + gradual rollout

3. **Cost Overrun**
   - *Riesgo*: Costos de infraestructura exceden presupuesto
   - *Mitigación*: Monitoring de costos + auto-scaling

---

## 📊 Conclusiones y Recomendaciones

### Recomendación Principal
**Implementar Core Data + CloudKit como primera prioridad**, con backend API como segunda fase. Esta aproximación ofrece:

1. **Rápida Implementación**: Core Data está maduro y bien integrado
2. **Sync Automático**: CloudKit maneja sincronización transparentemente
3. **Offline-First**: Funcionalidad completa sin conexión
4. **Escalabilidad**: Preparado para millones de registros

### Roadmap Recomendado
1. **Mes 1-2**: Core Data + CloudKit implementation
2. **Mes 3**: Data migration + testing
3. **Mes 4-5**: Backend API development
4. **Mes 6**: Advanced features + optimization

### ROI Esperado
- **Retención de Usuarios**: +25% por mejor experiencia
- **Engagement**: +40% por features offline
- **Escalabilidad**: Soporte para 100,000+ usuarios
- **Desarrollo Futuro**: Base sólida para nuevas features

---

*Documento creado: Septiembre 2025*
*Próxima revisión: Cada trimestre*
