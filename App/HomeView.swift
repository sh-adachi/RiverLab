import SwiftUI

struct TrainingSession: Identifiable {
    let id = UUID()
    let questions: [Exercise]
    let title: String
}

struct RootView: View {
    @State private var selectedTab = 0
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack { HomeView(selectedTab: $selectedTab) }
                .tabItem { Label("ホーム", systemImage: "square.grid.2x2") }.tag(0)
            NavigationStack { TrainingView(selectedTab: $selectedTab) }
                .tabItem { Label("トレーニング", systemImage: "suit.spade") }.tag(1)
            NavigationStack { LearnView() }
                .tabItem { Label("学ぶ", systemImage: "book.closed") }.tag(2)
            NavigationStack { LabView() }
                .tabItem { Label("ラボ", systemImage: "slider.horizontal.3") }.tag(3)
        }
        .toolbarBackground(Palette.background, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
    }
}

struct HomeView: View {
    @EnvironmentObject private var store: StudyStore
    @Binding var selectedTab: Int
    @State private var session: TrainingSession?
    @State private var showingProgress = false

    var body: some View {
        Screen {
            HStack(alignment: .center) {
                HStack(spacing: 9) {
                    Image(systemName: "suit.spade.fill").foregroundStyle(Palette.mint)
                    Text("RIVER LAB").font(.system(size: 19, weight: .heavy, design: .rounded)).tracking(3)
                }
                Spacer()
                Button { showingProgress = true } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "flame").foregroundStyle(Palette.gold)
                        Text("\(store.progress.streak()) 日").foregroundStyle(Palette.cream)
                    }.font(.caption.bold()).padding(10).background(Palette.surface, in: Capsule())
                }.accessibilityLabel("学習記録")
            }.padding(.top, 12)

            VStack(alignment: .leading, spacing: 12) {
                Text("その一手に、\n理由を持とう。").font(.system(size: 34, weight: .bold, design: .rounded))
                    .lineSpacing(5).fixedSize(horizontal: false, vertical: true)
                Text("テキサスホールデムを、確率から。")
                    .font(.subheadline).foregroundStyle(Palette.muted)
            }

            dailyCard

            HStack(spacing: 10) {
                metric("今日の解答", value: "\(store.progress.answeredToday())", suffix: "問")
                metric("正答率", value: store.progress.accuracy.map { "\(Int(($0 * 100).rounded()))" } ?? "—", suffix: "%")
                metric("学習済み", value: "\(store.progress.completedLessonIDs.count)", suffix: "/ \(Curriculum.lessons.count)")
            }

            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("理解を、一段ずつ。").font(.title3.bold())
                    Spacer()
                    Button("すべて見る") { selectedTab = 2 }.font(.caption.bold())
                }
                ForEach(Array(StudyTopic.allCases.enumerated()), id: \.element.id) { index, topic in
                    Button { selectedTab = 2 } label: {
                        HStack(spacing: 14) {
                            Text(String(format: "%02d", index + 1)).font(.system(.headline, design: .monospaced))
                                .foregroundStyle(topic.tint).frame(width: 42, height: 48)
                                .background(topic.tint.opacity(0.08), in: RoundedRectangle(cornerRadius: 13))
                            VStack(alignment: .leading, spacing: 5) {
                                Text(topic.title).font(.headline).foregroundStyle(Palette.cream)
                                Text(topicDescription(topic)).font(.caption).foregroundStyle(Palette.muted)
                            }
                            Spacer()
                            Image(systemName: "arrow.up.right").foregroundStyle(Palette.muted).font(.caption)
                        }.padding(15).background(Palette.surface, in: RoundedRectangle(cornerRadius: 19))
                    }.buttonStyle(.plain)
                }
            }

            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "sparkle").foregroundStyle(Palette.gold)
                VStack(alignment: .leading, spacing: 5) {
                    Text("結果より、判断の質。").font(.subheadline.bold())
                    Text("良い判断でも、1回の勝負には負ける。長い目で期待値を積み重ねよう。")
                        .font(.caption).foregroundStyle(Palette.muted).lineSpacing(4)
                }
            }.padding(.vertical, 5)
            if let warning = store.storageWarning { Text(warning).font(.caption).foregroundStyle(Palette.gold) }
        }
        .toolbar(.hidden, for: .navigationBar)
        .fullScreenCover(item: $session) { QuizView(session: $0) }
        .sheet(isPresented: $showingProgress) { ProgressViewSheet() }
    }

    private var dailyCard: some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 10) {
                    Eyebrow(text: "DAILY PRACTICE")
                    Text("毎日5問、\n判断を磨く。").font(.system(size: 25, weight: .bold, design: .rounded)).lineSpacing(3)
                    Text("基礎・確率・GTOの考え方").font(.caption).foregroundStyle(Palette.muted)
                }
                Spacer(minLength: 4)
                ZStack {
                    Circle().stroke(Palette.mint.opacity(0.1), lineWidth: 1).frame(width: 132, height: 132)
                    Circle().stroke(Palette.mint.opacity(0.1), lineWidth: 1).frame(width: 106, height: 106)
                    PlayingCard(code: "Ks").rotationEffect(.degrees(-14)).offset(x: -17, y: 1)
                    PlayingCard(code: "Ah").rotationEffect(.degrees(13)).offset(x: 22, y: 7)
                }.frame(width: 135, height: 128).accessibilityHidden(true)
            }
            Button {
                session = TrainingSession(questions: store.questions(), title: "今日の5問")
            } label: {
                HStack { Text("今日の5問をはじめる"); Spacer(); Image(systemName: "arrow.right") }
            }.buttonStyle(PrimaryButton())
            HStack(spacing: 6) {
                Image(systemName: "clock")
                Text("約3分")
                Text("·")
                Text("すべての問題に解説つき")
            }.font(.caption2).foregroundStyle(Palette.muted).frame(maxWidth: .infinity)
        }
        .padding(22)
        .background(LinearGradient(colors: [Color(red: 0.09, green: 0.19, blue: 0.19), Palette.surface], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 27))
        .overlay(RoundedRectangle(cornerRadius: 27).strokeBorder(Palette.mint.opacity(0.17)))
    }

    private func metric(_ title: String, value: String, suffix: String) -> some View {
        VStack(alignment: .leading, spacing: 11) {
            Text(title).font(.system(size: 11)).foregroundStyle(Palette.muted)
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(value).font(.system(size: 25, weight: .semibold, design: .rounded))
                Text(suffix).font(.system(size: 10)).foregroundStyle(Palette.muted)
            }.minimumScaleFactor(0.6).lineLimit(1)
        }.frame(maxWidth: .infinity, alignment: .leading).padding(15)
            .background(Palette.surface, in: RoundedRectangle(cornerRadius: 18))
    }

    private func topicDescription(_ topic: StudyTopic) -> String {
        switch topic {
        case .basics: return "役・ポジション・ゲームの流れ"
        case .probability: return "アウツ・ポットオッズ・期待値"
        case .gto: return "レンジ・バランス・混合戦略"
        }
    }
}

