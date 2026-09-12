import Foundation

public struct AnswerRecord: Codable, Identifiable, Sendable {
    public let id: UUID
    public let exerciseID: String
    public let topic: StudyTopic
    public let correct: Bool
    public let date: Date

    public init(id: UUID = UUID(), exerciseID: String, topic: StudyTopic, correct: Bool, date: Date = Date()) {
        self.id = id
        self.exerciseID = exerciseID
        self.topic = topic
        self.correct = correct
        self.date = date
    }
}

public struct LearningProgress: Codable, Sendable {
    public var answers: [AnswerRecord] = []
    public var completedLessonIDs: Set<String> = []
    public init() {}

    public var accuracy: Double? {
        guard !answers.isEmpty else { return nil }
        return Double(answers.filter(\.correct).count) / Double(answers.count)
    }

    public var reviewIDs: Set<String> {
        var latest: [String: Bool] = [:]
        for answer in answers { latest[answer.exerciseID] = answer.correct }
        return Set(latest.filter { !$0.value }.keys)
    }

    public func answeredToday(now: Date = Date(), calendar: Calendar = .current) -> Int {
        answers.filter { calendar.isDate($0.date, inSameDayAs: now) }.count
    }

    public func streak(now: Date = Date(), calendar: Calendar = .current) -> Int {
        let dates = Set(answers.map { calendar.startOfDay(for: $0.date) })
        let today = calendar.startOfDay(for: now)
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: today) else { return 0 }
        var day = dates.contains(today) ? today : yesterday
        var count = 0
        while dates.contains(day) {
            count += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = previous
        }
        return count
    }

    public mutating func record(_ answer: AnswerRecord) {
        guard !answers.contains(where: { $0.id == answer.id }) else { return }
        answers.append(answer)
    }
}
