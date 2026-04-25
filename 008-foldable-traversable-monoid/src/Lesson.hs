module Lesson
  ( Min' (..)
  , Tree (..)
  , parseInts
  , treeSum
  ) where

import Text.Read (readMaybe)

newtype Min' a = Min' { getMin' :: a }
  deriving (Eq, Show)

instance Ord a => Semigroup (Min' a) where
  (<>) = undefined

data Tree a = Leaf | Node (Tree a) a (Tree a)
  deriving (Eq, Show)

instance Functor Tree where
  fmap = undefined

instance Foldable Tree where
  foldr = undefined

instance Traversable Tree where
  traverse = undefined

parseInts :: [String] -> Maybe [Int]
parseInts = traverse readMaybe

treeSum :: Num a => Tree a -> a
treeSum = undefined