struct TrainingView: View {
    @EnvironmentObject private var store: StudyStore
    @Binding var selectedTab: Int
    @State private var session: TrainingSession?
    var body: some View {
        Screen {
            PageHeading(eyebrow: "TRAIN YOUR DECISIONS", title: "トレーニング", subtitle: "なんとなく、を卒業しよう。\n選んで、解説を読んで、もう一度。")
            ForEach(StudyTopic.allCases) { topic in
                Panel {
                    VStack(alignment: .leading, spacing: 17) {
                        HStack {
                            Image(systemName: topic.symbol).font(.title2).foregroundStyle(topic.tint)
                            Spacer()
                            Text("\(Curriculum.exercises.filter { $0.topic == topic }.count) 問から出題")
                                .font(.caption).foregroundStyle(Palette.muted)
                        }
                        Text(topic.title).font(.title2.bold())
                        Text(topic == .gto ? "条件を絞った理論問題で、GTOの土台を理解する。" : topic == .probability ? "数字を味方に。コールの根拠を計算しよう。" : "ルールを覚えて、テーブルに慣れよう。")
                            .font(.subheadline).foregroundStyle(Palette.muted).lineSpacing(4)
                        Button {
                            session = TrainingSession(questions: store.questions(topic: topic), title: topic.title)
                        } label: { HStack { Text("5問に挑戦"); Spacer(); Image(systemName: "arrow.right") } }
                            .buttonStyle(PrimaryButton()).accessibilityIdentifier("train_\(topic.rawValue)")
                    }
                }
            }
            Panel {
                VStack(alignment: .leading, spacing: 15) {
                    Label("間違えた問題を復習", systemImage: "arrow.counterclockwise").font(.headline)
                    Text(store.progress.reviewIDs.isEmpty ? "復習待ちの問題はありません。問題を解くと、苦手なテーマがここに集まります。" : "復習待ち \(store.progress.reviewIDs.count) 問。正解すると復習リストから外れます。")
                        .font(.subheadline).foregroundStyle(Palette.muted)
                    if !store.progress.reviewIDs.isEmpty {
                        Button("復習をはじめる") {
                            session = TrainingSession(questions: store.questions(review: true), title: "苦手を復習")
                        }.buttonStyle(PrimaryButton())
                    }
                }
            }
            Text("この版では、GTOの原理と簡略モデルを学べます。実際のホールデム全局面を解くソルバーや、ソルバー由来のプリフロップ表は含みません。")
                .font(.caption).foregroundStyle(Palette.muted).lineSpacing(4)
        }
        .toolbar(.hidden, for: .navigationBar)
        .fullScreenCover(item: $session) { QuizView(session: $0, onFinish: { selectedTab = 0 }) }
    }
}

