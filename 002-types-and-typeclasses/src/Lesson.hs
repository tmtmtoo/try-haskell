module Lesson
  ( Shape (..),
    area,
    Tree (..),
    insert,
    toList,
    Age,
    mkAge,
    unAge,
    Person (..),
    birthday,
  )
where

data Shape
  = Circle Double
  | Rectangle Double Double
  | Triangle Double Double Double
  deriving (Eq, Show)

area :: Shape -> Double
area (Circle r) = pi * r * r
area (Rectangle w h) = w * h
area (Triangle a b c) =
  let s = (a + b + c) / 2
   in sqrt (s * (s - a) * (s - b) * (s - c))

data Tree a = Leaf | Node (Tree a) a (Tree a)
  deriving (Eq, Show)

insert :: (Ord a) => a -> Tree a -> Tree a
insert n Leaf = Node Leaf n Leaf
insert n (Node l x r)
  | n < x = Node (insert n l) x r
  | n > x = Node l x (insert n r)
  | otherwise = Node l x r

toList :: Tree a -> [a]
toList Leaf = []
toList (Node l x r) = toList l ++ [x] ++ toList r

newtype Age = Age Int
  deriving (Eq, Ord, Show)

mkAge :: Int -> Maybe Age
mkAge n
  | n < 0 = Nothing
  | n > 150 = Nothing
  | otherwise = Just (Age n)

unAge :: Age -> Int
unAge (Age n) = n

data Person = Person
  { personName :: String,
    personAge :: Int
  }
  deriving (Eq, Show)

birthday :: Person -> Person
birthday p = p {personAge = personAge p + 1}
