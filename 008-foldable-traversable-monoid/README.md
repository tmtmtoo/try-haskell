# 008 — Foldable / Traversable / Monoid

## この章で何ができるようになるか

- 「**結合できる + 単位元がある**」型としての `Monoid` を識別できる
- 「`length` も `sum` も `toList` も、実は **同じパターン** の特殊例」と分かる
- `Foldable` で `foldr` / `foldMap` を使い分けられる
- `Traversable` の `traverse` で「**失敗するかもしれない map**」が書ける
- 自前の木構造に Foldable / Traversable インスタンスを書ける

## まず一行のメンタルモデル

- **Monoid**: 「`<>` で 2 つを結合できて、何もない `mempty` がある」型。文字列、リスト、加算、和集合、…
- **Foldable**: 「**畳める**」コンテナ。リストでなくても `sum` / `length` / `toList` が同じ書き方で動く
- **Traversable**: 「**効果付きの map**」を、リストにも木にも他の構造にも適用できるインターフェース

これら 3 つは **連動して理解する** のが一番速い。`Traversable t => Foldable t => Functor t` という階層関係になっている。

---

## 1. Semigroup と Monoid — 「結合できる型」

```haskell
class Semigroup a where
  (<>) :: a -> a -> a    -- 結合則: (x <> y) <> z = x <> (y <> z)

class Semigroup a => Monoid a where
  mempty :: a            -- 単位元: mempty <> x = x = x <> mempty
```

「結合できる」+「単位元がある」だけ。すごく単純な抽象だが、応用が広い。

### よくあるインスタンス

| 型 | `<>` の意味 | `mempty` |
|---|---|---|
| `[a]` | 連結 (`++`) | `[]` |
| `String` | 連結 | `""` |
| `Sum Int` | 加算 | `Sum 0` |
| `Product Int` | 乗算 | `Product 1` |
| `Min Int` | 小さい方 | `Min maxBound` |
| `Max Int` | 大きい方 | `Min minBound` |
| `Maybe a` (a が Semigroup) | 中身を結合、`Nothing` は単位元 | `Nothing` |
| `Endo a = a -> a` | 関数合成 (`.`) | `id` |
| `Map k v` | キーごとに結合（重複は左優先 or 値の `<>`） | `mempty = Map.empty` |

> **`Sum` / `Product` の wrapper はなぜ?**: `Int` には `<>` が **2 通り** ある（足し算と掛け算）。型で区別するために wrapper を用意して `<>` の意味を一意に決めている。

### 何が嬉しいか

「複数のものを 1 つに合体する」操作が、型を見るだけで意味が分かる:

```haskell
mconcat :: Monoid a => [a] -> a
mconcat [Sum 1, Sum 2, Sum 3]    -- Sum 6
mconcat ["hello, ", "world"]     -- "hello, world"
```

ライブラリ作者は「ログを集める」「設定をマージする」「集計する」関数を **`Monoid` 制約だけで書ける**。利用者はインスタンスを定義するだけで使える。

---

## 2. Foldable — 「畳める何か」

```haskell
class Foldable t where
  foldr   :: (a -> b -> b) -> b -> t a -> b
  foldMap :: Monoid m => (a -> m) -> t a -> m
  -- 他にもデフォルト実装で foldl', sum, length, toList などが derive される
```

リストで馴染みの `foldr` だが、これは **任意のコンテナ** に対して同じ形で書ける。

### `foldMap` がエレガント — 各要素を Monoid に変換して結合

```haskell
sum'    :: (Foldable t, Num a) => t a -> a
sum'    = getSum . foldMap Sum
-- 各要素を Sum に包んで <> で繋ぐ → Sum (1+2+3) → 取り出して 6

length' :: Foldable t => t a -> Int
length' = getSum . foldMap (const (Sum 1))
-- 各要素を Sum 1 に変換して足す = 要素数

toList' :: Foldable t => t a -> [a]
toList' = foldMap (: [])
-- 各要素を [a] に包む → [1] <> [2] <> [3] = [1,2,3]
```

`foldr` か `foldMap` の **片方だけ実装すれば**、残りの操作（`sum`, `length`, `toList`, `elem`, ...）は全部デフォルト実装で動く。

### 落とし穴: `foldl` の罠

```haskell
foldl  (+) 0 [1..10000000]   -- ⚠️ メモリを食う / 遅い（サンクが累積）
foldl' (+) 0 [1..10000000]   -- ✅ 正格版、速い
foldr  (+) 0 [1..1000]       -- 短いリストならこれでOK
```

**累積的な数値計算は `foldl'`**（正格版）一択。詳細は 13 章。

---

## 3. Traversable — 「効果付きの map」

`fmap` は「中身を `(a -> b)` で変換」、`traverse` は「中身を **`(a -> f b)`** で変換」。

