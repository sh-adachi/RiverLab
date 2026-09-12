import XCTest
@testable import RiverLabCore

final class LearningTests: XCTestCase {
    func testWrongAnswersRemainForReviewUntilCorrectedAndDuplicateRecordsAreIgnored() throws {
        var progress = LearningProgress()
        let wrong = AnswerRecord(exerciseID: "probability-01", topic: .probability, correct: false)
        progress.record(wrong)
        progress.record(wrong)
        XCTAssertEqual(progress.answers.count, 1)
        XCTAssertEqual(progress.reviewIDs, ["probability-01"])
        progress.record(AnswerRecord(exerciseID: "probability-01", topic: .probability, correct: true))
        XCTAssertTrue(progress.reviewIDs.isEmpty)
        XCTAssertEqual(progress.accuracy, 0.5)
        progress.completedLessonIDs.insert("basics-flow")
        let restored = try JSONDecoder().decode(LearningProgress.self, from: JSONEncoder().encode(progress))
        XCTAssertEqual(restored.answers.count, 2)
        XCTAssertEqual(restored.completedLessonIDs, ["basics-flow"])
        XCTAssertTrue(restored.reviewIDs.isEmpty)
    }

    func testStreakUsesCalendarDaysAndAllowsTodayToBeIncomplete() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        let today = calendar.date(from: DateComponents(year: 2026, month: 9, day: 13, hour: 0, minute: 5))!
        let yesterday = today.addingTimeInterval(-600)
        let twoDaysAgo = yesterday.addingTimeInterval(-86400)
        var progress = LearningProgress()
        XCTAssertNil(progress.accuracy)
        XCTAssertEqual(progress.streak(now: today, calendar: calendar), 0)
        for date in [twoDaysAgo, yesterday, yesterday] {
            progress.record(AnswerRecord(exerciseID: "gto-01", topic: .gto, correct: true, date: date))
        }
        XCTAssertEqual(progress.streak(now: today, calendar: calendar), 2)
        XCTAssertEqual(progress.answeredToday(now: today, calendar: calendar), 0)
        progress.record(AnswerRecord(exerciseID: "basics-01", topic: .basics, correct: false, date: today))
        XCTAssertEqual(progress.streak(now: today, calendar: calendar), 3)
        XCTAssertEqual(progress.answeredToday(now: today, calendar: calendar), 1)
        XCTAssertEqual(progress.streak(now: today.addingTimeInterval(172800), calendar: calendar), 0)
    }

    func testCurriculumQuestionsHaveValidUniqueCardsAndUnambiguousAnswerIndices() {
        XCTAssertEqual(Set(Curriculum.exercises.map(\.id)).count, Curriculum.exercises.count)
        XCTAssertEqual(Set(Curriculum.lessons.map(\.id)).count, Curriculum.lessons.count)
        for exercise in Curriculum.exercises {
            XCTAssertTrue(exercise.choices.indices.contains(exercise.answerIndex), exercise.id)
            XCTAssertEqual(Set(exercise.choices).count, exercise.choices.count, exercise.id)
            let cards = exercise.hero + exercise.board
            XCTAssertEqual(Set(cards).count, cards.count, exercise.id)
            XCTAssertTrue(exercise.hero.isEmpty || exercise.hero.count == 2, exercise.id)
            XCTAssertTrue([0, 3, 4, 5].contains(exercise.board.count), exercise.id)
            for card in cards {
                XCTAssertEqual(card.count, 2, exercise.id)
                XCTAssertTrue("23456789TJQKA".contains(card.first!), exercise.id)
                XCTAssertTrue("cdhs".contains(card.last!), exercise.id)
            }
        }
        for topic in StudyTopic.allCases {
            XCTAssertGreaterThanOrEqual(Curriculum.exercises.filter { $0.topic == topic }.count, 5)
            XCTAssertFalse(Curriculum.lessons.filter { $0.topic == topic }.isEmpty)
        }
    }

    func testSimplifiedRiverEquilibriumMakesBothPlayersIndifferent() {
        for bet in [25.0, 50.0, 100.0, 200.0] {
            let pot = 100.0
            let defense = PokerMath.minimumDefenseFrequency(pot: pot, bet: bet)
            let bluffShare = PokerMath.bluffFraction(pot: pot, bet: bet)
            XCTAssertEqual((1 - defense) * pot - defense * bet, 0, accuracy: 1e-10)
            XCTAssertEqual(PokerMath.callEV(equity: bluffShare, potBeforeBet: pot, bet: bet), 0, accuracy: 1e-10)
        }
    }
}
