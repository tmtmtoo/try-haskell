# 013 — 文字列とパフォーマンス

## この章で何ができるようになるか

- 「`String` を本番で使ってはいけない理由」と `Text` / `ByteString` の使い分けが分かる
- **遅延評価** とそのリスク（**サンク累積**）を直感的に説明できる
- `foldl` ではなく `foldl'` を使う癖がつく
- `seq` / `deepseq` / `BangPatterns` / `StrictData` がそれぞれ何をするか分かる

## まず一行のメンタルモデル

> **`String` は教育用、本番は `Text` か `ByteString`。遅延評価は強力だが、累積計算では裏切るので `foldl'` で正格化する**

---

## 1. 文字列 3 種類

| 型 | 内部表現 | 用途 |
|---|---|---|
| `String` (= `[Char]`) | 連結リスト | **教育用**、設定ファイル、エラーメッセージ |
| `Text` (`text` パッケージ) | UTF-8 配列 | **人間向けの文字列**（ログ、JSON、UI、DB） |
| `ByteString` (`bytestring`) | バイト列 | **バイナリ・ネットワーク** I/O、生バイト |

### なぜ `String` を本番で使わないか

`"hello"` は `'h' : 'e' : 'l' : 'l' : 'o' : []` の連結リスト。**1 文字ごとにポインタとコンストラクタ** を消費する。

- メモリ効率が悪い（1 文字あたり 16〜24 バイト）
- 連結 `++` が左引数の長さに比例
- UTF-8 対応の操作（`length` で文字数を取りたい等）が遅い

入門・教材では `String` のまま使うが、**実務に出る瞬間に `Text` に切り替える**。

### `Text` の典型

```haskell
{-# LANGUAGE OverloadedStrings #-}
import qualified Data.Text as T
import Data.Text (Text)

greet :: Text -> Text
greet name = "Hello, " <> name <> "!"
```

`OverloadedStrings` 拡張があると `"hello"` リテラルが `String` でも `Text` でも `ByteString` でもよくなる（型注釈で決まる）。

`Text` には strict (`Data.Text`) と lazy (`Data.Text.Lazy`) があり、**ストリーミングが要らないなら strict** が標準。

### `ByteString`

「人間向けの文字」ではなく **バイト列**。HTTP リクエストの body、ファイル I/O、バイナリプロトコルなどで使う。

`Data.ByteString.Char8` は「ASCII だけ」を仮定したショートカット。Unicode は使えないので教育用または ASCII 確定の場面のみ。

---

## 2. 遅延評価とは — 「必要になるまで計算しない」

```haskell
let x = expensiveComputation 1000     -- ← ここではまだ実行されない
print x                                -- ← ここで初めて実行される
```

中間の式は **サンク**（thunk）= 未評価の計算 として保存される。

```haskell
let xs = [1, 2, 3]
let ys = map (* 2) xs        -- ys は「map (*2) xs を計算する手続き」
let zs = ys ++ [100]         -- zs は「ys に 100 を足す手続き」
print zs                     -- ★ ここで初めて zs が評価される
```

### 利点

- 無限リスト (`[1..]`) を扱える
- 「使わなかった式は計算もされない」効率
- `if-then-else` のような分岐が値レベルで自然に表現できる

### 欠点 — サンク累積

「累積的に値を足していく」処理で、サンクが **数百万段の式の塔** になることがある。

```haskell
foldl  (+) 0 [1..10000000]   -- ⚠️ サンクが累積、メモリを食う / 遅い
foldl' (+) 0 [1..10000000]   -- ✅ 各ステップで強制評価、速い
```

`foldl` は `((((0 + 1) + 2) + 3) + ... + 10000000)` という **未評価の式** を構築してから最後に評価する。10M 段の式の塔がメモリに乗るまで何もしない。`foldl'` は毎ステップ評価するので、定数メモリで済む。

### 鉄則

- **累積計算は `foldl'`** か `foldr`（無限リスト対応）
- **`foldl` は使わない**

---

## 3. 強制評価のツールたち

| 道具 | 何をする |
|---|---|
| `seq a b` | `a` を WHNF（後述）まで評価してから `b` を返す |
| `($!)` | `f $! x` ＝「`x` を WHNF にしてから `f` に渡す」 |
| `deepseq` | データ構造を **底まで** 評価する（`deepseq` パッケージ） |
| `BangPatterns` 拡張 | パターンに `!x` を付けると WHNF 強制 |
| `StrictData` 拡張 | レコードフィールドを **デフォルト strict** にする |

### WHNF と NF

