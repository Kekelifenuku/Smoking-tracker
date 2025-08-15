import SwiftUI
import Foundation

// MARK: - Data Models
struct SmokingSession: Identifiable, Codable {
    let id = UUID()
    let timestamp: Date
    let triggerType: TriggerType
    let location: String
    let mood: MoodType
    let notes: String
    
    enum TriggerType: String, CaseIterable, Codable {
        case stress = "Stress"
        case social = "Social"
        case boredom = "Boredom"
        case habit = "Habit"
        case alcohol = "Alcohol"
        case `break` = "Break"
        
        var icon: String {
            switch self {
            case .stress: return "exclamationmark.triangle"
            case .social: return "person.2"
            case .boredom: return "clock"
            case .habit: return "repeat"
            case .alcohol: return "wineglass"
            case .break: return "pause.circle"
            }
        }
    }
    
    enum MoodType: String, CaseIterable, Codable {
        case happy = "Happy"
        case stressed = "Stressed"
        case anxious = "Anxious"
        case relaxed = "Relaxed"
        case sad = "Sad"
        case neutral = "Neutral"
        
        var emoji: String {
            switch self {
            case .happy: return "😊"
            case .stressed: return "😰"
            case .anxious: return "😟"
            case .relaxed: return "😌"
            case .sad: return "😢"
            case .neutral: return "😐"
            }
        }
    }
}

struct Milestone: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let hoursRequired: Int
    let icon: String
    let color: Color
    
    static let milestones = [
        Milestone(title: "20 Minutes", description: "Heart rate returns to normal", hoursRequired: 0, icon: "heart", color: .red),
        Milestone(title: "12 Hours", description: "Carbon monoxide levels drop", hoursRequired: 12, icon: "lungs", color: .blue),
        Milestone(title: "24 Hours", description: "Risk of heart attack decreases", hoursRequired: 24, icon: "heart.circle", color: .green),
        Milestone(title: "48 Hours", description: "Nerve endings regrow", hoursRequired: 48, icon: "brain", color: .purple),
        Milestone(title: "72 Hours", description: "Breathing improves", hoursRequired: 72, icon: "wind", color: .cyan),
        Milestone(title: "1 Week", description: "Taste and smell improve", hoursRequired: 168, icon: "nose", color: .orange),
        Milestone(title: "1 Month", description: "Circulation improves", hoursRequired: 720, icon: "drop", color: .pink),
        Milestone(title: "3 Months", description: "Lung function increases", hoursRequired: 2160, icon: "lungs.fill", color: .mint),
        Milestone(title: "1 Year", description: "Heart disease risk halved", hoursRequired: 8760, icon: "star.fill", color: .yellow)
    ]
}

struct CravingEntry: Identifiable, Codable {
    let id = UUID()
    let timestamp: Date
    let intensity: Int // 1-10
    let duration: TimeInterval
    let copingStrategy: String
    let wasSuccessful: Bool
}

// MARK: - Data Manager
class SmokingTrackerData: ObservableObject {
    @Published var smokingSessions: [SmokingSession] = []
    @Published var cravings: [CravingEntry] = []
    @Published var quitDate: Date = Date()
    @Published var cigarettesPerDayBefore: Int = 10
    @Published var pricePerPack: Double = 8.0
    @Published var cigarettesPerPack: Int = 20
    
    private let userDefaults = UserDefaults.standard
    
    init() {
        loadData()
    }
    
    func saveData() {
        if let encoded = try? JSONEncoder().encode(smokingSessions) {
            userDefaults.set(encoded, forKey: "smokingSessions")
        }
        if let encoded = try? JSONEncoder().encode(cravings) {
            userDefaults.set(encoded, forKey: "cravings")
        }
        userDefaults.set(quitDate.timeIntervalSince1970, forKey: "quitDate")
        userDefaults.set(cigarettesPerDayBefore, forKey: "cigarettesPerDayBefore")
        userDefaults.set(pricePerPack, forKey: "pricePerPack")
        userDefaults.set(cigarettesPerPack, forKey: "cigarettesPerPack")
    }
    
    func loadData() {
        if let data = userDefaults.data(forKey: "smokingSessions"),
           let decoded = try? JSONDecoder().decode([SmokingSession].self, from: data) {
            smokingSessions = decoded
        }
        if let data = userDefaults.data(forKey: "cravings"),
           let decoded = try? JSONDecoder().decode([CravingEntry].self, from: data) {
            cravings = decoded
        }
        let quitDateTimestamp = userDefaults.double(forKey: "quitDate")
        if quitDateTimestamp > 0 {
            quitDate = Date(timeIntervalSince1970: quitDateTimestamp)
        }
        cigarettesPerDayBefore = userDefaults.integer(forKey: "cigarettesPerDayBefore")
        if cigarettesPerDayBefore == 0 { cigarettesPerDayBefore = 10 }
        pricePerPack = userDefaults.double(forKey: "pricePerPack")
        if pricePerPack == 0 { pricePerPack = 8.0 }
        cigarettesPerPack = userDefaults.integer(forKey: "cigarettesPerPack")
        if cigarettesPerPack == 0 { cigarettesPerPack = 20 }
    }
    
