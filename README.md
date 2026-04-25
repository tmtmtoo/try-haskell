# try-haskell

Haskell 入門カリキュラム。各ワークスペースに学習目標・要点解説・演習が `README.md` としてまとまっており、`src/` の `undefined` を埋めながら `cabal test` を緑にすることで進めていく形式。

## 開発環境

- devcontainer + Nix flake + cabal
- VS Code で Reopen in Container すると、HLS / hlint / fourmolu / ghcid / cabal-install / GHC が揃った devShell に入れる
- ローカルで動かす場合は `nix develop` または direnv の `use flake`

## カリキュラム

### Phase 1: 土台
1. [001-basics](001-basics/) — 基礎文法（型注釈、パターンマッチ、リスト、再帰、高階関数）
2. [002-types-and-typeclasses](002-types-and-typeclasses/) — 代数的データ型、`newtype`、レコード、型クラス、`deriving`
3. [003-modules-and-project](003-modules-and-project/) — モジュール分割、エクスポートリスト、Cabal パッケージ

### Phase 2: テスト習慣
4. [004-testing](004-testing/) — Hspec、QuickCheck、tasty、doctest

### Phase 3: 抽象化の階段
5. [005-functor](005-functor/) — `fmap` と Functor 則
6. [006-applicative](006-applicative/) — `pure`/`<*>` と Validation
7. [007-monad](007-monad/) — `>>=` と `do` 記法
8. [008-foldable-traversable-monoid](008-foldable-traversable-monoid/) — `Semigroup`/`Monoid`/`Foldable`/`Traversable`

### Phase 4: 実践モナド
9. [009-monads-in-practice](009-monads-in-practice/) — `Maybe`/`Either`/`State`/`Reader`/`Writer`/`ST`
10. [010-monad-transformers](010-monad-transformers/) — mtl と `ExceptT`/`StateT`/`ReaderT`

### Phase 5: 実世界
11. [011-io-and-exceptions](011-io-and-exceptions/) — `IO`、`IORef`、例外、`bracket`
12. [012-concurrency](012-concurrency/) — `forkIO`、`async`、STM

### Phase 6: 実装スキルと締め
13. [013-strings-and-performance](013-strings-and-performance/) — `Text`/`ByteString`、遅延評価、正格性
14. [014-ecosystem-and-idioms](014-ecosystem-and-idioms/) — Hackage/Stackage、定番ライブラリ、Haskell 流儀

## 進め方

```sh
# 初回だけ: Hackage のパッケージリストを取得する
# （やらないと async など外部パッケージが "unknown package" で解決できない）
cabal update

# 章のテストだけ走らせる
cabal test x001-basics

# 章を絞り込んで反復
ghcid -c 'cabal repl x001-basics-test' -T main

# 全章をビルド
cabal build all
```

各章の `README.md` の「演習」節に従って `src/Lesson.hs` の `undefined` を実装していき、`cabal test xNNN-...` が緑になったら次章へ。
