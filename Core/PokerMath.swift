import Foundation

public enum Suit: String, CaseIterable, Codable, Sendable {
    case clubs, diamonds, hearts, spades

    public var symbol: String {
        switch self {
        case .clubs: return "♣"
        case .diamonds: return "♦"
        case .hearts: return "♥"
        case .spades: return "♠"
        }
    }
}

public struct Card: Hashable, Codable, Sendable, Identifiable {
    /// 2 through 14, with 14 representing an ace. Evaluators reject invalid ranks.
    public let rank: Int
    public let suit: Suit

    public init(rank: Int, suit: Suit) {
        self.rank = rank
        self.suit = suit
    }

    public var id: String { "\(rank)-\(suit.rawValue)" }

    public var label: String {
        let face: String
        switch rank {
        case 11: face = "J"
        case 12: face = "Q"
        case 13: face = "K"
        case 14: face = "A"
        default: face = String(rank)
        }
        return face + suit.symbol
    }

    public static let deck: [Card] = Suit.allCases.flatMap { suit in
        (2...14).map { Card(rank: $0, suit: suit) }
    }
}

public enum PokerError: Error, LocalizedError, Equatable, Sendable {
    case invalidRank(Int)
    case duplicateCard
    case invalidHandSize
    case invalidBoardSize
    case invalidEvaluationSize
    case invalidIterationCount

    public var errorDescription: String? {
        switch self {
        case .invalidRank: return "カードの数字は2〜14で指定してください。"
        case .duplicateCard: return "同じカードが重複しています。"
        case .invalidHandSize: return "自分と相手の手札をそれぞれ2枚選んでください。"
        case .invalidBoardSize: return "ボードは0枚・3枚・4枚・5枚のいずれかで指定してください。"
        case .invalidEvaluationSize: return "役の判定には5〜7枚のカードが必要です。"
        case .invalidIterationCount: return "試行回数は1以上で指定してください。"
        }
    }
}

public enum PokerMath {
    /// Pot before the opponent's bet is P; their bet and our call are each B.
    /// Break-even equity is B / (P + 2B). Assumes no rake or later betting.
    public static func requiredEquity(potBeforeBet: Double, bet: Double) -> Double {
        guard validMoney(potBeforeBet, bet) else { return .nan }
        let finalPot = potBeforeBet + 2 * bet
        return finalPot > 0 ? bet / finalPot : 0
    }

    /// Net EV of calling relative to folding now. Prior investments are sunk.
    /// Equity includes half of tied pots; assumes heads-up and no rake/later betting.
    public static func callEV(equity: Double, potBeforeBet: Double, bet: Double) -> Double {
        guard equity.isFinite, (0...1).contains(equity), validMoney(potBeforeBet, bet) else {
            return .nan
        }
        return equity * (potBeforeBet + 2 * bet) - bet
    }

    /// Probability of seeing at least one of a fixed set of outs, without replacement.
    /// This is a hit probability, not showdown equity: outs may be dirty or be redrawn.
    /// unseenCards counts every unknown card, including unknown opponents' hole cards.
    public static func drawProbability(outs: Int, unseenCards: Int, cardsToCome: Int) -> Double {
        guard unseenCards >= 0, outs >= 0, outs <= unseenCards,
              cardsToCome >= 0, cardsToCome <= unseenCards else { return .nan }
        guard outs > 0, cardsToCome > 0 else { return 0 }
        if cardsToCome > unseenCards - outs { return 1 }
        var missProbability = 1.0
        for draw in 0..<cardsToCome {
            missProbability *= Double(unseenCards - outs - draw) / Double(unseenCards - draw)
        }
        return 1 - missProbability
    }

    /// P / (P + B), with P measured before the bet. A simplified river benchmark
    /// against zero-equity bluffs, not a prescription for every street or range.
    public static func minimumDefenseFrequency(pot: Double, bet: Double) -> Double {
        guard validMoney(pot, bet) else { return .nan }
        return pot + bet > 0 ? pot / (pot + bet) : 1
    }

    /// Bluffs / (value bets + bluffs) in an idealized polarized river betting range.
    /// Assumes value always beats the bluff-catcher and bluffs always lose if called.
    public static func bluffFraction(pot: Double, bet: Double) -> Double {
        requiredEquity(potBeforeBet: pot, bet: bet)
    }

    private static func validMoney(_ pot: Double, _ bet: Double) -> Bool {
        pot.isFinite && bet.isFinite && pot >= 0 && bet >= 0
            && (pot + 2 * bet).isFinite
    }
}

public enum HandCategory: Int, CaseIterable, Codable, Comparable, Sendable {
    case highCard, onePair, twoPair, threeOfAKind, straight, flush, fullHouse, fourOfAKind, straightFlush

    public static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }

    public var title: String {
        switch self {
        case .highCard: return "ハイカード"
        case .onePair: return "ワンペア"
        case .twoPair: return "ツーペア"
        case .threeOfAKind: return "スリーカード"
        case .straight: return "ストレート"
        case .flush: return "フラッシュ"
        case .fullHouse: return "フルハウス"
        case .fourOfAKind: return "フォーカード"
        case .straightFlush: return "ストレートフラッシュ"
        }
    }
}

public struct HandValue: Equatable, Comparable, Sendable {
    public let category: HandCategory
    /// Ranks in tie-break order; an ace-low straight has a single kicker of 5.
    public let kickers: [Int]

    fileprivate var score: Int {
        var value = category.rawValue << 20
        for (index, rank) in kickers.enumerated() {
            value |= rank << (16 - index * 4)
        }
        return value
    }

    public static func < (lhs: Self, rhs: Self) -> Bool { lhs.score < rhs.score }
}

