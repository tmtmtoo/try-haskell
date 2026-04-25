# 012 — 並行プログラミング

## この章で何ができるようになるか

- Haskell の **軽量スレッド** モデルを説明できる
- `MVar` で共有状態の排他制御ができる
- `async` パッケージで「並行 IO」を組み立てられる
- STM の `TVar` / `atomically` / `retry` で **合成可能な** 並行制御ができる

## まず一行のメンタルモデル

> **GHC のスレッドは OS スレッドではなく軽量。数千～数十万を平気で起動できる**

並行制御の道具は 3 段階で覚える: **`MVar`（最低限のロック箱）→ `async` パッケージ（高水準 API）→ STM（合成可能なトランザクション）**。

---

## 1. `forkIO` — 軽量スレッドを起動

```haskell
import Control.Concurrent

example :: IO ()
example = do
  _ <- forkIO (putStrLn "world")
  putStrLn "hello"
```

`forkIO :: IO () -> IO ThreadId`。**バックグラウンドで動くアクションを起動**する。

実行結果は `helloworld\n` か `worldhello\n` か `hewolrloldd\n` か分からない（並行）。

> **GHC スレッドは超軽量**: OS スレッドと違って 1 個あたり数 KB のメモリしか食わない。100 万スレッドでも余裕。これがあるから「**ホテル予約サーバが並行リクエストを 1 リクエスト 1 スレッドで捌く**」みたいなナイーブな設計が現実的に動く。

---

## 2. `MVar` — 排他制御の基本

「**中身が 1 つ入る箱**」。空のとき、満杯のとき、それぞれの操作がブロックする。

| 操作 | 動作 |
|---|---|
| `newMVar x` | 中身 `x` で初期化された MVar を作る |
| `newEmptyMVar` | 空の MVar を作る |
| `takeMVar mv` | **取り出す**。空ならブロック |
| `putMVar mv x` | **入れる**。満杯ならブロック |
| `readMVar mv` | 取り出して即戻す（中身は残る） |
| `modifyMVar_ mv f` | 取り出して `f` を適用して戻す（例外安全） |

### 例: 共有カウンタ

```haskell
counter :: IO Int
counter = do
  mv <- newMVar (0 :: Int)
  let bump = modifyMVar_ mv (pure . (+ 1))
  -- 1000 スレッドが同時に bump
  _ <- mapConcurrently (const bump) [1..1000]
  readMVar mv     -- 1000
```

`modifyMVar_` は「取り出す → 更新 → 戻す」を **例外が起きても箱に戻す** ように面倒を見てくれる。直接 `takeMVar` / `putMVar` を書くより安全。

### `MVar` の限界 — **合成できない**

```haskell
-- 2 つの MVar を「同時に」更新したい
transfer :: MVar Int -> MVar Int -> Int -> IO ()
transfer from to amount = do
  -- ⚠️ ここで他のスレッドに割り込まれると、片方だけ変わった状態になる
  ...
```

`MVar` ではトランザクション境界を作れない。これが STM の動機。

---

## 3. `async` パッケージ — 並行 IO の高水準 API

`forkIO` を直接書く前に、まず `async` を検討する。**例外伝播・キャンセル・結果受け取り** が綺麗にまとまっている。

```haskell
import Control.Concurrent.Async
```

| 関数 | 意味 |
|---|---|
| `async :: IO a -> IO (Async a)` | 非同期で起動。後で結果を取れる |
| `wait :: Async a -> IO a` | 結果が出るまで待つ |
| `cancel :: Async a -> IO ()` | 起動した処理をキャンセル |
| `concurrently :: IO a -> IO b -> IO (a, b)` | **2 つを並行に走らせて両方の結果を返す** |
| `race :: IO a -> IO b -> IO (Either a b)` | **早い方の結果** を返す。遅い方は自動キャンセル |
| `mapConcurrently :: Traversable t => (a -> IO b) -> t a -> IO (t b)` | リストを並行に処理 |

### 例

```haskell
-- API を並行に叩いてレスポンスを両方取る
fetchBoth :: IO (User, Posts)
fetchBoth = concurrently fetchUser fetchPosts

-- タイムアウト
withTimeout :: Int -> IO a -> IO (Maybe a)
withTimeout micros action = do
  r <- race (threadDelay micros) action
  pure (case r of
          Left _  -> Nothing      -- タイムアウト先勝ち
          Right x -> Just x)
```

---

## 4. STM — 「ロックなしで複数の操作をまとめる」

STM = Software Transactional Memory。「複数のメモリ操作を **アトミックなトランザクション** にまとめる」ための仕組み。

### 基本

```haskell
import Control.Concurrent.STM

example :: IO Int
example = do
  tv <- atomically (newTVar (0 :: Int))    -- TVar Int を作る
  atomically (writeTVar tv 42)              -- 書き換え
  atomically (readTVar tv)                  -- 読み取り → 42
```

