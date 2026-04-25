module Main (main) where

import Test.Hspec
import Lesson

sampleTree :: Tree Int
sampleTree = Node (Node Leaf 1 Leaf) 2 (Node Leaf 3 Leaf)

main :: IO ()
main = hspec $ do
  describe "Functor Tree" $ do
    it "Leaf は不変" $ fmap (+ 1) (Leaf :: Tree Int) `shouldBe` Leaf
    it "fmap (+1) で全ノード +1" $
      fmap (+ 1) sampleTree
        `shouldBe` Node (Node Leaf 2 Leaf) 3 (Node Leaf 4 Leaf)
    it "Functor 則: fmap id == id" $
      fmap id sampleTree `shouldBe` sampleTree
    it "Functor 則: fmap (g . f) == fmap g . fmap f" $
      let f = (+ 1)
          g = (* 2)
       in fmap (g . f) sampleTree `shouldBe` (fmap g . fmap f) sampleTree

  describe "Functor Pair" $ do
    it "両要素に適用" $
      fmap (* 10) (Pair (1, 2 :: Int)) `shouldBe` Pair (10, 20)
    it "Functor 則: fmap id == id" $
      fmap id (Pair ('a', 'b')) `shouldBe` Pair ('a', 'b')

  describe "incrAll" $ do
    it "Maybe Int を +1" $ incrAll (Just 3) `shouldBe` Just 4
    it "[Int] を +1" $ incrAll [1, 2, 3 :: Int] `shouldBe` [2, 3, 4]

  describe "replaceAll" $ do
    it "Just _ を Just '!' に" $ replaceAll '!' (Just 'x') `shouldBe` Just '!'
    it "リストの中身を一律置換" $
      replaceAll (0 :: Int) [1, 2, 3 :: Int] `shouldBe` [0, 0, 0]
