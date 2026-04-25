# 007 — Monad

## この章で何ができるようになるか

- `>>=` と `do` 記法の関係（**`do` は `>>=` の糖衣構文**）が分かる
- 「Monad は怖いものじゃなくて、Applicative の上位互換で **依存のある計算** を扱えるもの」と説明できる
- `Maybe` モナドで「失敗で短絡する計算」を `do` で書ける
- `Either` モナドで「エラー値付きの短絡」が書ける
- 自分で簡単なモナドインスタンスを書ける

## まず一行のメンタルモデル

> **`>>=` は「箱を開けて、中身を使って次の箱付き計算を選ぶ」**

`Applicative` は「箱付き関数を箱付き引数に **適用**」だった。`Monad` の `>>=` は **「箱を開けたあとの計算」を、開けた値に応じて変えられる**。これが「依存」の正体。

---

## 1. 型クラス定義 — Applicative の上位互換

```haskell
class Applicative m => Monad m where
  (>>=)  :: m a -> (a -> m b) -> m b
  return :: a -> m a            -- pure と同じ（歴史的経緯で残っている別名）
```

- `m a` … 箱に入った値
- `(a -> m b)` … **「中身 `a` を見てから、次の箱付き計算を返す関数」**
- 結果 `m b` を返す

```
     m a   >>=   (a -> m b)   =    m b
     ↓                              ↑
   箱を開く        次の箱を作る
```

### Applicative との比較

```haskell
(<*>) :: f (a -> b) -> f a -> f b   -- 関数も引数も「最初から箱に入っている」
(>>=) :: m a -> (a -> m b) -> m b   -- 開けた値で「次の箱を選ぶ」関数を渡す
```

`<*>` は左右が独立、`>>=` は左の結果が右の関数の入力になる。

---

## 2. `do` 記法 — `>>=` の砂糖

`>>=` を直接書くとネストが増える。

```haskell
example :: Maybe Int
example = safeDiv 100 4 >>= \a ->
          safeDiv a 5   >>= \b ->
          safeDiv b 2   >>= \c ->
          pure c
```

`do` 記法はこれを **手続き型っぽい見た目** にしてくれるだけ:

```haskell
example :: Maybe Int
example = do
  a <- safeDiv 100 4
  b <- safeDiv a 5
  c <- safeDiv b 2
  pure c
```

- `<-` … 「箱を開けて中身を `a` に束縛」（`>>= \a ->` の砂糖）
- 最終行は普通に値を返す式（`pure` 必須）
- どこかで `Nothing` が返れば、それ以降の `<-` はスキップされて全体が `Nothing`

> **大事**: `do` は **IO のためのものではない**。`Maybe`, `Either`, `[]`, `State` ─ どんな Monad でも使える共通記法。

---

## 3. `Maybe` モナド — 失敗で短絡

```haskell
safeDiv :: Int -> Int -> Maybe Int
safeDiv _ 0 = Nothing
safeDiv x y = Just (x `div` y)

chain :: Maybe Int
chain = do
  a <- safeDiv 100 4    -- Just 25
  b <- safeDiv a 5      -- Just 5
  c <- safeDiv b 0      -- Nothing! ここで全体が Nothing になる
  pure c                -- 到達しない
```

「途中で失敗したら以降は全部スキップ」を、明示的な `if` を書かずに表現できる。これは null チェックの嵐を消せるのと近い。

---

## 4. `Either e` モナド — エラー値付き短絡

```haskell
safeDivE :: Int -> Int -> Either String Int
safeDivE _ 0 = Left "div by zero"
safeDivE x y = Right (x `div` y)

chain :: Either String Int
chain = do
  a <- safeDivE 100 4
  b <- safeDivE a 0     -- Left "div by zero"
  c <- safeDivE b 2     -- スキップ
  pure c
-- 結果: Left "div by zero"
```

`Maybe` と同じ流れだが、**失敗の理由が文字列で残る**。実用ではこっちのほうが多い。

> **再掲**: 「**複数のエラーを集めたい**」場合は Monad だと無理。**前章の `Validation` Applicative** を使う。Monad は逐次的（前のエラーで止まる）、Applicative は並列的（全部集める）。

---

## 5. Monad 則 — 守られていないとバグる

