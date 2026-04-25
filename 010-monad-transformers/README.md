# 010 — モナドトランスフォーマー

## この章で何ができるようになるか

- 「`State` と `Either` の **両方** が欲しい」のような **複数効果の合成** ができる
- `MaybeT` / `ExceptT` / `StateT` / `ReaderT` の役割と実行関数を覚える
- `lift` / `liftIO` の意味が分かる
- mtl 流の「**スタックの位置に依存しない関数**」を書ける

## まず一行のメンタルモデル

> **「素のモナドだけだと組み合わせられない。`StateT` のような末尾 `T` 付きトランスフォーマーは、もう一つ下にモナドを抱えるバージョン」**

`State` だけでは状態を扱える。`Either` だけではエラーを扱える。**両方欲しいときに重ねるのがトランスフォーマー**。

---

## 1. なぜ素のモナドでは足りないか

「カウンタを進めながら、エラー時には `Left` で短絡する」処理を書きたいとする。

- `State Int` だけだと: エラーを表現する手段がない
- `Either String` だけだと: 状態を持ち回せない

両方を **重ねる** には:

```haskell
ExceptT String (State Int) a
```

外側 `ExceptT String`（エラーを足す）、内側 `State Int`（カウンタ）。**外側のラッパーが内側の効果を抱えている**。

---

## 2. 命名規則と対応関係

末尾に `T` が付いている = 「下に別のモナドを持つバージョン」。

| 素のモナド | トランスフォーマー | 中身を取り出す関数 |
|---|---|---|
| `Maybe` | `MaybeT m a`   | `runMaybeT` |
| `Either e` | `ExceptT e m a` | `runExceptT` |
| `State s` | `StateT s m a`  | `runStateT` |
| `Reader r` | `ReaderT r m a` | `runReaderT` |
| `Writer w` | `WriterT w m a` | `runWriterT` |

`m` は「下に置くモナド」のための型変数。`m = Identity` を指定すると素のモナドに退化する:

```haskell
type Reader r = ReaderT r Identity
type State s  = StateT  s Identity
```

つまり前章の素モナドは「**`Identity` を下に敷いたトランスフォーマー**」と見ることもできる。

---

## 3. スタックの読み方

実務でよく見る型:

```haskell
type App = ReaderT Config (ExceptT AppError IO)
```

**外側から内側に** 読む:

1. `Config` を読み（`Reader`）
2. `AppError` で失敗するかも（`Except`）
3. 最後に `IO` （外部入出力）

実行は **外側から順に剥がす** イメージ:

```haskell
runApp :: App a -> Config -> IO (Either AppError a)
runApp action cfg = runExceptT (runReaderT action cfg)
--                              ^^^^^^^^^^^^^^^^^^^^
--                              まず Reader を剥がす
--                  ^^^^^^^^^^^                       
--                  次に Except を剥がす → IO (Either AppError a) になる
```

外側が先に外れて、最終的に `IO (...)` が残る。

---

## 4. `lift` — 一段下のモナドの操作を持ち上げる

トランスフォーマーの中から **下のモナド** の操作を呼ぶには `lift` が必要。

```haskell
import Control.Monad.State (State, get)
import Control.Monad.Except (ExceptT)
import Control.Monad.Trans (lift)

inner :: State Int Int
inner = get

outer :: ExceptT String (State Int) Int
outer = lift inner    -- State の操作を ExceptT の中で使う
```

「1 段下がるだけ」が `lift`。2 段下がりたいときは `lift . lift` のようになる ─ これは流石に手間で、後述の **mtl 流** で解決する。

### `liftIO` — IO だけ特別扱い

`liftIO :: MonadIO m => IO a -> m a` は `IO` を **何段でも一気に持ち上げる**。

```haskell
foo :: ReaderT Config (ExceptT Err IO) ()
foo = do
  liftIO (putStrLn "log")    -- IO putStrLn をスタックの一番下から表面に
```

実務では一番よく使う lift 系関数。

---

## 5. mtl 流 — 「位置に依存しない」書き方

スタックの何段目に `State` があるかを覚えるのは大変。mtl パッケージは **能力（型クラス）** だけを要求する書き方を提供する。

