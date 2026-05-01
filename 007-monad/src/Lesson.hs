module Lesson
  ( Identity' (..),
    safeDiv,
    chainDiv,
    Expr (..),
    evalExpr,
  )
where

newtype Identity' a = Identity' {runIdentity' :: a}
  deriving (Eq, Show)

instance Functor Identity' where
  fmap f (Identity' a) = Identity' $ f a

instance Applicative Identity' where
  pure = Identity'
  Identity' f <*> Identity' a = Identity' $ f a

instance Monad Identity' where
  Identity' a >>= f = f a

safeDiv :: Int -> Int -> Maybe Int
safeDiv _ 0 = Nothing
safeDiv x y = Just $ x `div` y

chainDiv :: Int -> [Int] -> Maybe Int
chainDiv a [] = Just a
chainDiv a (x : xs) = do
  b <- safeDiv a x
  c <- chainDiv b xs
  return c

data Expr
  = ELit Int
  | EAdd Expr Expr
  | EDiv Expr Expr
  deriving (Eq, Show)

evalExpr :: Expr -> Either String Int
evalExpr (ELit a) = Right a
evalExpr (EAdd l r) = do
  l' <- evalExpr l
  r' <- evalExpr r
  return $ l' + r'
evalExpr (EDiv l r) = do
  l' <- evalExpr l
  r' <- evalExpr r
  case safeDiv l' r' of
    Nothing -> Left "division by zero"
    Just x -> Right x
