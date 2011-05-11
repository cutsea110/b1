module B1.Program.Chart.Main
  ( main
  ) where

import Control.Monad
import Data.IORef
import Graphics.Rendering.FTGL
import Graphics.Rendering.OpenGL
import Graphics.UI.GLFW

import B1.Data.Action
import B1.Program.Chart.Dirty
import B1.Program.Chart.Resources
import B1.Program.Chart.Screen

main :: IO ()
main = do
  initialize
  createWindow
  initClientState
  loadTextures

  resourcesRef <- createInitialResources
  windowDirtyRef <- newIORef False
  windowSizeCallback $= myWindowSizeCallback resourcesRef windowDirtyRef

  drawLoop resourcesRef windowDirtyRef drawScreen

  -- TODO: Need to clean up shader resources before leaving?
  closeWindow
  terminate

createWindow :: IO ()
createWindow = do
  openWindow (Size 400 400) [DisplayAlphaBits 8] Window
  windowTitle $= "B1"

initClientState :: IO ()
initClientState = do
  blendFunc $= (SrcAlpha, One)
  blend $= Enabled
  clientState VertexArray $= Enabled
  clientState ColorArray $= Enabled

loadTextures :: IO ()
loadTextures = do
  mapM_ (uncurry bindTexture) (zip [0 ..] fileNames)
  texture Texture2D $= Disabled
  where
    fileNames =
      [ "res/add-normal.tga"
      , "res/add-hover.tga"
      , "res/add-press.tga"
      , "res/remove-normal.tga"
      , "res/remove-hover.tga"
      , "res/remove-press.tga"
      ]

