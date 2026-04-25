module Main (main) where

import Test.Hspec
import Lesson (mean, variance, stddev)

approx :: Double -> Double -> Bool
approx a b = abs (a - b) < 1e-9

main :: IO ()
main = hspec $ do
  describe "Lesson.Stats" $ do
    describe "mean" $ do
      it "[1,2,3,4,5] の平均は 3" $ mean [1, 2, 3, 4, 5] `shouldSatisfy` approx 3
      it "[10] の平均は 10" $ mean [10] `shouldSatisfy` approx 10

    describe "variance" $ do
      it "[1,2,3,4,5] の母分散は 2" $ variance [1, 2, 3, 4, 5] `shouldSatisfy` approx 2
      it "全部同じ値なら 0" $ variance [7, 7, 7, 7] `shouldSatisfy` approx 0

    describe "stddev" $ do
      it "[2,4,4,4,5,5,7,9] の標準偏差は 2" $
        stddev [2, 4, 4, 4, 5, 5, 7, 9] `shouldSatisfy` approx 2
