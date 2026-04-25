module Lesson
  ( newCounter
  , safeDiv
  , tryDiv
  , withResource
  ) where

import Control.Exception (ArithException)
import Data.IORef (IORef)

newCounter :: IO (IO Int, IO ())
newCounter = undefined

safeDiv :: Int -> Int -> IO Int
safeDiv = undefined

tryDiv :: Int -> Int -> IO (Either ArithException Int)
tryDiv = undefined

withResource :: IORef [String] -> String -> IO a -> IO a
withResource = undefined