public enum HandEvaluator {
    /// Finds the best five-card poker hand among five, six, or seven distinct cards.
    public static func evaluate(_ cards: [Card]) throws -> HandValue {
        guard (5...7).contains(cards.count) else { throw PokerError.invalidEvaluationSize }
        try validateCards(cards)
        return evaluateValidated(cards)
    }

    fileprivate static func evaluateValidated(_ cards: [Card]) -> HandValue {
        if cards.count == 5 { return evaluateFive(cards) }
        let count = cards.count
        var best = HandValue(category: .highCard, kickers: [])
        for a in 0..<(count - 4) {
            for b in (a + 1)..<(count - 3) {
                for c in (b + 1)..<(count - 2) {
                    for d in (c + 1)..<(count - 1) {
                        for e in (d + 1)..<count {
                            let value = evaluateFive([cards[a], cards[b], cards[c], cards[d], cards[e]])
                            if value > best { best = value }
                        }
                    }
                }
            }
        }
        return best
    }

    private static func evaluateFive(_ cards: [Card]) -> HandValue {
        var counts = [Int](repeating: 0, count: 15)
        for card in cards { counts[card.rank] += 1 }
        let ranks = (2...14).reversed().filter { counts[$0] > 0 }
        let isFlush = cards.allSatisfy { $0.suit == cards[0].suit }
        var straightHigh = 0
        if ranks.count == 5 {
            if ranks[0] - ranks[4] == 4 { straightHigh = ranks[0] }
            else if ranks == [14, 5, 4, 3, 2] { straightHigh = 5 }
        }
        if isFlush && straightHigh > 0 {
            return HandValue(category: .straightFlush, kickers: [straightHigh])
        }
        let groups = ranks.sorted {
            counts[$0] == counts[$1] ? $0 > $1 : counts[$0] > counts[$1]
        }
        if counts[groups[0]] == 4 { return HandValue(category: .fourOfAKind, kickers: groups) }
        if counts[groups[0]] == 3 && counts[groups[1]] == 2 {
            return HandValue(category: .fullHouse, kickers: groups)
        }
        if isFlush { return HandValue(category: .flush, kickers: ranks) }
        if straightHigh > 0 { return HandValue(category: .straight, kickers: [straightHigh]) }
        if counts[groups[0]] == 3 { return HandValue(category: .threeOfAKind, kickers: groups) }
        if counts[groups[0]] == 2 && counts[groups[1]] == 2 {
            return HandValue(category: .twoPair, kickers: groups)
        }
        if counts[groups[0]] == 2 { return HandValue(category: .onePair, kickers: groups) }
        return HandValue(category: .highCard, kickers: ranks)
    }
}

public struct EquityResult: Equatable, Sendable {
    /// Share of the pot: win + tie / 2. All four values are fractions in 0...1.
    public let equity: Double
    public let win: Double
    public let tie: Double
    public let loss: Double
    public let samples: Int
    public let isExact: Bool
}

public enum EquityCalculator {
    /// Heads-up equity for two specified hands. Turn and river enumerate all runouts;
    /// earlier streets use reproducible, uniform Monte Carlo samples without replacement.
    /// This synchronous computation can run in Task.detached to keep the UI responsive.
    public static func calculate(
        hero: [Card], villain: [Card], board: [Card], iterations: Int = 3_000
    ) throws -> EquityResult {
        guard hero.count == 2, villain.count == 2 else { throw PokerError.invalidHandSize }
        guard [0, 3, 4, 5].contains(board.count) else { throw PokerError.invalidBoardSize }
        guard iterations > 0 else { throw PokerError.invalidIterationCount }
        let known = hero + villain + board
        try validateCards(known)
        let knownSet = Set(known)
        var available = Card.deck.filter { !knownSet.contains($0) }
        var wins = 0
        var ties = 0
        var samples = 0

        func record(_ completedBoard: [Card]) {
            let ownValue = HandEvaluator.evaluateValidated(hero + completedBoard)
            let otherValue = HandEvaluator.evaluateValidated(villain + completedBoard)
            if ownValue > otherValue { wins += 1 }
            else if ownValue == otherValue { ties += 1 }
            samples += 1
        }

        let missing = 5 - board.count
        if missing == 0 {
            record(board)
        } else if missing == 1 {
            for river in available { record(board + [river]) }
        } else {
            var rng = SplitMix64(seed: 0x52495645524C4142)
            for _ in 0..<iterations {
                for index in 0..<missing {
                    let selected = index + rng.index(upperBound: available.count - index)
                    available.swapAt(index, selected)
                }
                record(board + available.prefix(missing))
            }
        }
        let total = Double(samples)
        let win = Double(wins) / total
        let tie = Double(ties) / total
        return EquityResult(
            equity: win + tie / 2,
            win: win,
            tie: tie,
            loss: Double(samples - wins - ties) / total,
            samples: samples,
            isExact: missing <= 1
        )
    }
}

private func validateCards(_ cards: [Card]) throws {
    for card in cards where !(2...14).contains(card.rank) {
        throw PokerError.invalidRank(card.rank)
    }
    guard Set(cards).count == cards.count else { throw PokerError.duplicateCard }
}

private struct SplitMix64 {
    var state: UInt64

    init(seed: UInt64) { state = seed }

    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var value = state
        value = (value ^ (value >> 30)) &* 0xBF58476D1CE4E5B9
        value = (value ^ (value >> 27)) &* 0x94D049BB133111EB
        return value ^ (value >> 31)
    }

    mutating func index(upperBound: Int) -> Int {
        let bound = UInt64(upperBound)
        let threshold = (0 &- bound) % bound
        var value = next()
        while value < threshold { value = next() }
        return Int(value % bound)
    }
}
