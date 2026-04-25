# 005 — Functor

## この章で何ができるようになるか

- 「`Maybe` の中身を変換」「リストの全要素を変換」「IO の結果を変換」を **同じ書き方で** できる、を体感する
- `fmap` と `<$>` の使い分けが分かる
- 「Functor 則」が **何を保証してくれるか** を説明できる
- 自分で作った型に Functor インスタンスを書ける

## まず一行のメンタルモデル

> **「箱の中の値だけを変換したい。箱は壊さずに」**

これがすべて。`Maybe Int` の中の `Int` を `Int -> String` で変換すれば `Maybe String` になる。リスト `[Int]` も同じ。`IO Int` も同じ。**箱の種類によらず同じインターフェース** を提供するのが Functor 型クラス。

---

## 1. 型クラス定義 — 1 つの関数だけ

```haskell
class Functor f where
  fmap :: (a -> b) -> f a -> f b
```

- `f` は **「箱の種類」** を表す型変数（`Maybe` とか `[]` とか `IO` とか）
- `fmap` の引数: 「中身を変換する関数」と「箱に入った値」
- 戻り値: 「変換後の中身を入れた箱」

### `<$>` は `fmap` の別名

```haskell
(<$>) :: Functor f => (a -> b) -> f a -> f b
(<$>) = fmap
```

つまり完全に同義。**インライン記法として `<$>` のほうが読みやすい** ので実務ではほぼこっち。

```haskell
fmap (+ 1) (Just 3)        -- Just 4
(+ 1) <$> Just 3           -- Just 4   ← 同じ意味
```

---

## 2. よくある Functor インスタンス

### `Maybe` — 「あるかも、ないかも」

```haskell
fmap (+ 1) (Just 3)     -- Just 4
fmap (+ 1) Nothing      -- Nothing      （箱が空なので何もしない）
```

`Nothing` のときは関数を呼ばない。**失敗を伝播させながら、成功時だけ変換** が一行で書ける。

### `[]` — 「リスト」

```haskell
fmap (* 2) [1, 2, 3]    -- [2, 4, 6]   ＝ map (* 2) [1, 2, 3]
```

リストの Functor インスタンスは `map` そのもの。

### `Either e` — 「成功か、エラーか」

```haskell
fmap (+ 1) (Right 5 :: Either String Int)    -- Right 6
fmap (+ 1) (Left "boom" :: Either String Int) -- Left "boom"
```

`Right` の中身だけが変換され、`Left`（エラー側）はそのまま。

> **「なぜ成功が右?」**: `Functor`/`Applicative`/`Monad` は型の **最後のパラメータ** に作用する。`Either e a` は `a` が最後なので `a` 側に作用する。「成功値を最後に置く」と決めると、これらの抽象が「成功時だけ進む／失敗で短絡」という直感的な意味で動く。だから慣習として `Right = 成功、Left = 失敗`。

### `IO` — 「実行すれば値が出てくるアクション」

```haskell
greet :: IO String
greet = ("Hello, " ++) <$> getLine
```

`getLine :: IO String` の結果に `("Hello, " ++)` を適用する **アクションの記述** を作る。**まだ実行されていない**。`main` から到達したときに初めて動く。

### `(->) r` — 「関数も Functor」

```haskell
fmap :: (a -> b) -> (r -> a) -> (r -> b)
```

これ、**関数合成 `.`** そのもの。実際 `fmap = (.)`。

---

## 3. Functor 則 — これが守られていないとバグる

すべての Functor インスタンスは以下の 2 つを満たす **べき**:

```
1. fmap id      = id                    -- 何もしない関数を渡したら何も起きない
2. fmap (g . h) = fmap g . fmap h       -- 関数を合成してから fmap = それぞれ fmap してから合成
```

則 1 は「箱の構造を勝手にいじらない」、則 2 は「2 回処理しても 1 回処理しても結果が同じ」を保証している。

> **コンパイラはこれをチェックしない**。守らないインスタンスを書いても通ってしまう。だから `deriving Functor`（`-XDeriveFunctor` 拡張）でコンパイラに任せたほうが安全。本演習では学習目的で手書きする。

---

## 4. `Functor` のもう一つの便利関数 `<$`

```haskell
(<$) :: Functor f => a -> f b -> f a
```

「箱はそのまま、中身を全部 `a` で置き換える」。

```haskell
'!' <$ Just 'x'         -- Just '!'
0 <$ [1, 2, 3 :: Int]   -- [0, 0, 0]
```

`fmap (const x)` と同じ。**ループ回数だけ知りたい / 値は捨てたい** ときに使う。

---

## 5. 自前の型に Functor を書く

二分木に Functor インスタンスを書く例:

```haskell
data Tree a = Leaf | Node (Tree a) a (Tree a)

instance Functor Tree where
  fmap _ Leaf         = Leaf
  fmap f (Node l x r) = Node (fmap f l) (f x) (fmap f r)
```

「葉はそのまま、ノードは左右の部分木を再帰的に `fmap`、値には `f` を適用」と自然に再帰で書ける。

---

## つまずきやすいポイント

- **「`fmap` で `Maybe` の中身を別の `Maybe` に置き換えたい」 → これは Functor では無理**: `(a -> b)` は普通の関数で、`Maybe` を返さない。「箱を作る関数で変換したい」なら **次章の Applicative や 7 章の Monad** が必要
- **`<$>` の優先順位**: `f <$> x <*> y` のように使うときに、思っているところで切れる。`(+) <$> Just 3 <*> Just 4` は `((+) <$> Just 3) <*> Just 4`
- **「`fmap id` が `id` にならないインスタンス」**: もしそんな実装を書いてしまったら `Tree` などで再帰しないとか、コンストラクタを変えてしまっている。テストで気付ける
- **`Functor` ≠ 「箱」**: 厳密には「`a` を `b` に写す関数を、`f a` を `f b` に写す関数に持ち上げる」操作を持つ何か、なので必ずしも値を「保持」している必要はない（`(->) r` のような関数 Functor もある）。でも初めはイメージとして「箱」で十分

---

## 演習

[src/Lesson.hs](src/Lesson.hs) の `undefined` を実装して `cabal test x005-functor` を緑にする。

| 項目 | 仕様 |
|---|---|
| `instance Functor Tree` | `fmap` を再帰で実装。`-XDeriveFunctor` は使わずに手書きする |
| `instance Functor Pair` | `Pair (a, a)` の両要素に同じ関数を適用 |
| `incrAll :: Functor f => f Int -> f Int` | `fmap (+ 1)` を使う **一行関数**。`f` は `Maybe` でもリストでも何でも OK |
| `replaceAll :: Functor f => b -> f a -> f b` | 中身を全部 `b` で置き換える（ヒント: `<$`） |

ヒント: `Pair` は `data Pair a = Pair (a, a)`。両要素を変換するには `Pair (f a, f b)` のようにパターンマッチで分解する。

---

## 参考

- [Typeclassopedia — Functor](https://wiki.haskell.org/Typeclassopedia#Functor)
- [Hackage: Data.Functor](https://hackage.haskell.org/package/base/docs/Data-Functor.html)
- [Functors, Applicatives, And Monads In Pictures](https://www.adit.io/posts/2013-04-17-functors,_applicatives,_and_monads_in_pictures.html) — 図でわかる定番記事
