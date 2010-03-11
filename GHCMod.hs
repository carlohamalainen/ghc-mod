module Main where

import Browse
import Check
import Control.Exception hiding (try)
import List
import Param
import Prelude hiding (catch)
import System.Console.GetOpt
import System.Environment (getArgs)
import System.IO

----------------------------------------------------------------

usage :: String
usage =    "ghc-mod version 0.2.0\n"
        ++ "Usage:\n"
        ++ "\t ghc-mod list\n"
        ++ "\t ghc-mod browse <module>\n"
        ++ "\t ghc-mod check <HaskellFile>\n"
        ++ "\t ghc-mod help\n"

----------------------------------------------------------------

defaultOptions :: Options
defaultOptions = Options { convert = toPlain
                         , ghc     = "ghc"
                         , ghci    = "ghci"
                         , ghcPkg  = "ghc-pkg"
                         }

argspec :: [OptDescr (Options -> Options)]
argspec = [ Option ['l'] ["tolisp"]
            (NoArg (\opts -> opts { convert = toLisp }))
            "print as a list of Lisp"
          , Option ['g'] ["ghc"]
            (ReqArg (\str opts -> opts { ghc = str }) "ghc")
            "GHC path"
          , Option ['i'] ["ghci"]
            (ReqArg (\str opts -> opts { ghci = str }) "ghci")
            "ghci path"
          , Option ['p'] ["ghc-pkg"]
            (ReqArg (\str opts -> opts { ghcPkg = str }) "ghc-pkg")
            "ghc-pkg path"
          ]

parseArgs :: [OptDescr (Options -> Options)] -> [String] -> (Options, [String])
parseArgs spec argv
    = case getOpt Permute spec argv of
        (o,n,[]  ) -> (foldl (flip id) defaultOptions o, n)
        (_,_,errs) -> error $ concat errs ++ usageInfo usage argspec

----------------------------------------------------------------

main :: IO ()
main = flip catch handler $ do
    args <- getArgs
    let (opt,cmdArg) = parseArgs argspec args
    res <- case cmdArg !! 0 of
      "browse" -> browseModule opt (cmdArg !! 1)
      "list"   -> listModules opt
      "check"  -> checkSyntax opt (cmdArg !! 1)
      _        -> error usage
    putStr res
  where
    handler :: ErrorCall -> IO ()
    handler _ = putStr usage

----------------------------------------------------------------
toLisp :: [String] -> String
toLisp ms = "(" ++ unwords quoted ++ ")\n"
    where
      quote x = "\"" ++ x ++ "\""
      quoted = map quote ms

toPlain :: [String] -> String
toPlain = unlines