    func addSmokingSession(_ session: SmokingSession) {
        smokingSessions.append(session)
        saveData()
    }
    
    func addCraving(_ craving: CravingEntry) {
        cravings.append(craving)
        saveData()
    }
    
    var daysSinceQuit: Int {
        Calendar.current.dateComponents([.day], from: quitDate, to: Date()).day ?? 0
    }
    
    var hoursSinceQuit: Int {
        Int(Date().timeIntervalSince(quitDate) / 3600)
    }
    
    var cigarettesAvoided: Int {
        let days = max(0, daysSinceQuit)
        return days * cigarettesPerDayBefore - smokingSessions.count
    }
    
    var moneySaved: Double {
        let cigarettesNotSmoked = max(0, cigarettesAvoided)
        return Double(cigarettesNotSmoked) / Double(cigarettesPerPack) * pricePerPack
    }
    
    var currentStreak: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var streak = 0
        var currentDate = today
        
        while currentDate >= calendar.startOfDay(for: quitDate) {
            let sessionsOnDate = smokingSessions.filter {
                calendar.isDate($0.timestamp, inSameDayAs: currentDate)
            }
            
            if sessionsOnDate.isEmpty {
                streak += 1
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate)!
            } else {
                break
            }
        }
        
        return max(0, streak - 1) // Subtract 1 because we include today
    }
}



struct ContentView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                    Text("Dashboard")
                }
            
            CravingsView()
                .tabItem {
                    Image(systemName: "brain.head.profile")
                    Text("Cravings")
                }
            
            MilestonesView()
                .tabItem {
                    Image(systemName: "target")
                    Text("Milestones")
                }
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
        }
        .accentColor(.blue)
    }
}

// MARK: - Dashboard View
struct DashboardView: View {
    @EnvironmentObject var data: SmokingTrackerData
    @State private var showingAddSession = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 20) {
                    // Main Stats
                    StatsCardView()
                    
                    // Quick Actions
                    QuickActionsView(showingAddSession: $showingAddSession)
                    
                    // Progress Chart
                    ProgressChartView()
                    
                    // Recent Sessions
                    RecentSessionsView()
                }
                .padding()
            }
            .navigationTitle("Quit Smoking")
            .sheet(isPresented: $showingAddSession) {
                AddSessionView()
            }
        }
    }
}

struct StatsCardView: View {
    @EnvironmentObject var data: SmokingTrackerData
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                StatView(title: "Days Smoke-Free", value: "\(data.daysSinceQuit)", color: .green)
                StatView(title: "Current Streak", value: "\(data.currentStreak)", color: .blue)
            }
            
            HStack {
                StatView(title: "Cigarettes Avoided", value: "\(data.cigarettesAvoided)", color: .orange)
                StatView(title: "Money Saved", value: String(format: "$%.2f", data.moneySaved), color: .purple)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct StatView: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}

struct QuickActionsView: View {
    @Binding var showingAddSession: Bool
    @State private var showingCravingHelp = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)
            
            HStack(spacing: 12) {
                ActionButton(title: "I Smoked", icon: "exclamationmark.circle", color: .red) {
                    showingAddSession = true
                }
                
                ActionButton(title: "Beat Craving", icon: "checkmark.circle", color: .green) {
                    showingCravingHelp = true
                }
            }
        }
        .sheet(isPresented: $showingCravingHelp) {
            CravingHelpView()
        }
    }
}

struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack {
                Image(systemName: icon)
                    .font(.title2)
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .foregroundColor(color)
            .background(color.opacity(0.1))
            .cornerRadius(8)
        }
    }
}

struct ProgressChartView: View {
    @EnvironmentObject var data: SmokingTrackerData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("7-Day Progress")
                .font(.headline)
            
