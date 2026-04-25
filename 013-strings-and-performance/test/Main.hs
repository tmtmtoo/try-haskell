module Main (main) where

import qualified Data.ByteString.Char8 as B
import qualified Data.Map.Strict as Map
import qualified Data.Text as T
import Test.Hspec

import Lesson

approx :: Double -> Double -> Bool
approx a b = abs (a - b) < 1e-9

main :: IO ()
main = hspec $ do
  describe "wordCount" $ do
    it "頻度を数える" $
      wordCount (T.pack "the quick brown fox the lazy dog the fox")
        `shouldBe` Map.fromList
          [ (T.pack "brown", 1)
          , (T.pack "dog", 1)
          , (T.pack "fox", 2)
          , (T.pack "lazy", 1)
          , (T.pack "quick", 1)
          , (T.pack "the", 3)
          ]
    it "空文字" $ wordCount (T.pack "") `shouldBe` Map.empty

  describe "strictSum" $ do
    it "[1..100]" $ strictSum [1 .. 100] `shouldBe` 5050
    it "巨大リストでもスタックを潰さない" $
      strictSum [1 .. 1000000] `shouldBe` 500000500000

  describe "runningMean" $ do
    it "1 要素ずつの累積平均" $ do
      let xs = runningMean [2, 4, 6, 8]
      length xs `shouldBe` 4
      xs `shouldSatisfy` and . zipWith approx [2, 3, 4, 5]

  describe "countLines" $ do
    it "改行 2 つで 3 行" $ countLines (B.pack "a\nb\nc") `shouldBe` 3
    it "末尾改行込み" $ countLines (B.pack "a\nb\n") `shouldBe` 3
    it "空入力は 0" $ countLines (B.pack "") `shouldBe` 0