| 操作 | 意味 |
|---|---|
| `newTVar x :: STM (TVar a)` | 可変参照を作る |
| `readTVar tv :: STM a` | 読む |
| `writeTVar tv x :: STM ()` | 書く |
| `atomically :: STM a -> IO a` | **STM ブロックを実行する** |

### `atomically` の中なら何でも合成できる

```haskell
transfer :: TVar Int -> TVar Int -> Int -> STM ()
transfer from to amount = do
  fromBal <- readTVar from
  if fromBal < amount
    then retry                    -- ⚠️ ここで「待つ」
    else do
      writeTVar from (fromBal - amount)
      toBal <- readTVar to
      writeTVar to (toBal + amount)

main :: IO ()
main = do
  a <- atomically (newTVar 100)
  b <- atomically (newTVar 0)
  atomically (transfer a b 30)    -- ★ 全体が「不可分（アトミック）」
```

`atomically` ブロックの中の操作は **全部成功** か **全部やり直し** のどちらか。途中で他のスレッドに割り込まれても、結果が壊れたまま見えることはない。

### `retry` — 「条件が変わるまで待つ」

`retry` を書くと「このトランザクションを **やり直し**」という意味になる。STM ランタイムは「読んだ `TVar` のどれかが変わるまで待つ」を自動でやってくれる。**スレッドの起こし方／ロックの取り方／タイムアウトを書く必要がない**。

```haskell
-- 残高 30 以上になるまで待ってから出金
withdraw :: TVar Int -> Int -> STM ()
withdraw tv amount = do
  bal <- readTVar tv
  if bal < amount
    then retry
    else writeTVar tv (bal - amount)
```

別のスレッドが入金して `bal` が増えると、自動でこのトランザクションが起き直る。

### `orElse` — 「どっちか先に成立した方」

```haskell
withdraw tv1 100 `orElse` withdraw tv2 100
-- どちらかの口座から 100 引ける方を選ぶ
```

これが **MVar には絶対に書けない芸当**。STM は **トランザクションを値として合成できる** ことが本質。

---

## 5. どれを使い分けるか

| やりたいこと | 道具 |
|---|---|
| 軽い並行 (fire-and-forget) | `forkIO` |
| 並行に何かを実行して結果を待つ | **`async`**（`concurrently` / `race`） |
| 単一の共有変数の排他更新 | `MVar` (`modifyMVar_`) |
| 複数の変数を「同時に」更新 | **STM** |
| 「条件待ち」が必要 | **STM の `retry`** |
| 「どっちか先に来た方」 | **STM の `orElse`** か `race` |

迷ったら **async + STM**。`forkIO` と `MVar` を直接書くのは、ライブラリ作者か特殊なケース。

---

## つまずきやすいポイント

- **`forkIO` した処理の例外は親に伝わらない**: 黙って死ぬ。これが嫌だから `async` を使う（例外をきちんと伝播してくれる）
- **`MVar` のデッドロック**: `takeMVar` を 2 つ取る順序が他のスレッドと逆になるとデッドロック。`modifyMVar_` を使うかロック順序を統一
- **`atomically` の中で `IO` を呼ぼうとする**: できない（型が `STM`、`IO` 不可）。**これは仕様**。「副作用なし → リトライしても安全」を型で保証している
- **`forkIO` で起動したスレッドは `main` が終わると殺される**: バックグラウンド処理を最後まで走らせたいなら `wait` か `link` (async) で待つ

---

## 演習

[src/Lesson.hs](src/Lesson.hs) の `undefined` を実装して `cabal test x012-concurrency` を緑にする。

| 関数 | 仕様 |
|---|---|
| `bumpManyTimes :: Int -> Int -> IO Int` | `MVar` カウンタを「`n` スレッド × 各 `m` 回」インクリメントし、最終値を返す。`mapConcurrently` を使うと簡潔 |
| `parPair :: IO a -> IO b -> IO (a, b)` | `concurrently` で 2 つの IO を並行に実行 |
| `Account` | `TVar Int` をラップした口座 |
| `mkAccount :: Int -> STM Account` | 初期残高で口座を作る |
| `balance :: Account -> STM Int` | 残高を読む |
| `transfer :: Int -> Account -> Account -> STM ()` | 残高不足なら `retry`、ok なら移動 |

ヒント:

- `bumpManyTimes` は `replicate (n * m) (modifyMVar_ mv (pure . (+1)))` を `mapConcurrently_` する
- `parPair = concurrently`（同義になる）
- `transfer` は本文の例とほぼ同じ

---

## 参考

- [Beautiful Concurrency — Simon Peyton Jones](https://www.microsoft.com/en-us/research/wp-content/uploads/2007/01/beautiful.pdf) — STM の論文、平易
- [async on Hackage](https://hackage.haskell.org/package/async)
- [stm on Hackage](https://hackage.haskell.org/package/stm)
- [Parallel and Concurrent Programming in Haskell — Simon Marlow](https://simonmar.github.io/pages/pcph.html) — 決定版書籍（無料 web 版あり）
