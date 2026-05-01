module Lesson
  ( Inventory,
    decreaseStock,
    runStock,
    AppConfig (..),
    decorate,
    runDecorate,
  )
where

import Control.Monad.Except (ExceptT, MonadError (throwError), runExceptT)
import Control.Monad.Reader (MonadTrans (lift), ReaderT (runReaderT), asks)
import Control.Monad.State (MonadState (get), State, modify, runState)

type Inventory = [(String, Int)]

decreaseStock :: String -> ExceptT String (State Inventory) Int
decreaseStock fruit = do
  inv <- get
  case lookup fruit inv of
    Just 0 -> throwError "out of stock"
    Just stock -> do
      modify $ map dec
      pure $ stock - 1
    Nothing -> throwError "not found"
  where
    dec (k, v)
      | k == fruit = (k, v - 1)
      | otherwise = (k, v)

runStock ::
  ExceptT String (State Inventory) a ->
  Inventory ->
  (Either String a, Inventory)
runStock m = runState $ runExceptT m

data AppConfig = AppConfig
  { prefix :: String,
    suffix :: String
  }
  deriving (Eq, Show)

decorate :: String -> ReaderT AppConfig (Either String) String
decorate "" = lift $ Left "empty"
decorate s = do
  pref <- asks prefix
  suff <- asks suffix
  pure $ pref ++ s ++ suff

runDecorate :: String -> AppConfig -> Either String String
runDecorate s cfg = runReaderT (decorate s) cfg
