module Lesson
  ( Min' (..),
    Tree (..),
    parseInts,
    treeSum,
  )
where

import Text.Read (readMaybe)

newtype Min' a = Min' {getMin' :: a}
  deriving (Eq, Show)

instance (Ord a) => Semigroup (Min' a) where
  Min' x <> Min' y = Min' $ min x y

data Tree a = Leaf | Node (Tree a) a (Tree a)
  deriving (Eq, Show)

instance Functor Tree where
  fmap _ Leaf = Leaf
  fmap f (Node l x r) = Node (f <$> l) (f x) (f <$> r)

instance Foldable Tree where
  foldr _ z Leaf = z
  foldr f z (Node l x r) = foldr f (f x $ foldr f z r) l

instance Traversable Tree where
  traverse _ Leaf = pure Leaf
  traverse f (Node l x r) = Node <$> traverse f l <*> f x <*> traverse f r

parseInts :: [String] -> Maybe [Int]
parseInts = traverse readMaybe

treeSum :: (Num a) => Tree a -> a
treeSum = sum
