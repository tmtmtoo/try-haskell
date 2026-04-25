module Main (main) where

import qualified Data.Map.Strict as Map
import qualified Data.Text as T
import Test.Hspec

import Lesson

main :: IO ()
main = hspec $ do
  describe "Email Smart Constructor" $ do
    it "@ ありで Right" $
      fmap unEmail (mkEmail (T.pack "a@b.com")) `shouldBe` Right (T.pack "a@b.com")
    it "@ なしで Left" $
      mkEmail (T.pack "abc") `shouldBe` Left "missing @"
    it "空は Left" $
      mkEmail (T.pack "") `shouldBe` Left "empty"

  describe "parseAssoc" $ do
    it "通常パース" $
      parseAssoc [T.pack "name", T.pack "age"] [T.pack "name=Alice", T.pack "age=30"]
        `shouldBe` Right [(T.pack "name", T.pack "Alice"), (T.pack "age", T.pack "30")]
    it "= 無しは InvalidValue" $
      parseAssoc [T.pack "k"] [T.pack "noequals"]
        `shouldBe` Left (InvalidValue "noequals")
    it "必須キーが足りないと MissingField" $
      parseAssoc [T.pack "name", T.pack "age"] [T.pack "name=Alice"]
        `shouldBe` Left (MissingField "age")

  describe "composeAll" $ do
    it "空リストは恒等" $ composeAll [] (5 :: Int) `shouldBe` 5
    it "[(+1),(*2)] 5 = 11 (右から適用)" $
      composeAll [(+ 1), (* 2)] (5 :: Int) `shouldBe` 11
    it "順序: 最初の関数が最後に適用される" $
      composeAll [(* 10), (+ 3)] (1 :: Int) `shouldBe` 40

  describe "tally" $ do
    it "頻度カウント" $
      tally "abracadabra"
        `shouldBe` Map.fromList [('a', 5), ('b', 2), ('c', 1), ('d', 1), ('r', 2)]
    it "空入力" $ tally ([] :: [Int]) `shouldBe` Map.empty
