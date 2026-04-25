# 009 — 実践的なモナド

## この章で何ができるようになるか

- 「`State` / `Reader` / `Writer` / `[]` / `ST` ってそれぞれ何のためにあるの?」に答えられる
- それぞれのモナドで「`do` を書く → 実行関数で剥がして結果を取り出す」流れができる
- 副作用の **種類** から「どのモナドを選ぶか」を判断できる

## まず一行のメンタルモデル

> **「やりたいこと」ごとに **専用の Monad** が用意されている。それぞれ「`do` で書く」「実行関数で剥がす」の 2 ステップ。**

各モナドが「どんな効果を提供するか」だけ覚えれば、書き方はすべて同じ。

---

## 0. モナドのカタログ

| モナド | 何ができる | 実行関数 |
|---|---|---|
| `Maybe` | 失敗したら短絡 | （直接使う） |
| `Either e` | エラー値付き短絡 | （直接使う） |
| `[]` | 複数候補（非決定計算） | （直接使う） |
| `Reader r` | **読み込み専用** の環境にアクセス | `runReader` |
| `Writer w` | **追記専用** のログを蓄積（`w` は Monoid） | `runWriter` |
| `State s` | **読み書き** できる状態 | `runState` |
| `ST s` | 「外に漏れない」可変参照 | `runST` |
| `IO` | 外部世界との相互作用 | （`main` で実行される） |

---

## 1. `State s` — 「変数を持ち回りたい」を解消する

可変変数のない言語で「カウンタを 1 進める」とどうやる? 関数の引数で旧状態を受け取り、戻り値で新状態を返す:

```haskell
bump :: Int -> Int
bump s = s + 1
```

これが **複数のステップでタネル**になると、毎回引数で持ち回す書き方が苦痛になる:

```haskell
example :: Int -> Int
example s0 =
  let s1 = bump s0
      s2 = bump s1
      s3 = bump s2
   in s3
```

`State` モナドはこれを **`do` で書ける** ようにする:

```haskell
import Control.Monad.State

example :: State Int Int
example = do
  modify (+ 1)
  modify (+ 1)
  modify (+ 1)
  get
```

実行する:

```haskell
runState example 0    -- (3, 3)   ← (戻り値, 最終状態)
evalState example 0   -- 3        ← 戻り値だけ
execState example 0   -- 3        ← 状態だけ
```

### 主要 API

| 関数 | 意味 |
|---|---|
| `get` | 現在の状態を **読み取る** |
| `put s` | 状態を `s` で **置き換える** |
| `modify f` | 状態に関数 `f` を適用 |
| `gets f` | `get` してから `f` を適用 |

### 例: スタック

```haskell
push :: Int -> State [Int] ()
push x = modify (x :)

pop :: State [Int] (Maybe Int)
pop = do
  xs <- get
  case xs of
    []     -> pure Nothing
    (h:t)  -> put t >> pure (Just h)
```

可変オブジェクトに見えるが、**実体は「関数の引数で状態を持ち回している」だけ**。`do` 記法のおかげで命令的に書ける。

---

## 2. `Reader r` — 「設定を引数で持ち回さない」

「DB 接続、設定ファイルの値、認証トークン」のような **読み取り専用の値** を、関数の引数で延々と持ち回すのは辛い。`Reader` でこれを隠せる。

```haskell
import Control.Monad.Reader

data Config = Config { hostname :: String, port :: Int }

url :: Reader Config String
url = do
  h <- asks hostname
  p <- asks port
  pure ("http://" ++ h ++ ":" ++ show p)
```

実行:

```haskell
runReader url (Config "localhost" 8080)
-- "http://localhost:8080"
```

### 主要 API

| 関数 | 意味 |
|---|---|
| `ask` | 環境全体を取得 |
| `asks f` | `ask` してから `f` を適用 |
| `local f m` | `m` の **実行中だけ** 環境を `f` で変換 |

「依存注入を、引数を書かずにやる」のが Reader。

---

## 3. `Writer w` — 「ログを集めながら計算」

「副作用として何かを **蓄積** したい」ときに使う。代表例はトレースログ。

```haskell
import Control.Monad.Writer

tracedFact :: Int -> Writer [String] Int
tracedFact 0 = do
  tell ["fact 0 = 1"]
  pure 1
tracedFact n = do
  tell ["calling fact " ++ show n]
  m <- tracedFact (n - 1)
  pure (n * m)
```

実行:

```haskell
runWriter (tracedFact 3)
-- (6, ["calling fact 3", "calling fact 2", "calling fact 1", "fact 0 = 1"])
```

### 主要 API

| 関数 | 意味 |
|---|---|
| `tell w` | ログ `w` を **追記** |
| `runWriter` | `(値, ログ)` を返す |