            HStack(spacing: 4) {
                ForEach(0..<7, id: \.self) { dayIndex in
                    let date = Calendar.current.date(byAdding: .day, value: -dayIndex, to: Date())!
                    let hasSmoked = data.smokingSessions.contains { session in
                        Calendar.current.isDate(session.timestamp, inSameDayAs: date)
                    }
                    
                    VStack {
                        Rectangle()
                            .fill(hasSmoked ? Color.red : Color.green)
                            .frame(height: 40)
                            .cornerRadius(4)
                        
                        Text(dayAbbreviation(for: date))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func dayAbbreviation(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return String(formatter.string(from: date).prefix(1)).uppercased()
    }
}

struct RecentSessionsView: View {
    @EnvironmentObject var data: SmokingTrackerData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Sessions")
                .font(.headline)
            
            if data.smokingSessions.isEmpty {
                Text("No sessions recorded yet")
                    .foregroundColor(.secondary)
                    .italic()
                    .padding()
            } else {
                ForEach(data.smokingSessions.suffix(3).reversed(), id: \.id) { session in
                    SessionRowView(session: session)
                }
            }
        }
    }
}

struct SessionRowView: View {
    let session: SmokingSession
    private let relativeDateFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter
    }()
    
    var body: some View {
        HStack {
            Image(systemName: session.triggerType.icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(session.triggerType.rawValue)
                        .fontWeight(.medium)
                    Spacer()
                    Text(session.mood.emoji)
                }
                Text(relativeDateFormatter.localizedString(for: session.timestamp, relativeTo: Date()))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

// MARK: - Add Session View
struct AddSessionView: View {
    @EnvironmentObject var data: SmokingTrackerData
    @Environment(\.presentationMode) var presentationMode
    
    @State private var selectedTrigger: SmokingSession.TriggerType = .stress
    @State private var selectedMood: SmokingSession.MoodType = .neutral
    @State private var location: String = ""
    @State private var notes: String = ""
    @State private var timestamp: Date = Date()
    
    var body: some View {
        NavigationView {
            Form {
                Section("When") {
                    DatePicker("Time", selection: $timestamp, displayedComponents: [.date, .hourAndMinute])
                }
                
                Section("Trigger") {
                    Picker("What triggered this?", selection: $selectedTrigger) {
                        ForEach(SmokingSession.TriggerType.allCases, id: \.self) { trigger in
                            HStack {
                                Image(systemName: trigger.icon)
                                Text(trigger.rawValue)
                            }
                            .tag(trigger)
                        }
                    }
                    .pickerStyle(WheelPickerStyle())
                }
                
                Section("Mood") {
                    Picker("How did you feel?", selection: $selectedMood) {
                        ForEach(SmokingSession.MoodType.allCases, id: \.self) { mood in
                            HStack {
                                Text(mood.emoji)
                                Text(mood.rawValue)
                            }
                            .tag(mood)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section("Location") {
                    TextField("Where were you?", text: $location)
                }
                
                Section("Notes") {
                    TextField("Additional thoughts...", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Log Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let session = SmokingSession(
                            timestamp: timestamp,
                            triggerType: selectedTrigger,
                            location: location,
                            mood: selectedMood,
                            notes: notes
                        )
                        data.addSmokingSession(session)
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Cravings View
struct CravingsView: View {
    @EnvironmentObject var data: SmokingTrackerData
    @State private var showingCravingTimer = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 20) {
                    CravingStatsView()
                    CravingStrategiesView()
                    RecentCravingsView()
                }
                .padding()
            }
            .navigationTitle("Cravings")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("New Craving") {
                        showingCravingTimer = true
                    }
                }
            }
        }
        .sheet(isPresented: $showingCravingTimer) {
            CravingTimerView()
        }
    }
}

struct CravingStatsView: View {
    @EnvironmentObject var data: SmokingTrackerData
    
    var cravingsToday: Int {
        Calendar.current.isDateInToday(Date()) ?
        data.cravings.filter { Calendar.current.isDateInToday($0.timestamp) }.count : 0
    }
    
    var successRate: Double {
        guard !data.cravings.isEmpty else { return 0 }
        let successful = data.cravings.filter { $0.wasSuccessful }.count
        return Double(successful) / Double(data.cravings.count) * 100
    }
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                StatView(title: "Cravings Today", value: "\(cravingsToday)", color: .orange)
                StatView(title: "Success Rate", value: String(format: "%.1f%%", successRate), color: .green)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct CravingStrategiesView: View {
    private let strategies = [
        ("Deep Breathing", "Take 10 deep breaths", "wind"),
        ("Drink Water", "Hydrate and occupy your mouth", "drop"),
        ("Go for a Walk", "Change your environment", "figure.walk"),
        ("Call Someone", "Connect with support", "phone"),
        ("Chew Gum", "Keep your mouth busy", "mouth"),
        ("Meditate", "Focus on the present", "brain.head.profile")
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Craving Strategies")
                .font(.headline)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(Array(strategies.enumerated()), id: \.offset) { _, strategy in
                    StrategyCard(title: strategy.0, description: strategy.1, icon: strategy.2)
                }
            }
        }
    }
}

struct StrategyCard: View {
    let title: String
    let description: String
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
            
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
            
            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(radius: 1)
    }
}

struct RecentCravingsView: View {
    @EnvironmentObject var data: SmokingTrackerData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Cravings")
                .font(.headline)
            
            if data.cravings.isEmpty {
                Text("No cravings recorded yet")
                    .foregroundColor(.secondary)
                    .italic()
                    .padding()
            } else {
                ForEach(data.cravings.suffix(5).reversed(), id: \.id) { craving in
                    CravingRowView(craving: craving)
                }
            }
        }
    }
}

struct CravingRowView: View {
    let craving: CravingEntry
    private let relativeDateFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter
    }()
    
    var body: some View {
        HStack {
            Circle()
                .fill(craving.wasSuccessful ? Color.green : Color.red)
                .frame(width: 10, height: 10)
            
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text("Intensity: \(craving.intensity)/10")
                        .fontWeight(.medium)
                    Spacer()
                    Text(craving.wasSuccessful ? "✅" : "❌")
                }
                Text(relativeDateFormatter.localizedString(for: craving.timestamp, relativeTo: Date()))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

// MARK: - Craving Timer View
struct CravingTimerView: View {
    @EnvironmentObject var data: SmokingTrackerData
    @Environment(\.presentationMode) var presentationMode
    
    @State private var intensity: Int = 5
    @State private var startTime = Date()
    @State private var isActive = false
    @State private var timeRemaining = 300 // 5 minutes
    @State private var copingStrategy = ""
    @State private var timer: Timer?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Text("Craving Timer")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                VStack(spacing: 20) {
                    Text("Intensity: \(intensity)/10")
                        .font(.title2)
                    
                    Slider(value: Binding(
                        get: { Double(intensity) },
                        set: { intensity = Int($0) }
                    ), in: 1...10, step: 1)
                    .tint(.orange)
                }
                .padding(.horizontal)
                
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 10)
                        .frame(width: 200, height: 200)
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(300 - timeRemaining) / 300)
                        .stroke(Color.blue, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                        .frame(width: 200, height: 200)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear, value: timeRemaining)
                    
                    VStack {
                        Text(timeString(timeRemaining))
                            .font(.title)
                            .fontWeight(.bold)
                        Text("Cravings usually pass\nin 3-5 minutes")
                            .font(.caption)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                    }
                }
                
