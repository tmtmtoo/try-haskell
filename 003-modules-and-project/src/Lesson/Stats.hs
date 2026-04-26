module Lesson.Stats
  ( mean
  , variance
  , stddev
  ) where

import qualified Lesson.Internal.Numeric as N

mean :: [Double] -> Double
mean list = N.total list / N.count list

variance :: [Double] -> Double
variance list = 
  let m = mean list
  in sum [(x - m) ** 2 | x <- list] / N.count list

stddev :: [Double] -> Double
stddev = sqrt . variance 
