# Qlypx Project Master Document

> **このファイルがプロジェクトの唯一の真実（Single Source of Truth）です。**
> `GEMINI.md` はこのファイルへの入口として短く保ちます。

**Current Version:** `1.20260503.9`

---

## 1. コンセプトとビジョン

Qlypx は、単なる Clipy のクローンではありません。**「Apple Silicon 時代に最適化された、究極にクリーンで高速なクリップボードマネージャー」**です。

### 核心とする価値観

| 価値観 | 説明 |
|---|---|
| **Native First** | Apple 標準フレームワークを優先し、外部依存を最小限に抑える |
| **軽量・高速** | バイナリサイズ、メモリ消費、CPU 負荷を極限まで削ぎ落とす |
| **システムフレンドリー** | macOS の最新デザインガイドライン（Unified Toolbar, SF Symbols）に準拠 |

---

## 2. テックスタック・AIルール・バージョン管理

### テックスタック

| レイヤー | 技術 |
|---|---|
| 言語 | Swift 5.9+ |
| UI フレームワーク | **SwiftUI** (Snippet Editor / Preferences), AppKit (NSMenu, NSWindow) |
| 非同期処理 | Combine |
| 永続化 | JSON (Codable) |
| ホットキー | Magnet / KeyHolder / Sauce (SPM) |
| CI | GitHub Actions (macOS 13+) |

### バージョン管理手法: `MAJOR.YYYYMMDD.連番`
// ... (omitted for brevity in replace_file_content but I will include it in the real call)

### バージョン管理手法: `MAJOR.YYYYMMDD.連番`

| 項目 | 説明 |
|---|---|
| `MAJOR` | 製品ライン（現在 `1`） |
| `YYYYMMDD` | リリース日 |
| `連番` | その日の修正番号（01始まり） |

**例:** `1.20260503.1`

#### バージョン同期ファイル一覧（版上げ時は全ファイルを一括更新）

| ファイル | 更新箇所 |
|---|---|
| `Qlypx/Supporting Files/Info.plist` | `CFBundleShortVersionString` / `CFBundleVersion` |
| `PROJECT.md` | **Current Version** ヘッダー（本ファイルの先頭） |
| `PROJECT.md §5 Change Log` | バージョンヘッダーと差分 |

> **運用**: ひとまとまりの機能完成ごとに版を上げ、上記ファイルを一括同期 → `git commit` → `git tag v1.YYYYMMDD.XX`

### AI エージェント向け開発ルール

1. **PROJECT.md 先行**: 新規スレッドでは推測で実装を始めない。Current Version・§3 ファイル辞書・§4 実装状況を読んでから着手する。
2. **型の集約**: 中核型は `Sources/Models/` に集約。再利用のない過剰なマイクロファイルは避ける。
3. **インクリメンタル**: 巨大ファイルの同時全面書き換えを避け、区切りごとに Xcode ビルド確認を挟む。
4. **既存ロジックの保護**: ユーザーが削除を明示していない既存動作は読んだうえで維持しながら最小差分で追加・修正する。
5. **Native First**: Apple 標準フレームワーク優先。外部依存を増やす前に必ずユーザー確認を取る。
6. **ユーザー向け説明**: 自然な日本語で行う。
7. **新ファイル追加時**: Xcode の `.xcodeproj` に登録されているファイルのみコンパイル対象になる。新規 `.swift` を追加しても Xcode 上で「Add to Target」しなければビルドエラーになる。既存ファイルへの統合を優先する。

### ⚠️ このプロジェクト固有のよくあるエラーと対処法

実際に踏んだ地雷を記録。同じ失敗を繰り返さないこと。

#### 1. `NSPasteboard.PasteboardType` 拡張で OS 標準と同名のプロパティを再定義してはいけない

```swift
// ❌ NG: OS標準の .string を extension 内で再定義すると、同じ extension 内の
//        カスタム定数（.legacyString 等）が「not found in scope」になる
extension NSPasteboard.PasteboardType {
    static let string = NSPasteboard.PasteboardType.string  // 循環・重複
    static let legacyString = ...  // ← コンパイラがこれを見失う
}

// ✅ OK: カスタム定数のみ定義。OS 標準（.string / .pdf 等）は再定義しない
extension NSPasteboard.PasteboardType {
    static let legacyString = NSPasteboard.PasteboardType(rawValue: "NSStringPboardType")
}

// ✅ OK: switch 文や引数では完全修飾名で曖昧さを消す
case NSPasteboard.PasteboardType.legacyString:
```

