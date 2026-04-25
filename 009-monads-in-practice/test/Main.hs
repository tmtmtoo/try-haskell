module Main (main) where

import Control.Monad.Reader (runReader)
import Control.Monad.State (runState)
import Control.Monad.Writer (runWriter)
import Test.Hspec

import Lesson

main :: IO ()
main = hspec $ do
  describe "State スタック" $ do
    it "push / pop の往復" $ do
      let action = do
            push 1
            push 2
            push 3
            (,,) <$> pop <*> pop <*> pop
      let (val, st) = runState action []
      val `shouldBe` (Just 3, Just 2, Just 1)
      st `shouldBe` []
    it "空からの pop は Nothing" $
      runState pop ([] :: [Int]) `shouldBe` (Nothing, [])

  describe "Reader Config" $ do
    it "URL を組み立てる" $
      runReader urlR (Config "localhost" 8080)
        `shouldBe` "http://localhost:8080"

  describe "Writer tracedFact" $ do
    it "計算結果は階乗" $ fst (runWriter (tracedFact 5)) `shouldBe` 120
    it "ログが残る" $ length (snd (runWriter (tracedFact 3))) `shouldSatisfy` (> 0)

  describe "List モナド pythagoreans" $ do
    it "n=20 を含む" $ do
      let xs = pythagoreans 20
      xs `shouldContain` [(3, 4, 5)]
      xs `shouldContain` [(5, 12, 13)]
      xs `shouldContain` [(8, 15, 17)]
    it "n=10 は (3,4,5),(6,8,10) のみ" $
      pythagoreans 10 `shouldBe` [(3, 4, 5), (6, 8, 10)]

  describe "ST sumST" $ do
    it "[1..100] の合計は 5050" $ sumST [1 .. 100] `shouldBe` 5050
    it "空リストは 0" $ sumST [] `shouldBe` 0