| 用語 | 意味 |
|---|---|
| **WHNF** (Weak Head Normal Form) | **最外コンストラクタ** が暴かれた状態。`Just _` まで来ているが中身は未評価でも OK |
| **NF** (Normal Form) | **葉まで** すべて評価された状態 |

`seq` は WHNF まで、`deepseq` は NF まで進める。**カウンタや単純な数値型は WHNF で十分**、レコードや木のような構造は `deepseq` を検討。

### `BangPatterns` の例

```haskell
{-# LANGUAGE BangPatterns #-}

mySum :: [Int] -> Int
mySum = go 0
  where
    go !acc []     = acc                      -- ! で acc を強制評価
    go !acc (x:xs) = go (acc + x) xs
```

これで `mySum` が `foldl'` 同等になる。

### `StrictData` の例

```haskell
{-# LANGUAGE StrictData #-}

data Stats = Stats
  { sCount :: Int          -- StrictData によって自動的に strict
  , sTotal :: Double
  }
```

レコードにサンクを溜めない、を **拡張ひとつで保証** する。本番コードでは付けっぱなしにすることが多い。

---

## 4. プロファイリング入門

サンク累積を見つけるには **ヒーププロファイル** が一番効く。

```sh
cabal build --enable-profiling
cabal run -- +RTS -p -RTS              # *.prof が出る (時間プロファイル)
cabal run -- +RTS -h -RTS              # *.hp が出る (ヒーププロファイル)
hp2ps -e8in -c file.hp                  # PostScript 化
```

サンクが累積していると、ヒーププロファイルの「型ごとの色分け」で `Int` や `<thunk>` が時系列で増えていくのが見える。

---

## 5. 文字列処理の典型 — 単語頻度

```haskell
import qualified Data.Text as T
import qualified Data.Map.Strict as Map
import Data.Text (Text)
import Data.Map.Strict (Map)

wordCount :: Text -> Map Text Int
wordCount = Map.fromListWith (+) . map (\w -> (w, 1)) . T.words
```

ポイント:

- `Data.Map.Strict` を使う（`Data.Map.Lazy` だと値がサンクで溜まる）
- `Map.fromListWith (+)` は重複キーを `+` で結合してくれる便利関数

---

## つまずきやすいポイント

- **「`foldl` で動いた」と思っても、実は 100 万要素を超えたところで OOM**: 検証のために大きめの入力でテストする習慣をつける
- **`Data.Map` をデフォルトで使う**: `Data.Map` ＝ `Data.Map.Lazy`（値が遅延）。`Data.Map.Strict` を使う癖をつける
- **`Text` と `String` の混在**: `pack` / `unpack` で変換する必要がある。コストもかかる。プロジェクト内では `Text` で統一
- **`OverloadedStrings` を有効にし忘れる**: `"hello" :: Text` が直接書けず冗長になる
- **`deepseq` は使いすぎると逆に遅い**: 必要なところ（外部に渡す前、IORef に書く前など）だけにする

---

## 演習

[src/Lesson.hs](src/Lesson.hs) の `undefined` を実装して `cabal test x013-strings-and-performance` を緑にする。

| 関数 | シグネチャ | 仕様 |
|---|---|---|
| `wordCount` | `Text -> Map Text Int` | 単語ごとの出現回数。空白で分割 |
| `strictSum` | `[Int] -> Int` | **`foldl'` で実装**。`foldl` を使わないこと（テストが 100 万要素を渡すので、`foldl` だと現実的な時間で終わらない可能性） |
| `runningMean` | `[Double] -> [Double]` | 各位置までの累積平均。`scanl'` などサンクを溜めない実装で |
| `countLines` | `ByteString -> Int` | `\n` の数 + 1（空入力は 0） |

ヒント:

- `wordCount` は `Map.fromListWith (+) . map (\w -> (w, 1)) . T.words`
- `strictSum` は `foldl' (+) 0`
- `runningMean` は `zipWith (/)` で「累積和」と「累積要素数」を割る
- `countLines` は `BS.length . BS.split '\n'` か `BS.count '\n'` を活用

---

## 参考

- [Foldr Foldl Foldl' — Haskell Wiki](https://wiki.haskell.org/Foldr_Foldl_Foldl')
- [The Haskell strict pragma](https://downloads.haskell.org/ghc/latest/docs/users_guide/exts/strict.html)
- [Real World Haskell — ch.25 Profiling and optimization](http://book.realworldhaskell.org/read/profiling-and-optimization.html)
- [text package](https://hackage.haskell.org/package/text) / [bytestring package](https://hackage.haskell.org/package/bytestring)
