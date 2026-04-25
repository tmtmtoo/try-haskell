# 004 — テスト

## この章で何ができるようになるか

- Hspec で「読みやすい仕様書」っぽいテストを書ける
- QuickCheck で「ランダム入力でも壊れないこと」を主張できる
- **例ベース**（`it "Xは Yになる"`） と **性質ベース**（`prop "X は常に Y を満たす"`）の使い分けができる
- tasty / doctest が **何のためにあるか** だけは知っている

## まず一行のメンタルモデル

- **Hspec**: 「人間が読める英語に近い形でテストを書く」フレームワーク。RSpec / Jest の describe-it スタイル
- **QuickCheck**: 「ランダム入力 100 通り食わせて全部成り立つことを確認」する道具。バグった反例を **自動で最小化** してくれるのが革命的

---

## 1. Hspec — 例ベース

```haskell
import Test.Hspec

main :: IO ()
main = hspec $ do
  describe "reverse" $ do
    it "空リストはそのまま" $
      reverse [] `shouldBe` ([] :: [Int])

    it "[1,2,3] -> [3,2,1]" $
      reverse [1, 2, 3 :: Int] `shouldBe` [3, 2, 1]

    it "2 回かけると元に戻る" $
      reverse (reverse [1, 2, 3 :: Int]) `shouldBe` [1, 2, 3]
```

### 主なマッチャ

| 書き方 | 意味 |
|---|---|
| `x \`shouldBe\` y` | `x == y` |
| `x \`shouldSatisfy\` p` | `p x == True` |
| `xs \`shouldContain\` ys` | リストの部分包含 |
| `action \`shouldThrow\` selector` | 例外を投げる |
| `pendingWith "理由"` | 「未実装」とマーク（赤にもならない） |

### `describe` で階層を作れる

```haskell
describe "Math" $ do
  describe "addition" $ do
    it "可換" $ ...
  describe "multiplication" $ do
    it "結合則" $ ...
```

これは見た目の話だけではなく、CI で「`Math.addition` だけ走らせる」フィルタリングにも使える。

### `hspec-discover`（次のステップ）

`*Spec.hs` ファイルを並べておくと、`hspec-discover` が自動で集めて `main` を作ってくれる。本講義ではシンプルさのため使っていないが、本番プロジェクトでは便利。

---

## 2. QuickCheck — 性質ベース

例ベースだと「自分で思いついた入力」しかテストできない。QuickCheck は **乱数で 100 ケース生成して、ぜんぶ成り立つか** を確認する。

```haskell
import Test.Hspec
import Test.Hspec.QuickCheck (prop)

main = hspec $ do
  describe "reverse" $ do
    prop "involutive (2 回かけると元)" $ \xs ->
      reverse (reverse xs) == (xs :: [Int])

    prop "長さは保たれる" $ \xs ->
      length (reverse xs) == length (xs :: [Int])
```

`\xs ->` は「`xs` を受け取って真偽値を返す関数」。QuickCheck がこの `xs` に **無作為なリスト** を 100 通り食わせる。

### 反例の最小化（shrink） — ここが本当に強い

例えば `\xs -> length xs < 10` という間違ったプロパティを書くと:

```
*** Failed! Falsified (after 12 tests and 5 shrinks):
[(),(),(),(),(),(),(),(),(),()]
```

「12 ケース目で失敗、5 回縮小して、これが最小の反例です」と教えてくれる。**ランダムなゴミではなく、人間が読める最小ケース** が出るので、デバッグが超早い。

### 何を性質にするか — 4 つの定石パターン

| パターン | 例 |
|---|---|
| **逆操作との往復** | `decode . encode == id` / `parse . pretty == id` |
| **冪等性** | `f (f x) == f x` (`sort`, `normalize` など) |
| **モデル比較** | 自作 `mySort` ≡ 既知正解 `Data.List.sort` |
| **不変条件** | 出力は常にソート済み／常に空でない／総和が保存される |

「境界値（空リスト、最小・最大値）」は **例ベース** で書き、一般則は **プロパティ** で書く、と組み合わせるのが実務。

> **落とし穴**: プロパティを書いたつもりが「型推論で `xs :: [()]` になっていて、`unit` のリストばかり生成されていた」のは初心者あるある。`(xs :: [Int])` のように **型を固定** するのが定石。

---

## 3. tasty — 「複数フレームワークを束ねるランナー」

Hspec, HUnit, QuickCheck, SmallCheck などをひとつのツリーにまとめ、

- 並列実行
- パターンでフィルタ
- JUnit XML 出力（CI 連携）

を統一して提供する。**今すぐは不要** だが、CI で複数の testing スタイルが混在する大きめのプロジェクトでは事実上の標準。

```haskell
import Test.Tasty
import Test.Tasty.HUnit
import Test.Tasty.QuickCheck

main = defaultMain $ testGroup "all"
  [ testCase "addition"  (1 + 1 @?= 2)
  , testProperty "rev rev" (\xs -> reverse (reverse xs) == (xs :: [Int]))
  ]
```

---

## 4. doctest — 「ドキュメント中の例を実行」

Haddock コメントに REPL 風の例を書いておくと、それがそのまま実行されてテストになる。

```haskell
-- | 二乗
--
-- >>> square 5
-- 25
square :: Int -> Int
square x = x * x
```

**ドキュメントが古びない** のが最大の利点。本講義では扱わないが、ライブラリ作者なら必須に近い。

---

## つまずきやすいポイント

- **`pure ()` を `it` の中身にしてしまう**: テストが「常に成功」してしまう。Hspec は **本体の `IO ()` が例外を投げないこと** で成功判定するので、何もしなければ通ってしまう
- **QuickCheck の生成型が `()` のリストになる**: 上記の通り、`(xs :: [Int])` で固定する
- **Spec の中で `pure ()` を最後に書く理由**: `do` ブロックは最後の式の型に揃える必要がある。先行する `it` / `prop` だけだと最後の判定が無いので、**演習用にコメントだけ残したいときは `pure ()` で締める**
- **`shouldBe` の左右の順番**: `actual \`shouldBe\` expected` の順。エラーメッセージの読みやすさに関わる

---

## 演習

[src/Lesson.hs](src/Lesson.hs) に 4 つの関数を実装し、[test/Main.hs](test/Main.hs) に **追加で QuickCheck プロパティを 3 つ書いて** 緑にする。

| 関数 | シグネチャ | 仕様 |
|---|---|---|
| `reverseList` | `[a] -> [a]` | `Prelude.reverse` を使わずに再帰で実装 |
| `sortList` | `Ord a => [a] -> [a]` | 昇順ソート（実装方法は問わない） |
| `isPalindrome` | `Eq a => [a] -> Bool` | 回文判定。空リストは `True` |
| `myGcd` | `Integer -> Integer -> Integer` | 非負入力を想定した最大公約数 |

[test/Main.hs](test/Main.hs) の末尾に **追加で書くプロパティ**:

1. `reverseList . reverseList == id` （involution）
2. `sortList . sortList == sortList` （冪等性）
3. `myGcd a b == myGcd b a` （可換性）。生成は `\(NonNegative a) (NonNegative b) -> ...` のように `NonNegative` ラッパーを使うと負値を排除できる

---

## 参考

- [Hspec User's Manual](https://hspec.github.io/)
- [QuickCheck — quick reference](https://hackage.haskell.org/package/QuickCheck)
- [Property-based testing with QuickCheck](https://www.fpcomplete.com/blog/2017/01/quickcheck/)（実例豊富）
- [tasty](https://github.com/UnkindPartition/tasty)
- [doctest](https://github.com/sol/doctest)
