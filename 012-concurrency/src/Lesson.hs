module Lesson
  ( bumpManyTimes
  , parPair
  , Account
  , mkAccount
  , balance
  , transfer
  ) where

import Control.Concurrent.STM (STM, TVar)

bumpManyTimes :: Int -> Int -> IO Int
bumpManyTimes = undefined

parPair :: IO a -> IO b -> IO (a, b)
parPair = undefined

newtype Account = Account (TVar Int)

mkAccount :: Int -> STM Account
mkAccount = undefined

balance :: Account -> STM Int
balance = undefined

transfer :: Int -> Account -> Account -> STM ()
transfer = undefined
