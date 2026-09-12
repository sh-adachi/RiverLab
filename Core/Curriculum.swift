import Foundation

public enum StudyTopic: String, Codable, CaseIterable, Sendable, Identifiable {
    case basics, probability, gto

    public var id: String { rawValue }
    public var title: String {
        switch self {
        case .basics: "基礎知識"
        case .probability: "確率と期待値"
        case .gto: "GTOの考え方"
        }
    }
    public var symbol: String {
        switch self {
        case .basics: "book.closed.fill"
        case .probability: "percent"
        case .gto: "scale.3d"
        }
    }
}

public struct LessonSection: Sendable {
    public let title: String
    public let body: String

    public init(title: String, body: String) {
        self.title = title
        self.body = body
    }
}

public struct Lesson: Identifiable, Sendable {
    public let id: String
    public let topic: StudyTopic
    public let title: String
    public let subtitle: String
    public let minutes: Int
    public let sections: [LessonSection]
    public let takeaway: String
    public let sourceURL: String
}

public struct Exercise: Identifiable, Sendable {
    public let id: String
    public let topic: StudyTopic
    public let title: String
    public let prompt: String
    public let context: String
    public let choices: [String]
    public let answerIndex: Int
    public let explanation: String
    public let formula: String?
    public let hero: [String]
    public let board: [String]

    public init(id: String, topic: StudyTopic, title: String, prompt: String,
                context: String, choices: [String], answerIndex: Int,
                explanation: String, formula: String? = nil,
                hero: [String] = [], board: [String] = []) {
        self.id = id
        self.topic = topic
        self.title = title
        self.prompt = prompt
        self.context = context
        self.choices = choices
        self.answerIndex = answerIndex
        self.explanation = explanation
        self.formula = formula
        self.hero = hero
        self.board = board
    }
}

