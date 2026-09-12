import SwiftUI

private enum LabMode: String, CaseIterable, Identifiable {
    case odds = "ポットオッズ", draws = "ドロー確率", equity = "エクイティ", balance = "GTOモデル"
    var id: String { rawValue }
}

struct LabView: View {
    @State private var mode = LabMode.odds
    var body: some View {
        Screen {
            PageHeading(eyebrow: "EXPLORE THE NUMBERS", title: "確率を、体感する。", subtitle: "条件を変えて、数字の動きを確かめよう。")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(LabMode.allCases) { item in
                        Button { mode = item } label: {
                            Text(item.rawValue).font(.subheadline.bold()).padding(.horizontal, 16).padding(.vertical, 12)
                                .foregroundStyle(mode == item ? Palette.background : Palette.muted)
                                .background(mode == item ? Palette.mint : Palette.surface, in: Capsule())
                        }.buttonStyle(.plain)
                    }
                }
            }
            switch mode {
            case .odds: OddsLab()
            case .draws: DrawLab()
            case .equity: EquityLab()
            case .balance: BalanceLab()
            }
        }.toolbar(.hidden, for: .navigationBar)
    }
}

private struct NumberControl: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    var step: Double = 1
    var unit = "bb"
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text(title).font(.subheadline).foregroundStyle(Palette.muted)
                Spacer()
                Text("\(number(value)) \(unit)").font(.system(.headline, design: .rounded)).monospacedDigit()
            }
            Slider(value: $value, in: range, step: step).tint(Palette.mint).accessibilityLabel(title)
        }
    }
}

private struct OddsLab: View {
    @State private var pot = 100.0
    @State private var bet = 50.0
    @State private var equity = 30.0
    private var required: Double { PokerMath.requiredEquity(potBeforeBet: pot, bet: bet) }
    private var ev: Double { PokerMath.callEV(equity: equity / 100, potBeforeBet: pot, bet: bet) }
    var body: some View {
        Panel {
            VStack(alignment: .leading, spacing: 24) {
                Eyebrow(text: "THE PRICE OF A CALL")
                NumberControl(title: "相手のベット前のポット", value: $pot, range: 10...300, step: 10)
                NumberControl(title: "相手のベット額", value: $bet, range: 0...300, step: 5)
                HStack {
                    Text("ベットサイズ").font(.caption).foregroundStyle(Palette.muted)
                    Spacer()
                    Text(String(format: "%.0f%% ポット", bet / pot * 100)).font(.caption.bold())
                }
                HStack(spacing: 8) {
                    ForEach([0.25, 0.5, 0.75, 1.0], id: \.self) { size in
                        Button("\(Int(size * 100))%") { bet = pot * size }
                            .font(.caption.bold()).frame(maxWidth: .infinity).padding(.vertical, 10)
                            .background(Palette.elevated, in: RoundedRectangle(cornerRadius: 10))
                    }
                }
            }
        }
        Panel {
            VStack(alignment: .leading, spacing: 14) {
                Text("コールに必要なエクイティ").font(.subheadline).foregroundStyle(Palette.muted)
                Text(percent(required)).font(.system(size: 52, weight: .medium, design: .rounded)).foregroundStyle(Palette.mint)
                    .accessibilityIdentifier("requiredEquity")
                Text("\(number(bet)) ÷ (\(number(pot)) + \(number(bet)) × 2) = \(percent(required))")
                    .font(.system(.caption, design: .monospaced)).foregroundStyle(Palette.muted)
                Divider()
                NumberControl(title: "想定するエクイティ", value: $equity, range: 0...100, unit: "%")
                HStack {
                    Text(bet == 0 ? "チェックの期待値" : "コールの期待値").font(.subheadline)
                    Spacer()
                    Text(String(format: "%+.1f bb", ev)).font(.system(.title2, design: .rounded).bold())
                        .foregroundStyle(ev >= 0 ? Palette.mint : Palette.red).accessibilityIdentifier("callEV")
                }
                Text(bet == 0 ? "ベットがなければ、追加投入なしでチェックできます。" : abs(ev) < 0.0001 ? "この条件では、コールとフォールドの期待値が同じです。" : ev > 0 ? "この条件では、コールの期待値がフォールドを上回ります。" : "この条件では、フォールドの期待値がコールを上回ります。")
                    .font(.caption).foregroundStyle(Palette.muted).lineSpacing(4)
            }
        }
        LabNote(text: "ヘッズアップ、レーキなし、コール後に追加ベットがない場合。フォールドの期待値を0として計算します。エクイティは勝率＋引き分け率の半分です。実際には相手のレンジや今後のアクションも考慮します。")
    }
}

