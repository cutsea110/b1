module B1.Graphics.Rendering.OpenGL.Shapes
  ( drawRoundedRectangle
  , drawSquarePlaceholder
  ) where

import Graphics.Rendering.OpenGL

import B1.Data.Range
import B1.Graphics.Rendering.OpenGL.Utils

-- | Draws a rounded rectangle around (0, 0).
drawRoundedRectangle :: GLfloat -> GLfloat -> GLfloat -> Int -> IO ()
drawRoundedRectangle width height cornerRadius cornerVertices =
  renderPrimitive LineLoop $ do
    mapM_ vertex (getRoundedRectangleVertices width height
        cornerRadius cornerVertices)

getRoundedRectangleVertices :: GLfloat -> GLfloat -> GLfloat -> Int
    -> [Vertex2 GLfloat]
getRoundedRectangleVertices width height cornerRadius cornerVertices =
  let lowerLeftRadians = linearRange (3 * pi / 2) pi cornerVertices
      upperLeftRadians = linearRange pi (pi / 2) cornerVertices
      upperRightRadians = linearRange (pi / 2) 0 cornerVertices
      lowerRightRadians = linearRange (2 * pi) (3 * pi / 2) cornerVertices

      circlePoint :: GLfloat -> GLfloat -> (GLfloat, GLfloat)
      circlePoint radius radians = (radius * realToFrac (cos radians),
          radius * realToFrac (sin radians))

      point2Vertex :: (GLfloat, GLfloat) -> Vertex2 GLfloat
      point2Vertex (x, y) = vertex2 x y

      lowerLeftTranslate :: (GLfloat, GLfloat) -> (GLfloat, GLfloat)
      lowerLeftTranslate (x, y) = (x - width / 2 + cornerRadius,
          y - height / 2 + cornerRadius)

      upperLeftTranslate :: (GLfloat, GLfloat) -> (GLfloat, GLfloat)
      upperLeftTranslate (x, y) = (x - width / 2 + cornerRadius,
          y + height / 2 - cornerRadius)

      upperRightTranslate :: (GLfloat, GLfloat) -> (GLfloat, GLfloat)
      upperRightTranslate (x, y) = (x + width / 2 - cornerRadius,
          y + height / 2 - cornerRadius)
  
      lowerRightTranslate :: (GLfloat, GLfloat) -> (GLfloat, GLfloat)
      lowerRightTranslate (x, y) = (x + width / 2 - cornerRadius,
          y - height / 2 + cornerRadius)

      lowerLeftVertices = map (point2Vertex . lowerLeftTranslate
          . circlePoint cornerRadius) lowerLeftRadians
      upperLeftVertices = map (point2Vertex . upperLeftTranslate
          . circlePoint cornerRadius) upperLeftRadians
      upperRightVertices = map (point2Vertex . upperRightTranslate
          . circlePoint cornerRadius) upperRightRadians
      lowerRightVertices = map (point2Vertex . lowerRightTranslate
          . circlePoint cornerRadius) lowerRightRadians

  in lowerLeftVertices ++ upperLeftVertices ++ upperRightVertices
      ++ lowerRightVertices

drawSquarePlaceholder :: IO ()
drawSquarePlaceholder = do
  renderPrimitive LineLoop $ do
    vertex $ vertex2 (-1) (-1)
    vertex $ vertex2 (-1) 1
    vertex $ vertex2 1 1
    vertex $ vertex2 1 (-1)

  renderPrimitive Lines $ do
    vertex $ vertex2 (-1) 1
    vertex $ vertex2 1 (-1)
    vertex $ vertex2 (-1) (-1)
    vertex $ vertex2 1 1
