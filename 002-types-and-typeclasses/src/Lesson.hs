module Lesson
  ( Shape (..)
  , area
  , Tree (..)
  , insert
  , toList
  , Age
  , mkAge
  , unAge
  , Person (..)
  , birthday
  ) where

data Shape
  = Circle Double
  | Rectangle Double Double
  | Triangle Double Double Double
  deriving (Eq, Show)

area :: Shape -> Double
area = undefined

data Tree a = Leaf | Node (Tree a) a (Tree a)
  deriving (Eq, Show)

insert :: Ord a => a -> Tree a -> Tree a
insert = undefined

toList :: Tree a -> [a]
toList = undefined

newtype Age = Age Int
  deriving (Eq, Ord, Show)

mkAge :: Int -> Maybe Age
mkAge = undefined

unAge :: Age -> Int
unAge (Age n) = n

data Person = Person
  { personName :: String
  , personAge  :: Int
  }
  deriving (Eq, Show)

birthday :: Person -> Person
birthday = undefined
