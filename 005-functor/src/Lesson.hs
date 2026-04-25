module Lesson
  ( Tree (..)
  , Pair (..)
  , incrAll
  , replaceAll
  ) where

data Tree a = Leaf | Node (Tree a) a (Tree a)
  deriving (Eq, Show)

instance Functor Tree where
  fmap = undefined

newtype Pair a = Pair (a, a)
  deriving (Eq, Show)

instance Functor Pair where
  fmap = undefined

incrAll :: Functor f => f Int -> f Int
incrAll = undefined

replaceAll :: Functor f => b -> f a -> f b
replaceAll = undefined