private struct DrawLab: View {
    @State private var outs = 9.0
    @State private var stage = 0
    private var unseen: Int { stage == 2 ? 46 : 47 }
    private var draws: Int { stage == 0 ? 2 : 1 }
    private var probability: Double { PokerMath.drawProbability(outs: Int(outs), unseenCards: unseen, cardsToCome: draws) }
    var body: some View {
        Panel {
            VStack(alignment: .leading, spacing: 22) {
                Eyebrow(text: "COUNT YOUR OUTS")
                Picker("残りのカード", selection: $stage) {
                    Text("フロップ→リバー").tag(0)
                    Text("フロップ→ターン").tag(1)
                    Text("ターン→リバー").tag(2)
                }.pickerStyle(.menu).tint(Palette.mint)
                NumberControl(title: "アウツの枚数", value: $outs, range: 0...20, unit: "枚")
                HStack(spacing: 8) {
                    ForEach([4, 8, 9, 15], id: \.self) { n in
                        Button("\(n) outs") { outs = Double(n) }.font(.caption.bold())
                            .frame(maxWidth: .infinity).padding(.vertical, 12)
                            .background(Palette.elevated, in: RoundedRectangle(cornerRadius: 10))
                    }
                }
                Text("ガットショット 4枚 · 両面ストレート 8枚\nフラッシュ 9枚 · 重複は二重に数えない")
                    .font(.caption).foregroundStyle(Palette.muted).lineSpacing(5)
            }
        }
        Panel {
            VStack(alignment: .leading, spacing: 18) {
                Text("少なくとも1枚、アウツを引く確率").font(.subheadline).foregroundStyle(Palette.muted)
                Text(percent(probability)).font(.system(size: 52, weight: .medium, design: .rounded)).foregroundStyle(Palette.mint)
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 5), count: 10), spacing: 5) {
                    ForEach(0..<100) { i in
                        RoundedRectangle(cornerRadius: 3).fill(Double(i) < (probability * 100).rounded() ? Palette.mint : Palette.elevated).frame(height: 9)
                    }
                }.accessibilityHidden(true)
                Text("100マスで確率を表示（整数に丸めています）").font(.caption2).foregroundStyle(Palette.muted)
                Text(draws == 2 ? "1 − (\(unseen - Int(outs))/\(unseen)) × (\(unseen - Int(outs) - 1)/\(unseen - 1))" : "\(Int(outs)) ÷ \(unseen)")
                    .font(.system(.subheadline, design: .monospaced))
                Text("2・4の法則による概算：\(Int(outs) * (draws == 2 ? 4 : 2))%")
                    .font(.caption).foregroundStyle(Palette.muted)
            }
        }
        LabNote(text: "自分の手札とボード以外は未知として、アウツが固定の場合の厳密な完成率です。完成しても相手に負ける場合があるため、勝率とは異なります。フロップから2枚を見る計算は、リバーまで追加費用なく進めるとは限りません。")
    }
}

private struct BalanceLab: View {
    @State private var size = 50.0
    private var defense: Double { PokerMath.minimumDefenseFrequency(pot: 100, bet: size) }
    private var bluffs: Double { PokerMath.bluffFraction(pot: 100, bet: size) }
    var body: some View {
        Panel {
            VStack(alignment: .leading, spacing: 20) {
                Eyebrow(text: "A SIMPLIFIED RIVER GAME")
                Text("ベットサイズと、バランス。").font(.title2.bold())
                Text("強いバリューか、勝ち目のないブラフか。条件を絞ると、GTOの原理を数式で見ることができます。")
                    .font(.subheadline).foregroundStyle(Palette.muted).lineSpacing(5)
                NumberControl(title: "100 bbのポットにベット", value: $size, range: 10...200, step: 5)
            }
        }
        Panel {
            VStack(alignment: .leading, spacing: 18) {
                Text("守る側：レンジ全体の防御頻度の基準").font(.subheadline)
                Text(percent(defense)).font(.system(size: 42, weight: .medium, design: .rounded)).foregroundStyle(Palette.mint)
                ProgressView(value: defense).tint(Palette.mint)
                Text("MDF = ポット ÷（ポット + ベット）").font(.system(.caption, design: .monospaced)).foregroundStyle(Palette.muted)
                Divider()
                Text("打つ側：ベットレンジ内のブラフ比率").font(.subheadline)
                Text(percent(bluffs)).font(.system(size: 42, weight: .medium, design: .rounded)).foregroundStyle(Palette.gold)
                ProgressView(value: bluffs).tint(Palette.gold)
                Text("ブラフ比率 = ベット ÷（ポット + 2 × ベット）")
                    .font(.system(.caption, design: .monospaced)).foregroundStyle(Palette.muted)
                Text("ベットが大きいほど、守る頻度は下がり、バリューに混ぜられるブラフの比率は上がります。")
                    .font(.subheadline).lineSpacing(5)
            }
        }
        LabNote(text: "簡略モデル：リバーのヘッズアップ、1つのベットサイズ、レーキ・レイズなし。打つ側は必ず勝つバリューと必ず負けるブラフ、守る側はブラフだけに勝つハンドを持つと仮定し、必要なコンボが十分ある場合。MDFは個々のハンドで必ずコールすべき頻度ではありません。ホールデム全体のソルバー解ではありません。")
    }
}

