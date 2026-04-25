# 011 — IO と例外

## この章で何ができるようになるか

- 「Haskell では **副作用が型に表れる**」のが何のためなのかを腑に落とす
- `IORef` で局所的な可変状態を扱える
- 例外の 3 種類（**純粋例外** / **同期 IO 例外** / **非同期例外**）の違いと、それぞれの捕まえ方が分かる
- `try` / `catch` / `bracket` / `finally` を使い分けられる

## まず一行のメンタルモデル

> **`IO a` は「実行可能なアクションの **設計図**」。`main` から呼び出されたときに初めて動く**

`putStrLn "hi"` という式は **印字を実行しない**。「印字を実行するアクションを作る」だけ。なので `IO` の値は組み合わせて、加工して、最終的に `main` まで届けてはじめて動く。

---

## 1. なぜ Haskell は IO をこんな扱いにするのか

```haskell
greet :: String -> IO ()
greet name = putStrLn ("hello " ++ name)

double :: Int -> Int
double x = x * 2
```

シグネチャを見るだけで、

- `greet` … **副作用がある**（`IO` という箱に包まれている）
- `double` … **純粋関数**（同じ入力に対して毎回同じ出力）

が読み取れる。「この関数が DB を叩くのか / ネットワークアクセスするのか / ロガーを動かすのか」を **型を読むだけで判別** できる、というのが Haskell の特徴。

### `do` 記法は IO でもただの Monad

```haskell
main :: IO ()
main = do
  putStrLn "What's your name?"
  name <- getLine
  putStrLn ("hello " ++ name)
```

`do` は IO 専用ではない（7 章でやった通り、Maybe や Either でも同じ書き方）。`<-` で「箱を開けて中身を変数に束縛」、`pure x` で「値を箱に入れて返す」。

### 純粋関数から IO は呼べない

```haskell
double :: Int -> Int
double x = do
  putStrLn "doubling"   -- ⚠️ コンパイルエラー
  pure (x * 2)
```

これは Haskell の **強み**。「気がついたらここで DB アクセスしていた」という事故を、コンパイル時に防ぐ。

---

## 2. `IORef` — 「IO の世界での可変変数」

```haskell
import Data.IORef

example :: IO Int
example = do
  ref <- newIORef 0           -- IORef Int を作る、初期値 0
  writeIORef ref 42           -- 上書き
  readIORef ref               -- 読み取り → 42
```

| 関数 | 意味 |
|---|---|
| `newIORef x` | 初期値 `x` の IORef を作る |
| `readIORef r` | 中身を読む |
| `writeIORef r x` | `x` で書き換え |
| `modifyIORef r f` | `r := f r`、ただし **遅延評価** に注意 |
| `modifyIORef' r f` | **正格版**。カウンタは必ずこっち |

### `modifyIORef` の罠

```haskell
modifyIORef ref (+ 1)    -- ⚠️ サンクが溜まる
modifyIORef' ref (+ 1)   -- ✅ 正格、即時評価
```

ループでカウンタを進めるような用途で `modifyIORef` を使うと、内部に `1+0`, `1+(1+0)`, `1+(1+(1+0))` ... と **未評価の式の塔** ができる。`modifyIORef'` は毎回評価するので安全。13 章のテーマ。

### スレッド安全ではない

`IORef` は **単一スレッド前提**。複数スレッドから共有するなら次章の `MVar` / `TVar`。

---

## 3. 例外の 3 種類

Haskell の例外は他言語より多層的。3 つに分類しておく。

### 3-a. 純粋例外 — 「これはバグ」

`error`, `undefined`, `head []`, `1 `div` 0` のような、**プログラムが壊れている兆候**。

```haskell
head []          -- *** Exception: Prelude.head: empty list
```

- **基本捕まえない**。捕まえようとしている時点で設計に問題があることが多い
- もし出たらコードを直す（`Maybe` / `Either` を使う、Smart Constructor を使う）

### 3-b. 同期 IO 例外 — 「捕まえて回復する」

ファイル読み込み失敗、ネットワークエラー、JSON パース失敗、…。**外部要因で起きる、想定内のエラー**。

`try` / `catch` で扱う。

```haskell
import Control.Exception

safeRead :: FilePath -> IO (Either IOError String)
safeRead path = try (readFile path)
```

`try :: Exception e => IO a -> IO (Either e a)`。`Either` で結果を返してくれる。

```haskell
readWithDefault :: FilePath -> IO String
readWithDefault path = readFile path `catch` \(_ :: IOError) -> pure ""
```

