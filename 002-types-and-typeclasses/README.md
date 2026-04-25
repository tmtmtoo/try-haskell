# 002 — 型と型クラス

## この章で何ができるようになるか

- 「列挙型」も「構造体」も「タグ付き union」も `data` ひとつで書ける、を体感する
- `newtype` を使って **「中身は同じだけど別の型」** を作れる
- レコード構文で構造体っぽく書ける
- 型クラス（他言語の interface に近い）を `deriving` で楽に手に入れる
- **不正な値を作れない型** という、Haskell が一番得意なやつを実装できる

## まず一行のメンタルモデル

Haskell の `data` は、**「直和（OR）」と「直積（AND）」を一つの構文で同時に書ける** 道具。型クラスは **「この型はこういう操作をサポートします」という宣言** で、Go の interface や Rust の trait と近いが、より宣言的。

---

## 1. ADT (Algebraic Data Type) — 型を組み立てる

### 1-a. 直和: 「これかこれか」

他言語の enum / tagged union。

```haskell
data Color = Red | Green | Blue
```

`Color` 型の値は **必ず `Red`, `Green`, `Blue` のどれか**。第 4 の値はあり得ない。

### 1-b. 直積: 「これとこれを同時に持つ」

他言語の構造体／タプル。

```haskell
data Point = Point Double Double
--   ^^^^^   ^^^^^
--   型名    コンストラクタ（同じ名前にしてもOK）
```

`Point 3.0 4.0` で値を作る。

### 1-c. 直和 + 直積を一気に書ける

ここが他の言語と決定的に違うところ。

```haskell
data Shape
  = Circle Double                 -- 円: 半径 1 つ
  | Rectangle Double Double       -- 長方形: 幅と高さ
  | Triangle Double Double Double -- 三角形: 三辺
  deriving (Eq, Show)
```

「`Shape` であるとは、3 つの形のどれかであり、それぞれ必要なフィールドを持つ」。Rust の `enum` でフィールド付きバリアントを書くのに近い。

### パターンマッチで分解する

```haskell
area :: Shape -> Double
area (Circle r)         = pi * r * r
area (Rectangle w h)    = w * h
area (Triangle a b c)   = let s = (a + b + c) / 2
                          in sqrt (s * (s - a) * (s - b) * (s - c))
```

> **ポイント**: 形が増えたら関数の `case` をすべて書き直す必要がある。`-Wall` が「網羅されていません」と教えてくれるのが Haskell の安全性の柱。

### 再帰的な型 — 木構造

```haskell
data Tree a = Leaf | Node (Tree a) a (Tree a)
--          ^^^^   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^
--          葉     左部分木 + 値 + 右部分木
```

`a` は型変数（ジェネリクスの T）。`Tree Int` なら `Int` を持つ二分木。

---

## 2. `newtype` — 中身そのまま、型だけ別物

```haskell
newtype Age = Age Int
```

実行時のメモリ表現は **そのままの `Int`**（オーバーヘッドゼロ）。でも型としては別物。

### なぜ嬉しいか — 「`Int` の取り違え」を型で防ぐ

```haskell
newtype UserId    = UserId    Int
newtype ProductId = ProductId Int

getProduct :: ProductId -> IO Product
```

`getProduct (UserId 42)` はコンパイルエラー。`Int` のままだったら通ってしまうバグが、型レベルで止められる。

### `data` との違い

| | `data` | `newtype` |
|---|---|---|
| コンストラクタの数 | 何個でも | **1 個だけ** |
| フィールド数 | 何個でも | **1 個だけ** |
| 実行時のオーバーヘッド | 1 コンストラクタぶん | **ゼロ**（コンパイル時に剥がされる） |
| 用途 | 普通の型定義 | 型安全のためのラッパー |

### `type` は「ただの別名」

```haskell
type Name = String   -- 透過的。Name と String は完全に交換可能
```

これは **型安全のためにはほぼ役に立たない**（`String` が来てもコンパイラは喜んで通す）。読みやすさのためだけ。

---

## 3. レコード構文 — フィールドに名前を付ける

普通の直積:

```haskell
data Person = Person String Int
```

これだと「1 番目が名前、2 番目が年齢」を覚えていないといけない。レコード構文で名前を付ける:

```haskell
data Person = Person
  { personName :: String
  , personAge  :: Int
  }
  deriving (Eq, Show)
```

### 値の作り方 / 取り出し方

```haskell
alice :: Person
alice = Person { personName = "Alice", personAge = 30 }

-- フィールド名は自動で「ゲッター関数」になる
personName alice    -- → "Alice"
```

### 更新（イミュータブルなコピー）

Haskell は値を書き換えない。**フィールドを変えた新しい値を作る**。

```haskell
older :: Person
older = alice { personAge = personAge alice + 1 }
```

> **慣習**: フィールド名はモジュール内でユニークでないとぶつかる。`personName`, `personAge` のように **型名のプレフィックス** を付けるのが定番（GHC 9.2+ なら `OverloadedRecordDot` で `alice.personAge` 風の書き方もできる）。

---

## 4. 型クラス — 「この型はこの操作ができる」の宣言

他の言語との対比:

