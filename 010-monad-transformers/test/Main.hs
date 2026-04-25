module Main (main) where

import Test.Hspec
import Lesson

initial :: Inventory
initial = [("apple", 3), ("banana", 0)]

main :: IO ()
main = hspec $ do
  describe "decreaseStock" $ do
    it "存在する商品を 1 減らす" $
      runStock (decreaseStock "apple") initial
        `shouldBe` (Right 2, [("apple", 2), ("banana", 0)])

    it "在庫 0 なら out of stock" $
      runStock (decreaseStock "banana") initial
        `shouldBe` (Left "out of stock", initial)

    it "存在しない商品なら not found" $
      runStock (decreaseStock "carrot") initial
        `shouldBe` (Left "not found", initial)

  describe "decorate" $ do
    let cfg = AppConfig "[" "]"
    it "前後を装飾" $
      runDecorate "hello" cfg `shouldBe` Right "[hello]"
    it "空入力は Left" $
      runDecorate "" cfg `shouldBe` Left "empty"
