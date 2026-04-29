module Lesson
  ( Validation (..),
    Person (..),
    validateName,
    validateAge,
    mkPerson,
  )
where

data Validation e a = Failure e | Success a
  deriving (Eq, Show)

instance Functor (Validation e) where
  fmap _ (Failure e) = Failure e
  fmap f (Success a) = Success $ f a

instance (Semigroup e) => Applicative (Validation e) where
  pure = Success
  Failure x <*> Failure y = Failure $ x <> y
  Failure x <*> Success _ = Failure x
  Success _ <*> Failure x = Failure x
  Success f <*> Success x = Success $ f x

data Person = Person
  { personName :: String,
    personAge :: Int
  }
  deriving (Eq, Show)

validateName :: String -> Validation [String] String
validateName name
  | name == "" = Failure ["name is empty"]
  | otherwise = Success name

validateAge :: Int -> Validation [String] Int
validateAge age
  | age < 0 = Failure ["age out of range"]
  | age >= 150 = Failure ["age out of range"]
  | otherwise = Success age

mkPerson :: String -> Int -> Validation [String] Person
mkPerson name age = Person <$> validateName name <*> validateAge age