/// Original Japanese learning content. The linked primary sources explain the
/// concepts; exercise situations and their arithmetic are created for this app.
/// No full-game solver outputs or preflop frequencies are claimed here.
public enum Curriculum {
    public static let lessons: [Lesson] = [
        Lesson(
            id: "basics-flow", topic: .basics, title: "まずは1ハンドの流れ", subtitle: "2枚の手札、5枚の共有カード", minutes: 3,
            sections: [
                .init(title: "最強の5枚を作る", body: "ホールデムでは自分だけの手札2枚と、全員が使える共有カード5枚から最も強い5枚を選びます。手札は0枚・1枚・2枚のどの使い方でも構いません。相手を全員フォールドさせてもポットを獲得できます。"),
                .init(title: "4つのベッティングラウンド", body: "手札だけで始まるプリフロップ、共有カードが3枚出るフロップ、4枚目のターン、5枚目のリバーの順です。最後に複数人が残れば、ショーダウンで役を比べます。"),
                .init(title: "5つの行動", body: "まだベットがなければチェックかベット。ベットに直面したらフォールド・コール・レイズを選びます。チェックは追加投入せず次の人へ回すこと、コールは必要な差額を払うことです。")
            ], takeaway: "勝敗を決めるのは、7枚から選んだ最強の5枚。",
            sourceURL: "https://www.pokerstars.com/poker/learn/lesson/texas-holdem-rules/"),
        Lesson(
            id: "basics-hands", topic: .basics, title: "役とキッカーを読む", subtitle: "同じワンペアでも、強さは違う", minutes: 4,
            sections: [
                .init(title: "役の強さ", body: "強い順に、ストレートフラッシュ、フォーカード、フルハウス、フラッシュ、ストレート、スリーカード、ツーペア、ワンペア、ハイカード。ロイヤルフラッシュはAを頂点とする最強のストレートフラッシュです。"),
                .init(title: "キッカーは5枚の中で比較", body: "同じ役なら役を構成する数字を先に比べ、それも同じなら残りのカードを高い順に比較します。この比較に使うカードがキッカー。6枚目のカードやスートの違いでは勝敗は変わりません。"),
                .init(title: "共有カードだけで同点もある", body: "ボードがA・K・Q・J・Tでフラッシュもできなければ、全員の最強の役はAハイストレートです。手札にペアがあっても、そのペアで5枚のストレートを上回ることはできません。")
            ], takeaway: "役が同じなら、最強の5枚を高い順に比べる。",
            sourceURL: "https://www.pokerstars.com/poker/learn/lesson/poker-hand-rankings/"),
        Lesson(
            id: "basics-position", topic: .basics, title: "ポジションは情報の差", subtitle: "後から行動できる価値", minutes: 3,
            sections: [
                .init(title: "BTN・SB・BB", body: "BTNはボタン、SBはスモールブラインド、BBはビッグブラインド。ブラインドは手札を見る前の強制ベットです。bbという単位はビッグブラインド1回分のチップを表します。"),
                .init(title: "後に動くと判断材料が増える", body: "ボタンは参加している限りフロップ以降に最後に行動します。相手のチェックやベットを見てから判断できるため、ポットの大きさや次のカードを見るかを選びやすくなります。"),
                .init(title: "同じ手札でも条件が変わる", body: "まだ多くの人が後ろにいる席とボタンでは、参加するハンドの範囲が変わります。プリフロップ表は人数、スタック、レイク、レイズ額までそろえて読む必要があります。1枚の表を全条件に使うことはできません。")
            ], takeaway: "手札だけでなく、誰が先に行動するかを見る。",
            sourceURL: "https://www.pokerstars.com/poker/learn/lesson/position/"),
        Lesson(
            id: "basics-ranges", topic: .basics, title: "相手を1つの手札に決めない", subtitle: "レンジとブロッカーの入り口", minutes: 4,
            sections: [
                .init(title: "レンジは手札候補の集まり", body: "相手の手札は見えません。そこで候補とその重みをまとめたレンジで考えます。位置や行動、ボードが変わるたびに見直します。レイズだけを見て『必ずAA』と断定しないことが第一歩です。"),
                .init(title: "コンボを数える", body: "見えているカードがないとき、AAは4枚から2枚を選ぶ6通り。AKは16通りで、同じスートのAKsが4通り、異なるスートのAKoが12通りです。自分がAを1枚持つと相手のAA候補は3通りに減ります。"),
                .init(title: "ブロックする対象を確かめる", body: "自分が持つカードは相手には配られません。この除去効果がブロッカーです。強い役を減らすカードでも、同時に相手のブラフを減らすことがあります。カード1枚の名前だけでコールやブラフを決めず、相手のレンジへの影響を考えます。")
            ], takeaway: "『何を持っているか』を、候補と組み合わせの数で考える。",
            sourceURL: "https://blog.gtowizard.com/understanding-blockers-in-poker/"),
        Lesson(
            id: "probability-outs", topic: .probability, title: "アウツから完成率へ", subtitle: "次の1枚と、残り2枚を区別する", minutes: 4,
            sections: [
                .init(title: "目標の役を作るカード", body: "たとえば手札とフロップにハートが合計4枚なら、残りのハートは9枚です。これはフラッシュを完成させる候補。ただし完成しても、相手のフルハウスなどに負ける場合があります。完成率とショーダウンでの勝率は別物です。"),
                .init(title: "正確に数える", body: "相手の手札が不明で、見えているカード以外は一様と仮定します。フロップ時点の未確認カードは47枚。9枚のアウツを次の1枚で引く確率は9÷47で約19.1%。リバーまで2枚とも見られるなら1−(38÷47)×(37÷46)で約35.0%です。"),
                .init(title: "2倍・4倍は概算", body: "次の1枚ならアウツ×2%、フロップから残り2枚ならアウツ×4%が手早い近似です。アウツが多いほど誤差も増えます。フロップのコールだけでリバーまで無料とは限らないので、2枚分を無条件に使わないようにします。")
            ], takeaway: "何枚先までの確率か、完成したら勝てるかを分けて確認。",
            sourceURL: "https://www.pokerstars.com/poker/learn/lesson/calculating-outs/"),
        Lesson(
            id: "probability-pot-odds", topic: .probability, title: "コールに必要な勝率", subtitle: "ポットオッズを自分で計算する", minutes: 4,
            sections: [
                .init(title: "分母はコール後のポット", body: "相手のベット前のポットをP、相手のベットと自分のコール額をBとします。ヘッズアップでレイクなし、コール後に追加ベットがなければ、必要なエクイティはB÷(P＋2B)です。引き分けがあれば、その取り分もエクイティに含めます。"),
                .init(title: "半ポットには25%", body: "ポット100に相手が50をベット。自分も50を払うと最終ポットは200です。必要なエクイティは50÷200＝25%。ポットと同額のベットなら100÷300で約33.3%になります。"),
                .init(title: "現在の値段と将来の支払い", body: "まだ次のラウンドがあるなら、追加で払う額や得られる額、相手に降ろされる可能性も関わります。ドローの完成率だけでコールを確定することはできません。まずは追加ベットのないリバーやオールインで式を練習しましょう。")
            ], takeaway: "コール額 ÷ コール後のポット ＝ 必要なエクイティ。",
            sourceURL: "https://www.pokerstars.com/poker/learn/lesson/pot-odds/"),
        Lesson(
            id: "probability-ev", topic: .probability, title: "期待値で行動を比べる", subtitle: "1回の結果から、平均の価値へ", minutes: 4,
            sections: [
                .init(title: "EVは確率で重みづけした平均", body: "期待値（EV）は起こりうる結果と、その確率を掛けて足した値です。現在の判断から先を比べ、すでに払ったチップは埋没費用として扱います。フォールドを0と置くと、コールする価値を比較しやすくなります。"),
                .init(title: "リバーのコールを計算", body: "レイクなし、ヘッズアップ、引き分けなし。P＝100、B＝50、勝率30%なら、勝つと今の判断から150を得て、負けると50を失います。EV＝0.30×150−0.70×50＝＋10。これは1回につき必ず10増えるという意味ではありません。"),
                .init(title: "ブラフにも同じ考え方", body: "コールされると必ず負けるリバーブラフを考えます。フォールドされる確率をFとすると、EV＝F×P−(1−F)×B。フォールドしてもらう頻度がB÷(P＋B)を上回ると、このブラフはチェックで必ず負ける場合より利益的です。")
            ], takeaway: "結果の良し悪しではなく、判断時点のEVを比べる。",
            sourceURL: "https://blog.gtowizard.com/mdf-alpha/"),
        Lesson(
            id: "probability-variance", topic: .probability, title: "勝率が高くても負ける", subtitle: "短期のブレを理解する", minutes: 3,
            sections: [
                .init(title: "80%は100%ではない", body: "勝率80%の状況でも20%は負けます。独立で同じ条件の試行を仮定すると、2回続けて負ける確率は0.2×0.2＝4%。良い判断から負けることも、悪い判断から勝つこともあります。"),
                .init(title: "連敗は次の勝利を約束しない", body: "独立した試行では、過去に負けが続いても次の勝率は変わりません。長期平均が期待値に近づくことと、過去の損失が必ず戻ることは別です。少ない試行回数で実力を断定しないようにします。"),
                .init(title: "復習するのは判断の根拠", body: "ポット額、コール額、想定したレンジ、勝率の根拠を記録すると、結果に左右されず復習できます。練習問題の正答率は学んだ概念の理解度であり、実戦の収益率やGTOへの一致度を示すものではありません。")
            ], takeaway: "短期の勝敗と、判断の質を切り離して復習する。",
            sourceURL: "https://www.pokerstars.com/poker/learn/lesson/bad-beats-and-variance/"),
        Lesson(
            id: "gto-equilibrium", topic: .gto, title: "GTOが目指すもの", subtitle: "相手に一方的な改善を許さない", minutes: 4,
            sections: [
                .init(title: "均衡を基準にする", body: "GTOはゲーム理論に基づく均衡戦略を指します。ナッシュ均衡では、他のプレイヤーの戦略を固定したとき、自分だけ戦略を変えても期待値を改善できません。ここでは主にレイクなし・2人のゼロサムモデルから学びます。"),
                .init(title: "ソルバーの解は条件つき", body: "参加人数、初期レンジ、スタック、ベットサイズの選択肢、レイクなどが変わると解も変わります。実用的なソルバーの結果は設定されたゲームの近似解です。『この手札は常にレイズ』という状況を省いた暗記には限界があります。"),
                .init(title: "このアプリのGTO学習", body: "まず期待値、無差別、レンジのバランスを学び、条件を絞ったリバーのモデルを数式で解きます。ここでの頻度はその簡略モデルの計算結果です。ノーリミットホールデム全体の解や、未計算の実戦ハンドの推奨頻度ではありません。")
            ], takeaway: "GTOの答えは、ゲームの前提条件とセットで読む。",
            sourceURL: "https://blog.gtowizard.com/how-solvers-work/"),
        Lesson(
            id: "gto-mixing", topic: .gto, title: "複数の行動が正解になる", subtitle: "混合戦略と無差別", minutes: 4,
            sections: [
                .init(title: "混ぜるのには理由がある", body: "完全な均衡で、ある場面の同じ手札に複数の行動が使われる場合、その行動のEVは等しくなります。これが無差別です。利益をわざと捨てるために、悪い行動を混ぜているわけではありません。"),
                .init(title: "1回の行動と長期の頻度", body: "ベットもチェックも同じEVなら、1回チェックしたことだけで誤りとは言えません。一方、長期的に片方ばかり選ぶとレンジ構成が偏り、相手が戦略を調整して利益を得られる場合があります。"),
                .init(title: "ランダム化を練習する", body: "たとえば指定された簡略モデルでベット頻度30%を再現するなら、0〜99の一様な乱数の0〜29でベットします。100回で必ず30回になるわけではありません。頻度の練習とEVの理解を両方進めます。")
            ], takeaway: "1つの正解ボタンではなく、EVと頻度の両方を見る。",
            sourceURL: "https://blog.gtowizard.com/the-three-laws-of-indifference/"),
        Lesson(
            id: "gto-river-model", topic: .gto, title: "小さなリバーを解いてみる", subtitle: "ブラフ比率とコール頻度の関係", minutes: 5,
            sections: [
                .init(title: "モデルのルール", body: "レイクなしの2人戦、リバーのみ。先手は必ず勝つバリューか、必ず負けるエアを半々で持ちます。先手は固定額のベットかチェック。チェックなら即ショーダウン、後手はベットにコールかフォールドのみ。後手はエアにだけ勝つブラフキャッチャーです。"),
                .init(title: "後手を無差別にする", body: "Pをベット前のポット、Bをベット額とします。後手の必要勝率はB÷(P＋2B)なので、ベットしたレンジのブラフ割合をそこに合わせます。P＝120、B＝60なら25%。バリュー全部をベットし、ブラフ対バリューを1対3にすれば達成できます。"),
                .init(title: "先手のエアも無差別にする", body: "後手がP÷(P＋B)の頻度でコールすると、エアのベットEVは0です。P＝120、B＝60なら約66.7%。先手の初期バリューとエアが半々なので、バリューを100%、エアを約33.3%ベットするのがこのモデルの均衡です。")
            ], takeaway: "ベット範囲のブラフ割合と、エアをベットする頻度は別の数値。",
            sourceURL: "https://blog.gtowizard.com/how-to-solve-toy-games/"),
        Lesson(
            id: "gto-mdf", topic: .gto, title: "MDFを正しく使う", subtitle: "レンジ全体の指標を理解する", minutes: 4,
            sections: [
                .init(title: "純粋なブラフを利益0にする", body: "MDFはP÷(P＋B)。Pはベット前のポット、Bはベット額です。コールされると必ず負けるブラフを、ベットと諦めの間で無差別にする防御頻度です。防御にはコールとレイズの両方が含まれます。"),
                .init(title: "個別の手札への命令ではない", body: "MDFが50%でも、すべての手札を半分ずつコールするという意味ではありません。レンジ全体の続行割合を表します。相手のレンジに対する勝率やカード除去効果で、続行に適した手札を考えます。"),
                .init(title: "前提が違えば、そのまま使わない", body: "相手がほとんどブラフしないなら、ブラフキャッチャーをMDFに合わせて無理にコールする理由はありません。複数人のポット、将来のベット、ブラフにも勝率がある場面、トーナメントの賞金構造などでは、単純なMDFが均衡の防御頻度になるとは限りません。")
            ], takeaway: "MDFは出発点。相手のレンジとモデルの前提を確かめる。",
            sourceURL: "https://blog.gtowizard.com/the-art-of-bluff-catching-2/")
    ]

