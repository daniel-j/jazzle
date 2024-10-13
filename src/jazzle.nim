
import raylib, rlgl
import jazzle/tileset
import jazzle/level

const
  screenWidth = 800
  screenHeight = 600

type
  GrayAlpha {.packed.} = object
    gray: uint8
    alpha: uint8

var lastCurrentMonitor: int32 = 0
var currentTileset: Tileset
var currentLevel: Level
var texture: Texture2D
var paletteTexture: Texture2D
var layerTexture: Texture2D
var shader: Shader
var paletteLoc: ShaderLocation
var tilesetLoc: ShaderLocation
var layerSize: ShaderLocation


proc monitorChanged(monitor: int32) =
  setTargetFPS(getMonitorRefreshRate(monitor)) # Set our game to run at display framerate frames-per-second

proc updateDrawFrame {.cdecl.} =
  # Update and draw
  # --------------------------------------------------------------------------------------
  let mousePos = getMousePosition()
  beginDrawing()
  clearBackground(Color(r: 72, g: 48, b: 168, a: 255))
  shaderMode(shader):
    setShaderValueTexture(shader, paletteLoc, paletteTexture)
    setShaderValueTexture(shader, tilesetLoc, texture)
    setShaderValue(shader, layerSize, Vector2(x: currentLevel.layers[3].width.float, y: currentLevel.layers[3].height.float))
    drawTexture(layerTexture, Rectangle(x: 0, y: 0, width: currentLevel.layers[3].width.float32, height: currentLevel.layers[3].height.float32), Rectangle(x: -mousePos.x, y: -mousePos.y, width: currentLevel.layers[3].width.float32 * 32, height: currentLevel.layers[3].height.float32 * 32), Vector2(x: 0, y: 0), 0, White)
  drawText("Congrats! You created your first window!", 190, 100, 20, LightGray)
  drawText("FPS: " & $getFPS(), 190, 130, 20, Gold)
  endDrawing()
  # --------------------------------------------------------------------------------------


proc main =

  # initialize window
  const f = flags(WindowResizable, VsyncHint)
  setConfigFlags(f)
  initWindow(screenWidth, screenHeight, "JazzLE")
  defer: closeWindow()
  setExitKey(KeyboardKey.Null)
  setWindowMinSize(320, 100)
  # maximizeWindow()

  const tileShaderFs = staticRead("jazzle/shaders/tile.fs")
  let tilesetData = "assets/TubeNite.j2t"
  let levelData = "assets/Tube2.j2l"

  currentTileset = Tileset()
  currentTileset.load(tilesetData)

  const format = UncompressedGrayAlpha
  const width = 64 * 32
  const height = 64 * 32
  var imageData = newSeq[GrayAlpha](width * height)
  var layerData = newSeq[GrayAlpha]()

  for i in 1..<currentTileset.maxTiles.int:
    let tileId = currentTileset.tileOffsets[i].image
    let transOffset = currentTileset.tileOffsets[i].transOffset
    for j in 0..<1024:
      let x = (i mod 64) * 32 + (j mod 32)
      let y = (i div 64) * 32 + (j div 32)
      let index = x + y * width
      imageData[index].gray = currentTileset.tileImage[tileId][j]
      imageData[index].alpha = if currentTileset.tileTransMask[transOffset][j]: 255'u8 else: 0'u8

  texture = Texture2D(
    id: rlgl.loadTexture(imageData[0].addr, width.int32, height.int32, format.int32, 1),
    width: width.int32,
    height: height.int32,
    mipmaps: 1,
    format: format
  )
  imageData.reset()

  paletteTexture = Texture2D(
    id: rlgl.loadTexture(currentTileset.palette[0].addr, 256.int32, 1.int32, UncompressedR8g8b8a8.int32, 1),
    width: 256.int32,
    height: 1.int32,
    mipmaps: 1,
    format: UncompressedR8g8b8a8
  )

  currentLevel = Level()
  if currentLevel.load(levelData):
    let layer = currentLevel.layers[3]
    layerData.setLen(layer.width * layer.height)
    if layer.haveAnyTiles:
      for j, wordId in layer.wordMap.pairs:
        if wordId == 0: continue
        let word = currentLevel.dictionary[wordId]
        for t, tile in word.pairs:
          if tile.tileId == 0: continue
          if ((j * 4 + t) mod layer.realWidth.int) >= layer.width.int: continue
          let tileId = tile.tileId
          let x = ((j * 4 + t) mod layer.realWidth.int)
          let y = ((j * 4 + t) div layer.realWidth.int)
          let index = x + y * layer.width.int
          layerData[index].gray = uint8 tileId mod 64
          layerData[index].alpha = uint8 tileId div 64

    layerTexture = Texture2D(
      id: rlgl.loadTexture(layerData[0].addr, layer.width.int32, layer.height.int32, UncompressedGrayAlpha.int32, 1),
      width: layer.width.int32,
      height: layer.height.int32,
      mipmaps: 1,
      format: UncompressedGrayAlpha
    )
    layerData.reset()

  let shaderPrefix = case rlgl.getVersion():
  of Opengl33: "#version 330\nout vec4 finalColor;"
  else: "#version 100\nprecision mediump float;\n#define texture texture2D\n#define finalColor gl_FragColor\n#define in varying\n"

  shader = loadShaderFromMemory("", shaderPrefix & tileShaderFs)
  paletteLoc = getShaderLocation(shader, "texture1")
  tilesetLoc = getShaderLocation(shader, "texture2")
  layerSize = getShaderLocation(shader, "layerSize")

  when defined(emscripten):
    emscriptenSetMainLoop(updateDrawFrame, 0, 1)
  else:
    # lastCurrentMonitor = getCurrentMonitor()
    # monitorChanged(lastCurrentMonitor)

    # Main game loop
    while not windowShouldClose(): # Detect window close button or ESC key
      # let currentMonitor = getCurrentMonitor()
      # if lastCurrentMonitor != currentMonitor:
      #   lastCurrentMonitor = currentMonitor
      #   monitorChanged(currentMonitor)

      updateDrawFrame()

main()
