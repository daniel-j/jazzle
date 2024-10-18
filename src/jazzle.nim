
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
var tilesetMap: Texture2D
var tilesetMapData: seq[uint16]
var animGrid: Texture2D
var shader: Shader
var paletteLoc: ShaderLocation
var tilesetLoc: ShaderLocation
var layerSizeLoc: ShaderLocation
var tilesetMapLoc: ShaderLocation
var camera: Camera2D
var textureParallax: RenderTexture2D
var animsUpdated = false
var mouseUpdated = false
var lastMousePos = Vector2()

proc monitorChanged(monitor: int32) =
  setTargetFPS(getMonitorRefreshRate(monitor)) # Set our game to run at display framerate frames-per-second

proc update() =
  let mousePos = getMousePosition()
  if lastMousePos != mousePos:
    mouseUpdated = true
  lastMousePos = mousePos
  camera.zoom =1.0
  camera.offset.x = -mousePos.x
  camera.offset.y = -mousePos.y

  animsUpdated = currentLevel.updateAnims(getTime())

  if animsUpdated:
    let offset = currentLevel.animOffset.int
    for i, anim in currentLevel.anims:
      let tile = currentLevel.calculateAnimTile(i.uint16)
      let tileId = tile.tileId + tile.hflipped.uint16 * 0x1000 + tile.vflipped.uint16 * 0x2000
      tilesetMapData[offset + i] = tileId
    rlgl.updateTexture(tilesetMap.id, 0, 0, 64, 64, UncompressedGrayAlpha, tilesetMapData[0].addr)

proc draw() =
  # if not animsUpdated and not mouseUpdated: return
  beginDrawing()
  clearBackground(RayWhite)
  if animsUpdated:
    animsUpdated = false
  # textureMode(textureParallax):
  clearBackground(Color(r: 72, g: 48, b: 168, a: 255))
  shaderMode(shader):
    mode2D(camera):
      setShaderValueTexture(shader, paletteLoc, paletteTexture)
      setShaderValueTexture(shader, tilesetLoc, texture)
      setShaderValueTexture(shader, tilesetMapLoc, tilesetMap)
      setShaderValue(shader, layerSizeLoc, Vector2(x: layerTexture.width.float, y: layerTexture.height.float))
      drawTexture(layerTexture, Rectangle(x: 0, y: 0, width: layerTexture.width.float32, height: layerTexture.height.float32), Rectangle(x: 0, y: 0, width: float32 layerTexture.width*32, height: float32 layerTexture.height*32), Vector2(), 0, White)

  shaderMode(shader):
    setShaderValue(shader, layerSizeLoc, Vector2(x: animGrid.width.float32, y: animGrid.height.float32))
    drawTexture(animGrid, Rectangle(x: 0, y: 0, width: animGrid.width.float32, height: animGrid.height.float32), Rectangle(x: 0, y: float32 getRenderHeight()-animGrid.height*32, width: float32 animGrid.width*32, height: float32 animGrid.height*32), Vector2(), 0, White)

#  drawTexture(textureParallax.texture, Rectangle(x: 0, y: 0, width: textureParallax.texture.width.float32, height: -textureParallax.texture.height.float32), Vector2(), White)
  drawText("Congrats! You created your first window!", 190, 100, 20, LightGray)
  drawText("FPS: " & $getFPS(), 190, 130, 20, Gold)
  endDrawing()
  mouseUpdated = false


proc updateDrawFrame {.cdecl.} =
  update()
  draw()

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
  tilesetMapData.setLen(64 * 64)

  for i in 1..<currentTileset.maxTiles.int:
    let tileId = currentTileset.tileOffsets[i].image
    if tileId == 0: continue
    let transOffset = currentTileset.tileOffsets[i].transOffset
    tilesetMapData[i] = uint16 i
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

  tilesetMap = Texture2D(
    id: rlgl.loadTexture(tilesetMapData[0].addr, 64, 64, UncompressedGrayAlpha.int32, 1),
    width: 64,
    height: 64,
    mipmaps: 1,
    format: UncompressedGrayAlpha
  )

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
    var layerData = newSeq[uint16](layer.width * layer.height)
    if layer.haveAnyTiles:
      for j, wordId in layer.wordMap.pairs:
        if wordId == 0: continue
        let word = currentLevel.dictionary[wordId]
        for t, tile in word.pairs:
          if tile.tileId == 0: continue
          if ((j * 4 + t) mod layer.realWidth.int) >= layer.width.int: continue
          var tileId = tile.tileId
          if tile.animated: tileId += currentLevel.animOffset
          tileId += tile.hflipped.uint16 * 0x1000 + tile.vflipped.uint16 * 0x2000
          let x = ((j * 4 + t) mod layer.realWidth.int)
          let y = ((j * 4 + t) div layer.realWidth.int)
          let index = x + y * layer.width.int
          layerData[index] = tileId

    layerTexture = Texture2D(
      id: rlgl.loadTexture(layerData[0].addr, layer.width.int32, layer.height.int32, UncompressedGrayAlpha.int32, 1),
      width: layer.width.int32,
      height: layer.height.int32,
      mipmaps: 1,
      format: UncompressedGrayAlpha
    )
    layerData.reset()

    var animGridData = newSeq[uint16](currentLevel.anims.len)
    for i in 0 ..< currentLevel.anims.len:
      let tileId = currentLevel.animOffset.int + i
      animGridData[i] = uint16 tileId

    animGrid = Texture2D(
      id: rlgl.loadTexture(animGridData[0].addr, 10, int32 (currentLevel.anims.len+9) div 10, UncompressedGrayAlpha.int32, 1),
      width: 10,
      height: int32 (currentLevel.anims.len+9) div 10,
      mipmaps: 1,
      format: UncompressedGrayAlpha
    )
    animGridData.reset()

  let shaderPrefix = case rlgl.getVersion():
  of OpenGl43, OpenGl33: "#version 330\nout vec4 finalColor;\n"
  of OpenGlEs20: "#version 100\nprecision mediump float;\n#define texture texture2D\n#define finalColor gl_FragColor\n#define in varying\n"
  of OpenGlEs30: "#version 300 es\nprecision mediump float;\nout vec4 finalColor;\n"
  else: ""

  echo rlgl.getVersion()

  shader = loadShaderFromMemory("", shaderPrefix & tileShaderFs)
  paletteLoc = getShaderLocation(shader, "texture1")
  tilesetLoc = getShaderLocation(shader, "texture2")
  tilesetMapLoc = getShaderLocation(shader, "texture3")
  layerSizeLoc = getShaderLocation(shader, "layerSize")

  for anim in currentLevel.anims.mitems:
    anim.state.lastTime = getTime()

  textureParallax = loadRenderTexture(600, 400)

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