                TextField("What strategy are you using?", text: $copingStrategy)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                
                Button(isActive ? "Stop Timer" : "Start Timer") {
                    toggleTimer()
                }
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(isActive ? Color.red : Color.blue)
                .cornerRadius(10)
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        timer?.invalidate()
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        saveCraving(successful: true)
                    }
                    .disabled(!isActive && timeRemaining == 300)
                }
            }
        }
    }
    
    private func toggleTimer() {
        if isActive {
            timer?.invalidate()
            saveCraving(successful: false)
        } else {
            startTime = Date()
            isActive = true
            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                if timeRemaining > 0 {
                    timeRemaining -= 1
                } else {
                    timer?.invalidate()
                    isActive = false
                    saveCraving(successful: true)
                }
            }
        }
    }
    
    private func saveCraving(successful: Bool) {
        let duration = Date().timeIntervalSince(startTime)
        let craving = CravingEntry(
            timestamp: startTime,
            intensity: intensity,
            duration: duration,
            copingStrategy: copingStrategy,
            wasSuccessful: successful
        )
        data.addCraving(craving)
        timer?.invalidate()
        presentationMode.wrappedValue.dismiss()
    }
    
    private func timeString(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
}

// MARK: - Craving Help View
struct CravingHelpView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("You've got this! 💪")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Quick Strategies:")
                            .font(.headline)
                        
                        ForEach([
                            "Take 10 deep breaths",
                            "Drink a glass of water",
                            "Go for a 5-minute walk",
                            "Call a friend or family member",
                            "Do 10 push-ups or jumping jacks",
                            "Chew gum or eat a healthy snack"
                        ], id: \.self) { strategy in
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text(strategy)
                            }
                        }
                    }
                    
                    Text("Remember: Cravings are temporary and will pass. You've already made it this far!")
                        .font(.body)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                }
                .padding()
            }
            .navigationTitle("Beat This Craving")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Milestones View
