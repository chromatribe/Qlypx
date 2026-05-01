<div align="center">
  <img src="./Resources/qlypx_logo.png" width="400">
  <h1>Qlypx</h1>
  <p><strong>Apple Silicon 時代に最適化された、究極にクリーンで高速な macOS 用クリップボードマネージャー</strong></p>
</div>

<br>

Qlypx は、macOS 標準の機能を最大限に活用し、外部ライブラリへの依存を極限まで削ぎ落としたクリップボード拡張アプリです。伝説的なアプリ「Clipy」の魂を受け継ぎつつ、現代の macOS システムにふさわしいアーキテクチャでゼロから作り直されました。

---

## 🚀 特徴

- **Apple Silicon ネイティブ**: arm64 構成で動作し、電力効率とレスポンスを最大化。
- **脱サードパーティライブラリ**: `RxSwift`, `Realm`, `PINCache` などの重厚なライブラリを排除し、`Combine`, `Codable`, `NSCache` などの Apple 標準フレームワークへ移行。
- **モダンな UI**: macOS Big Sur 以降のシステムデザインに適合した `NSToolbar` と **SF Symbols** を採用。
- **爆速・軽量**: バイナリサイズを大幅に削減し、メモリ消費を最小限に抑制。
- **堅牢なプライバシー**: 履歴はローカルで JSON 管理され、外部サーバーとの通信は一切ありません。

## 🖥 動作環境

- **macOS 13.0 (Ventura) 以上**
- Apple Silicon (M1/M2/M3) または Intel Mac

## 🛠 ビルド方法

Qlypx は外部のパッケージ管理ツール（CocoaPods 等）を必要としません。

1. このリポジトリをクローンします。
2. `Qlypx.xcodeproj` を Xcode (15.0以上推奨) で開きます。
3. ビルドターゲットを選択し、`Cmd + R` で実行します。

## 📜 ライセンス

Qlypx は MIT ライセンスの下で提供されています。詳細は `LICENSE` ファイルを参照してください。

---

### Special Thanks

このプロジェクトは、[@naotaka](https://github.com/naotaka) 氏による [ClipMenu](https://github.com/naotaka/ClipMenu) および、[Clipy](https://github.com/Clipy/Clipy) チームの素晴らしい成果に敬意を表し、その遺産を2026年の最新環境に引き継ぐために開発されました。
