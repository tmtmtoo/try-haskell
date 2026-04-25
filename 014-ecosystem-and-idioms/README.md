# 014 — エコシステムと Haskell らしさ

## この章で何ができるようになるか

- パッケージ検索（**Hoogle**）と公式インデックス（Hackage / Stackage）の使い方が分かる
- ツールチェーン（ghcup / HLS / hlint / fourmolu / ghcid / cabal）の役割を区別できる
- 「これは `containers`、これは `aeson`、これは `optparse-applicative`」のような **定番ライブラリの場所** を覚えた
- Haskell らしいコードを書くときの **コアイディオム**（Smart Constructor / `newtype` 型安全 / point-free / ADT エラー型 / 最弱抽象選択）を意識して書ける

---

## エコシステム

### 1. Hackage / Stackage / Hoogle

| サイト | できること |
|---|---|
| **[Hackage](https://hackage.haskell.org/)** | 公式パッケージリポジトリ。最新版のソース、Haddock ドキュメント、依存関係 |
| **[Stackage](https://www.stackage.org/)** | 「動く組み合わせ」を保証する **LTS スナップショット**。`stack` の標準だが、cabal でも参照できる |
| **[Hoogle](https://hoogle.haskell.org/)** | **型から関数を検索**。Haskell 最強の道具のひとつ |

Hoogle の使い方の例:

```
Hoogle: (a -> b) -> Maybe a -> Maybe b
↓
fmap, <$>
```

```
Hoogle: Maybe a -> (a -> Maybe b) -> Maybe b
↓
(>>=)
```

「こういう型のものが欲しい」と思ったら Hoogle に貼る、が習慣化すると速度が一気に上がる。

### 2. ツールチェーン

| ツール | 役割 |
|---|---|
| **ghcup** | GHC / cabal-install / HLS のバージョン管理（macOS/Linux で実質標準） |
| **cabal** | ビルド、テスト、依存解決、リリース。本講義で使っているのもこれ |
| **stack** | cabal の代替。Stackage ベースで再現性重視 |
| **HLS (haskell-language-server)** | エディタ統合。型情報・補完・hlint 表示・リファクタリング |
| **hlint** | Linter。「ここは `<$>` で書けます」のような書き換え提案 |
| **fourmolu / ormolu** | フォーマッタ。`fourmolu -i src/` で in-place フォーマット |
| **ghcid** | 編集→保存→自動再ビルド。タイトループでの開発に便利 |

このリポジトリは Nix flake で全部まとめて入れている（[flake.nix](../flake.nix) 参照）。`nix develop` か devcontainer に入れば全部揃う。

### 3. 定番ライブラリ — どこに何があるか

| カテゴリ | パッケージ | 何ができる |
|---|---|---|
| データ構造 | **`containers`** | `Data.Map`, `Data.Set`, `Data.Sequence`, `Data.IntMap` |
| 高速ハッシュ Map | `unordered-containers` | キー順序が要らないなら速い |
| 文字列 | **`text`**, **`bytestring`** | 13 章で扱った |
| JSON | **`aeson`** | `FromJSON` / `ToJSON` で派生、`encode` / `decode` |
| CLI | **`optparse-applicative`** | サブコマンド、ヘルプ自動生成、`<*>` で記述的 |
| ロガー | `co-log` / `katip` / `monad-logger` | 構造化ログ |
| HTTP クライアント | `http-client` + `http-client-tls` / `req` / `wreq` | API 叩き |
| Web フレームワーク | `servant` (型レベル) / `wai` + `warp` (低レベル) / `yesod` (フル) | サーバ |
| RDB | `persistent` (ORM 風) / `postgresql-simple` / `beam` | DB アクセス |
| 時刻 | `time` | 日付時刻 |
| 並行 | `async`, `stm` | 12 章で扱った |
| Lens | `lens` (大きい) / `optics` (新世代) | 深い更新、フィールドアクセス |
| Effect 系 | `mtl` / `effectful` / `polysemy` / `fused-effects` | 副作用の整理。10 章の発展 |
| テスト | `hspec`, `tasty`, `QuickCheck` | 4 章で扱った |
| ビルド時生成 | `template-haskell` | マクロ的な機能 |

### 4. cabal の常用コマンド

```sh
cabal build all              # 全パッケージビルド
cabal test xNNN-name         # 特定パッケージのテスト
cabal repl xNNN-name         # GHCi 起動
cabal run xNNN-exe -- arg    # 実行ファイルを起動（-- の後ろは引数）
cabal freeze                 # 依存をピン留め (cabal.project.freeze)
cabal outdated               # 古い依存をリスト
cabal haddock                # ドキュメント生成
```

---

## Haskell らしいプログラミングのイディオム

ここからが「**書ける** から **Haskell らしく書ける**」への分かれ目。

### 1. Smart Constructor — 不正な値が作れない型

2 章でやった通り。「コンストラクタを隠して、検査済みのファクトリ関数だけ公開」。

```haskell
module Email (Email, mkEmail, unEmail) where  -- Email(..) と書かないことでコンストラクタを隠す

newtype Email = Email Text

mkEmail :: Text -> Either String Email
mkEmail t
  | T.null t            = Left "empty"
  | not ('@' `T.elem` t) = Left "missing @"
  | otherwise            = Right (Email t)

unEmail :: Email -> Text
unEmail (Email t) = t
```

これで「`Email` 型の値を持っている = `@` を含む非空文字列」が **型レベルで保証** される。受け取る関数側で再検査する必要がない。

### 2. `newtype` で「意味の違う `Int`」を区別

```haskell
newtype UserId    = UserId    Int deriving (Eq, Show)
newtype ProductId = ProductId Int deriving (Eq, Show)
newtype OrderId   = OrderId   Int deriving (Eq, Show)

getProduct :: ProductId -> IO Product
getProduct = ...
```

`getProduct (UserId 42)` はコンパイルエラー。**実行時のオーバーヘッドはゼロ**（newtype はコンパイル時に剥がされる）。

これは **Go や TypeScript では効果が薄い**（前者は構造的型、後者は構造的型 + ゆるい型）。Haskell の名目的型システムだから機能する。

### 3. Point-free スタイル — 引数を持ち回さない書き方

```haskell
-- ふつうに書く
sumOfSquares :: [Int] -> Int
sumOfSquares xs = sum (map (^ 2) xs)

-- point-free
sumOfSquares :: [Int] -> Int
sumOfSquares = sum . map (^ 2)
```

「関数の合成」として表現できると、**意図が「関数の組み立て」として見える**。`xs` を持ち回す書き方より読み手が短くなる。

> **やりすぎ注意**: 3 段くらいまでが読みやすい。`(.) . (.) . foo . (.) . bar` のような魔境は避ける。

### 4. ADT でエラーを表現する

```haskell
-- 悪い: 文字列でエラー
parseRow :: Text -> Either String Row
parseRow = ...

-- 良い: ADT で構造化
data ParseError
  = MissingField  String
  | InvalidValue  String String      -- (フィールド名, 値)
  | TypeMismatch  String String      -- (期待型, 実際)
  deriving (Eq, Show)

parseRow :: Text -> Either ParseError Row
parseRow = ...
```

利点:

- ハンドラ側で `case` を **網羅** できる（`-Wincomplete-patterns` で漏れを検出）
- メッセージ文字列のスペルミスがコンパイルエラーで防げる
- ログ・テスト・国際化で構造を活かせる

### 5. 最弱抽象を選ぶ

| 必要なこと | 使うもの |
|---|---|
| ただの値変換 | `fmap` (Functor) |
| 並列な合成（依存なし） | `<*>` (Applicative) |
| 直前の結果を見て次を選ぶ | `>>=` (Monad) |
| 効果が違うなら | モナドトランスフォーマー |

「依存があるかも」と読み手に疑わせるのを避ける。

### 6. シグネチャを先に書く

```haskell
-- まず型を書く
parseInt :: Text -> Either ParseError Int
parseInt = ???

-- 次に実装を考える
```

REPL でも `:t function` で型から設計が透ける。**設計のズレ** を実装する前に検出できる。

### 7. "Make illegal states unrepresentable"

「不正な状態を **そもそも作れないようにする**」。

```haskell
-- 悪い: contact が空でも flag が True になりうる
data User = User
  { userName       :: Text
  , userContact    :: Maybe Text
  , userIsContacted :: Bool
  }

-- 良い: 連絡できる状態 / できない状態を型で分ける
data User
  = ContactableUser   { userName :: Text, userContact :: Text }
  | UncontactableUser { userName :: Text }
```

「実行時 `assert` を書きたくなったら型を変える」発想。

---

## つまずきやすいポイント

- **`module Email (Email, ...)` と `module Email (Email(..), ...)` を間違える**: `Email(..)` だとコンストラクタも公開してしまい Smart Constructor が無意味になる
- **`newtype` を書いたのに `deriving` を書き忘れる**: `Eq` / `Show` がないと比較もデバッグもしにくい
- **エラー ADT を作ったが、外に出すときに `Show` してしまう**: メッセージは UI / ログ用に整形する関数を別に用意する
- **「Haskell らしい」を追求しすぎてチームメイトに伝わらない**: 可読性とのバランス。**「読み手が誰か」** を優先する

---

## 演習

[src/Lesson.hs](src/Lesson.hs) の `undefined` を実装して `cabal test x014-ecosystem-and-idioms` を緑にする。

| 項目 | 仕様 |
|---|---|
| `Email` | `newtype Email = Email Text` ─ コンストラクタは **エクスポートしない**（モジュールヘッダで `Email` のみ公開、`Email(..)` ではない） |
| `mkEmail :: Text -> Either String Email` | `'@'` を含まなければ `Left "missing @"`、空文字は `Left "empty"` |
| `unEmail :: Email -> Text` | 中身を取り出す |
| `data ParseError` | `MissingField String` または `InvalidValue String` |
| `parseAssoc :: [Text] -> [Text] -> Either ParseError [(Text, Text)]` | `["k=v","a=b"]` を `[("k","v"),("a","b")]` に。`=` を含まない要素なら `Left (InvalidValue ...)`。先頭引数で必須キーを与え、結果に **そのキーすべて** が含まれていなければ `Left (MissingField ...)` |
| `composeAll :: [a -> a] -> a -> a` | **point-free で書く**（ヒント: `foldr (.) id`） |
| `tally :: Ord a => [a] -> Map a Int` | 出現回数を `Data.Map.Strict.fromListWith` で |

ヒント:

- `parseAssoc` は `traverse` で 1 行 1 行 `Either ParseError (Text, Text)` を作って結合、その後で必須キー検査
- `composeAll = foldr (.) id` の **一行関数** で書ける（`composeAll [(+1),(*2)] 5 = (+1) ((*2) 5) = 11`）

---

## ここまでで身についた力

| Phase | 何ができるようになったか |
|---|---|
| 1 (001-003) | 関数を書ける／読める。型クラスで API を表現できる。プロジェクトを分割できる |
| 2 (004) | 例ベース／性質ベースのテストが書ける |
| 3 (005-008) | Functor / Applicative / Monad / Foldable / Traversable / Monoid を理解し、自前のインスタンスが書ける |
| 4 (009-010) | 実用的な Monad と Monad トランスフォーマーで効果を組み合わせられる |
| 5 (011-012) | IO・例外・並行プログラミングを安全に書ける |
| 6 (013-014) | パフォーマンス問題に気付き対処できる。Haskell らしいコードを書ける |

---

## 次の一歩 — おすすめの方向性

| 興味の方向 | 次に学ぶ |
|---|---|
| Web サーバを書きたい | `servant` / `wai` + `warp`、`persistent` |
| 業務 CLI を書きたい | `optparse-applicative` + `aeson` + `text` |
| 関数型を深く | `lens` / `optics`、`free` モナド、tagless final |
| 並行・分散 | `Cloud Haskell`、`reflex-frp`（FRP） |
| 型レベル | GADTs、TypeFamilies、Singletons |
| コンパイラを書く | `megaparsec`、`alex` + `happy` |
| プロダクション | `stack`、CI 設定、Hackage 公開 |

---

## 参考

- [Hoogle](https://hoogle.haskell.org/) — 型検索
- [State of Haskell Survey](https://taylor.fausak.me/survey/) — 業界動向
- [Haskell Weekly](https://haskellweekly.news/) — 週刊ニュース
- [School of Haskell](https://www.schoolofhaskell.com/)
- [Haskell Discourse](https://discourse.haskell.org/) — コミュニティ
