# ジャグラー設定判別 (iOS / Swift + SwiftUI)

Android版と同じロジック・データを移植した、iPhone / iPad向けアプリです。

## 対応機種・判別ロジック
Android版と同一です（詳細は Android版 README を参照）。
- マイジャグラーV / ネオアイムジャグラーEX / ファンキージャグラー2 /
  ハッピージャグラーV3 / ゴーゴージャグラー3 / ミスタージャグラー / ジャグラーガールズSS
- 各役の出現回数をポアソン分布とみなし、ベイズ推定で設定1〜6の事後確率を算出

## ファイル構成
```
JugglerSettei.xcodeproj/     Xcodeプロジェクトファイル
JugglerSettei/
  JugglerSetteiApp.swift     Appエントリーポイント
  ContentView.swift          メイン画面（機種選択・入力・結果表示）
  Models/JugglerModels.swift 機種データ
  Logic/SettingEstimator.swift ベイズ推定ロジック
  Assets.xcassets/           アイコン・アクセントカラー（プレースホルダー）
```

## ビルド方法
1. Macで `JugglerSettei.xcodeproj` をダブルクリックしてXcodeで開く
2. 上部の実行先を「iPhone 15」などのシミュレータ、または実機に設定
3. 実機の場合は Signing & Capabilities で自分のApple IDチームを選択（無料のPersonal Teamで可）
4. ▶ボタンでビルド・実行

> ⚠️ このプロジェクトファイル(`project.pbxproj`)は手作業で作成しています。
> Xcodeのバージョンによっては開いた際に軽微な自動修正が入ることがあります。
> もし正常に開けない場合は、Xcodeで新規iOSアプリ(SwiftUI)プロジェクトを作成し、
> `JugglerSettei/` フォルダ内のSwiftファイル4つをドラッグ＆ドロップで追加する方法が
> 確実です（Modelsフォルダ・Logicフォルダも一緒にグループとして追加してください）。

## 動作要件
- Xcode 15以降
- iOS 16.0以降（シミュレータ・実機とも）

## 注意事項
Android版と同様、収録している確率データは解析サイト調べのおおよその値です。
判別結果は統計的な目安であり、設定を保証するものではありません。
