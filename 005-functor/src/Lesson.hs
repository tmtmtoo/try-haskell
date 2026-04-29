module Lesson
  ( Tree (..)
  , Pair (..)
  , incrAll
  , replaceAll
  ) where

data Tree a = Leaf | Node (Tree a) a (Tree a)
  deriving (Eq, Show)

instance Functor Tree where
  fmap _ Leaf = Leaf
  fmap f (Node l x r) = Node (f <$> l) (f x) (f <$> r)

newtype Pair a = Pair (a, a)
  deriving (Eq, Show)

instance Functor Pair where
  fmap f (Pair (x, y)) = Pair (f x, f y)

incrAll :: Functor f => f Int -> f Int
incrAll = fmap (+1)

replaceAll :: Functor f => b -> f a -> f b
replaceAll x y = x <$ y
