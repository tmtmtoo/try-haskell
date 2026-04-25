module Lesson
  ( Email
  , mkEmail
  , unEmail
  , ParseError (..)
  , parseAssoc
  , composeAll
  , tally
  ) where

import Data.Map.Strict (Map)
import Data.Text (Text)

-- 注意: Email のコンストラクタは export していない（Smart Constructor）。
newtype Email = Email Text
  deriving (Eq, Show)

mkEmail :: Text -> Either String Email
mkEmail = undefined

unEmail :: Email -> Text
unEmail (Email t) = t

data ParseError
  = MissingField String
  | InvalidValue String
  deriving (Eq, Show)

parseAssoc :: [Text] -> [Text] -> Either ParseError [(Text, Text)]
parseAssoc = undefined

composeAll :: [a -> a] -> a -> a
composeAll = undefined

tally :: Ord a => [a] -> Map a Int
tally = undefined
