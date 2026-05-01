# Qlypx 開発リファレンス (Development Reference)

本ドキュメントは、旧 `Clipy` から新生 `Qlypx` へのモダン化プロセスの全記録と、現在のプロジェクト構造、および今後の開発指針をまとめたものです。

---

## 0. Qlypx のアイデンティティ

Qlypx は、単なる Clipy のクローンではありません。**「Apple Silicon 時代に最適化された、究極にクリーンで高速なクリップボードマネージャー」**です。

### 核心とする価値観

- **脱ライブラリ (Native First)**: Apple 標準フレームワークを優先し、外部依存を最小限に抑える。
- **軽量・高速**: バイナリサイズ、メモリ消費、CPU負荷を極限まで削ぎ落とす。
- **システムフレンドリー**: macOS の最新デザインガイドライン (Unified Toolbar, SF Symbols) に準拠する。

---

## 1. 達成済みタスク (Modernization Journey)

### ✅ Phase 1: 基盤の刷新 (環境対応)

- **Apple Silicon (arm64) ネイティブ対応**: Rosetta 2 への依存を排除。
- **SPM への完全移行**: CocoaPods を廃止し、Swift Package Manager に統一。
- **起動時自動起動の近代化**: `SMAppService` (macOS 13+) への移行。
- **リブランディング**: アプリ名、Bundle ID、UserDefaults キーを `Qlypx` に統一。

### ✅ Phase 2: 軽量化と断捨離 (アーキテクチャ刷新)

- **Realm の廃止**: `RealmSwift` を削除し、`Codable` による JSON 保存 (`DataService`) へ移行。
- **RxSwift の排除**: `RxSwift`, `RxCocoa` 等をすべて削除し、標準の `Combine` フレームワークへ完全移行。
- **キャッシュのネイティブ化**: `PINCache` を削除し、`NSCache` と `FileManager` を組み合わせた `ImageCacheService` を自作。
- **スクリーンショット監視のネイティブ化**: `Screeen` ライブラリを廃止し、`NSMetadataQuery` を用いた `ScreenShotObserver` を実装。
- **UI モダン化 (macOS 13+ スタイル)**:
  - Preferences 及び Snippets Editor のカスタムツールバーを廃止。
  - ネイティブな `NSToolbar` (Unified Style) と **SF Symbols** を導入。
- **不要機能の完全削除 (断捨離)**:
  - **Sparkle (自動アップデート) 廃止**: 肥大なライブラリを捨て、軽量な自作 `UpdateService` に置き換え。
  - **スニペット共有機能 廃止**: 複雑な XML 処理 (`AEXML`) と UI を削除。
  - **Beta機能 廃止**: メンテナンスコスト削減のため削除。
- **最終クリーンアップ (2026/05/02)**:
  - 不要な画像アセット (`xcassets`) の削除。
  - レガシープロジェクト (`Clipy.xcodeproj`) および移行スクリプトの完全排除。
  - CI (`GitHub Actions`) の macOS 13+ / SPM ベースへの刷新。

---

## 2. 現在のプロジェクト構造

### 主要コンポーネント

- **`DataService`**: JSON ベースの永続化ロジック。
- **`ClipService`**: クリップボードの監視と履歴管理。
- **`MenuManager`**: Combine で駆動する動的なメニュー構築。
- **`ScreenShotObserver`**: `NSMetadataQuery` による純正スクリーンショット監視。
- **`ImageCacheService`**: `NSCache` によるメモリ管理とディスクキャッシュ。

### 依存している外部ライブラリ (最小限)

- **`Magnet` / `KeyHolder`**: グローバルホットキー管理用。
- **`Sauce`**: キーボードレイアウトに依存しないキーコード取得用。

---

## 3. 今後のロードマップ (Phase 3: 洗練と深化)

### 🗑️ クラス名プレフィックスの整理 (優先度: 低)

- 歴史的経緯で残っている `CPY` (Clipy) プレフィックスを `QLY` またはプレフィックスなしへリネームする（影響範囲が広いため、慎重な一括置換が必要）。

### 🎨 設定項目のさらなる整理

- ユーザーが迷わないよう、あまり使われないマニアックな設定項目をさらに絞り込み、究極のミニマリズムを目指す。

### ⚡️ パフォーマンスの極限追求

- 履歴が増大した際のメニュー表示速度や、検索機能のアルゴリズム改善。

---

## 4. 開発者へのメモ

- **UI 変更時**: `.xib` を編集する際は、AutoLayout の制約に注意。特に `NSToolbar` を使用しているため、Window の `contentView` はシンプルに保つこと。
- **Combine**: `UserDefaults` の変更監視には `qly_observe` エクステンションを使用すること。