    public static let exercises: [Exercise] = [
        Exercise(id: "basics-01", topic: .basics, title: "最強の5枚", prompt: "ホールデムで、役を作るときに使う手札の枚数は？", context: "ルールの基礎", choices: ["必ず2枚", "0枚・1枚・2枚のいずれでもよい", "必ず1枚"], answerIndex: 1, explanation: "手札2枚と共有カード5枚から最強の5枚を選びます。手札を使わずボードだけで役を作ることもできます。"),
        Exercise(id: "basics-02", topic: .basics, title: "フロップの次", prompt: "4枚目の共有カードが出るラウンドは？", context: "1ハンドの流れ", choices: ["リバー", "プリフロップ", "ターン"], answerIndex: 2, explanation: "フロップで3枚、ターンで4枚目、リバーで5枚目が公開されます。"),
        Exercise(id: "basics-03", topic: .basics, title: "役の強さ", prompt: "ストレートとフラッシュでは、どちらが強い？", context: "通常の52枚のホールデム", choices: ["フラッシュ", "ストレート", "スートによって変わる"], answerIndex: 0, explanation: "フラッシュはストレートより上の役です。スート自体に強弱はありません。"),
        Exercise(id: "basics-04", topic: .basics, title: "キッカーの比較", prompt: "相手は A♣ Q♦。ショーダウンで勝つのは？", context: "あなたの手札とリバーボード", choices: ["相手", "引き分け", "あなた"], answerIndex: 2, explanation: "どちらもAのワンペアですが、あなたの最強5枚はA・A・K・9・7。相手はA・A・Q・9・7で、KのキッカーがQに勝ちます。", hero: ["Ah", "Ks"], board: ["Ad", "9c", "7s", "4h", "2c"]),
        Exercise(id: "basics-05", topic: .basics, title: "ボードを使う", prompt: "相手は 8♥ 8♣。このリバーでの結果は？", context: "フラッシュはできないボード", choices: ["あなたの勝ち", "引き分け", "相手の勝ち"], answerIndex: 1, explanation: "2人ともボードのA・K・Q・J・Tを使うAハイストレートです。手札のペアは勝敗に影響しません。", hero: ["9h", "9d"], board: ["As", "Kd", "Qc", "Jh", "Ts"]),
        Exercise(id: "basics-06", topic: .basics, title: "最後に行動する席", prompt: "参加していれば、フロップ以降に最後に行動する席は？", context: "6人卓のポジション", choices: ["ビッグブラインド", "スモールブラインド", "ボタン"], answerIndex: 2, explanation: "ボタンはフロップ以降の最後の行動者です。相手の行動を見てから判断できる利点があります。"),
        Exercise(id: "basics-07", topic: .basics, title: "チェックできる条件", prompt: "そのラウンドでまだ誰もベットしていないとき、追加投入せず順番を回す行動は？", context: "ベッティングの用語", choices: ["チェック", "コール", "レイズ"], answerIndex: 0, explanation: "チェックは追加投入なしで順番を回します。コールはベットに対して必要額を払う行動です。"),
        Exercise(id: "basics-08", topic: .basics, title: "AAは何通り？", prompt: "Aが1枚も見えていないとき、AAのカードの組み合わせは何通り？", context: "レンジをコンボで数える", choices: ["4通り", "6通り", "12通り"], answerIndex: 1, explanation: "4枚のAから異なる2枚を選びます。順番を区別しないので4×3÷2＝6通りです。", formula: "C(4, 2) = 6"),
        Exercise(id: "basics-09", topic: .basics, title: "同じスートのAK", prompt: "AもKも見えていないとき、AKsは何通り？", context: "s＝suited（同じスート）", choices: ["4通り", "12通り", "16通り"], answerIndex: 0, explanation: "スペード、ハート、ダイヤ、クラブの各1通りで合計4通り。スート違いのAKoは12通り、AK全体は16通りです。"),
        Exercise(id: "basics-10", topic: .basics, title: "Aを持つ除去効果", prompt: "あなたがAを1枚持ち、他にAが見えていないとき、相手のAAは何通り？", context: "ブロッカーの基礎", choices: ["6通り", "1通り", "3通り"], answerIndex: 2, explanation: "相手が使えるAは3枚。3枚から2枚を選ぶので3通りです。Aを1枚持つだけでAA候補は6通りから3通りに減ります。", formula: "C(3, 2) = 3", hero: ["Ah", "Ks"]),
        Exercise(id: "probability-01", topic: .probability, title: "半ポットへのコール", prompt: "ポット80に相手が40をベット。コールに必要なエクイティは？", context: "リバー・2人・レイクなし・追加ベットなし", choices: ["50%", "25%", "33.3%"], answerIndex: 1, explanation: "コール額40を、コール後のポット80＋40＋40＝160で割ります。40÷160＝25%です。", formula: "40 / (80 + 2 × 40) = 25%"),
        Exercise(id: "probability-02", topic: .probability, title: "ポットサイズのベット", prompt: "ポット90に相手が90をベット。コールに必要なエクイティは？", context: "リバー・2人・レイクなし・追加ベットなし", choices: ["約33.3%", "50%", "約66.7%"], answerIndex: 0, explanation: "コール後のポットは270。90÷270＝1/3で、約33.3%のエクイティが必要です。", formula: "90 / (90 + 2 × 90) ≈ 33.3%"),
        Exercise(id: "probability-03", topic: .probability, title: "オーバーベットの値段", prompt: "ポット100に相手が200をベット。コールに必要なエクイティは？", context: "リバー・2人・レイクなし・追加ベットなし", choices: ["50%", "約66.7%", "40%"], answerIndex: 2, explanation: "ベットが大きくても、相手が出したチップも獲得対象です。200÷(100＋200＋200)＝40%になります。", formula: "200 / (100 + 2 × 200) = 40%"),
        Exercise(id: "probability-04", topic: .probability, title: "フラッシュの候補", prompt: "次にハートが出てフラッシュが完成するカードは、未確認カードの中に何枚？", context: "相手の手札は不明・完成しても勝利は保証されない", choices: ["8枚", "9枚", "13枚"], answerIndex: 1, explanation: "ハートは全部で13枚。手札とフロップに4枚見えているので、残りは9枚です。", formula: "13 − 4 = 9", hero: ["Ah", "Jh"], board: ["7h", "2h", "Kc"]),
        Exercise(id: "probability-05", topic: .probability, title: "ターンからの1枚", prompt: "ターンで未確認46枚のうち9枚がフラッシュを完成させるとき、リバーで完成する確率は？", context: "相手の手札は不明・未確認カードは一様と仮定", choices: ["約19.6%", "約35.0%", "約9.0%"], answerIndex: 0, explanation: "残りは1枚なので9÷46で約19.6%。これはフラッシュの完成率であり、相手の手札に対する勝率そのものではありません。", formula: "9 / 46 ≈ 19.6%", hero: ["Ah", "Jh"], board: ["7h", "2h", "Kc", "4s"]),
        Exercise(id: "probability-06", topic: .probability, title: "フロップからの2枚", prompt: "フロップからリバーまで両方見られるとき、9枚のアウツを少なくとも1枚引く確率は？", context: "未確認47枚は一様・9枚の対象カードは固定", choices: ["約19.1%", "約38.3%", "約35.0%"], answerIndex: 2, explanation: "2枚とも外す確率を1から引きます。1−(38/47)×(37/46)≒34.97%。19.1%を単純に2倍すると、両方で当たる場合を重ねて数えてしまいます。", formula: "1 − (38 / 47) × (37 / 46) ≈ 35.0%", hero: ["Ah", "Jh"], board: ["7h", "2h", "Kc"]),
        Exercise(id: "probability-07", topic: .probability, title: "完成率と勝率", prompt: "フラッシュ完成率が約35%なら、ショーダウンのエクイティも必ず約35%？", context: "ドローを評価するときの注意", choices: ["必ず同じ", "同じとは限らない", "必ず35%より低い"], answerIndex: 1, explanation: "完成しても上の役に負ける場合や、未完成でも勝つ場合、引き分ける場合があります。エクイティは相手のレンジに対する最終的な取り分の期待割合です。"),
        Exercise(id: "probability-08", topic: .probability, title: "プラスのEV", prompt: "ポット100、相手のベット50。勝率30%のコールEVは？", context: "リバー・2人・レイクなし・引き分けなし・フォールドEV＝0", choices: ["−10", "0", "＋10"], answerIndex: 2, explanation: "勝てば今ある150を獲得し、負ければコールの50を失います。0.30×150−0.70×50＝＋10。必要勝率25%を上回っています。", formula: "0.30 × 150 − 0.70 × 50 = +10"),
        Exercise(id: "probability-09", topic: .probability, title: "2回の不運", prompt: "勝率80%の試行を独立に2回行うとき、2回とも負ける確率は？", context: "同じ確率・独立試行という仮定", choices: ["4%", "20%", "40%"], answerIndex: 0, explanation: "1回負ける確率は20%。独立なら0.20×0.20＝0.04、つまり4%です。連敗だけで元の判断が悪いとは言えません。", formula: "(1 − 0.80)² = 4%"),
        Exercise(id: "probability-10", topic: .probability, title: "純粋なブラフの採算", prompt: "ポット120に60をブラフベット。相手が40%フォールドするならEVは？", context: "リバー・レイクなし・コールされると必敗・チェックEV＝0", choices: ["−12", "＋12", "＋48"], answerIndex: 1, explanation: "フォールドされた40%で120を得て、コールされた60%で60を失います。48−36＝＋12。成功時のポットだけでなく、失敗時の損失も含めます。", formula: "0.40 × 120 − 0.60 × 60 = +12"),
        Exercise(id: "gto-01", topic: .gto, title: "均衡の意味", prompt: "ナッシュ均衡の説明として正しいのは？", context: "GTOの基礎概念", choices: ["全ハンドで勝つ戦略", "相手の手札を特定する戦略", "他者の戦略が固定なら、自分だけ変えてもEVを改善できない状態"], answerIndex: 2, explanation: "均衡とは、お互いの戦略が最善応答になっている状態です。毎回の勝利や、相手の手札を正確に当てることを意味しません。"),
        Exercise(id: "gto-02", topic: .gto, title: "混合戦略のEV", prompt: "完全な均衡で同じ手札がベットとチェックを混ぜるとき、その2つのEVは？", context: "同じ場面・相手は均衡戦略", choices: ["等しい", "必ずベットの方が高い", "必ずチェックの方が高い"], answerIndex: 0, explanation: "均衡で正の頻度で選ばれる行動は無差別、つまり同じEVです。実用ソルバーの数値は近似計算なので、微小な差が表示される場合があります。"),
        Exercise(id: "gto-03", topic: .gto, title: "ポットベットのMDF", prompt: "ポット100に100のベット。純粋なブラフをEV＝0にする防御頻度は？", context: "リバーの簡略モデル・2人・レイクなし・ブラフはコールされると必敗", choices: ["約33.3%", "50%", "約66.7%"], answerIndex: 1, explanation: "MDF＝P÷(P＋B)＝100÷200＝50%。レンジ全体で半分続行すれば、純粋なブラフは半分で100を得て半分で100を失います。", formula: "100 / (100 + 100) = 50%"),
        Exercise(id: "gto-04", topic: .gto, title: "半ポットのMDF", prompt: "ポット120に60のベット。同じ簡略モデルのMDFは？", context: "リバー・2人・レイクなし・コールされるブラフの勝率0%", choices: ["25%", "50%", "約66.7%"], answerIndex: 2, explanation: "120÷(120＋60)＝2/3で約66.7%。ベットが小さいほど、相手は少ないリスクでポットを狙えるため、防御頻度は高くなります。", formula: "120 / (120 + 60) ≈ 66.7%"),
        Exercise(id: "gto-05", topic: .gto, title: "ブラフの割合", prompt: "半ポットベットに対し後手をコールとフォールドで無差別にする、ベット範囲のブラフ割合は？", context: "簡略リバー・2人・レイクなし・先手は必勝バリューか必敗エア・後手は純粋なブラフキャッチャー", choices: ["25%", "約33.3%", "約66.7%"], answerIndex: 0, explanation: "P＝120、B＝60なら後手の必要勝率は60÷240＝25%。後手はブラフにだけ勝つため、ベット範囲の25%をブラフにするとコールEV＝0になります。", formula: "B / (P + 2B) = 60 / 240 = 25%"),
        Exercise(id: "gto-06", topic: .gto, title: "割合と頻度を区別", prompt: "先手の初期レンジはバリューとエアが半々。バリューを全部半ポットベットするとき、エアを何%ベットすればベット範囲の25%がブラフになる？", context: "簡略リバー・2人・レイクなし・固定サイズ・チェックで終局・後手はブラフキャッチャーでコールかフォールドのみ", choices: ["25%", "約33.3%", "50%"], answerIndex: 1, explanation: "バリューを3単位、エアも3単位持つと考えます。3単位のバリューに1単位のブラフを混ぜると、ブラフは全4単位の25%。エア3単位のうち1単位をベットするので約33.3%です。", formula: "1 / (3 + 1) = 25%; 1 / 3 ≈ 33.3%"),
        Exercise(id: "gto-07", topic: .gto, title: "MDFは誰の頻度？", prompt: "MDFが50%なら、どのように解釈する？", context: "レンジと個別ハンドを区別", choices: ["すべての手札を50%コールする", "強い手札だけを必ずフォールドする", "レンジ全体で続行する割合の指標"], answerIndex: 2, explanation: "MDFはレンジ全体の指標です。各手札を同じ頻度で続行する指示ではなく、勝率やブロッカーを考慮して続行する候補を選びます。"),
        Exercise(id: "gto-08", topic: .gto, title: "ブラフがない相手", prompt: "相手が必勝バリューしかベットしないと確実に分かるなら、必ず負けるブラフキャッチャーでの最善の行動は？", context: "リバー・2人・レイクなし・選択肢はコールかフォールド", choices: ["フォールド", "MDFに合わせてコール", "必ずコール"], answerIndex: 0, explanation: "この前提ならコールは必ずコール額を失い、フォールドは今の判断から0です。MDFを守ること自体が目的ではありません。実戦で相手のブラフがゼロと断定するには十分な根拠が必要です。"),
        Exercise(id: "gto-09", topic: .gto, title: "1回だけでは分からない", prompt: "均衡でベットとチェックが同じEVの場面。ある1回でチェックしたという事実だけで、ミスと言える？", context: "混合戦略の復習", choices: ["ベットしなかったのでミス", "それだけではミスと言えない", "頻度に関係なくチェックだけが常に最適"], answerIndex: 1, explanation: "同じEVの行動なら、1回の選択だけで誤りとは言えません。長期的に混合比率が偏ると、相手が調整して利益を得る余地が生まれる場合があります。"),
        Exercise(id: "gto-10", topic: .gto, title: "モデルの外に出る前に", prompt: "簡略リバーゲームで得たベット頻度を、実戦の別のボードにそのまま使ってよい？", context: "理論を実戦に結びつける", choices: ["同じベット額なら常に使える", "手札が同じなら常に使える", "レンジや選択肢など、前提が一致するか確認する"], answerIndex: 2, explanation: "簡略ゲームはバリューが必ず勝つ、エアが必ず負ける、固定サイズ、レイズなしなどの条件つきです。実戦には中間の強さ、ブロッカー、複数サイズ、レイクなどがあり、頻度がそのまま一致するとは限りません。")
    ]
}
