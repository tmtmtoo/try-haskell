module Main (main) where

import Test.Hspec
import Lesson

sampleTree :: Tree Int
sampleTree = Node (Node Leaf 1 Leaf) 2 (Node Leaf 3 Leaf)

main :: IO ()
main = hspec $ do
  describe "Min'" $ do
    it "Min' 3 <> Min' 5 == Min' 3" $
      (Min' 3 <> Min' 5 :: Min' Int) `shouldBe` Min' 3
    it "Min' 'b' <> Min' 'a' == Min' 'a'" $
      (Min' 'b' <> Min' 'a') `shouldBe` Min' 'a'
    it "結合則" $
      ((Min' 1 <> Min' 5) <> Min' 3 :: Min' Int)
        `shouldBe` (Min' 1 <> (Min' 5 <> Min' 3))

  describe "Functor Tree" $ do
    it "fmap (+1)" $
      fmap (+ 1) sampleTree
        `shouldBe` Node (Node Leaf 2 Leaf) 3 (Node Leaf 4 Leaf)

  describe "Foldable Tree" $ do
    it "toList で中順走査" $
      foldr (:) [] sampleTree `shouldBe` [1, 2, 3]
    it "sum" $ sum sampleTree `shouldBe` 6
    it "length" $ length sampleTree `shouldBe` 3
    it "elem" $ (2 `elem` sampleTree) `shouldBe` True

  describe "Traversable Tree" $ do
    it "traverse Just は元の木" $
      traverse Just sampleTree `shouldBe` Just sampleTree
    it "途中で Nothing なら全体 Nothing" $
      let f n = if n == 2 then Nothing else Just n
       in traverse f sampleTree `shouldBe` Nothing

  describe "parseInts" $ do
    it "全部成功" $ parseInts ["1", "2", "3"] `shouldBe` Just [1, 2, 3]
    it "ひとつでも失敗" $ parseInts ["1", "x", "3"] `shouldBe` Nothing
    it "空リスト" $ parseInts [] `shouldBe` Just []

  describe "treeSum" $ do
    it "葉は 0" $ treeSum (Leaf :: Tree Int) `shouldBe` 0
    it "1+2+3 = 6" $ treeSum sampleTree `shouldBe` 6
