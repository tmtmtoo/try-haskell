module Main (main) where

import Test.Hspec
import Lesson

main :: IO ()
main = hspec $ do
  describe "Identity'" $ do
    it "Functor: fmap (+1) (Identity' 3)" $
      fmap (+ 1) (Identity' 3) `shouldBe` Identity' 4
    it "Applicative: pure 5" $ (pure 5 :: Identity' Int) `shouldBe` Identity' 5
    it "Applicative: (+) <$> Identity' 3 <*> Identity' 4" $
      ((+) <$> Identity' 3 <*> Identity' 4) `shouldBe` Identity' 7
    it "Monad: do 記法で連結" $
      runIdentity' (do { x <- Identity' 3; y <- Identity' 4; pure (x + y) })
        `shouldBe` 7
    it "Monad 則: 左単位 return a >>= k == k a" $
      (pure 3 >>= \x -> Identity' (x + 1)) `shouldBe` Identity' 4
    it "Monad 則: 右単位 m >>= return == m" $
      (Identity' 7 >>= pure) `shouldBe` Identity' 7

  describe "safeDiv" $ do
    it "通常除算" $ safeDiv 10 2 `shouldBe` Just 5
    it "0 除算" $ safeDiv 10 0 `shouldBe` Nothing

  describe "chainDiv" $ do
    it "[2, 5] で 100 を割る" $ chainDiv 100 [2, 5] `shouldBe` Just 10
    it "途中で 0 があると Nothing" $ chainDiv 100 [2, 0, 5] `shouldBe` Nothing
    it "空リストはそのまま" $ chainDiv 42 [] `shouldBe` Just 42

  describe "evalExpr" $ do
    it "リテラル" $ evalExpr (ELit 7) `shouldBe` Right 7
    it "加算" $ evalExpr (EAdd (ELit 3) (ELit 4)) `shouldBe` Right 7
    it "除算 (1+1)/(2)" $
      evalExpr (EDiv (EAdd (ELit 1) (ELit 1)) (ELit 2)) `shouldBe` Right 1
    it "0 除算は Left" $
      evalExpr (EDiv (ELit 1) (ELit 0)) `shouldBe` Left "division by zero"