private struct CardSlot: Identifiable { let index: Int; var id: Int { index } }

private struct EquityLab: View {
    @State private var cards: [Card?] = [Card(rank: 14, suit: .spades), Card(rank: 14, suit: .hearts), Card(rank: 13, suit: .spades), Card(rank: 13, suit: .hearts), nil, nil, nil, nil, nil]
    @State private var stage = 0
    @State private var selectedSlot: CardSlot?
    @State private var result: EquityResult?
    @State private var calculating = false
    @State private var calculationID = UUID()
    @State private var error: String?
    private var boardCount: Int { [0, 3, 4, 5][stage] }
    private var activeCards: [Card?] { Array(cards.prefix(4 + boardCount)) }

    var body: some View {
        Panel {
            VStack(alignment: .leading, spacing: 22) {
                Eyebrow(text: "HAND VS HAND")
                Text("2人のハンドを比べる").font(.title2.bold())
                Picker("ストリート", selection: $stage) {
                    Text("プリフロップ").tag(0)
                    Text("フロップ").tag(1)
                    Text("ターン").tag(2)
                    Text("リバー").tag(3)
                }.pickerStyle(.menu).disabled(calculating)
                HStack(alignment: .top) {
                    VStack(spacing: 11) {
                        Text("あなた").font(.caption).foregroundStyle(Palette.mint)
                        HStack(spacing: 7) { slot(0); slot(1) }
                    }
                    Spacer()
                    Text("VS").font(.system(.caption, design: .monospaced)).foregroundStyle(Palette.muted).padding(.top, 55)
                    Spacer()
                    VStack(spacing: 11) {
                        Text("相手").font(.caption).foregroundStyle(Palette.gold)
                        HStack(spacing: 7) { slot(2); slot(3) }
                    }
                }
                if boardCount > 0 {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("ボード").font(.caption).foregroundStyle(Palette.muted)
                        HStack(spacing: 8) { ForEach(4..<(4 + boardCount), id: \.self) { slot($0, small: true) } }
                    }
                }
                Text("カードをタップして変更").font(.caption2).foregroundStyle(Palette.muted)
                Button(action: calculate) {
                    HStack(spacing: 10) {
                        if calculating { ProgressView().tint(Palette.background) }
                        Text(calculating ? "計算中…" : "エクイティを計算")
                    }
                }.buttonStyle(PrimaryButton()).disabled(calculating || activeCards.contains(where: { $0 == nil }))
                    .opacity(activeCards.contains(where: { $0 == nil }) ? 0.4 : 1)
                    .accessibilityIdentifier("calculateEquity")
            }
        }
        if let error { Text(error).foregroundStyle(Palette.red).font(.subheadline) }
        if let result {
            Panel {
                VStack(alignment: .leading, spacing: 18) {
                    Text("あなたのエクイティ").font(.subheadline).foregroundStyle(Palette.muted)
                    Text(percent(result.equity)).font(.system(size: 52, weight: .medium, design: .rounded)).foregroundStyle(Palette.mint)
                        .accessibilityIdentifier("equityResult")
                    ProgressView(value: result.equity).tint(Palette.mint)
                    HStack {
                        breakdown("勝ち", result.win)
                        Spacer()
                        breakdown("引き分け", result.tie)
                        Spacer()
                        breakdown("負け", result.loss)
                    }
                    Text(result.isExact ? "全 \(result.samples) 通りを列挙した厳密値" : "\(result.samples) 回のモンテカルロ試行による推定値")
                        .font(.caption).foregroundStyle(Palette.muted)
                    if !result.isExact {
                        Text("固定乱数で再現できる推定です。真の値とは差があり、勝率50%付近で95%誤差幅の目安は約±2ポイントです。")
                            .font(.caption).foregroundStyle(Palette.muted).lineSpacing(4)
                    }
                }
            }
        }
        LabNote(text: "相手の手札を2枚に固定したショーダウン比較です。エクイティ = 勝率 + 引き分け率 ÷ 2。相手のレンジ全体への評価や、ベット・フォールドの戦略は計算しません。ターンとリバーは全列挙、それ以前は2,500回の試行で推定します。")
            .onChange(of: stage) { _, _ in
                for i in (4 + boardCount)..<9 { cards[i] = nil }
                invalidate()
            }
            .onChange(of: cards) { _, _ in invalidate() }
            .onDisappear { calculationID = UUID(); calculating = false }
            .sheet(item: $selectedSlot) { selection in
                CardPicker(selected: cards[selection.index], unavailable: Set(cards.enumerated().compactMap { $0.offset == selection.index ? nil : $0.element })) { card in
                    cards[selection.index] = card
                    selectedSlot = nil
                }
            }
    }

    private func slot(_ index: Int, small: Bool = false) -> some View {
        Button { selectedSlot = CardSlot(index: index) } label: {
            if let card = cards[index] { PlayingCard(code: card.notation, small: small) }
            else {
                Image(systemName: "plus").font(.title3).foregroundStyle(Palette.muted)
                    .frame(width: small ? 40 : 57, height: small ? 56 : 79)
                    .background(Palette.elevated, in: RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Palette.muted.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [4])))
            }
        }.buttonStyle(.plain).disabled(calculating).accessibilityLabel("\(index < 2 ? "あなた" : index < 4 ? "相手" : "ボード")のカード\(index + 1)：\(cards[index]?.label ?? "未選択")")
            .accessibilityIdentifier("cardSlot_\(index)")
    }

    private func breakdown(_ title: String, _ value: Double) -> some View {
        VStack(alignment: .leading, spacing: 6) { Text(title).font(.caption).foregroundStyle(Palette.muted); Text(percent(value)).font(.subheadline.bold()) }
    }
    private func invalidate() { result = nil; error = nil; calculationID = UUID(); calculating = false }
    private func calculate() {
        let hero = cards[0..<2].compactMap { $0 }
        let villain = cards[2..<4].compactMap { $0 }
        let board = cards[4..<(4 + boardCount)].compactMap { $0 }
        let token = UUID()
        calculationID = token
        calculating = true
        result = nil
        error = nil
        Task {
            let outcome = await Task.detached(priority: .userInitiated) {
                Result { try EquityCalculator.calculate(hero: hero, villain: villain, board: board, iterations: 2500) }
            }.value
            guard token == calculationID else { return }
            calculating = false
            switch outcome {
            case .success(let value): result = value
            case .failure(let failure): error = failure.localizedDescription
            }
        }
    }
}