bindTexture :: Int -> String -> IO ()
bindTexture textureNumber fileName = do
  textureBinding Texture2D $= Just (TextureObject (fromIntegral textureNumber))
  textureFilter Texture2D $= ((Linear', Nothing), Linear')
  loadResult <- loadTexture2D fileName [BuildMipMaps]
  putStrLn $ "Loading texture " ++ fileName ++ ": " ++ show loadResult

-- | Initialize the resources that should be immutable like fonts.
-- The other fields will be filled in later.
createInitialResources :: IO (IORef Resources)
createInitialResources = do
  font <- createTextureFont "res/fonts/orbitron/orbitron-medium.ttf"
  program <- loadProgram ["res/shaders/vertex-shader.txt"]
      ["res/shaders/fragment-shader.txt"]
  newIORef $ newResources font program

loadProgram :: [FilePath] -> [FilePath] -> IO Program
loadProgram vertexShaderPaths fragmentShaderPaths= do
  vertexShaders <- mapM readAndCompileShader vertexShaderPaths
  fragmentShaders <- mapM readAndCompileShader fragmentShaderPaths
  createProgram vertexShaders fragmentShaders

readAndCompileShader :: Shader s => FilePath -> IO s
readAndCompileShader filePath = do
  src <- readFile filePath
  [shader] <- genObjectNames 1
  shaderSource shader $= [src]
  compileShader shader
  ok <- get $ compileStatus shader
  infoLog <- get $ shaderInfoLog shader
  putStrLn $ "Shader info log: " ++ infoLog
  unless ok $ do
    deleteObjectNames [shader]
    ioError $ userError "Shader compilation failed"
  return shader

createProgram :: [VertexShader] -> [FragmentShader] -> IO Program
createProgram vertexShader fragmentShader = do
  [program] <- genObjectNames 1
  attachedShaders program $= (vertexShader, fragmentShader)
  linkProgram program
  ok <- get $ linkStatus program
  infoLog <- get $ programInfoLog program
  putStrLn $ "Program info log: " ++ infoLog
  unless ok $ do
    deleteObjectNames [program]
    ioError $ userError "Program linking failed"
  return program

myWindowSizeCallback :: IORef Resources -> IORef Dirty -> Size -> IO ()
myWindowSizeCallback resourcesRef windowDirtyRef size@(Size width height) = do
  viewport $= (Position 0 0, size)
  modifyIORef resourcesRef $ updateWindowSize size
  writeIORef windowDirtyRef True

  -- Use orthographic projection, since it is easier to position text.
  -- (0, 0) is lower left corner of the screen.
  matrixMode $= Projection
  loadIdentity
  ortho2D 0 (realToFrac width) 0 (realToFrac height)

  matrixMode $= Modelview 0
  loadIdentity

drawLoop :: IORef Resources -> IORef Dirty
    -> (Resources -> IO (Action Resources Dirty, Dirty)) -> IO ()
drawLoop resourcesRef windowDirtyRef action = do
  clear [ColorBuffer, DepthBuffer]

  refreshMousePosition resourcesRef
      >>= refreshMouseButtonState
      >>= refreshMouseWheelPosition
      >>= refreshKeysPressed
  resources <- readIORef resourcesRef
--  print resources

  (Action nextAction, isContentDirty) <- action resources

  swapBuffers
  sleep 0.001

  -- Screen may have been resized after swapBuffers even though
  -- there are no dirty animations.
  isWindowDirty <- readIORef windowDirtyRef
  writeIORef windowDirtyRef False

  control <- getKey LCTRL
  c <- getKey 'C'
  unless (control == Press && c == Press) $ do
    -- TODO: Need to do the same for key presses. 
    let isMouseStateDirty = isMouseButtonPressed resources ButtonLeft
            || isMouseWheelMoving resources

    -- If the screen is not dirty, then wait for events rather than drawing
    -- the same frame again and pegging the CPU to a 100%.
    unless (isWindowDirty || isContentDirty || isMouseStateDirty) $ do
--      putStrLn $ "Waiting isWindowDirty: " ++ show isWindowDirty
--          ++ " isContentDirty: " ++ show isContentDirty
--          ++ " isMouseStateDirty: " ++ show isMouseStateDirty
      waitEvents

    drawLoop resourcesRef windowDirtyRef nextAction

refreshMousePosition :: IORef Resources -> IO (IORef Resources)
refreshMousePosition resourcesRef = do
  position <- get mousePos
  modifyIORef resourcesRef
      (invertMousePositionY . updateMousePosition position)
  return resourcesRef

refreshMouseButtonState :: IORef Resources -> IO (IORef Resources)
refreshMouseButtonState resourcesRef = do
  leftState <- getMouseButton ButtonLeft
  rightState <- getMouseButton ButtonRight
  let keyStates = [(ButtonLeft, leftState), (ButtonRight, rightState)]
      pressedButtons = (map fst . filter ((== Press) . snd)) keyStates
      releasedButtons = (map fst . filter ((== Release) . snd)) keyStates
  modifyIORef resourcesRef $
      updateMouseButtonState pressedButtons releasedButtons
  return resourcesRef

refreshMouseWheelPosition :: IORef Resources -> IO (IORef Resources)
refreshMouseWheelPosition resourcesRef = do
  position <- get mouseWheel
  modifyIORef resourcesRef $ updateMouseWheelPosition position
  return resourcesRef

refreshKeysPressed :: IORef Resources -> IO (IORef Resources)
refreshKeysPressed resourcesRef = do
  updatePressed resourcesRef getKey keys Press updateKeysPressed
  return resourcesRef
  where
    alphaKeys = map CharKey ['A'..'Z']
    specialKeys = map SpecialKey [ENTER, BACKSPACE, ESC]
    keys = alphaKeys ++ specialKeys

updatePressed :: IORef Resources -> (a -> IO KeyButtonState)
    -> [a] -> KeyButtonState -> ([a] -> Resources -> Resources) -> IO ()
updatePressed resourcesRef ioFunction values buttonState updateFunction = do
  states <- mapM ioFunction values
  let indexedStates = zip values states
      matchingStates = filter ((== buttonState) . snd) indexedStates
      matchingValues = map fst matchingStates
  modifyIORef resourcesRef $ updateFunction matchingValues