```haskell
class (Functor t, Foldable t) => Traversable t where
  traverse  :: Applicative f => (a -> f b) -> t a -> f (t b)
  sequenceA :: Applicative f => t (f a) -> f (t a)
```

### 典型例: 「全部成功」を集める

```haskell
parseInts :: [String] -> Maybe [Int]
parseInts = traverse readMaybe
```

```haskell
parseInts ["1", "2", "3"]    -- Just [1, 2, 3]
parseInts ["1", "x", "3"]    -- Nothing  ← 一個でも失敗で全体失敗
```

リストの形を保ったまま、`Maybe` の効果を **外側に集める**。

### 図で見る

```
[String]                     →  traverse readMaybe
  ["1", "2", "3"]             →  [Just 1, Just 2, Just 3]   ← 普通の fmap だとこれ
                              →  Just [1, 2, 3]              ← traverse はここまで進める
```

`fmap` は `[Maybe Int]`（中に Maybe）で止まる。`traverse` は **外側に Maybe を持ち上げて** `Maybe [Int]`（外に Maybe）にする。これが **`fmap` と `traverse` の違い**。

### Validation と組み合わせる — エラー蓄積版

`Validation` を Applicative にしたものに対して `traverse` すると、**全件のエラーを集めながら、構造を保つ** ことができる。

```haskell
parseAll :: [String] -> Validation [String] [Int]
parseAll = traverse validateInt
```

`Maybe` を使うと「どこで失敗したか分からないまま全体 `Nothing`」だが、`Validation` を使うと「3 番目と 5 番目がエラー」のように位置と理由が両方わかる。

### `sequence` / `sequenceA`

「中身が `f a` のコンテナ」を「`f (コンテナ a)` 」にひっくり返す。

```haskell
sequence [Just 1, Just 2, Just 3]    -- Just [1, 2, 3]
sequence [Just 1, Nothing, Just 3]   -- Nothing
```

実は `sequence = traverse id` で書ける。

---

## 4. 自前の Tree に Foldable / Traversable を書く

```haskell
data Tree a = Leaf | Node (Tree a) a (Tree a)

instance Functor Tree where
  fmap _ Leaf         = Leaf
  fmap f (Node l x r) = Node (fmap f l) (f x) (fmap f r)

instance Foldable Tree where
  foldr _ z Leaf         = z
  foldr f z (Node l x r) = foldr f (f x (foldr f z r)) l
  -- 中順 (左→根→右) で畳む

instance Traversable Tree where
  traverse _ Leaf         = pure Leaf
  traverse f (Node l x r) = Node <$> traverse f l <*> f x <*> traverse f r
```

`Traversable` は **`Functor` + `Foldable`** が前提なので 3 つセットで書く。`traverse` の実装が一番きれい: ノードのコンストラクタを Applicative で「箱の中で」組み立てる。

---

## つまずきやすいポイント

- **`foldr` の引数順がややこしい**: `foldr (\x acc -> ...) initial list`。`x` が現在の要素、`acc` が「ここまでの結果」
- **`Monoid` を選び間違える**: `Int` をそのまま `<>` で繋ぎたくなるが、`Sum` か `Product` で包む必要がある（型で意味を区別するため）
- **`traverse` と `fmap` の使い分けが分からない**: 関数が `(a -> b)` なら `fmap`、`(a -> f b)` なら `traverse`。**型を見て選ぶ**
- **「で、これを使うと何ができるの?」が見えづらい**: 9〜10 章で `Maybe` / `State` / `Either` と組み合わさるとぐっと実用に近づく。今は「ライブラリを作る側の道具」と思っておいてよい

---

## 演習

[src/Lesson.hs](src/Lesson.hs) の `undefined` を実装して `cabal test x008-foldable-traversable-monoid` を緑にする。

| 項目 | 仕様 |
|---|---|
| `newtype Min' a` | （定義済み）。「小さい方を取る」Semigroup を作るためのラッパー |
| `instance Ord a => Semigroup (Min' a)` | `Min' x <> Min' y = Min' (min x y)` |
| `instance Functor Tree` | （5 章のものを移植してよい） |
| `instance Foldable Tree` | `foldr` を中順で実装 |
| `instance Traversable Tree` | `traverse` を `<$>` / `<*>` で実装 |
| `parseInts :: [String] -> Maybe [Int]` | `traverse readMaybe` の **一行関数** |
| `treeSum :: Num a => Tree a -> a` | `Foldable` 由来の `sum` を使う |

---

## 参考

- [Typeclassopedia — Monoid / Foldable / Traversable](https://wiki.haskell.org/Typeclassopedia)
- [The Essence of the Iterator Pattern (McBride & Paterson)](https://www.cs.ox.ac.uk/jeremy.gibbons/publications/iterator.pdf) — Traversable の元論文（やや難）
- [Stop sub-classing Foldable](https://www.parsonsmatt.org/2020/01/03/plucking_constraints.html) — `Foldable` 抽象の実用的な視点
