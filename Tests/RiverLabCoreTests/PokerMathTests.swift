import XCTest
@testable import RiverLabCore

final class PokerMathTests: XCTestCase {
    private func cards(_ notation: String) -> [Card] {
        notation.split(separator: " ").map { token in
            let characters = Array(token)
            let faces: [Character: Int] = ["T": 10, "J": 11, "Q": 12, "K": 13, "A": 14]
            let suits: [Character: Suit] = ["c": .clubs, "d": .diamonds, "h": .hearts, "s": .spades]
            return Card(rank: faces[characters[0]] ?? Int(String(characters[0]))!, suit: suits[characters[1]]!)
        }
    }

    func testDeckContains52DistinctCards() {
        XCTAssertEqual(Card.deck.count, 52)
        XCTAssertEqual(Set(Card.deck).count, 52)
        XCTAssertEqual(Card(rank: 14, suit: .spades).label, "A♠")
    }

    func testPotOddsAndCallEVUsePotBeforeOpponentsBet() {
        XCTAssertEqual(PokerMath.requiredEquity(potBeforeBet: 100, bet: 50), 0.25, accuracy: 1e-12)
        XCTAssertEqual(PokerMath.callEV(equity: 0.25, potBeforeBet: 100, bet: 50), 0, accuracy: 1e-12)
        XCTAssertEqual(PokerMath.callEV(equity: 0.30, potBeforeBet: 100, bet: 50), 10, accuracy: 1e-12)
        XCTAssertEqual(PokerMath.callEV(equity: 0, potBeforeBet: 100, bet: 50), -50)
        XCTAssertEqual(PokerMath.callEV(equity: 1, potBeforeBet: 100, bet: 50), 150)
        XCTAssertEqual(PokerMath.minimumDefenseFrequency(pot: 100, bet: 50), 2.0 / 3, accuracy: 1e-12)
        XCTAssertEqual(PokerMath.bluffFraction(pot: 100, bet: 100), 1.0 / 3, accuracy: 1e-12)
    }

    func testDrawProbabilityUsesSamplingWithoutReplacement() {
        XCTAssertEqual(PokerMath.drawProbability(outs: 9, unseenCards: 47, cardsToCome: 1), 9.0 / 47, accuracy: 1e-12)
        XCTAssertEqual(PokerMath.drawProbability(outs: 9, unseenCards: 47, cardsToCome: 2), 1 - (38.0 / 47) * (37.0 / 46), accuracy: 1e-12)
        XCTAssertEqual(PokerMath.drawProbability(outs: 9, unseenCards: 46, cardsToCome: 1), 9.0 / 46, accuracy: 1e-12)
        XCTAssertEqual(PokerMath.drawProbability(outs: 0, unseenCards: 47, cardsToCome: 2), 0)
        XCTAssertEqual(PokerMath.drawProbability(outs: 5, unseenCards: 5, cardsToCome: 1), 1)
        XCTAssertEqual(PokerMath.drawProbability(outs: 1, unseenCards: 5, cardsToCome: 5), 1)
        XCTAssertTrue(PokerMath.drawProbability(outs: 48, unseenCards: 47, cardsToCome: 1).isNaN)
    }

    func testInvalidMathInputsAndFreeCheck() {
        XCTAssertTrue(PokerMath.requiredEquity(potBeforeBet: -1, bet: 10).isNaN)
        XCTAssertTrue(PokerMath.callEV(equity: 1.1, potBeforeBet: 100, bet: 10).isNaN)
        XCTAssertTrue(PokerMath.minimumDefenseFrequency(pot: .infinity, bet: 10).isNaN)
        XCTAssertEqual(PokerMath.requiredEquity(potBeforeBet: 100, bet: 0), 0)
        XCTAssertEqual(PokerMath.minimumDefenseFrequency(pot: 100, bet: 0), 1)
    }

    func testWheelIsFiveHighAndLosesToSixHighStraight() throws {
        let wheel = try HandEvaluator.evaluate(cards("As 2d 3c 4h 5s"))
        let sixHigh = try HandEvaluator.evaluate(cards("2s 3d 4c 5h 6s"))
        XCTAssertEqual(wheel.category, .straight)
        XCTAssertEqual(wheel.kickers, [5])
        XCTAssertLessThan(wheel, sixHigh)
    }

    func testFlushBeatsStraightAndFullHouseBeatsFlush() throws {
        let straight = try HandEvaluator.evaluate(cards("Ts Jd Qc Kh As"))
        let flush = try HandEvaluator.evaluate(cards("2h 5h 7h Jh Ah"))
        let fullHouse = try HandEvaluator.evaluate(cards("3c 3d 3h 2s 2d"))
        XCTAssertEqual(flush.category, .flush)
        XCTAssertEqual(fullHouse.category, .fullHouse)
        XCTAssertGreaterThan(flush, straight)
        XCTAssertGreaterThan(fullHouse, flush)
    }

    func testBestFiveOfSevenChoosesHigherFullHouseWithTwoTrips() throws {
        let value = try HandEvaluator.evaluate(cards("Ac Ad Ah Kc Kd Kh 2s"))
        XCTAssertEqual(value.category, .fullHouse)
        XCTAssertEqual(value.kickers, [14, 13])
    }

    func testBestFiveOfSevenCanPlayTheBoardAndIgnoreHoleCards() throws {
        let board = cards("Ts Js Qs Ks As")
        let first = try HandEvaluator.evaluate(cards("2c 3d") + board)
        let second = try HandEvaluator.evaluate(cards("4c 5d") + board)
        XCTAssertEqual(first, second)
        XCTAssertEqual(first.category, .straightFlush)
        XCTAssertEqual(first.kickers, [14])
    }