> **重要**: ログ型 `w` は **`Monoid`** であること。`String` ではなく `[String]` が定石（`++` の漸増コストを避けるため）。本格的にやるなら `DList` パッケージ。

---

## 4. List モナド — 「複数候補から選ぶ」

リストはモナドでもある。「すべての可能性を試す」探索が `do` で書ける。

```haskell
triples :: Int -> [(Int, Int, Int)]
triples n = do
  a <- [1..n]              -- a を 1..n の中から選ぶ
  b <- [a..n]              -- b を a..n の中から選ぶ
  c <- [b..n]
  if a*a + b*b == c*c
    then pure (a, b, c)    -- 条件を満たすなら結果に追加
    else []                -- 満たさないなら捨てる
```

「リスト内包表記」と等価:

```haskell
triples n =
  [ (a, b, c)
  | a <- [1..n]
  , b <- [a..n]
  , c <- [b..n]
  , a*a + b*b == c*c
  ]
```

両方マスターしておくと、適材適所で使い分けられる。

---

## 5. `ST` モナド — 「外に漏れない可変変数」

「アルゴリズム的に **可変変数が欲しい** けど、IO は使いたくない」というニッチだが強力な道具。

```haskell
import Control.Monad.ST
import Data.STRef

sumST :: [Int] -> Int
sumST xs = runST $ do
  ref <- newSTRef 0
  mapM_ (\x -> modifySTRef ref (+ x)) xs
  readSTRef ref
```

`runST` の型は **`(forall s. ST s a) -> a`** という特殊な形（ランクN多相）。これは「`ST` の中で作った可変参照は外に出られない」を **型で強制** している。だから `sumST :: [Int] -> Int` という **純粋関数** として外に見せられる。

### `IO` との違い

|  | `IO` | `ST` |
|---|---|---|
| 外部入出力 | できる | できない |
| 可変参照 | `IORef` | `STRef` |
| 外への漏れ | あり（`main` まで伝播） | **なし**（`runST` で純粋関数になる） |

純粋関数の中で局所的に可変アルゴリズムを書きたいときの逃げ道。

---

## 6. `Maybe` / `Either` モナドの再確認

7 章でやった通り。

```haskell
import Text.Read (readMaybe)

example :: Maybe Int
example = do
  a <- readMaybe "100"
  b <- readMaybe "5"
  pure (a + b)
```

「失敗するかも」が連鎖する場面では **常に活躍する**。

---

## どのモナドを選ぶか — 早見表

| 副作用の種類 | 使うモナド |
|---|---|
| 失敗するかも | `Maybe` |
| 失敗時にメッセージが欲しい | `Either e` |
| 複数候補を探索 | `[]` |
| 設定を読みたい | `Reader r` |
| ログを溜めたい | `Writer w` |
| カウンタなど読み書き状態 | `State s` |
| 局所的に可変変数 | `ST s` |
| 外部入出力 | `IO`（11 章） |

複数組み合わせたい? → 次章 **モナドトランスフォーマー**。

---

## つまずきやすいポイント

- **`runState` の戻り値順を忘れる**: `(a, s)` の順で「戻り値、最終状態」。`runReader` は `a` だけ、`runWriter` は `(a, w)`
- **`Writer` の蓄積が `String` だと遅い**: `++` が左結合で再帰的に呼ばれて O(n²) になる。`[String]` か `DList` を使う
- **`State` で「並列実行」を期待する**: `State` は逐次実行。並列にしたいなら別の道具（`Par` モナドなど）
- **`ST` の `s` 型変数が謎に見える**: 「絶対に外に出ないよ」のラベルでしかない。実装上は触れる必要なし

---

## 演習

[src/Lesson.hs](src/Lesson.hs) の `undefined` を実装して `cabal test x009-monads-in-practice` を緑にする。

| 関数 | 仕様 |
|---|---|
| `push :: Int -> State [Int] ()` | スタックに積む |
| `pop :: State [Int] (Maybe Int)` | 空なら `Nothing`、そうでなければ取り出す |
| `urlR :: Reader Config String` | `"http://<host>:<port>"` を組み立てる |
| `tracedFact :: Int -> Writer [String] Int` | 各呼び出しで `tell ["..."]` を残しつつ階乗を返す |
| `pythagoreans :: Int -> [(Int, Int, Int)]` | List モナドで `1..n` の範囲のピタゴラス数 (`a≤b≤c`) |
| `sumST :: [Int] -> Int` | `STRef` を使った合計 |

---

## 参考

- [mtl on Hackage](https://hackage.haskell.org/package/mtl) — `Control.Monad.{State,Reader,Writer}` を提供
- [Control.Monad.ST](https://hackage.haskell.org/package/base/docs/Control-Monad-ST.html)
- [State Monad — A Better Way to Solve Sudoku](https://www.fpcomplete.com/blog/2017/04/state-monad/) — State の実例
