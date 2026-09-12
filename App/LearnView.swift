import SwiftUI

struct LearnView: View {
    @EnvironmentObject private var store: StudyStore
    var body: some View {
        Screen {
            PageHeading(eyebrow: "BUILD YOUR FOUNDATION", title: "基礎から、着実に。", subtitle: "1レッスン数分。知識をつないで、\n自分の言葉で判断できるように。")
            ForEach(StudyTopic.allCases) { topic in
                VStack(alignment: .leading, spacing: 12) {
                    Label(topic.title, systemImage: topic.symbol).font(.headline).foregroundStyle(topic.tint).padding(.bottom, 3)
                    ForEach(Curriculum.lessons.filter { $0.topic == topic }) { lesson in
                        NavigationLink { LessonView(lesson: lesson) } label: {
                            HStack(spacing: 13) {
                                Image(systemName: store.progress.completedLessonIDs.contains(lesson.id) ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(store.progress.completedLessonIDs.contains(lesson.id) ? Palette.mint : Palette.muted.opacity(0.4))
                                VStack(alignment: .leading, spacing: 7) {
                                    Text(lesson.title).font(.subheadline.bold()).foregroundStyle(Palette.cream)
                                    Text(lesson.subtitle).font(.caption).foregroundStyle(Palette.muted).multilineTextAlignment(.leading)
                                    Text("\(lesson.minutes) 分").font(.caption2).foregroundStyle(topic.tint)
                                }.frame(maxWidth: .infinity, alignment: .leading)
                                Image(systemName: "chevron.right").font(.caption2).foregroundStyle(Palette.muted)
                            }.padding(17).background(Palette.surface, in: RoundedRectangle(cornerRadius: 18))
                        }.buttonStyle(.plain).accessibilityIdentifier("lesson_\(lesson.id)")
                    }
                }
            }
        }.toolbar(.hidden, for: .navigationBar)
    }
}

struct LessonView: View {
    let lesson: Lesson
    @EnvironmentObject private var store: StudyStore
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        Screen {
            PageHeading(eyebrow: "\(lesson.topic.title) · \(lesson.minutes) MIN", title: lesson.title, subtitle: lesson.subtitle)
            ForEach(Array(lesson.sections.enumerated()), id: \.offset) { index, section in
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .top, spacing: 12) {
                        Text(String(format: "%02d", index + 1)).font(.system(.caption, design: .monospaced)).foregroundStyle(Palette.mint).padding(.top, 3)
                        Text(section.title).font(.title3.bold())
                    }
                    Text(section.body).font(.body).lineSpacing(8).foregroundStyle(Palette.cream.opacity(0.9)).fixedSize(horizontal: false, vertical: true)
                }
                Divider().overlay(Palette.muted.opacity(0.15))
            }
            Panel {
                VStack(alignment: .leading, spacing: 13) {
                    Label("覚えておきたいこと", systemImage: "bookmark").font(.headline).foregroundStyle(Palette.mint)
                    Text(lesson.takeaway).font(.subheadline).lineSpacing(6)
                }
            }
            if let url = URL(string: lesson.sourceURL) {
                Link(destination: url) { Label("参考資料を読む（外部サイト）", systemImage: "arrow.up.right.square").font(.caption) }
            }
            Button(store.progress.completedLessonIDs.contains(lesson.id) ? "学習済み・一覧に戻る" : "学習を完了する") {
                store.complete(lesson)
                dismiss()
            }.buttonStyle(PrimaryButton())
        }.navigationBarTitleDisplayMode(.inline)
    }
}
