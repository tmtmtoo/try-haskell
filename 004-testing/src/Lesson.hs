module Lesson
  ( reverseList,
    sortList,
    isPalindrome,
    myGcd,
  )
where

reverseList :: [a] -> [a]
reverseList [] = []
reverseList (x : xs) = reverseList xs ++ [x]

sortList :: (Ord a) => [a] -> [a]
sortList list
  | bubble list == list = list
  | otherwise = sortList $ bubble list
  where
    bubble [] = []
    bubble [x] = [x]
    bubble (x:y:xs)
      | x < y = x : bubble (y : xs)
      | otherwise = y : bubble (x : xs)

isPalindrome :: (Eq a) => [a] -> Bool
isPalindrome x = x == reverseList x

myGcd :: Integer -> Integer -> Integer
myGcd x 0 = abs x
myGcd x y = myGcd y $ x `mod` y
