# 006 — Applicative

## この章で何ができるようになるか

- 「`Maybe` 同士、`Either` 同士、リスト同士を **掛け合わせて** 一つの `Maybe` / `Either` / リストを得る」が書ける
- `pure` と `<*>` の意味を、Functor との対比で説明できる
- 「Applicative と Monad の違い」を一言で言える
- **複数のエラーを集める** Validation パターンを実装できる

## まず一行のメンタルモデル

> **Functor は「箱の中身を 1 つの関数で変換」、Applicative は「箱の中の関数を、箱の中の引数に適用」**

`fmap (+) (Just 3)` は `Just (3 +)` を返す ─ つまり「足し算の途中結果が箱に入った状態」になる。これに `Just 4` を **適用** したい。それを実現するのが `<*>`。

---

## 1. 型クラス定義 — Functor の上位互換

```haskell
class Functor f => Applicative f where
  pure  :: a -> f a
  (<*>) :: f (a -> b) -> f a -> f b
```

- `Functor f =>` … 「Applicative である型は必ず Functor でもある」（前章の上位）
- `pure` … 値を **「最小の文脈」で箱に入れる**。`Just`, `[x]`, `pure :: IO a` など
- `<*>` … **「箱に入った関数」を「箱に入った引数」に適用する**

### よく見るシグネチャの読み方

```haskell
(<*>) :: f (a -> b) -> f a -> f b
        ^^^^^^^^^^   ^^^   ^^^
        箱付き関数    箱付き引数  → 箱付き結果
```

---

## 2. 典型的な使い方

### 2 つの `Maybe` を「掛け合わせる」

```haskell
add :: Int -> Int -> Int
add x y = x + y

(+) <$> Just 3 <*> Just 4    -- Just 7
(+) <$> Just 3 <*> Nothing   -- Nothing
(+) <$> Nothing <*> Just 4   -- Nothing
```

順を追って読むと:

1. `(+) <$> Just 3` は `Just (3 +)` ─ つまり「3 を足す関数が入った Maybe」
2. それに `<*> Just 4` を適用 → `Just (3 + 4)` ＝ `Just 7`

途中で `Nothing` が混ざると、それ以降は短絡して `Nothing`。

### 3 引数以上 — `liftA2`, `liftA3`

```haskell
liftA2 :: Applicative f => (a -> b -> c) -> f a -> f b -> f c
liftA2 (+) (Just 3) (Just 4)    -- Just 7

-- liftA2 f x y は f <$> x <*> y と同じ
```

引数が多くなったら `<$>` / `<*>` を並べるか `liftA2` / `liftA3` を使う。

### `IO` での使い方 — 並列読み込み

```haskell
greeting :: IO String
greeting = (++) <$> getLine <*> getLine
-- 1 行目を読んで、2 行目を読んで、連結する
```

---

## 3. Applicative と Monad の違い — ここが肝

```haskell
(<*>) :: f (a -> b) -> f a -> f b      -- Applicative
(>>=) :: f a -> (a -> f b) -> f b      -- Monad
```

- **Applicative**: 左右の計算は **互いに無関係**。並列に評価できる
- **Monad**: 「左側の結果 `a` を見て、次の計算 `(a -> f b)` を選ぶ」 ─ つまり **依存** がある

### 何が嬉しいか

依存がないなら Applicative で済ませる、と覚える。理由:

1. **並列化できる**: 例えば `Concurrently` Applicative なら `(+) <$> ioA <*> ioB` を並行実行に最適化できる
2. **静的解析できる**: フォームバリデーションのように「全フィールドを一気に検査」する処理が書ける
3. **読みやすい**: 「依存がない」が型から明らか

「`Monad` は強力だけど、いつでも一番強力な道具を選ぶのが正しいわけじゃない」という考え方が Haskell の特徴。

---

## 4. Validation — Applicative の真骨頂

`Either e` も Applicative だが、**最初のエラーで短絡** する。