#### 2. ファイル名の変更は必ず Xcode 上で行う

```bash
# ❌ NG: terminal の mv コマンドはファイルを動かすだけ。
#        .xcodeproj/project.pbxproj の参照は古いままになりビルドエラーになる
mv NSPasteboard+Deprecated.swift NSPasteboard+Modern.swift

# ✅ OK: Xcode のファイルリスト上で直接リネーム（Xcode が .xcodeproj も自動更新）
```

#### 3. `NSObject` の `hash` オーバーライドは `Hasher` を使う

```swift
// ❌ NG: URL の .hash は (inout Hasher)->() であり Int ではないので型エラーになる
override var hash: Int {
    var h = 0
    fileURLs.forEach { h ^= $0.hash }  // コンパイルエラー
    return h
}

// ✅ OK: Hasher.combine() に渡す
override var hash: Int {
    var hasher = Hasher()
    fileURLs.forEach { hasher.combine($0) }  // URL は Hashable
    return hasher.finalize()
}
```

#### 4. `Environment` / `AppEnvironment` に新サービスを追加するときは 4 箇所同時更新

1 ファイルでも漏れると `Cannot find type 'XxxService' in scope` が多発する。

| ファイル | 更新内容 |
|---|---|
| `Environment.swift` | プロパティ宣言 + `init` の引数と代入 |
| `AppEnvironment.swift` - `push()` | 引数追加 + `Environment(...)` 呼び出しに追記 |
| `AppEnvironment.swift` - `replaceCurrent()` | 同上 |
| `AppEnvironment.swift` - `fromStorage()` | `return Environment(...)` の末尾に引数追記 |

#### 5. `NSPasteboard.PasteboardType(rawValue:)` は非オプショナル

```swift
let type = NSPasteboard.PasteboardType(rawValue: clip.primaryType)
// type の型は NSPasteboard.PasteboardType（Optional ではない）

// ❌ NG: optional chaining は使えない
if type?.isImage == true { ... }

// ✅ OK
if type.isImage { ... }
```

#### 6. SwiftGen は環境によって実行できない場合がある

`LocalizedStrings.swift` に新しい L10n キーを追加するときは `swiftgen` コマンドを試みること。
実行環境がない場合は手動で `LocalizedStrings.swift` に静的プロパティを追記する（構造を崩さないよう末尾に追加）。

---

## 3. ファイル辞書（責務の一覧）

新規ファイルの追加・削除時は必ずこのセクションを更新すること。

### エントリポイント

| ファイル | 責務 |
|---|---|
| `AppDelegate.swift` | アプリ起動・終了ライフサイクル管理。全サービスの初期化エントリポイント。 |
| `Constants.swift` | UserDefaults キー・メニュー識別子・NotificationCenter 名などの定数定義。 |

### Environments

| ファイル | 責務 |
|---|---|
| `Environment.swift` | 全サービスを束ねる依存性注入コンテナ（struct）。テスト時のスタブ差し替えも担う。 |
| `AppEnvironment.swift` | `Environment` のスタック管理。`current` で現在の環境にアクセスする。 |

### Services

| ファイル | 責務 |
|---|---|
| `ClipService.swift` | NSPasteboard の changeCount をポーリングして履歴を生成・管理する。 |
| `DataService.swift` | JSON (Codable) によるクリップ履歴・スニペットの永続化読み書き。 |
| `DataCleanService.swift` | 孤立した `.data` ファイルの定期クリーンアップ。 |
| `PasteService.swift` | クリップボードへの書き戻し・`Cmd+V` のシミュレーション貼り付け。 |
| `HotKeyService.swift` | グローバルホットキーの登録・解除 (Magnet/KeyHolder)。 |
| `ImageCacheService.swift` | NSCache（メモリ）＋ FileManager（ディスク）の2層サムネイルキャッシュ。 |
| `ExcludeAppService.swift` | コピー除外アプリの判定ロジック。 |
| `AccessibilityService.swift` | アクセシビリティ権限の確認とアラート表示。 |
| `UpdateService.swift` | GitHub Releases API を用いた軽量な自作アップデートチェック。 |
| `SnippetCSVService.swift` | スニペットの CSV インポート・エクスポート。 |

### Models

