# Cloak
<div align="center">
   <img width="200" height="200" alt="AppIcon" src="https://github.com/user-attachments/assets/8221dd72-abc4-4924-abf9-41a37f3b31a7" />
</div>

macOS の画面右上 (など) に常駐するデジタルクロック。
フルスクリーンアプリの上にも表示され、クリックは下のアプリに透過。
フォント・カラー・配置などをカスタマイズでき、ディスプレイごとに表示/位置を変えることもできる。

## インストール (ビルド済みバイナリ)

1. [Releases](../../releases) ページから最新の `Cloak-vX.Y.Z.zip` をダウンロードして解凍。
2. `Cloak.app` を `/Applications` に移動。
3. 初回起動時に Gatekeeper の警告が出ます (ad-hoc 署名のため)。次のいずれかで回避してください:
   - `Cloak.app` を **右クリック → 開く** → ダイアログで確認
   - もしくはターミナルで:
     ```bash
     xattr -dr com.apple.quarantine /Applications/Cloak.app
     ```

## 必要環境 (ソースからビルドする場合)

- macOS 13 以上
- Swift 6.0 以上 (Command Line Tools `xcode-select --install` で OK、フル Xcode は不要)

## ビルド

```bash
bash scripts/build-app.sh
```

`build/Cloak.app` が生成される。アイコン (`Resources/AppIcon.icns`) が無ければ `Resources/AppIcon.png` から自動生成。

## 起動

```bash
open ./build/Cloak.app
```

- メニューバーに時計アイコンが表示される
- 接続中の各ディスプレイの右上 (デフォルト) に時計が現れる
- クロックの上はクリックスルー。下のアプリを通常通り操作できる
- フルスクリーンアプリの上、全 Space にまたがって表示

## 設定

メニューバーの時計アイコン → **設定…**

### 外観
- フォント: デザイン (System / Rounded / Monospaced / Serif)、ウェイト、サイズ
- 文字: 色、影
- 背景: 色、不透明度 (0 にすると完全透明)、ぼかし (Blur)、角丸

### 配置・表示
- 表示する画面: 接続中の各ディスプレイ別に ON/OFF
- 配置:
  - 横位置 (左/中央/右)、縦位置 (上/下)
  - 横/縦オフセット (px or %)
  - **オフセットを画面サイズ比 (%) で扱う** (デフォルト ON): 画面サイズに対する % として解釈。サイズの違うディスプレイでも視覚的に同じ位置に配置可能
  - **画面ごとに位置を設定**: 各ディスプレイで独立した位置を保存
- ドラッグで移動: 修飾キー (⌥/⌘/⌃/⇧) を選択 — 押しながらクロックをドラッグすると好きな位置に移動できる
- 時刻フォーマット: HH:mm:ss / HH:mm / h:mm:ss a / h:mm a

### 一般
- ログイン時に Cloak を起動 (SMAppService)
- バージョン情報

設定は `UserDefaults` (com.vvsaito.Cloak) に保存され、再起動後も維持される。

## 終了

メニューバーの時計アイコン → **Cloak を終了**

## アイコンの差し替え

別の画像にしたい場合は `Resources/AppIcon.png` を 1024×1024 の好きな PNG に差し替えて、`scripts/make-icon.sh` を実行 → 再ビルド。

```bash
bash scripts/make-icon.sh
bash scripts/build-app.sh
```

## リリース (メンテナ向け)

`gh` CLI で認証済みであることを確認した上で:

```bash
bash scripts/release.sh v1.0.0
```

- 作業ツリーがクリーンで、指定タグが未使用であることをチェック
- `scripts/build-app.sh` で `Cloak.app` をビルド
- `ditto` で `build/Cloak-v1.0.0.zip` を作成 (ad-hoc 署名と拡張属性を保持)
- 注釈付きタグを作成して origin に push
- `gh release create` でインストール手順入りの Release を作成し、zip を添付

## アーキテクチャ

- 純粋な SwiftPM 構成 (Xcode 不要、`swift build` のみで .app バンドル化)
- AppKit (NSPanel/NSStatusItem) と SwiftUI (ClockView/SettingsView) のハイブリッド
- 各ディスプレイ用に `NSPanel` (clickthrough + `.statusBar` レベル + `.fullScreenAuxiliary` + `.canJoinAllSpaces`)
- 修飾キー監視は `NSEvent.addGlobalMonitorForEvents(.flagsChanged)` (Input Monitoring 権限不要) + 1 秒の安全ネット

## ライセンス

未設定 (適宜追加してください)
