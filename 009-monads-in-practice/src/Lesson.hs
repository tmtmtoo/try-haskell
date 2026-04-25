module Lesson
  ( push
  , pop
  , Config (..)
  , urlR
  , tracedFact
  , pythagoreans
  , sumST
  ) where

import Control.Monad.Reader (Reader)
import Control.Monad.State (State)
import Control.Monad.Writer (Writer)

push :: Int -> State [Int] ()
push = undefined

pop :: State [Int] (Maybe Int)
pop = undefined

data Config = Config
  { hostname :: String
  , port     :: Int
  }
  deriving (Eq, Show)

urlR :: Reader Config String
urlR = undefined

tracedFact :: Int -> Writer [String] Int
tracedFact = undefined

pythagoreans :: Int -> [(Int, Int, Int)]
pythagoreans = undefined

sumST :: [Int] -> Int
sumST = undefined
