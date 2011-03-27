module B1.Program.Chart.Config
  ( Config (..)
  , readConfig
  , writeConfig
  ) where

import System.IO

import B1.Data.String.Utils
import B1.Program.Chart.Symbol

data Config = Config
  { symbols :: [Symbol]
  } deriving (Eq, Show, Read)

readConfig :: FilePath -> IO Config
readConfig filePath = do
  contents <- readFile filePath
  return $ case (reads contents)::[(Config, String)] of
    ((config, _):_) -> config
    _ -> Config { symbols = [] }

writeConfig :: FilePath -> Config -> IO ()
writeConfig filePath config = writeFile filePath $ show config
