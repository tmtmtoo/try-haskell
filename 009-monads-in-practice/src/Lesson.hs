module Lesson
  ( push,
    pop,
    Config (..),
    urlR,
    tracedFact,
    pythagoreans,
    sumST,
  )
where

import Control.Monad.Reader (Reader, asks)
import Control.Monad.ST (runST)
import Control.Monad.State (MonadState (get, put), State, modify)
import Control.Monad.Writer (MonadWriter (tell), Writer)
import Data.STRef (modifySTRef, newSTRef, readSTRef)

push :: Int -> State [Int] ()
push x = modify (x :)

pop :: State [Int] (Maybe Int)
pop = do
  xs <- get
  case xs of
    [] -> pure Nothing
    (h : t) -> put t >> pure (Just h)

data Config = Config
  { hostname :: String,
    port :: Int
  }
  deriving (Eq, Show)

urlR :: Reader Config String
urlR = do
  h <- asks hostname
  p <- asks port
  pure $ "http://" ++ h ++ ":" ++ show p

tracedFact :: Int -> Writer [String] Int
tracedFact 0 = do
  tell ["fact 0 = 1"]
  pure 1
tracedFact x = do
  tell ["calling fact" ++ show x]
  y <- tracedFact (x - 1)
  pure $ x * y

pythagoreans :: Int -> [(Int, Int, Int)]
pythagoreans x = do
  a <- [1 .. x]
  b <- [a .. x]
  c <- [b .. x]
  if sq a + sq b == sq c
    then pure (a, b, c)
    else []
  where
    sq n = n * n

sumST :: [Int] -> Int
sumST xs = runST $ do
  ref <- newSTRef 0
  mapM_ (\x -> modifySTRef ref (+ x)) xs
  readSTRef ref