| ファイル | 責務 |
|---|---|
| `CPYClip.swift` | 履歴1件を表す永続化モデル（Codable）。 |
| `CPYClipData.swift` | クリップボードの実データ（NSCoding）。型別フィールドを保持し、NSPasteboard との変換を担う。 |
| `CPYFolder.swift` | スニペットのフォルダモデル（Codable）。CRUD 操作を自身が持つ。 |
| `CPYSnippet.swift` | スニペット1件のモデル（Codable）。 |
| `CPYAppInfo.swift` | 除外アプリ情報のモデル（NSCoding）。 |
| `CPYDraggedData.swift` | スニペットエディタのドラッグ&ドロップ用データ。 |

### Managers

| ファイル | 責務 |
|---|---|
| `MenuManager.swift` | Combine で駆動する動的なメニューバーメニューの構築・更新。 |

### Preferences / UI

| ファイル | 責務 |
|---|---|
| `CPYPreferencesWindowController.swift` | 設定ウィンドウ（NSToolbar ナビゲーション）。 |
| `CPYSnippetsEditorWindowController.swift` | スニペットエディタウィンドウ（SwiftUI）。全機能を一つの ViewModel とビュー群に統合。 |
| `CPYTypePreferenceViewController.swift` | 「保存する種類」設定パネル。 |
| `CPYExcludeAppPreferenceViewController.swift` | 除外アプリ設定パネル（ドラッグ&ドロップ対応）。 |
| `CPYShortcutsPreferenceViewController.swift` | ショートカットキー設定パネル（KeyHolder）。 |

### Extensions

| ファイル | 責務 |
|---|---|
| `NSPasteboard+Deprecated.swift` | レガシー互換 PasteboardType 定数（`legacyString` 等）とモダン型のヘルパー（`isImage`, `isPDF`, `isFileURL`）。 |
| `Combine+Extensions.swift` | `qly_observe` - UserDefaults の Combine 変更監視ヘルパー。 |
| `NSImage+Resize.swift` | サムネイル生成用のリサイズ拡張。 |
| `NSBundle+Version.swift` | `Bundle.appVersion` - CFBundleShortVersionString の取得。 |
| その他 Extension | 各 NS クラスへの小さなユーティリティ拡張。 |

### Utility

| ファイル | 責務 |
|---|---|
| `QlyLogger.swift` | `os_log` ラッパー（debug/info/warn/error）。**SlackNotificationService / DiagnosticService も同ファイルに統合。** |
| `CPYUtilities.swift` | アプリサポートフォルダのパス取得・SDK 初期化・UserDefaults デフォルト値登録。 |
| `ScreenShotObserver.swift` | `NSMetadataQuery` によるスクリーンショット生成の監視。 |

### Generated（自動生成・手動で編集可）

| ファイル | 責務 |
|---|---|
| `LocalizedStrings.swift` | SwiftGen 生成の型安全 L10n enum。`swiftgen` コマンドで再生成、手動追加も可。 |
| `AssetsImages.swift` | SwiftGen 生成のアセット定数。 |

### DiagnosticServer（サーバー側）

| ファイル | 責務 |
|---|---|
| `DiagnosticServer/src/index.js` | Node.js (Express) 製のクラッシュレポート受信 API。Discord/Slack Webhook に転送。 |
| `DiagnosticServer/.env.example` | サーバー設定例（`PORT`, `WEBHOOK_URL`）。 |

---

## 4. 実装状況

### ✅ 完了

- **Phase 1** - Apple Silicon (arm64) 対応、SPM 移行、SMAppService 対応、リブランディング
- **Phase 2** - Realm/RxSwift 廃止、Combine 移行、ImageCacheService、ScreenShotObserver、NSToolbar モダン化、Sparkle 廃止、スニペット共有廃止、クリーンアップ
- **Phase 3 - i18n** - ハードコード文字列の撲滅、L10n enum への完全移行
- **Phase 3 - Clipboard** - deprecated PasteboardType の排除、PDF/FileURL のモダン化
- **Phase 3 - Diagnostics** - DiagnosticService（クラッシュ検知 + Web API 自動送信）、受信サーバー、**SlackNotificationService（エラー/クラッシュの Slack 即時通知）**
- **Phase 4 - SwiftUI** - 設定画面、スニペットエディタの完全 SwiftUI 移行完了。

### 🚧 進行中 / 未着手

