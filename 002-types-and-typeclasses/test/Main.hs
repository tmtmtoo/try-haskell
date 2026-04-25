module Main (main) where

import Test.Hspec
import Lesson

main :: IO ()
main = hspec $ do
  describe "area" $ do
    it "Circle 1 は π" $ area (Circle 1) `shouldSatisfy` (\x -> abs (x - pi) < 1e-9)
    it "Rectangle 3 4 は 12" $ area (Rectangle 3 4) `shouldBe` 12
    it "Triangle 3 4 5 は 6" $ area (Triangle 3 4 5) `shouldSatisfy` (\x -> abs (x - 6) < 1e-9)

  describe "Tree" $ do
    it "空木に挿入すると 1 要素" $
      toList (insert 5 (Leaf :: Tree Int)) `shouldBe` [5]
    it "複数挿入で昇順" $ do
      let t = foldr insert (Leaf :: Tree Int) [5, 3, 8, 1, 4]
      toList t `shouldBe` [1, 3, 4, 5, 8]
    it "重複は無視" $ do
      let t = foldr insert (Leaf :: Tree Int) [3, 1, 3, 2, 1]
      toList t `shouldBe` [1, 2, 3]

  describe "mkAge" $ do
    it "0 は許容" $ fmap unAge (mkAge 0) `shouldBe` Just 0
    it "150 は許容" $ fmap unAge (mkAge 150) `shouldBe` Just 150
    it "-1 は不可" $ mkAge (-1) `shouldBe` Nothing
    it "151 は不可" $ mkAge 151 `shouldBe` Nothing

  describe "birthday" $ do
    let alice = Person { personName = "Alice", personAge = 29 }
    it "年齢を 1 増やす" $ personAge (birthday alice) `shouldBe` 30
    it "名前は変えない" $ personName (birthday alice) `shouldBe` "Alice"
