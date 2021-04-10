module Compiler.Util (pathToComponent) where

import Data.Char

type AbsolutePath = String

type ProjectPath = String

pathToComponent :: ProjectPath -> AbsolutePath -> Maybe String
pathToComponent [] (a : as) = Just (toUpper a : slashToDash (removeFileExtension as))
pathToComponent (p : ps) (a : as)
  | p == a = pathToComponent ps as
  | otherwise = Nothing

removeFileExtension :: String -> String
removeFileExtension p = take (length p - 3) p

slashToDash :: String -> String
slashToDash [] = []
slashToDash ('/' : p : ps) = toUpper p : slashToDash ps
slashToDash (p : ps) = p : slashToDash ps