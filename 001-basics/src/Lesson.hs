module Lesson
  ( square,
    factorial,
    fizzbuzz,
    myLength,
    myMap,
    pythagoreanTriples,
  )
where

square :: Int -> Int
square n = n * n

factorial :: Integer -> Integer
factorial 0 = 1
factorial n = n * factorial (n - 1)

fizzbuzz :: Int -> String
fizzbuzz n
  | n `mod` 15 == 0 = "FizzBuzz"
  | n `mod` 3 == 0 = "Fizz"
  | n `mod` 5 == 0 = "Buzz"
  | otherwise = show n

myLength :: [a] -> Int
myLength [] = 0
myLength (_ : xs) = 1 + myLength xs

myMap :: (a -> b) -> [a] -> [b]
myMap _ [] = []
myMap f (x : xs) = [f x] ++ myMap f xs

pythagoreanTriples :: Int -> [(Int, Int, Int)]
pythagoreanTriples n =
  [ (a, b, c)
  | a <- [1 .. n],
    b <- [1 .. n],
    c <- [1 .. n],
    a * a + b * b == c * c && a <= b && b <= c
  ]
