module B1.Program.Chart.MiniChart
  ( MiniChartInput(..)
  , MiniChartOutput(..)
  , MiniChartState(..)
  , drawMiniChart
  , newMiniChartState
  ) where

import Data.Maybe
import Graphics.Rendering.OpenGL

import B1.Data.Range
import B1.Graphics.Rendering.FTGL.Utils
import B1.Graphics.Rendering.OpenGL.Box
import B1.Graphics.Rendering.OpenGL.Shapes
import B1.Graphics.Rendering.OpenGL.Utils
import B1.Program.Chart.Animation
import B1.Program.Chart.Colors
import B1.Program.Chart.Dirty
import B1.Program.Chart.Resources
import B1.Program.Chart.StockData
import B1.Program.Chart.Symbol

import qualified B1.Program.Chart.Header as H

data MiniChartInput = MiniChartInput
  { bounds :: Box
  , alpha :: GLfloat
  , symbol :: Symbol
  , inputState :: MiniChartState
  }

data MiniChartOutput = MiniChartOutput
  { outputState :: MiniChartState
  , isDirty :: Bool
  , removeChart :: Bool
  }

data MiniChartState = MiniChartState
  { stockData :: StockData
  , headerState :: H.HeaderState
  }

newMiniChartState :: Symbol -> IO MiniChartState
newMiniChartState symbol = do
  stockData <- newStockData symbol
  return $ MiniChartState
    { stockData = stockData
    , headerState = H.newHeaderState H.ShortStatus H.RemoveButton
    }

drawMiniChart :: Resources -> MiniChartInput -> IO MiniChartOutput
drawMiniChart resources
    MiniChartInput
      { bounds = bounds
      , alpha = alpha
      , symbol = symbol
      , inputState = inputState@MiniChartState
        { stockData = stockData
        , headerState = headerState
        }
      } = do
  preservingMatrix $ do
    color $ blue alpha
    drawRoundedRectangle (boxWidth paddedBox) (boxHeight paddedBox)
        cornerRadius cornerVertices

    let headerInput = H.HeaderInput
          { H.bounds = paddedBox
          , H.fontSize = 10
          , H.padding = 8
          , H.alpha = alpha
          , H.symbol = symbol
          , H.stockData = stockData
          , H.inputState = headerState
          }

    headerOutput <- H.drawHeader resources headerInput

    let H.HeaderOutput
          { H.outputState = outputHeaderState
          , H.clickedSymbol = maybeRemovedSymbol
          , H.isDirty = isHeaderDirty
          } = headerOutput

    return $ MiniChartOutput
      { isDirty = isHeaderDirty
      , removeChart = isJust maybeRemovedSymbol
      , outputState = inputState
        { headerState = outputHeaderState
        }
      }
  where
    cornerRadius = 5
    cornerVertices = 5
    padding = 5
    paddedBox = boxShrink bounds padding
