module Main (main) where

import Control.Concurrent (threadDelay)
import Control.Concurrent.STM (atomically)
import Test.Hspec

import Lesson

main :: IO ()
main = hspec $ do
  describe "bumpManyTimes" $ do
    it "10 スレッド × 1000 回 = 10000 になる" $ do
      n <- bumpManyTimes 10 1000
      n `shouldBe` 10000

  describe "parPair" $ do
    it "結果ペアを返す" $ do
      r <- parPair (pure (1 :: Int)) (pure "hi")
      r `shouldBe` (1, "hi")
    it "並行に走る (sleep が並列化される)" $ do
      let sleepReturn x = threadDelay 100000 >> pure x
      r <- parPair (sleepReturn (1 :: Int)) (sleepReturn (2 :: Int))
      r `shouldBe` (1, 2)

  describe "Account / transfer" $ do
    it "正常な送金で残高が変わる" $ do
      (a, b) <- atomically $ do
        a <- mkAccount 100
        b <- mkAccount 0
        transfer 30 a b
        (,) <$> balance a <*> balance b
      a `shouldBe` 70
      b `shouldBe` 30

    it "送金額が残高ぴったりでも成功" $ do
      (a, b) <- atomically $ do
        a <- mkAccount 50
        b <- mkAccount 0
        transfer 50 a b
        (,) <$> balance a <*> balance b
      a `shouldBe` 0
      b `shouldBe` 50