struct MilestonesView: View {
    @EnvironmentObject var data: SmokingTrackerData
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(Milestone.milestones) { milestone in
                        MilestoneCard(milestone: milestone, achieved: data.hoursSinceQuit >= milestone.hoursRequired)
                    }
                }
                .padding()
            }
            .navigationTitle("Health Milestones")
        }
    }
}

struct MilestoneCard: View {
    let milestone: Milestone
    let achieved: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(achieved ? milestone.color : Color.gray.opacity(0.3))
                    .frame(width: 50, height: 50)
                
                Image(systemName: milestone.icon)
                    .font(.title2)
                    .foregroundColor(achieved ? .white : .gray)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(milestone.title)
                    .font(.headline)
                    .foregroundColor(achieved ? .primary : .secondary)
                
                Text(milestone.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if achieved {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.green)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        .opacity(achieved ? 1.0 : 0.6)
    }
}

// MARK: - Settings View
struct SettingsView: View {
    @EnvironmentObject var data: SmokingTrackerData
    @State private var showingQuitDatePicker = false
    
    var body: some View {
        NavigationView {
            Form {
                Section("Quit Information") {
                    HStack {
                        Text("Quit Date")
                        Spacer()
                        Button(DateFormatter.shortDate.string(from: data.quitDate)) {
                            showingQuitDatePicker = true
                        }
                        .foregroundColor(.blue)
                    }
                    
                    HStack {
                        Text("Cigarettes per day (before)")
                        Spacer()
                        Text("\(data.cigarettesPerDayBefore)")
                            .foregroundColor(.secondary)
                    }
                    
                    Stepper("Cigarettes per day: \(data.cigarettesPerDayBefore)", value: $data.cigarettesPerDayBefore, in: 1...50) { _ in
                        data.saveData()
                    }
                }
                
                Section("Cost Information") {
                    HStack {
                        Text("Price per pack")
                        Spacer()
                        Text(String(format: "$%.2f", data.pricePerPack))
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Cigarettes per pack")
                        Spacer()
                        Text("\(data.cigarettesPerPack)")
                            .foregroundColor(.secondary)
                    }
                    
                    Stepper("Price per pack: $\(String(format: "%.2f", data.pricePerPack))", value: $data.pricePerPack, in: 1...50, step: 0.5) { _ in
                        data.saveData()
                    }
                    
                    Stepper("Cigarettes per pack: \(data.cigarettesPerPack)", value: $data.cigarettesPerPack, in: 10...30) { _ in
                        data.saveData()
                    }
                }
                
                Section("Statistics") {
                    StatisticRow(title: "Total Sessions Logged", value: "\(data.smokingSessions.count)")
                    StatisticRow(title: "Total Cravings Tracked", value: "\(data.cravings.count)")
                    StatisticRow(title: "Days Since Quit", value: "\(data.daysSinceQuit)")
                    StatisticRow(title: "Current Streak", value: "\(data.currentStreak) days")
                }
                
                Section("Motivational Quotes") {
                    MotivationalQuoteView()
                }
                
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    Text("This app helps you track your journey to quit smoking using principles from atomic habits and behavioral psychology.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Settings")
        }
        .sheet(isPresented: $showingQuitDatePicker) {
            QuitDatePickerView()
        }
    }
}

struct StatisticRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
        }
    }
}

struct MotivationalQuoteView: View {
    private let quotes = [
        "Every cigarette you don't smoke is doing you good. - Unknown",
        "You are stronger than your cravings. - Unknown",
        "Quitting smoking is easy, I've done it hundreds of times. - Mark Twain",
        "The best time to plant a tree was 20 years ago. The second best time is now. - Chinese Proverb",
        "Success is the sum of small efforts repeated day in and day out. - Robert Collier"
    ]
    
    @State private var currentQuote = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(quotes[currentQuote])
                .font(.body)
                .italic()
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            
            Button("New Quote") {
                currentQuote = (currentQuote + 1) % quotes.count
            }
            .font(.caption)
            .foregroundColor(.blue)
        }
    }
}

struct QuitDatePickerView: View {
    @EnvironmentObject var data: SmokingTrackerData
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedDate: Date
    
    init() {
        _selectedDate = State(initialValue: Date())
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("When did you quit smoking?")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                DatePicker("Quit Date", selection: $selectedDate, in: ...Date(), displayedComponents: [.date])
                    .datePickerStyle(WheelDatePickerStyle())
                    .padding()
                
                Spacer()
            }
            .padding()
            .navigationTitle("Set Quit Date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        data.quitDate = selectedDate
                        data.saveData()
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
        .onAppear {
            selectedDate = data.quitDate
        }
    }
}

// MARK: - Extensions
extension DateFormatter {
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
}

// MARK: - Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(SmokingTrackerData())
    }
}