```
1. return a >>= k         = k a                       -- 左単位元
2. m >>= return           = m                         -- 右単位元
3. (m >>= k) >>= h        = m >>= (\x -> k x >>= h)    -- 結合則
```

則 1: 「pure で包んでから開ける」は「直接 k に渡す」と同じ。
則 2: 「最後に `pure` で包んで終わり」は「何もしない」と同じ。
則 3: `do` ブロックの **書く順番** に意味があって、グループ分けは結果を変えない。

これらが成り立つから `do` 記法が「期待通り」に動く。Functor 則 / Applicative 則と同じく、コンパイラはチェックしない。

---

## 6. Monad はそんなに特別じゃない — 「使い分け」が大事

| 必要なこと | 使うもの |
|---|---|
| ただの値変換 | `fmap` (Functor) |
| 並列な合成（依存なし） | `<*>` (Applicative) |
| 直前の結果を見て次を選ぶ | `>>=` (Monad) |

「全部 Monad で書ける」は事実だが、**読み手に「依存があるかも」と疑わせる** ので、依存がないところで Monad を使わないのが Haskell 流儀。3 章で「最弱の抽象を選ぶ」のはこういう理由。

---

## 7. 自前モナド — `Identity'` を書く

学習用に「何もしないモナド」を書く:

```haskell
newtype Identity' a = Identity' { runIdentity' :: a }

instance Functor Identity' where
  fmap f (Identity' a) = Identity' (f a)

instance Applicative Identity' where
  pure = Identity'
  Identity' f <*> Identity' a = Identity' (f a)

instance Monad Identity' where
  Identity' a >>= f = f a
```

「箱が値そのもの」のモナド。`>>=` は中身を取り出して次の関数に渡すだけ。一番単純で、Monad の **構造** を理解する練習になる。

---

## つまずきやすいポイント

- **`>>=` の右辺が関数を期待していることを忘れる**: 値を渡してしまうとエラーになる。`do` で書けば `<-` のおかげで意識しなくてよい
- **`do` の最後に `pure` を書き忘れる**: `do` ブロックは最後の式の型に揃える必要がある。`pure x` か、もう既に `m a` 型の式で締める
- **`a <- pureValue` と書こうとする**: `<-` の右は **`m _` 型の式** であること。`a <- 3` は `Int` を Maybe から開けようとしてエラー
- **「Monad 完全に理解した」と「Monad なんもわからん」を 100 回往復する**: Haskeller の通過儀礼。3 周くらいすると慣れる

---

## 演習

[src/Lesson.hs](src/Lesson.hs) の `undefined` を実装して `cabal test x007-monad` を緑にする。

| 項目 | 仕様 |
|---|---|
| `newtype Identity' a = Identity' { runIdentity' :: a }` | （定義済み） |
| `instance Functor Identity'` | 自前で書く |
| `instance Applicative Identity'` | 自前で書く |
| `instance Monad Identity'` | `>>=` を自前で書く |
| `safeDiv :: Int -> Int -> Maybe Int` | 0 除算なら `Nothing` |
| `chainDiv :: Int -> [Int] -> Maybe Int` | 初期値 `Int` をリストの各要素で順に `safeDiv`。途中で 0 があれば `Nothing` |
| `data Expr = ELit Int \| EAdd Expr Expr \| EDiv Expr Expr` | （定義済み） |
| `evalExpr :: Expr -> Either String Int` | `do` 記法で再帰的に評価。0 除算は `Left "division by zero"` |

ヒント: `chainDiv` は `foldM safeDiv` でも書けるし、明示再帰でも書ける。`evalExpr` は `EDiv` のところで `if y == 0 then Left ... else Right ...` で分岐するか、`safeDivE` ヘルパを定義するとスッキリする。

---

## 参考

- [Typeclassopedia — Monad](https://wiki.haskell.org/Typeclassopedia#Monad)
- [You Could Have Invented Monads (And Maybe You Already Have)](https://blog.sigfpe.com/2006/08/you-could-have-invented-monads-and.html) — 「自分で発明できた」目線の名解説
- [Functors, Applicatives, And Monads In Pictures](https://www.adit.io/posts/2013-04-17-functors,_applicatives,_and_monads_in_pictures.html)
