module Lesson
  ( Validation (..)
  , Person (..)
  , validateName
  , validateAge
  , mkPerson
  ) where

data Validation e a = Failure e | Success a
  deriving (Eq, Show)

instance Functor (Validation e) where
  fmap = undefined

instance Semigroup e => Applicative (Validation e) where
  pure  = undefined
  (<*>) = undefined

data Person = Person
  { personName :: String
  , personAge  :: Int
  }
  deriving (Eq, Show)

validateName :: String -> Validation [String] String
validateName = undefined

validateAge :: Int -> Validation [String] Int
validateAge = undefined

mkPerson :: String -> Int -> Validation [String] Person
mkPerson = undefined
