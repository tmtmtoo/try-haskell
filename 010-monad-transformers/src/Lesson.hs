module Lesson
  ( Inventory
  , decreaseStock
  , runStock
  , AppConfig (..)
  , decorate
  , runDecorate
  ) where

import Control.Monad.Except (ExceptT)
import Control.Monad.Reader (ReaderT)
import Control.Monad.State (State)

type Inventory = [(String, Int)]

decreaseStock :: String -> ExceptT String (State Inventory) Int
decreaseStock = undefined

runStock
  :: ExceptT String (State Inventory) a
  -> Inventory
  -> (Either String a, Inventory)
runStock = undefined

data AppConfig = AppConfig
  { prefix :: String
  , suffix :: String
  }
  deriving (Eq, Show)

decorate :: String -> ReaderT AppConfig (Either String) String
decorate = undefined

runDecorate :: String -> AppConfig -> Either String String
runDecorate = undefined