- [ ] `CPY` プレフィックスの `QLY` またはプレフィックスなしへのリネーム（優先度：低）
- [ ] 設定項目のさらなる絞り込み（重複コピー・上書きの UX 改善）
- [ ] DiagnosticServer のデプロイ（Vercel / 自前サーバー）と Webhook 接続
- [ ] 履歴増大時のメニュー表示パフォーマンス改善

---

## 5. Change Log

### 1.20260503.2
- **Refactor**: 設定画面を大幅に整理。迷わせないミニマリズム構成へ移行。
- **Feature**: 重複コピー時に「上書きして先頭に移動」する挙動を標準化。
- **UI**: 設定パネルから冗長な項目（Cmd+V自動入力、数字キーショートカット、0開始設定等）を削除し、レイアウトを最適化。
- **Logic**: `DataService` と `ClipService` の重複処理ロジックを統合・簡略化。

### 1.20260503.9
- **Security**: Slack へのエラー通知を中継サーバー（Google Cloud Run）経由に刷新。アプリから Webhook URL を完全に排除し、安全性を向上。
- **Modernization**: `DiagnosticServer` を Cloud Run へデプロイし、サーバーレスでのエラー収集体制を確立。

### 1.20260503.8
- **Modernization**: スニペットエディタを完全に SwiftUI 移行。`NavigationSplitView` によるモダンな 2 ペインレイアウトを採用。
- **Feature**: `SlackNotificationService` を実装。配布版アプリで発生したエラーやクラッシュをリアルタイムで Slack へ通知する仕組みを導入。
- **UI/UX**: メニュー項目のレイアウトを `attributedTitle` で刷新。画像がある場合でも「番号. [画像] タイトル」の順で綺麗に整列するように改善。
- **Refactor**: `CPYFolder` および `CPYSnippet` を `Identifiable` / `ObservableObject` 化し、SwiftUI との親和性を向上。
- **Fix**: ウィンドウホスト時のレイアウト再帰呼び出し警告を修正。

### 1.20260503.7
- **UI/UX**: 全タブのレイアウト構造（余白、見出しスタイル）を完全に同期し、視覚的な一貫性を向上。
- **UI/UX**: 「対応形式」および「除外アプリ」タブのスペーシングを修正。

### 1.20260503.6
- **UI/UX**: `Layout` 定数を導入し、ウィンドウサイズ（520x550）と全タブの余白を一貫して管理。
- **UI/UX**: 上部余白を 48px に増やし、ツールバーへのコンテンツ食い込みを完全に修正。
- **UI/UX**: 除外アプリ画面に「－（削除）」ボタンを追加。

### 1.20260503.5
- **UI/UX**: 設定画面のレイアウトを左上（topLeading）固定に統一し、ウィンドウ縮小時のコンテンツ食い込みを修正。
- **UI/UX**: 全タブの余白を左右下 52px に最適化。
- **i18n**: 設定画面内のハードコード文字列を完全に排除し、L10n 移行を完了。

### 1.20260503.4
- **UI/UX**: 設定画面の全5タブを完全に SwiftUI へ移行。
- **Modernization**: ウィンドウのリサイズ対応と最新 API (SMAppService, UTType) への準拠。
- **Fix**: `CPYAppInfo` のアイコン取得ロジックの修正。

### 1.20260503.3
- **Modernization**: 設定画面（一般・メニュー）の SwiftUI 移行。
- **Feature**: ログイン時起動の `SMAppService` 対応。

### 1.20260503.1
- **Modernization**: クリップボード処理を `deprecated` 定数から最新 API に刷新。PDF/FileURL の互換性向上。
- **Feature**: `DiagnosticService` - クラッシュ検知と Web API への自動レポート送信機能を追加。
- **Feature**: `DiagnosticServer` - Node.js 製のレポート受信 API（Discord/Slack Webhook 対応）を新設。
- **i18n**: ハードコード文字列を撲滅し、L10n enum への完全移行を完了。
- **Fix**: `NSPasteboard+Deprecated.swift` - 冗長な型定義を整理し、コンパイルエラーを解消。
- **Versioning**: バージョン管理手法を `MAJOR.YYYYMMDD.連番` に移行。`1.20260503.1` に更新。
- **Docs**: `PROJECT.md` を新設。`GEMINI.md` は入口として最小化。

### 1.2.1 (以前)
- Clipy から Qlypx へのモダン化 Phase 1・2 完了（詳細は Git ログ参照）。
