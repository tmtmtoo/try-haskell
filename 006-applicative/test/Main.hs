module Main (main) where

import Test.Hspec
import Lesson

main :: IO ()
main = hspec $ do
  describe "Functor (Validation e)" $ do
    it "Success の中身に適用" $
      fmap (+ 1) (Success 3 :: Validation [String] Int) `shouldBe` Success 4
    it "Failure はそのまま" $
      fmap (+ 1) (Failure ["e"] :: Validation [String] Int) `shouldBe` Failure ["e"]

  describe "Applicative (Validation e)" $ do
    it "両方 Success" $
      ((+) <$> Success 3 <*> Success 4 :: Validation [String] Int) `shouldBe` Success 7
    it "右が Failure" $
      ((+) <$> Success 3 <*> (Failure ["e"] :: Validation [String] Int))
        `shouldBe` Failure ["e"]
    it "両方 Failure はエラーを蓄積" $
      ((+) <$> (Failure ["e1"] :: Validation [String] Int)
           <*> (Failure ["e2"] :: Validation [String] Int))
        `shouldBe` Failure ["e1", "e2"]

  describe "validateName" $ do
    it "非空は Success" $ validateName "Alice" `shouldBe` Success "Alice"
    it "空は Failure" $ validateName "" `shouldBe` Failure ["name is empty"]

  describe "validateAge" $ do
    it "30 は Success" $ validateAge 30 `shouldBe` Success 30
    it "-1 は Failure" $ validateAge (-1) `shouldBe` Failure ["age out of range"]
    it "151 は Failure" $ validateAge 151 `shouldBe` Failure ["age out of range"]

  describe "mkPerson" $ do
    it "両方有効なら Success Person" $
      mkPerson "Alice" 30 `shouldBe` Success (Person "Alice" 30)
    it "名前だけ無効" $
      mkPerson "" 30 `shouldBe` Failure ["name is empty"]
    it "両方無効ならエラーを両方集める" $
      mkPerson "" 999 `shouldBe` Failure ["name is empty", "age out of range"]
