module Lesson.Internal.Numeric
  ( total,
    count,
  )
where

total :: [Double] -> Double
total [] = 0
total (x : xs) = x + total xs

count :: [Double] -> Double
count [] = 0
count (_ : xs) = 1 + count xs