```haskell
import Control.Monad.State (MonadState, get, put)
import Control.Monad.Except (MonadError, throwError)

decrement :: (MonadState Int m, MonadError String m) => m ()
decrement = do
  n <- get
  if n <= 0
    then throwError "below zero"
    else put (n - 1)
```

- `MonadState Int m` … 「`m` には Int 状態を読み書きする能力がある」
- `MonadError String m` … 「`m` には String でエラーを投げる能力がある」

具体的なスタック (`ExceptT String (State Int)` か、`StateT Int (Except String)` か、もっと複雑な何か) を **書かない**。実装側が `lift` を **コンパイラに自動推論させる**。

### 何が嬉しいか

- **テストでスタックを差し替えられる**: 本番は `IO` 込み、テストは純粋でいい
- **将来効果を増やすときに書き換えがいらない**: シグネチャに制約を増やすだけ
- **スタックの深さを意識しなくていい**

> **`mtl` 流の落とし穴**: 「2 つの `State Int` が混じる」ような同じ型クラスの **多重インスタンス** は型推論が困る。本格的に複雑になると `effectful` / `polysemy` / `fused-effects` のような後継ライブラリの出番（14 章で軽く触れる）。

---

## 6. `MonadIO` — 「どこからでも IO したい」

```haskell
class Monad m => MonadIO m where
  liftIO :: IO a -> m a
```

`IO` を含むスタックなら、ほぼすべて `MonadIO` インスタンスを持っている。`liftIO` 一発で IO アクションを表面に持ち上げられる。

```haskell
greet :: (MonadIO m, MonadReader Config m) => m ()
greet = do
  cfg <- ask
  liftIO (putStrLn ("hello " ++ hostname cfg))
```

---

## つまずきやすいポイント

- **「`get` だけ書いたらエラーになる」**: トランスフォーマースタックの中だと、どの State の `get` か曖昧。型注釈を `(get :: m Int)` のようにつけるか、mtl 制約 `MonadState Int m` を入れる
- **`lift` を忘れる**: 「`State` の操作を `ExceptT` の中で使う」ときに `lift` が要る。mtl 流ならコンパイラが推論してくれる
- **`runExceptT` と `runStateT` の **順番** を間違える**: スタックの **外側から剥がす**。`ExceptT String (State Int) a` なら `runState (runExceptT m) initialState`
- **「Identity を下に敷いたトランスフォーマー」と素のモナドが違う型に見える**: 内部的にはほぼ同じだが、**`runReader` と `runReaderT m Identity` を結ぶ** には `runIdentity` が必要なときがある

---

## 演習

[src/Lesson.hs](src/Lesson.hs) の `undefined` を実装して `cabal test x010-monad-transformers` を緑にする。

| 項目 | 仕様 |
|---|---|
| `type Inventory = [(String, Int)]` | （定義済み）`(商品名, 在庫数)` のリスト |
| `decreaseStock :: String -> ExceptT String (State Inventory) Int` | 商品が無ければ `throwError "not found"`、在庫 0 なら `throwError "out of stock"`、それ以外は 1 減らして残量を返す |
| `runStock :: ExceptT String (State Inventory) a -> Inventory -> (Either String a, Inventory)` | スタックを実行して `(Either, 状態)` を返す |
| `data AppConfig` | `prefix :: String`, `suffix :: String` |
| `decorate :: String -> ReaderT AppConfig (Either String) String` | 入力が空なら `Left "empty"`、それ以外は `prefix ++ s ++ suffix` |
| `runDecorate :: String -> AppConfig -> Either String String` | `decorate` の実行ヘルパ |

ヒント:

- `decreaseStock` は `lift get` で在庫リストを取り、`lookup` でエントリを探す。状態を `lift . put` で書き戻す
- `runStock action st = runState (runExceptT action) st`
- `decorate` は `do { cfg <- ask; ... }` で `Reader` から設定を取り、`lift (Left "empty")` でエラー側に降りる

---

## 参考

- [transformers package](https://hackage.haskell.org/package/transformers) — トランスフォーマーの実装
- [mtl package](https://hackage.haskell.org/package/mtl) — 型クラス版
- [The mtl tutorial — Real World Haskell ch.18](http://book.realworldhaskell.org/read/monad-transformers.html)
- [Three layers cake — ReaderT pattern](https://www.fpcomplete.com/blog/2017/06/readert-design-pattern/) — 実務での書き方
