module B1.Program.Chart.Resources
  ( Resources (..)
  , updateKeyPress
  , updateMousePosition
  , updateWindowSize
  ) where

import Data.Maybe
import Graphics.Rendering.FTGL
import Graphics.Rendering.OpenGL
import Graphics.UI.GLFW

data Resources = Resources
  { font :: Font
  , windowWidth :: GLfloat
  , windowHeight :: GLfloat
  , sideBarWidth :: GLfloat
  , keyPress :: Maybe Key
  , mousePosition :: (GLfloat, GLfloat)
  } deriving (Show, Eq)

updateKeyPress :: Maybe Key -> Resources -> Resources
updateKeyPress maybeKeyPress resources = resources
  { keyPress = maybeKeyPress
  }

updateMousePosition :: Position -> Resources -> Resources
updateMousePosition (Position x y) resources = resources
  { mousePosition = (fromIntegral x, fromIntegral y)
  }

updateWindowSize :: Size -> Resources -> Resources
updateWindowSize (Size width height) resources = resources
  { windowWidth = fromIntegral width
  , windowHeight = fromIntegral height
  }