```haskell
(+) <$> Left "name empty" <*> Left "age out of range"
-- Left "name empty"   ← 1 個目のエラーしか見えない
```

実際のフォームバリデーションでは「名前も年齢も両方ダメ」をユーザーに見せたい。これには **Either ではない** 専用の型が必要。

```haskell
data Validation e a = Failure e | Success a

instance Semigroup e => Applicative (Validation e) where
  pure = Success
  Failure e1 <*> Failure e2 = Failure (e1 <> e2)   -- ★ ここでエラーを「結合」
  Failure e  <*> Success _  = Failure e
  Success _  <*> Failure e  = Failure e
  Success f  <*> Success a  = Success (f a)
```

ポイント:

- `Failure <*> Failure` のとき、両方のエラーを `<>`（連結演算）で **結合** する
- `e` には `[String]` を入れることが多い（リストは `<>` で連結できる）

### 使い方

```haskell
mkPerson :: String -> Int -> Validation [String] Person
mkPerson name age =
  Person <$> validateName name <*> validateAge age

mkPerson ""    999    -- Failure ["name is empty", "age out of range"]
                       -- ★ 両方のエラーが見える
```

> **「`Validation` は Monad にしないの?」**: しません。Monad 則を満たそうとすると **エラーを蓄積する性質と矛盾** するため。これは「Applicative にしかない強さ」の好例で、`Validation` を学ぶと「Monad より弱い抽象が役に立つ場面がある」が腑に落ちる。

---

## 5. Applicative 則（参考）

```
pure id <*> v             = v                      -- 恒等
pure (.) <*> u <*> v <*> w = u <*> (v <*> w)        -- 合成
pure f <*> pure x         = pure (f x)             -- 準同型
u <*> pure y              = pure ($ y) <*> u       -- 交換
```

最初は丸暗記不要。実装を書くときに `pure x <*> y` のような自然な組み合わせが期待通り動くことが、これらの帰結。

---

## つまずきやすいポイント

- **`pure` の型が決まらない**: `pure 5` だけでは何の Applicative か決まらないので「Ambiguous type」のエラーが出る。`pure 5 :: Maybe Int` のように **使う側で型を固定** する
- **`Validation` を `do` で書きたくなる**: できない（Monad ではないため）。`<$>` と `<*>` で書く
- **「`<*>` の左に来るのは `f (a -> b)`」が理解しづらい**: 上で書いた「`(+) <$> Just 3` がまず `Just (3 +)` という関数入り Maybe になる」流れを声に出して読み直すと納得する
- **`liftA2` の存在を忘れる**: 引数 2 つなら `liftA2 f x y` のほうが `f <$> x <*> y` より読みやすいことが多い

---

## 演習

[src/Lesson.hs](src/Lesson.hs) の `undefined` を実装して `cabal test x006-applicative` を緑にする。

| 項目 | 仕様 |
|---|---|
| `data Validation e a = Failure e \| Success a` | （定義済み） |
| `instance Functor (Validation e)` | `Success` の中身に適用、`Failure` はそのまま |
| `instance Semigroup e => Applicative (Validation e)` | `pure` と `<*>` を実装。`Failure <*> Failure` は `<>` でエラー結合 |
| `validateName :: String -> Validation [String] String` | 空なら `Failure ["name is empty"]`、それ以外は `Success` |
| `validateAge :: Int -> Validation [String] Int` | 0..150 外なら `Failure ["age out of range"]` |
| `mkPerson :: String -> Int -> Validation [String] Person` | `Person <$> validateName name <*> validateAge age` の形 |

---

## 参考

- [Typeclassopedia — Applicative](https://wiki.haskell.org/Typeclassopedia#Applicative)
- [`validation` package](https://hackage.haskell.org/package/validation) — 実プロダクトでの実装
- [Functors, Applicatives, And Monads In Pictures](https://www.adit.io/posts/2013-04-17-functors,_applicatives,_and_monads_in_pictures.html)
