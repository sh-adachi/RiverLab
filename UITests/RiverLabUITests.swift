import XCTest

final class RiverLabUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting", "-AppleLanguages", "(ja)", "-AppleLocale", "ja_JP"]
        app.launch()
    }

    func testDailyTrainingCanBeCompletedAndRestarted() {
        for title in ["ホーム", "トレーニング", "学ぶ", "ラボ"] {
            XCTAssertTrue(app.tabBars.buttons[title].waitForExistence(timeout: 5))
        }
        capture("ホーム")
        revealAndTap(app.buttons["今日の5問をはじめる"])

        for questionIndex in 0..<5 {
            let answer = app.buttons["answer_0"]
            revealAndTap(answer)
            // Feedback must lock the selected answer before advancing, avoiding double scoring.
            XCTAssertFalse(answer.isEnabled)
            if questionIndex < 4 {
                revealAndTap(app.buttons["次の問題"])
            } else {
                revealAndTap(app.buttons["結果を見る"])
            }
        }

        XCTAssertTrue(app.staticTexts["セッション結果"].firstMatch.waitForExistence(timeout: 5))
        capture("5問のセッション結果")
        revealAndTap(app.buttons["ホームに戻る"])
        XCTAssertTrue(app.buttons["今日の5問をはじめる"].waitForExistence(timeout: 5))
        revealAndTap(app.buttons["今日の5問をはじめる"])
        let answer = app.buttons["answer_0"]
        XCTAssertTrue(answer.waitForExistence(timeout: 5))
        XCTAssertTrue(answer.isEnabled)
    }

    func testLessonCompletionPersistsAcrossRelaunch() {
        selectTab("学ぶ")
        let firstLesson = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "lesson_")).firstMatch
        XCTAssertTrue(firstLesson.waitForExistence(timeout: 5))
        let lessonIdentifier = firstLesson.identifier
        capture("基礎から学ぶ")
        revealAndTap(firstLesson)
        revealAndTap(app.buttons["学習を完了する"])
        XCTAssertTrue(app.buttons[lessonIdentifier].waitForExistence(timeout: 5))

        app.terminate()
        app.launchArguments = ["--uitesting-preserve", "-AppleLanguages", "(ja)", "-AppleLocale", "ja_JP"]
        app.launch()
        selectTab("学ぶ")
        revealAndTap(app.buttons[lessonIdentifier])
        let completed = app.buttons["学習済み・一覧に戻る"]
        reveal(completed)
        XCTAssertTrue(completed.exists)
        XCTAssertFalse(app.buttons["学習を完了する"].exists)
        capture("レッスンの学習済み状態を復元")
        completed.tap()
        XCTAssertTrue(app.buttons[lessonIdentifier].waitForExistence(timeout: 5))
    }

    func testProbabilityLabCalculatesAndCardPickerExcludesDuplicates() {
        selectTab("ラボ")
        let required = app.staticTexts["requiredEquity"]
        reveal(required)
        XCTAssertEqual(required.label, "25.0%")
        let ev = app.staticTexts["callEV"]
        reveal(ev)
        XCTAssertEqual(ev.label, "+10.0 bb")
        capture("ポットオッズと期待値")
        revealAndTap(app.buttons["エクイティ"])
        revealAndTap(app.buttons["cardSlot_0"])
        XCTAssertTrue(app.buttons["pick_Ah"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["pick_Ah"].isEnabled)
        revealAndTap(app.buttons["pick_Ac"])
        revealAndTap(app.buttons["calculateEquity"])
        let equity = app.staticTexts["equityResult"]
        XCTAssertTrue(equity.waitForExistence(timeout: 15))
        reveal(equity)
        XCTAssertFalse(equity.label.isEmpty)
        capture("ハンド対ハンドのエクイティ")
    }

    private func selectTab(_ title: String) {
        let tab = app.tabBars.buttons[title]
        XCTAssertTrue(tab.waitForExistence(timeout: 5))
        tab.tap()
    }

    private func revealAndTap(_ element: XCUIElement) {
        reveal(element)
        XCTAssertTrue(element.waitForExistence(timeout: 5))
        XCTAssertTrue(element.isHittable)
        element.tap()
    }

    private func reveal(_ element: XCUIElement) {
        for _ in 0..<12 {
            if element.exists && element.isHittable { return }
            app.swipeUp()
        }
        for _ in 0..<12 {
            if element.exists && element.isHittable { return }
            app.swipeDown()
        }
    }

    private func capture(_ title: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = title
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
