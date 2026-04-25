module Main (main) where

import Control.Exception (ArithException (DivideByZero), evaluate, try)
import Data.IORef (newIORef, readIORef)
import Test.Hspec

import Lesson

main :: IO ()
main = hspec $ do
  describe "newCounter" $ do
    it "初期値は 0" $ do
      (readN, _) <- newCounter
      n <- readN
      n `shouldBe` 0
    it "increment で +1" $ do
      (readN, incr) <- newCounter
      incr
      incr
      incr
      n <- readN
      n `shouldBe` 3

  describe "safeDiv / tryDiv" $ do
    it "通常除算" $ do
      r <- safeDiv 10 2
      r `shouldBe` 5
    it "0 除算は例外" $
      safeDiv 1 0 `shouldThrow` (== DivideByZero)
    it "tryDiv は Right を返す（通常）" $ do
      r <- tryDiv 10 2
      r `shouldBe` Right 5
    it "tryDiv は Left を返す（0 除算）" $ do
      r <- tryDiv 1 0
      r `shouldBe` Left DivideByZero

  describe "withResource" $ do
    it "正常終了で start/end が両方記録される" $ do
      logRef <- newIORef []
      _ <- withResource logRef "db" (pure (42 :: Int))
      logs <- readIORef logRef
      logs `shouldSatisfy` ("start db" `elem`)
      logs `shouldSatisfy` ("end db" `elem`)
    it "例外でも end は記録される" $ do
      logRef <- newIORef []
      r <- try (withResource logRef "db" (evaluate (1 `div` 0)) :: IO Int)
      case (r :: Either ArithException Int) of
        Left _  -> pure ()
        Right _ -> expectationFailure "should have thrown"
      logs <- readIORef logRef
      logs `shouldSatisfy` ("end db" `elem`)