| 言語 | 似た仕組み |
|---|---|
| Go | interface |
| Rust | trait |
| Java | interface |
| Scala | trait（implicit） |

### 既存の型クラス

```haskell
class Eq a where
  (==) :: a -> a -> Bool
  (/=) :: a -> a -> Bool

class Eq a => Ord a where    -- Eq を前提とする（継承っぽいが、より宣言的）
  compare :: a -> a -> Ordering
  (<), (<=), (>), (>=) :: a -> a -> Bool
```

`a` は **「どんな型でもいい型変数」**。`Eq a =>` は「`a` は `Eq` であること」という制約。

### `deriving` — お任せで生成

```haskell
data Shape
  = Circle Double
  | Rectangle Double Double
  deriving (Eq, Show, Ord)
```

`==`, `show`, `compare` を **コンパイラが自動生成** する。これだけで `print someShape`、`s1 == s2`、`sort [shapes]` が動く。

### 自分でインスタンスを書く

`deriving` の生成内容が気に入らないとき:

```haskell
data Currency = USD | JPY | EUR

instance Show Currency where
  show USD = "$"
  show JPY = "¥"
  show EUR = "€"
```

`deriving Show` だと `show USD == "USD"` になるが、上のように手書きすると `"$"` を返せる。

---

## 5. Smart Constructor — 「不正な値が作れない型」

これは **Haskell が一番得意な小ワザ**。型を作るときに「外からはコンストラクタを直接呼べないようにし、検査済みの作成関数だけを公開する」。

```haskell
-- src/Lesson.hs
module Lesson
  ( Age          -- 型は公開
  , mkAge        -- コンストラクタ代わりの関数を公開
  , unAge        -- 中身を取り出す関数を公開
  ) where        -- ↑ Age(..) と書かないことで、コンストラクタは隠す

newtype Age = Age Int
  deriving (Eq, Ord, Show)

mkAge :: Int -> Maybe Age
mkAge n
  | n >= 0 && n <= 150 = Just (Age n)
  | otherwise          = Nothing

unAge :: Age -> Int
unAge (Age n) = n
```

### 何が嬉しいか

外側のコードは `mkAge` 経由でしか `Age` を作れない。だから **手元に `Age` の値があれば、それは `0..150` の範囲だと型が保証** している。

これは Go や TypeScript ではコンストラクタやファクトリ関数を「呼んでね」と書くだけで、誰かが直接構造体リテラルを書けば破綻する。Haskell ではモジュールシステムと組み合わせて **コンパイル時に強制** できる。

> **覚えておく価値**: 「不変条件があるなら型で表現する」が Haskell の流儀。実行時 `assert` ではなく `mkAge :: Int -> Maybe Age` のシグネチャで「失敗するかも」を呼び出し側に伝える。

---

## つまずきやすいポイント

- **`Foo` という名前が型名なのかコンストラクタ名なのか**: 同じ名前を両方に使えるので混乱しやすい。`data Point = Point Double Double` は左の `Point` が型、右の `Point` がコンストラクタ
- **「`Eq` の右辺は何?」**: `class Eq a where` の `a` は型変数。`instance Eq Int where` のように、後で具体型ごとに実装を書く
- **レコードのゲッター衝突**: 同じモジュール内で同じフィールド名を別の型に使うとぶつかる。プレフィックスで回避するか、`OverloadedRecordDot` を有効にする
- **`deriving (Show)` で「無限ループ表示になる」**: 再帰的な型で循環参照を作ると `show` が止まらない。デバッグ時に注意

---

## 演習

[src/Lesson.hs](src/Lesson.hs) の `undefined` を実装して `cabal test x002-types-and-typeclasses` を緑にする。

| 関数 / 型 | 仕様 |
|---|---|
| `data Shape = Circle Double \| Rectangle Double Double \| Triangle Double Double Double` | 既に書いてある |
| `area :: Shape -> Double` | パターンマッチで形ごとに計算。三角形はヘロンの公式 |
| `data Tree a = Leaf \| Node (Tree a) a (Tree a)` | 既に書いてある |
| `insert :: Ord a => a -> Tree a -> Tree a` | 二分探索木として挿入。重複は無視 |
| `toList :: Tree a -> [a]` | 中順走査（左→根→右）で昇順リストにする |
| `newtype Age` / `mkAge` / `unAge` | Smart Constructor。`mkAge` は 0..150 外なら `Nothing` |
| `Person` レコード | `personName :: String`, `personAge :: Int` |
| `birthday :: Person -> Person` | 年齢を 1 増やした新しい `Person` を返す |

ヒント: `Tree` の `insert` は「葉 → 値だけのノード」「左小さい右大きい」「等しいなら何もしない」の 3 パターン。`toList` は左を先、根、右の順で `++` する素直な再帰でいい。

## 参考

- [GHC Users Guide — record syntax](https://downloads.haskell.org/ghc/latest/docs/users_guide/exts/record_field_syntax.html)
- [Haskell Wiki — Smart constructors](https://wiki.haskell.org/Smart_constructors)
- [Type classes vs interfaces (StackOverflow)](https://stackoverflow.com/questions/8123832/type-class-vs-interface) — Java/Scala の interface との比較