struct ProgressViewSheet: View {
    @EnvironmentObject private var store: StudyStore
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            Screen {
                PageHeading(eyebrow: "YOUR LEARNING", title: "小さな積み重ね。", subtitle: "学習記録は、このiPhoneに保存されます。")
                Panel {
                    VStack(alignment: .leading, spacing: 20) {
                        stat("累計解答", "\(store.progress.answers.count) 問")
                        stat("連続トレーニング", "\(store.progress.streak()) 日")
                        stat("学習済みレッスン", "\(store.progress.completedLessonIDs.count) / \(Curriculum.lessons.count)")
                        stat("復習待ち", "\(store.progress.reviewIDs.count) 問")
                    }
                }
                ForEach(StudyTopic.allCases) { topic in
                    let records = store.progress.answers.filter { $0.topic == topic }
                    Panel {
                        VStack(alignment: .leading, spacing: 12) {
                            Label(topic.title, systemImage: topic.symbol).foregroundStyle(topic.tint)
                            if records.isEmpty {
                                Text("まだ解答がありません").font(.subheadline).foregroundStyle(Palette.muted)
                            } else {
                                let correct = records.filter(\.correct).count
                                stat("\(records.count) 問に解答", "正答率 \(Int(Double(correct) / Double(records.count) * 100))%")
                                ProgressView(value: Double(correct), total: Double(records.count)).tint(topic.tint)
                            }
                        }
                    }
                }
                Text("正答率は教材への理解の目安です。実戦での勝率やGTOへの一致度を示すものではありません。")
                    .font(.caption).foregroundStyle(Palette.muted)
            }.navigationTitle("学習記録").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("閉じる") { dismiss() } } }
        }.preferredColorScheme(.dark)
    }
    private func stat(_ label: String, _ value: String) -> some View {
        HStack { Text(label).foregroundStyle(Palette.muted); Spacer(); Text(value).bold() }.font(.subheadline)
    }
}
