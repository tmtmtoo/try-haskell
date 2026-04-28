module Main (main) where

import Data.List (sort)
import Test.Hspec
import Test.Hspec.QuickCheck (prop)

import Lesson
import Test.QuickCheck.Modifiers (NonNegative(NonNegative))

main :: IO ()
main = hspec $ do
  describe "reverseList (例ベース)" $ do
    it "空リストはそのまま" $ reverseList ([] :: [Int]) `shouldBe` []
    it "[1,2,3] -> [3,2,1]" $ reverseList [1, 2, 3 :: Int] `shouldBe` [3, 2, 1]

  describe "sortList (例ベース)" $ do
    it "[3,1,2] -> [1,2,3]" $ sortList [3, 1, 2 :: Int] `shouldBe` [1, 2, 3]

  describe "isPalindrome (例ベース)" $ do
    it "\"racecar\" は回文" $ isPalindrome "racecar" `shouldBe` True
    it "\"haskell\" は回文ではない" $ isPalindrome "haskell" `shouldBe` False
    it "空文字は回文" $ isPalindrome "" `shouldBe` True

  describe "myGcd (例ベース)" $ do
    it "gcd 12 8 == 4" $ myGcd 12 8 `shouldBe` 4
    it "gcd 0 7 == 7" $ myGcd 0 7 `shouldBe` 7

  describe "プロパティ" $ do
    -- 性質ベーステストの例
    prop "reverseList は長さを保つ" $ \xs ->
      length (reverseList xs) == length (xs :: [Int])

    prop "sortList は Data.List.sort と一致する" $ \xs ->
      sortList xs == sort (xs :: [Int])

    prop "sortList の出力は昇順" $ \xs ->
      let ys = sortList (xs :: [Int])
       in and (zipWith (<=) ys (drop 1 ys))

    -- TODO: 演習 — 以下のプロパティを書いて緑にする
    --   1. reverseList の involution: reverseList . reverseList == id
    --   2. sortList の冪等性: sortList . sortList == sortList
    --   3. myGcd の可換性: myGcd a b == myGcd b a (a, b は非負)
    -- 例:
    -- prop "reverseList is involutive" $ \xs ->
    --   reverseList (reverseList xs) == (xs :: [Int])
    prop "reverseList . reverseList == id" $ \xs ->
      let f = reverseList . reverseList
       in f xs == (xs :: [Int]) 

    prop "sortList . sortList == sortList" $ \xs ->
      let f = sortList . sortList
       in f xs == sortList (xs :: [Int])

    prop "myGcd a b == myGcd b a" $ \(NonNegative a) (NonNegative b) ->
      myGcd a b == myGcd b a
