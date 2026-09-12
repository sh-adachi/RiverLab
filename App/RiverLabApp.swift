import SwiftUI

@main
struct RiverLabApp: App {
    @StateObject private var store = StudyStore()
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .preferredColorScheme(.dark)
                .tint(Palette.mint)
        }
    }
}

@MainActor
final class StudyStore: ObservableObject {
    @Published private(set) var progress = LearningProgress()
    @Published var storageWarning: String?
    private let defaults: UserDefaults
    private let key = "riverlab.progress.v1"

    init() {
        let arguments = ProcessInfo.processInfo.arguments
        let testing = arguments.contains("--uitesting") || arguments.contains("--uitesting-preserve")
        defaults = testing ? UserDefaults(suiteName: "jp.adachi.riverlab.uitests")! : .standard
        if arguments.contains("--uitesting") { defaults.removeObject(forKey: key) }
        if let data = defaults.data(forKey: key) {
            do { progress = try JSONDecoder().decode(LearningProgress.self, from: data) }
            catch { storageWarning = "学習記録を読み込めませんでした。保存済みデータを保護するため、この起動中の記録は保存しません。" }
        }
    }

    func record(_ exercise: Exercise, correct: Bool) {
        progress.record(AnswerRecord(exerciseID: exercise.id, topic: exercise.topic, correct: correct))
        save()
    }

    func complete(_ lesson: Lesson) {
        progress.completedLessonIDs.insert(lesson.id)
        save()
    }

    private func save() {
        guard storageWarning == nil else { return }
        do { defaults.set(try JSONEncoder().encode(progress), forKey: key) }
        catch { storageWarning = "学習記録を保存できませんでした。" }
    }

    func questions(topic: StudyTopic? = nil, review: Bool = false, count: Int = 5) -> [Exercise] {
        var available = Curriculum.exercises.filter {
            (topic == nil || $0.topic == topic) && (!review || progress.reviewIDs.contains($0.id))
        }
        if ProcessInfo.processInfo.arguments.contains("--uitesting") { return Array(available.prefix(count)) }
        available.shuffle()
        if topic == nil && !review {
            var balanced = StudyTopic.allCases.compactMap { topic in available.first { $0.topic == topic } }
            let chosen = Set(balanced.map(\.id))
            balanced += available.filter { !chosen.contains($0.id) }
            return Array(balanced.prefix(count)).shuffled()
        }
        return Array(available.prefix(count))
    }
}

enum Palette {
    static let background = Color(red: 0.038, green: 0.064, blue: 0.078)
    static let surface = Color(red: 0.077, green: 0.11, blue: 0.128)
    static let elevated = Color(red: 0.105, green: 0.15, blue: 0.17)
    static let mint = Color(red: 0.59, green: 0.91, blue: 0.77)
    static let cream = Color(red: 0.95, green: 0.93, blue: 0.86)
    static let muted = Color(red: 0.61, green: 0.68, blue: 0.69)
    static let gold = Color(red: 0.90, green: 0.73, blue: 0.44)
    static let red = Color(red: 1, green: 0.52, blue: 0.50)
}

struct Panel<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }
    var body: some View {
        content.padding(20).frame(maxWidth: .infinity, alignment: .leading)
            .background(Palette.surface, in: RoundedRectangle(cornerRadius: 24))
            .overlay(RoundedRectangle(cornerRadius: 24).strokeBorder(.white.opacity(0.055)))
    }
}

struct PrimaryButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.system(.headline, design: .rounded)).frame(maxWidth: .infinity)
            .padding(.horizontal, 16).padding(.vertical, 17).background(Palette.mint, in: RoundedRectangle(cornerRadius: 16))
            .foregroundStyle(Palette.background).opacity(configuration.isPressed ? 0.75 : 1)
    }
}

struct Eyebrow: View {
    let text: String
    var body: some View {
        Text(text).font(.system(size: 11, weight: .bold, design: .monospaced))
            .tracking(2).foregroundStyle(Palette.mint)
    }
}

struct PageHeading: View {
    let eyebrow: String
    let title: String
    let subtitle: String
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Eyebrow(text: eyebrow)
            Text(title).font(.system(size: 30, weight: .bold, design: .rounded)).foregroundStyle(Palette.cream)
            Text(subtitle).font(.subheadline).foregroundStyle(Palette.muted).lineSpacing(4)
        }.frame(maxWidth: .infinity, alignment: .leading).padding(.top, 14).padding(.bottom, 6)
    }
}

struct Screen<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) { content }
                .padding(.horizontal, 22).padding(.bottom, 32).frame(maxWidth: 650)
                .frame(maxWidth: .infinity)
        }.background(Palette.background).foregroundStyle(Palette.cream)
    }
}

struct PlayingCard: View {
    let code: String
    var small = false
    private var rank: String { let r = String(code.dropLast()); return r == "T" ? "10" : r }
    private var suit: String { ["h":"♥", "d":"♦", "c":"♣", "s":"♠"][String(code.suffix(1))] ?? "♠" }
    private var isRed: Bool { code.hasSuffix("h") || code.hasSuffix("d") }
    var body: some View {
        VStack(spacing: 0) {
            Text(rank).font(.system(size: small ? 19 : 27, weight: .bold, design: .rounded))
            Text(suit).font(.system(size: small ? 16 : 24))
        }
        .foregroundStyle(isRed ? Color(red: 0.76, green: 0.25, blue: 0.26) : Palette.background)
        .frame(width: small ? 40 : 57, height: small ? 56 : 79)
        .background(Palette.cream, in: RoundedRectangle(cornerRadius: small ? 7 : 10))
        .overlay(RoundedRectangle(cornerRadius: small ? 7 : 10).strokeBorder(.white.opacity(0.4)))
        .accessibilityLabel("\(rank) \(suit)")
    }
}

extension StudyTopic {
    var tint: Color {
        switch self { case .basics: return Palette.gold; case .probability: return Palette.mint; case .gto: return Color(red: 0.65, green: 0.73, blue: 1) }
    }
}
