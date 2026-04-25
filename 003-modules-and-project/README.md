# 003 — モジュールとプロジェクト

## この章で何ができるようになるか

- ファイルを分割して `import` で繋げる、普通の意味でのモジュール分割ができる
- 「外から見える API」と「中だけで使う実装」を **エクスポートリスト** と **`other-modules`** の合わせ技で隠せる
- `qualified` import で名前衝突を避けられる
- Cabal パッケージの中身（`exposed-modules` / `other-modules`）が読める／書ける

## まず一行のメンタルモデル

Haskell のモジュールは **ファイル 1 つ = モジュール 1 つ**。Python の package と似た階層構造を持つ。**何を見せて何を隠すかをモジュールヘッダで決めるのが要**。

---

## 1. モジュールヘッダ — 見せるものを選ぶ

```haskell
module Lesson.Stats
  ( mean
  , variance
  , stddev
  ) where

mean :: [Double] -> Double
mean = ...

helper :: ...   -- これは外には見えない
helper = ...
```

- `module Lesson.Stats` … モジュール名
- `( mean, variance, stddev )` … エクスポートリスト。**書いたものだけが外に見える**
- エクスポートリストを **省略すると全部公開** される。これは事故のもと。**最初から書く癖**を付ける

> **ファイル配置の規則**: `Lesson.Stats` は `src/Lesson/Stats.hs` に置く。`.` がディレクトリ区切りに対応する。Python と同じ。

---

## 2. import の 5 つの形

| 書き方 | 意味 |
|---|---|
| `import Data.Map` | このモジュールの「公開されている全部」が裸で使える |
| `import Data.Map (Map, fromList)` | 必要なものだけ拾う。**おすすめ** |
| `import Data.Map hiding (lookup)` | ぶつかる名前だけ除外して、それ以外は使う |
| `import qualified Data.Map as M` | 「`M.lookup`」のように **接頭辞付きでしか呼べない**。名前衝突回避の主力 |
| `import Data.Map (Map); import qualified Data.Map as M` | 型は裸、関数は `M.` 付き。実用で一番多い形 |

### `qualified` を使う典型例

`Data.Map` の `lookup` は `Prelude` の `lookup` とぶつかる。素朴に `import Data.Map` すると警告が出る。

```haskell
import Data.Map (Map)
import qualified Data.Map as M

countWords :: [String] -> Map String Int
countWords = foldr (\w -> M.insertWith (+) w 1) M.empty
```

「`Map` という型は裸、`M.insertWith` / `M.empty` のような **関数** は `M.` を必ず付ける」のが業界標準。

---

## 3. 階層モジュール — 「公開窓口」と「内部実装」を分ける

実務でやる典型的な分け方:

```
src/
├── Lesson.hs                    -- 公開窓口 (re-export)
├── Lesson/
│   ├── Stats.hs                 -- 公開 API
│   └── Internal/
│       └── Numeric.hs           -- 内部実装（外から見せたくない）
```

- 利用者は `import Lesson` だけすれば全部使える
- `Lesson.Internal.*` は **`.Internal.` という命名** + **cabal の `other-modules`** で「触らないでね」を二重に守る

### 公開窓口モジュールでの再エクスポート

```haskell
module Lesson
  ( module Lesson.Stats
  ) where

import Lesson.Stats
```

`module Lesson.Stats` を再エクスポート、と書くと「`Lesson.Stats` から見える名前を全部、自分の名前で外に出す」意味。

---

## 4. Cabal の `exposed-modules` / `other-modules`

cabal ファイルにこう書く:

```cabal
library
    exposed-modules:
        Lesson
        Lesson.Stats
    other-modules:
        Lesson.Internal.Numeric
    hs-source-dirs:   src
```

- `exposed-modules` … **このパッケージを依存に追加した別パッケージ** から `import` できるモジュール
- `other-modules` … ビルドはするが、**外のパッケージからは `import` できない**

つまり、

| 隠し方 | 守ってくれるもの |
|---|---|
| エクスポートリスト | **モジュールの中の関数／型** を外に出すか |
| `other-modules` | **モジュールそのもの** を外のパッケージに見せるか |

両方使うと「実装詳細を完全に隠した、安定した公開 API」を作れる。

---

## 5. 演習でやること

[src/](src/) に **3 つのモジュール** を実装する:

```
src/
├── Lesson.hs                       -- 公開窓口、Lesson.Stats を再エクスポート
├── Lesson/
│   ├── Stats.hs                    -- mean / variance / stddev
│   └── Internal/
│       └── Numeric.hs              -- total / count（内部用）
```

cabal はこのレイアウトに合わせて以下のように設定済み（[x003-modules-and-project.cabal](x003-modules-and-project.cabal)）:

```cabal
exposed-modules:
    Lesson
    Lesson.Stats
other-modules:
    Lesson.Internal.Numeric
```

### 各モジュールにやってほしいこと

#### `Lesson.Internal.Numeric`（`other-modules`）

| 関数 | シグネチャ | 仕様 |
|---|---|---|
| `total` | `[Double] -> Double` | 合計（`Prelude.sum` を使ってよい） |
| `count` | `[Double] -> Double` | 要素数を `Double` で返す |

エクスポートリストには `total`, `count` を書く。

#### `Lesson.Stats`（`exposed-modules`）

`Lesson.Internal.Numeric` を **`qualified ... as N`** で import すること（教育目的）。

| 関数 | シグネチャ | 仕様 |
|---|---|---|
| `mean` | `[Double] -> Double` | 算術平均（空入力の挙動は問わない） |
| `variance` | `[Double] -> Double` | **母分散**（`/ n`、`/ (n - 1)` ではない） |
| `stddev` | `[Double] -> Double` | `sqrt . variance` |

#### `Lesson`（`exposed-modules`、再エクスポート）

```haskell
module Lesson
  ( module Lesson.Stats
  ) where

import Lesson.Stats
```

これだけ。利用者（テスト）からは `import Lesson (mean, variance, stddev)` で済むようにする。

---

## つまずきやすいポイント

- **テストが「`Could not find module 'Lesson'` で失敗」する**: 演習開始時はこれが正常な状態。`Lesson.hs` を書き上げると消える
- **`exposed-modules` に書き忘れる**: `cabal build` は通るが、テストや別パッケージから `import` できない。エラーメッセージが分かりづらいので最初に疑う
- **`other-modules` に書き忘れる**: ビルド時に「使われていません」警告が出るか、最悪コンパイルされない
- **`qualified` 忘れ**: `Data.Map` を裸で import すると `lookup` のような Prelude の関数とぶつかる。コンパイラが「`lookup` がどっちか分かりません」と教えてくれる

---

## 参考

- [GHC Users Guide — modules](https://downloads.haskell.org/ghc/latest/docs/users_guide/exts/modules.html)
- [Cabal Users Guide — Library section](https://cabal.readthedocs.io/en/stable/cabal-package.html#library)
- [The Haskell Cabal — package description](https://cabal.readthedocs.io/en/stable/cabal-package-description-file.html)
