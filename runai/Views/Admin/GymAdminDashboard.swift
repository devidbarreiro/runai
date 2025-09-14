//
//  GymAdminDashboard.swift
//  runai
//
//  Admin dashboard for gym owners and managers
//

import SwiftUI
import Charts

struct GymAdminDashboard: View {
    @ObservedObject var tenantManager = TenantManager.shared
    @State private var selectedPeriod: GymAnalytics.AnalyticsPeriod = .month
    @State private var showingSettings = false
    @State private var showingMemberManagement = false
    @State private var showingClassManagement = false
    
    // Mock data - in real app, this would come from API
    @State private var analytics = GymAnalytics(
        gymId: UUID(),
        period: .month,
        totalMembers: 347,
        activeMembers: 289,
        newMembersThisPeriod: 23,
        memberRetentionRate: 0.83,
        averageWorkoutsPerMember: 12.4,
        popularWorkoutTimes: [
            TimeSlot(hour: 6, memberCount: 45),
            TimeSlot(hour: 7, memberCount: 67),
            TimeSlot(hour: 8, memberCount: 52),
            TimeSlot(hour: 18, memberCount: 89),
            TimeSlot(hour: 19, memberCount: 76),
            TimeSlot(hour: 20, memberCount: 43)
        ],
        classAttendanceRates: [
            ClassAttendance(className: "Yoga Matutino", attendanceRate: 0.85, averageParticipants: 17),
            ClassAttendance(className: "CrossFit", attendanceRate: 0.92, averageParticipants: 24),
            ClassAttendance(className: "Spinning", attendanceRate: 0.78, averageParticipants: 19)
        ],
        revenueThisPeriod: 15420.50,
        membershipTypeBreakdown: [
            MembershipTypeStats(membershipType: "Básica", count: 156, percentage: 0.45, revenue: 4668.44),
            MembershipTypeStats(membershipType: "Premium", count: 134, percentage: 0.39, revenue: 6698.66),
            MembershipTypeStats(membershipType: "VIP", count: 57, percentage: 0.16, revenue: 5699.43)
        ]
    )
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header with gym info
                    GymHeaderCard()
                    
                    // Quick stats
                    QuickStatsGrid(analytics: analytics)
                    
                    // Charts section
                    VStack(spacing: 16) {
                        // Period selector
                        PeriodSelector(selectedPeriod: $selectedPeriod)
                        
                        // Member activity chart
                        MemberActivityChart(timeSlots: analytics.popularWorkoutTimes)
                        
                        // Revenue breakdown
                        RevenueBreakdownChart(membershipStats: analytics.membershipTypeBreakdown)
                    }
                    
                    // Quick actions
                    QuickActionsGrid(
                        onMemberManagement: { showingMemberManagement = true },
                        onClassManagement: { showingClassManagement = true },
                        onSettings: { showingSettings = true }
                    )
                    
                    // Recent activity
                    RecentActivityCard()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingSettings = true }) {
                        Image(systemName: "gearshape.fill")
                    }
                }
            }
        }
        .sheet(isPresented: $showingSettings) {
            GymSettingsView()
        }
        .sheet(isPresented: $showingMemberManagement) {
            GymUserManagementView()
        }
        .sheet(isPresented: $showingClassManagement) {
            ClassManagementView()
        }
    }
}

struct GymHeaderCard: View {
    @ObservedObject var tenantManager = TenantManager.shared
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                // Gym logo placeholder
                Circle()
                    .fill(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Text("🏋️")
                            .font(.title2)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(tenantManager.currentTenant?.name ?? "Mi Gimnasio")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Plan Empresarial")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                        Text("Activo")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Hoy")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("89")
                        .font(.title3)
                        .fontWeight(.semibold)
                    Text("miembros activos")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
        )
    }
}

struct QuickStatsGrid: View {
    let analytics: GymAnalytics
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
            StatCard(
                title: "Miembros Totales",
                value: "\(analytics.totalMembers)",
                subtitle: "+\(analytics.newMembersThisPeriod) este mes",
                icon: "person.3.fill",
                color: .blue
            )
            
            StatCard(
                title: "Retención",
                value: "\(Int(analytics.memberRetentionRate * 100))%",
                subtitle: "Tasa de retención",
                icon: "chart.line.uptrend.xyaxis",
                color: .green
            )
            
            StatCard(
                title: "Ingresos",
                value: "$\(String(format: "%.0f", analytics.revenueThisPeriod))",
                subtitle: "Este mes",
                icon: "dollarsign.circle.fill",
                color: .orange
            )
            
