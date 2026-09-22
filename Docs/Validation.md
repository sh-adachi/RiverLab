# 検証記録

2026-09-12、Xcode 26.3、iPhone 17 Proシミュレーター（iOS 26.3）で確認。

- 最終版の `xcodebuild ... build`：成功。
- `swift test`：18件成功、失敗0件。役とキッカー、A2345、最強5枚、ターンの全列挙、引き分け、モンテカルロの再現性、ポットオッズ・EV・MDF、入力検証、学習記録・復習・日付境界、教材のカード整合性、簡略均衡の無差別条件。
- UIテスト：3件成功、失敗0件。5問の解答と再開始、解答後の二重採点防止、レッスン完了と再起動後の復元、既定条件で25%・+10 bbの表示、重複カードの選択禁止、エクイティ計算。
- ホーム、レッスン一覧、学習済み状態、セッション結果、確率ラボのスクリーンショットを目視確認。
- 最後にボタンの左右余白と不正なボード枚数の検証を調整し、コアテストとビルドを再実行して成功。実機での画面操作テスト・App Store配布・全対応端末のレイアウト検証は未実施。

以下のログとテスト成果物はローカルの `Artifacts/` に保存し、Gitリポジトリには含めていません。

ログ：`Artifacts/build.log`、`Artifacts/core-tests.log`、`Artifacts/ui-tests.log`。
UI結果：`Artifacts/VerifiedUITests.xcresult`。画面：`Artifacts/home.png`、`Artifacts/Screenshots/`。

## 実機導入

2026-09-12、実機へのDebugビルド・インストール・起動を確認。

- Apple Development署名とAutomatic provisioningで実機ビルド成功。
- `devicectl device install app` で `jp.adachi.riverlab` のインストール成功。
- `devicectl device process launch` で起動成功。
- 実機ビルドログ：`Artifacts/device-build.log`。

実機ではインストール・起動まで確認しています。画面操作の自動テストは上記シミュレーターで実施しました。
