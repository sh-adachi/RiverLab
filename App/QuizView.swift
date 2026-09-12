import SwiftUI

struct QuizView: View {
    let session: TrainingSession
    var onFinish: () -> Void = {}
    @EnvironmentObject private var store: StudyStore
    @Environment(\.dismiss) private var dismiss
    @State private var index = 0
    @State private var selected: Int?
    @State private var correctCount = 0
    @State private var finished = false

    var body: some View {
        NavigationStack {
            Group {
                if finished || session.questions.isEmpty { result }
                else { questionBody }
            }
            .background(Palette.background)
            .navigationTitle(session.title).navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarLeading) {
                Button { dismiss() } label: { Image(systemName: "xmark") }.accessibilityLabel("トレーニングを閉じる")
            } }
        }.preferredColorScheme(.dark)
    }

    private var questionBody: some View {
        let question = session.questions[index]
        return ScrollViewReader { proxy in
            Screen {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("QUESTION \(String(format: "%02d", index + 1)) / \(String(format: "%02d", session.questions.count))")
                            .font(.system(.caption, design: .monospaced)).tracking(2)
                        Spacer()
                        Text(question.topic.title).font(.caption).foregroundStyle(question.topic.tint)
                    }
                    ProgressView(value: Double(index), total: Double(session.questions.count)).tint(Palette.mint)
                }.padding(.top, 12).id("questionTop")
                VStack(alignment: .leading, spacing: 12) {
                    Text(question.title).font(.title2.bold())
                    Text(question.context).font(.caption).foregroundStyle(Palette.muted).lineSpacing(4)
                }
                if !question.hero.isEmpty || !question.board.isEmpty {
                    Panel {
                        VStack(spacing: 18) {
                            if !question.board.isEmpty {
                                VStack(spacing: 9) {
                                    Eyebrow(text: "BOARD")
                                    HStack(spacing: 8) { ForEach(question.board, id: \.self) { PlayingCard(code: $0, small: true) } }
                                }
                            }
                            if !question.hero.isEmpty {
                                VStack(spacing: 9) {
                                    HStack(spacing: 8) { ForEach(question.hero, id: \.self) { PlayingCard(code: $0) } }
                                    Text("あなたのハンド").font(.caption).foregroundStyle(Palette.muted)
                                }
                            }
                        }.frame(maxWidth: .infinity)
                    }
                }
                Text(question.prompt).font(.title3.weight(.semibold)).lineSpacing(5).fixedSize(horizontal: false, vertical: true)
                VStack(spacing: 10) {
                    ForEach(Array(question.choices.enumerated()), id: \.offset) { option, choice in
                        Button {
                            guard selected == nil else { return }
                            selected = option
                            let isCorrect = option == question.answerIndex
                            if isCorrect { correctCount += 1 }
                            store.record(question, correct: isCorrect)
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            withAnimation { proxy.scrollTo("feedback", anchor: .bottom) }
                        } label: {
                            HStack(spacing: 13) {
                                Text(String(UnicodeScalar(65 + option)!)).font(.system(.subheadline, design: .monospaced).bold())
                                    .foregroundStyle(answerColor(option, question)).frame(width: 28)
                                Text(choice).font(.subheadline.weight(.medium)).multilineTextAlignment(.leading).frame(maxWidth: .infinity, alignment: .leading)
                                if selected != nil && option == question.answerIndex { Image(systemName: "checkmark.circle.fill").foregroundStyle(Palette.mint) }
                                else if selected == option { Image(systemName: "xmark.circle").foregroundStyle(Palette.red) }
                            }
                            .padding(17).foregroundStyle(Palette.cream)
                            .background(answerColor(option, question).opacity(selected != nil && option == question.answerIndex ? 0.14 : 0.045), in: RoundedRectangle(cornerRadius: 16))
                            .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(answerColor(option, question).opacity(selected == option || selected != nil && option == question.answerIndex ? 0.65 : 0.13)))
                        }.buttonStyle(.plain).disabled(selected != nil).accessibilityIdentifier("answer_\(option)")
                    }
                }
                if let selected {
                    Panel {
                        VStack(alignment: .leading, spacing: 14) {
                            Label(selected == question.answerIndex ? "正解。その理由を確認しよう。" : "ここが、伸びしろ。", systemImage: selected == question.answerIndex ? "checkmark.circle.fill" : "lightbulb")
                                .font(.headline).foregroundStyle(selected == question.answerIndex ? Palette.mint : Palette.gold)
                            if let formula = question.formula {
                                Text(formula).font(.system(.subheadline, design: .monospaced)).foregroundStyle(Palette.mint)
                                    .padding(13).frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Palette.background, in: RoundedRectangle(cornerRadius: 12))
                            }
                            Text(question.explanation).font(.subheadline).lineSpacing(6).foregroundStyle(Palette.cream)
                            Button(index + 1 == session.questions.count ? "結果を見る" : "次の問題") {
                                if index + 1 == session.questions.count { finished = true }
                                else { index += 1; self.selected = nil; proxy.scrollTo("questionTop", anchor: .top) }
                            }.buttonStyle(PrimaryButton())
                        }
                    }.id("feedback")
                }
            }
        }
    }

    private func answerColor(_ option: Int, _ question: Exercise) -> Color {
        if selected != nil && option == question.answerIndex { return Palette.mint }
        if selected == option { return Palette.red }
        return Palette.muted
    }

    private var result: some View {
        Screen {
            VStack(spacing: 24) {
                Eyebrow(text: "SESSION COMPLETE")
                ZStack {
                    Circle().stroke(Palette.elevated, lineWidth: 10)
                    Circle().trim(from: 0, to: Double(correctCount) / Double(max(1, session.questions.count)))
                        .stroke(Palette.mint, style: StrokeStyle(lineWidth: 10, lineCap: .round)).rotationEffect(.degrees(-90))
                    VStack(spacing: 5) {
                        Text("\(correctCount) / \(session.questions.count)").font(.system(size: 44, weight: .semibold, design: .rounded))
                        Text("正解").font(.subheadline).foregroundStyle(Palette.muted)
                    }
                }.frame(width: 185, height: 185).padding(.vertical, 12)
                Text("セッション結果").font(.title.bold())
                Text(correctCount == session.questions.count ? "すべての判断に、根拠ができました。\n次のテーマにも挑戦してみよう。" : "間違えた問題は、復習リストへ。\n理由を理解するたび、一歩前へ。")
                    .font(.subheadline).foregroundStyle(Palette.muted).multilineTextAlignment(.center).lineSpacing(6)
                Button("ホームに戻る") { onFinish(); dismiss() }.buttonStyle(PrimaryButton())
                Text(store.storageWarning ?? "解答と学習記録を保存しました").font(.caption).foregroundStyle(Palette.muted)
            }.frame(maxWidth: .infinity).padding(.top, 35)
        }
    }
}