            StatCard(
                title: "Entrenamientos",
                value: "\(String(format: "%.1f", analytics.averageWorkoutsPerMember))",
                subtitle: "Promedio por miembro",
                icon: "figure.strengthtraining.traditional",
                color: .purple
            )
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(title)
                    .font(.body)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
}

struct PeriodSelector: View {
    @Binding var selectedPeriod: GymAnalytics.AnalyticsPeriod
    
    var body: some View {
        HStack {
            Text("Período")
                .font(.headline)
                .fontWeight(.semibold)
            
            Spacer()
            
            Picker("Período", selection: $selectedPeriod) {
                ForEach(GymAnalytics.AnalyticsPeriod.allCases, id: \.self) { period in
                    Text(period.displayName).tag(period)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .frame(maxWidth: 200)
        }
    }
}

struct MemberActivityChart: View {
    let timeSlots: [TimeSlot]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Actividad por Horario")
                .font(.headline)
                .fontWeight(.semibold)
            
            Chart(timeSlots, id: \.hour) { slot in
                BarMark(
                    x: .value("Hora", slot.hour),
                    y: .value("Miembros", slot.memberCount)
                )
                .foregroundStyle(.blue.gradient)
            }
            .frame(height: 200)
            .chartXAxis {
                AxisMarks(values: .stride(by: 2)) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let hour = value.as(Int.self) {
                            Text("\(hour):00")
                                .font(.caption)
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
}

struct RevenueBreakdownChart: View {
    let membershipStats: [MembershipTypeStats]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Ingresos por Membresía")
                .font(.headline)
                .fontWeight(.semibold)
            
            Chart(membershipStats, id: \.membershipType) { stat in
                SectorMark(
                    angle: .value("Revenue", stat.revenue),
                    innerRadius: .ratio(0.5),
                    angularInset: 2
                )
                .foregroundStyle(by: .value("Type", stat.membershipType))
            }
            .frame(height: 200)
            
            // Legend
            VStack(alignment: .leading, spacing: 8) {
                ForEach(membershipStats, id: \.membershipType) { stat in
                    HStack {
                        Circle()
                            .fill(colorForMembership(stat.membershipType))
                            .frame(width: 12, height: 12)
                        
                        Text(stat.membershipType)
                            .font(.body)
                        
                        Spacer()
                        
                        Text("$\(String(format: "%.0f", stat.revenue))")
                            .font(.body)
                            .fontWeight(.medium)
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
    
    private func colorForMembership(_ type: String) -> Color {
        switch type {
        case "Básica": return .blue
        case "Premium": return .orange
        case "VIP": return .purple
        default: return .gray
        }
    }
}

struct QuickActionsGrid: View {
    let onMemberManagement: () -> Void
    let onClassManagement: () -> Void
    let onSettings: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Acciones Rápidas")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                QuickActionCard(
                    title: "Gestionar Usuarios",
                    icon: "person.3.sequence.fill",
                    color: .blue,
                    action: onMemberManagement
                )
                
                QuickActionCard(
                    title: "Clases",
                    icon: "calendar.badge.plus",
                    color: .green,
                    action: onClassManagement
                )
                
                QuickActionCard(
                    title: "Reportes",
                    icon: "chart.bar.doc.horizontal",
                    color: .orange,
                    action: {}
                )
                
                QuickActionCard(
                    title: "Configuración",
                    icon: "gearshape.fill",
                    color: .purple,
                    action: onSettings
                )
            }
        }
    }
}

struct QuickActionCard: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct RecentActivityCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Actividad Reciente")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                ActivityRow(
                    icon: "person.badge.plus",
                    title: "Nuevo miembro registrado",
                    subtitle: "María González se unió al plan Premium",
                    time: "Hace 2 horas",
                    color: .green
                )
                
                ActivityRow(
                    icon: "calendar.badge.clock",
                    title: "Clase programada",
                    subtitle: "Yoga Matutino - Mañana 7:00 AM",
                    time: "Hace 4 horas",
                    color: .blue
                )
                
                ActivityRow(
                    icon: "exclamationmark.triangle",
                    title: "Membresía por vencer",
                    subtitle: "5 membresías vencen esta semana",
                    time: "Hace 1 día",
                    color: .orange
                )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
}

struct ActivityRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let time: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(time)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Supporting Views (Placeholder)
struct GymSettingsView: View {
    var body: some View {
        Text("Configuración del Gimnasio")
            .navigationTitle("Configuración")
    }
}

struct MemberManagementView: View {
    var body: some View {
        Text("Gestión de Miembros")
            .navigationTitle("Miembros")
    }
}

struct ClassManagementView: View {
    var body: some View {
        Text("Gestión de Clases")
            .navigationTitle("Clases")
    }
}

#Preview {
    GymAdminDashboard()
}