    func testKickersAndPairOrderingBreakTies() throws {
        XCTAssertGreaterThan(
            try HandEvaluator.evaluate(cards("Ac Ad Kh Qs 9c 3s 2d")),
            try HandEvaluator.evaluate(cards("Ah As Kc Jd Tc 4s 2h"))
        )
        XCTAssertGreaterThan(
            try HandEvaluator.evaluate(cards("Ac Ad 2h 2s 3c")),
            try HandEvaluator.evaluate(cards("Kh Ks Qc Qd Ah"))
        )
        XCTAssertGreaterThan(
            try HandEvaluator.evaluate(cards("9c 9d 9h 9s Ac")),
            try HandEvaluator.evaluate(cards("8c 8d 8h 8s Ac"))
        )
    }

    func testExactRiverWinAndTie() throws {
        let won = try EquityCalculator.calculate(hero: cards("As Ah"), villain: cards("Ks Kh"), board: cards("2c 3d 7h 8s 9c"))
        XCTAssertEqual(won.equity, 1)
        XCTAssertEqual(won.win, 1)
        XCTAssertEqual(won.loss, 0)
        XCTAssertEqual(won.samples, 1)
        XCTAssertTrue(won.isExact)
        let tied = try EquityCalculator.calculate(hero: cards("2c 3d"), villain: cards("4c 5d"), board: cards("Ts Js Qs Ks As"))
        XCTAssertEqual(tied.equity, 0.5)
        XCTAssertEqual(tied.tie, 1)
        XCTAssertEqual(tied.win, 0)
    }

    func testTurnEnumeratesAll44Rivers() throws {
        let result = try EquityCalculator.calculate(hero: cards("As Ah"), villain: cards("Ks Kh"), board: cards("Ac Ad 2c 3c"))
        XCTAssertEqual(result.samples, 44)
        XCTAssertEqual(result.equity, 1)
        XCTAssertTrue(result.isExact)
    }

    func testTurnCountsExactWinningOutsAndSymmetry() throws {
        // Kings can win only with one of the two remaining kings.
        let hero = cards("As Ah"), villain = cards("Ks Kh"), board = cards("2c 3d 7h 8s")
        let aces = try EquityCalculator.calculate(hero: hero, villain: villain, board: board)
        let kings = try EquityCalculator.calculate(hero: villain, villain: hero, board: board)
        XCTAssertEqual(aces.equity, 42.0 / 44, accuracy: 1e-12)
        XCTAssertEqual(kings.equity, 2.0 / 44, accuracy: 1e-12)
        XCTAssertEqual(aces.equity + kings.equity, 1, accuracy: 1e-12)
    }

    func testMonteCarloIsReproducibleAndReportsSampleCount() throws {
        let first = try EquityCalculator.calculate(hero: cards("As Ah"), villain: cards("Ks Kh"), board: [], iterations: 500)
        let second = try EquityCalculator.calculate(hero: cards("As Ah"), villain: cards("Ks Kh"), board: [], iterations: 500)
        XCTAssertEqual(first, second)
        XCTAssertFalse(first.isExact)
        XCTAssertEqual(first.samples, 500)
        XCTAssertEqual(first.win + first.tie + first.loss, 1, accuracy: 1e-12)
        XCTAssertEqual(first.equity, first.win + first.tie / 2, accuracy: 1e-12)
        XCTAssertTrue((0.7...0.9).contains(first.equity))
    }

    func testCardValidationRejectsDuplicatesInvalidRanksAndCounts() throws {
        for incompleteBoard in ["2c", "2c 3d"] {
            XCTAssertThrowsError(try EquityCalculator.calculate(hero: cards("Ac Ad"), villain: cards("Ks Kh"), board: cards(incompleteBoard))) {
                XCTAssertEqual($0 as? PokerError, .invalidBoardSize)
            }
        }
        XCTAssertThrowsError(try HandEvaluator.evaluate(cards("Ac Ac 2h 3s 4c"))) {
            XCTAssertEqual($0 as? PokerError, .duplicateCard)
        }
        XCTAssertThrowsError(try HandEvaluator.evaluate([Card(rank: 15, suit: .clubs)] + cards("2c 3d 4h 5s"))) {
            XCTAssertEqual($0 as? PokerError, .invalidRank(15))
        }
        XCTAssertThrowsError(try EquityCalculator.calculate(hero: cards("Ac Ad"), villain: cards("Ac Kh"), board: [])) {
            XCTAssertEqual($0 as? PokerError, .duplicateCard)
        }
        XCTAssertThrowsError(try EquityCalculator.calculate(hero: cards("Ac"), villain: cards("Ks Kh"), board: [])) {
            XCTAssertEqual($0 as? PokerError, .invalidHandSize)
        }
        XCTAssertThrowsError(try EquityCalculator.calculate(hero: cards("Ac Ad"), villain: cards("Ks Kh"), board: cards("2c 3c 4c 5c 6c 7c"))) {
            XCTAssertEqual($0 as? PokerError, .invalidBoardSize)
        }
        XCTAssertThrowsError(try EquityCalculator.calculate(hero: cards("Ac Ad"), villain: cards("Ks Kh"), board: [], iterations: 0)) {
            XCTAssertEqual($0 as? PokerError, .invalidIterationCount)
        }
    }
}
