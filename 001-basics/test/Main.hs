module Main (main) where

import Test.Hspec
import Lesson

main :: IO ()
main = hspec $ do
  describe "square" $ do
    it "0 を 0 にする" $ square 0 `shouldBe` 0
    it "正の数を二乗する" $ square 7 `shouldBe` 49
    it "負の数も二乗できる" $ square (-3) `shouldBe` 9

  describe "factorial" $ do
    it "0! は 1" $ factorial 0 `shouldBe` 1
    it "5! は 120" $ factorial 5 `shouldBe` 120
    it "10! は 3628800" $ factorial 10 `shouldBe` 3628800

  describe "fizzbuzz" $ do
    it "1 はそのまま" $ fizzbuzz 1 `shouldBe` "1"
    it "3 は Fizz" $ fizzbuzz 3 `shouldBe` "Fizz"
    it "5 は Buzz" $ fizzbuzz 5 `shouldBe` "Buzz"
    it "15 は FizzBuzz" $ fizzbuzz 15 `shouldBe` "FizzBuzz"
    it "7 は 7" $ fizzbuzz 7 `shouldBe` "7"

  describe "myLength" $ do
    it "空リストは 0" $ myLength ([] :: [Int]) `shouldBe` 0
    it "要素 3 つは 3" $ myLength [10, 20, 30 :: Int] `shouldBe` 3

  describe "myMap" $ do
    it "空リストは空" $ myMap (+ 1) ([] :: [Int]) `shouldBe` []
    it "各要素に関数を適用する" $ myMap (* 2) [1, 2, 3 :: Int] `shouldBe` [2, 4, 6]

  describe "pythagoreanTriples" $ do
    it "n=20 で (3,4,5),(5,12,13),(6,8,10),(8,15,17),(9,12,15) を含む" $ do
      let xs = pythagoreanTriples 20
      xs `shouldContain` [(3, 4, 5)]
      xs `shouldContain` [(5, 12, 13)]
      xs `shouldContain` [(6, 8, 10)]
      xs `shouldContain` [(8, 15, 17)]
      xs `shouldContain` [(9, 12, 15)]
    it "a <= b <= c の順序を保つ" $ do
      let xs = pythagoreanTriples 30
      all (\(a, b, c) -> a <= b && b <= c) xs `shouldBe` True
