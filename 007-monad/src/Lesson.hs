module Lesson
  ( Identity' (..)
  , safeDiv
  , chainDiv
  , Expr (..)
  , evalExpr
  ) where

newtype Identity' a = Identity' { runIdentity' :: a }
  deriving (Eq, Show)

instance Functor Identity' where
  fmap = undefined

instance Applicative Identity' where
  pure  = undefined
  (<*>) = undefined

instance Monad Identity' where
  (>>=) = undefined

safeDiv :: Int -> Int -> Maybe Int
safeDiv = undefined

chainDiv :: Int -> [Int] -> Maybe Int
chainDiv = undefined

data Expr
  = ELit Int
  | EAdd Expr Expr
  | EDiv Expr Expr
  deriving (Eq, Show)

evalExpr :: Expr -> Either String Int
evalExpr = undefined