private struct CardPicker: View {
    let selected: Card?
    let unavailable: Set<Card>
    let onSelect: (Card) -> Void
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            Screen {
                Text("同じカードは2回選べません。").font(.subheadline).foregroundStyle(Palette.muted).padding(.top)
                ForEach(Suit.allCases, id: \.self) { suit in
                    VStack(alignment: .leading, spacing: 10) {
                        Text(suit.symbol).font(.title2).foregroundStyle(suit == .hearts || suit == .diamonds ? Palette.red : Palette.mint)
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 5), count: 7), spacing: 10) {
                            ForEach((2...14).reversed(), id: \.self) { rank in
                                let card = Card(rank: rank, suit: suit)
                                Button { onSelect(card) } label: {
                                    PlayingCard(code: card.notation, small: true)
                                        .overlay(RoundedRectangle(cornerRadius: 7).strokeBorder(selected == card ? Palette.mint : .clear, lineWidth: 3))
                                        .opacity(unavailable.contains(card) ? 0.16 : 1)
                                }.buttonStyle(.plain).disabled(unavailable.contains(card))
                                    .accessibilityIdentifier("pick_\(card.notation)")
                            }
                        }
                    }
                }
            }.navigationTitle("カードを選ぶ").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("閉じる") { dismiss() } } }
        }.preferredColorScheme(.dark)
    }
}

private struct LabNote: View {
    let text: String
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "info.circle").foregroundStyle(Palette.mint)
            Text(text).font(.caption).foregroundStyle(Palette.muted).lineSpacing(5)
        }
    }
}

private func percent(_ value: Double) -> String { String(format: "%.1f%%", value * 100) }
private func number(_ value: Double) -> String { String(format: value.rounded() == value ? "%.0f" : "%.1f", value) }

private extension Card {
    var notation: String {
        let rankCode = [10: "T", 11: "J", 12: "Q", 13: "K", 14: "A"][rank] ?? String(rank)
        let suitCode: String
        switch suit { case .clubs: suitCode = "c"; case .diamonds: suitCode = "d"; case .hearts: suitCode = "h"; case .spades: suitCode = "s" }
        return rankCode + suitCode
    }
}