`catch :: Exception e => IO a -> (e -> IO a) -> IO a`。**ハンドラの型注釈 `:: IOError` で「捕まえる例外の型」を固定** するのが定石。`SomeException` で「全部」捕まえると、本来潰してはいけないバグまで握りつぶしてしまう。

### 3-c. 非同期例外 — 「いつでも飛んでくる」

別スレッドからの `killThread`、`Ctrl-C` の `UserInterrupt`、メモリ不足など。**自分の処理の最中に外から強制的に投げ込まれる**。

直接捕まえようとせず、`bracket` で「**例外が出ても解放処理は走る**」を保証するのが正解。

---

## 4. `bracket` — 資源管理の鉄則

```haskell
bracket
  :: IO a            -- 1. 確保: ファイルを開く / DB 接続を作る / ロックを取る
  -> (a -> IO b)     -- 2. 解放: 必ず走る、例外が出ても、kill されても
  -> (a -> IO c)     -- 3. 本処理
  -> IO c
```

```haskell
import Control.Exception (bracket)
import System.IO

readFirstLine :: FilePath -> IO String
readFirstLine path =
  bracket
    (openFile path ReadMode)    -- 確保
    hClose                       -- 解放（必ず）
    hGetLine                     -- 本処理
```

これが「ファイル / ハンドル / DB 接続 / ロック / 一時ファイル」の **正しい扱い方**。`finally m action` は値を渡さない簡易版。

### 同期 vs 非同期、どっちにも効く

- 本処理が `IOError` を投げても、解放は走る（`catch` よりエレガント）
- 外から `killThread` されても、解放は走る
- これが `bracket` の存在意義

---

## 5. 「捕まえる例外の型を固定する」が大事

```haskell
-- 良い: 期待した例外だけ捕まえる
action `catch` \(e :: IOError) -> handleIO e

-- 悪い: あらゆる例外を握りつぶす
action `catch` \(_ :: SomeException) -> pure ()
```

後者は **バグも捕まえてしまう**（`undefined` を踏んでも何事もなかったかのように先に進む）。本当に「全例外」を捕まえる必要があるのは `main` の最外側だけ。

---

## つまずきやすいポイント

- **`putStrLn` は副作用ではなく「副作用の記述」を作るだけ**: モジュールの `IO` 値を `let _ = putStrLn "x"` にしても何も起きない。`do` ブロックや `>>` で繋いで `main` まで届けないと
- **遅延評価 + 例外の組み合わせ**: `let x = 1 \`div\` 0` だけでは例外は出ない。`x` を評価したときに出る。テストで `evaluate x` で強制評価するのは、これを補うため
- **`modifyIORef` を `modifyIORef'` で読み替える癖**: ほぼ常に正格版でよい
- **`SomeException` を最初から使う**: 上記。型を絞る習慣を付ける
- **`bracket` の引数順は「確保、解放、本処理」**: 直感的には「確保、本処理、解放」と並べたくなるが、Haskell の引数順は **解放が先** （部分適用の都合）

---

## 演習

[src/Lesson.hs](src/Lesson.hs) の `undefined` を実装して `cabal test x011-io-and-exceptions` を緑にする。

| 関数 | シグネチャ | 仕様 |
|---|---|---|
| `newCounter` | `IO (IO Int, IO ())` | `(現在値を返すアクション, 1 増やすアクション)` のペアを返す。内部で `IORef` を使う |
| `safeDiv` | `Int -> Int -> IO Int` | 0 除算なら `throwIO DivideByZero` を投げる。それ以外は普通に割り算 |
| `tryDiv` | `Int -> Int -> IO (Either ArithException Int)` | `safeDiv` を `try` で囲んで結果を `Either` で返す |
| `withResource` | `IORef [String] -> String -> IO a -> IO a` | `bracket` で「`"start <name>"` を log に書く」「本処理」「`"end <name>"` を log に書く」を実装。本処理が例外を投げても **end は記録される** こと |

ヒント:

- `newCounter` は `do { ref <- newIORef 0; pure (readIORef ref, modifyIORef' ref (+1)) }`
- `safeDiv` は `if y == 0 then throwIO DivideByZero else pure (x \`div\` y)`
- `withResource` は `bracket_ (modifyIORef ref ("start "++name :)) (modifyIORef ref ("end "++name :)) action` のような形（`bracket_` は値を渡さない簡易版）

---

## 参考

- [Control.Exception](https://hackage.haskell.org/package/base/docs/Control-Exception.html) — 標準 API ドキュメント
- [Asynchronous Exceptions in Haskell — Marlow](https://www.well-typed.com/blog/97/) — 非同期例外の本質
- [Exceptions tutorial — School of Haskell](https://www.schoolofhaskell.com/school/starting-with-haskell/libraries-and-frameworks/exceptions)
