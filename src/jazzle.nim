
import raylib, rlgl, raygui
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
var paletteTexture: Texture2D
var tilesetImage: Texture2D
var tilesetIndex10Texture: Texture2D
var tilesetIndex64Texture: Texture2D
var layerTextures: seq[Texture2D]
var tilesetMapData: seq[uint16]
var animGrid: Texture2D
var shader: Shader
var paletteLoc: ShaderLocation
var tilesetImageLoc: ShaderLocation
var layerSizeLoc: ShaderLocation
var tilesetMapLoc: ShaderLocation
var camera: Camera2D
var animsUpdated = true
var mouseUpdated = true
var lastMousePos = Vector2()

var scrollParallaxPos = Rectangle(x: 335, y: 20, width: 1, height: 1)
var scrollParallaxView = Rectangle()
var scrollParallax = Vector2()

var scrollTilesetPos = Rectangle(x: 0, y: 20, width: 334, height: 1)
var scrollTilesetView = Rectangle()
var scrollTileset = Vector2()

proc monitorChanged(monitor: int32) =
  setTargetFPS(getMonitorRefreshRate(monitor)) # Set our game to run at display framerate frames-per-second

proc drawTiles(texture: Texture2D; destRect: Rectangle) =
  let layerSize = Vector2(x: texture.width.float, y: texture.height.float)
  shader.setShaderValue(layerSizeLoc, layerSize)
  drawTexture(texture, Rectangle(x: 0, y: 0, width: layerSize.x, height: layerSize.y), destRect, Vector2(), 0, White)


proc update() =
  let t = getTime()
  let mousePos = getMousePosition()
  if lastMousePos != mousePos:
    mouseUpdated = true
  lastMousePos = mousePos
  camera.zoom = 1.0
  #camera.offset.x = -mousePos.x
  #camera.offset.y = -mousePos.y

  animsUpdated = currentLevel.updateAnims(t) or animsUpdated

  if animsUpdated:
    let offset = currentLevel.animOffset.int
    for i, anim in currentLevel.anims:
      let tile = currentLevel.calculateAnimTile(i.uint16)
      let tileId = tile.tileId + tile.hflipped.uint16 * 0x1000 + tile.vflipped.uint16 * 0x2000
      tilesetMapData[offset + i] = tileId
    rlgl.updateTexture(tilesetIndex64Texture.id, 0, 0, 64, 64, UncompressedGrayAlpha, tilesetMapData[0].addr)
    animsUpdated = false

proc draw() =
  # if not animsUpdated and not mouseUpdated: return
  beginDrawing()
  clearBackground(getColor(guiGetStyle(GuiControl.Default, BackgroundColor.cint).uint32))

  let tilesetRec = Rectangle(x: 0, y: 0, width: float32 tilesetIndex10Texture.width * 32, height: float32 tilesetIndex10Texture.height * 32)


  scrollTilesetPos.height = getRenderHeight().float - scrollTilesetPos.y - 128

  var mouseCell = Vector2()

  discard guiScrollPanel(scrollTilesetPos, "Tileset".cstring, tilesetRec, scrollTileset, scrollTilesetView)
  scissorMode(scrollTilesetView.x.int32, scrollTilesetView.y.int32, scrollTilesetView.width.int32, scrollTilesetView.height.int32):
    clearBackground(Color(r: 72, g: 48, b: 168, a: 255))
    discard guiGrid(Rectangle(x: scrollTilesetView.x + scrollTileset.x, y: scrollTilesetView.y + scrollTileset.y, width: tilesetRec.width, height: tilesetRec.height), nil, 32*5, 5, mouseCell)
    shaderMode(shader):
      drawTiles(tilesetIndex10Texture, Rectangle(
        x: scrollTilesetView.x + scrollTileset.x,
        y: scrollTilesetView.y + scrollTileset.y,
        width: tilesetRec.width,
        height: tilesetRec.height
      ))

  let parallaxRec = Rectangle(x: 0, y: 0, width: layerTextures[3].width.float32*32, height: layerTextures[3].height.float32*32)

  scrollParallaxPos.width = getRenderWidth().float - scrollParallaxPos.x
  scrollParallaxPos.height = getRenderHeight().float - scrollParallaxPos.y

  discard guiScrollPanel(scrollParallaxPos, "Parallax View", parallaxRec, scrollParallax, scrollParallaxView)
  scissorMode(scrollParallaxView.x.int32, scrollParallaxView.y.int32, scrollParallaxView.width.int32, scrollParallaxView.height.int32):
    clearBackground(Color(r: 72, g: 48, b: 168, a: 255))
    for i in countdown(currentLevel.layers.len - 1, 0):
      if i == 3:
        discard guiGrid(Rectangle(x: scrollParallaxView.x + scrollParallax.x, y: scrollParallaxView.y + scrollParallax.y, width: parallaxRec.width, height: parallaxRec.height), nil, 32*4, 4, mouseCell)
      let layer = currentLevel.layers[i].addr
      let layerTexture = layerTextures[i].addr
      let w = layerTexture.width * 32
      let h = layerTexture.height * 32

      var rect = Rectangle(width: float32 w, height: float32 h)

      shaderMode(shader):
        var x = scrollParallax.x.int * currentLevel.layers[i].speedX div 65536
        while layer.properties.tileWidth and x > 0: x -= w # step back outside left edge
        while x < scrollParallaxView.width.int: # until right edge
          var y = scrollParallax.y.int * currentLevel.layers[i].speedY div 65536
          while layer.properties.tileHeight and y > 0: y -= h # step back outside top edge
          while y < scrollParallaxView.height.int: # until bottom edge
            rect.x = float32 scrollParallaxView.x.int + x
            rect.y = float32 scrollParallaxView.y.int + y
            drawTiles(layerTexture[], rect)
            if not layer.properties.tileHeight: break
            y += h
          if not layer.properties.tileWidth: break
          x += w

      # drawRectangleLines(Rectangle(
      #   x: scrollParallaxView.x + scrollParallaxView.width / 2 - 640 / 2,
      #   y: scrollParallaxView.y + scrollParallaxView.height / 2 - 480 / 2,
      #   width: 640,
      #   height: 480
      # ), 1, White)

  shaderMode(shader):
    drawTiles(animGrid, Rectangle(x: 0, y: float32 getRenderHeight()-animGrid.height*32, width: float32 animGrid.width*32, height: float32 animGrid.height*32))

  # discard GuiButton(Rectangle(x: 25, y: 255, width: 125, height: 30), GuiIconText(ICON_FILE_SAVE.cint, "Save File".cstring))
  # let mbox = GuiMessageBox(Rectangle(x: 85, y: 70, width: 250, height: 100), "#191#Message Box", "Hi! This is a message!", "Nice;Cool")
  # if mbox != -1: echo mbox

  drawText("FPS: " & $getFPS(), 5, 1, 20, Gold)

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
  let tileset10Height = (currentTileset.numTiles.int + 9) div 10
  tilesetMapData.setLen(max(10 * tileset10Height, 64 * 64))

  for i in 1..<currentTileset.numTiles.int:
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

  tilesetImage = Texture2D(
    id: rlgl.loadTexture(imageData[0].addr, width.int32, height.int32, format.int32, 1),
    width: width.int32,
    height: height.int32,
    mipmaps: 1,
    format: format
  )
  imageData.reset()

  tilesetIndex10Texture = Texture2D(
    id: rlgl.loadTexture(tilesetMapData[0].addr, 10, tileset10Height.int32, UncompressedGrayAlpha.int32, 1),
    width: 10,
    height: tileset10Height.int32,
    mipmaps: 1,
    format: UncompressedGrayAlpha
  )

  tilesetIndex64Texture = Texture2D(
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
    layerTextures.setLen(8)
    for i in 0 ..< 8:
      let layer = currentLevel.layers[i].addr
      var layerData = newSeq[uint16](layer.width * layer.height)
      let realWidth = ((layer.realWidth + 3) div 4) * 4
      if layer.haveAnyTiles:
        for j, wordId in layer.wordMap.pairs:
          if wordId == 0: continue
          let word = currentLevel.dictionary[wordId]
          for t, tile in word.pairs:
            if tile.tileId == 0: continue
            if ((j * 4 + t) mod realWidth.int) >= layer.width.int: continue
            var tileId = tile.tileId
            if tile.animated: tileId += currentLevel.animOffset
            tileId += tile.hflipped.uint16 * 0x1000 + tile.vflipped.uint16 * 0x2000
            let x = ((j * 4 + t) mod realWidth.int)
            let y = ((j * 4 + t) div realWidth.int)
            let index = x + y * layer.width.int
            layerData[index] = tileId

      layerTextures[i] = Texture2D(
        id: rlgl.loadTexture(layerData[0].addr, layer.width.int32, layer.height.int32, UncompressedGrayAlpha.int32, 1),
        width: layer.width.int32,
        height: layer.height.int32,
        mipmaps: 1,
        format: UncompressedGrayAlpha
      )

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
    animsUpdated = true

  let shaderPrefix = case rlgl.getVersion():
  of OpenGl43, OpenGl33: "#version 330\nout vec4 finalColor;\n"
  of OpenGlEs20: "#version 100\nprecision mediump float;\n#define texture texture2D\n#define finalColor gl_FragColor\n#define in varying\n"
  of OpenGlEs30: "#version 300 es\nprecision mediump float;\nout vec4 finalColor;\n"
  else: ""

  echo rlgl.getVersion()

  shader = loadShaderFromMemory("", shaderPrefix & tileShaderFs)
  paletteLoc = shader.getShaderLocation("texture1")
  tilesetImageLoc = shader.getShaderLocation("texture2")
  tilesetMapLoc = shader.getShaderLocation("texture3")
  layerSizeLoc = shader.getShaderLocation("layerSize")

  shader.setShaderValueTexture(paletteLoc, paletteTexture)
  shader.setShaderValueTexture(tilesetImageLoc, tilesetImage)
  shader.setShaderValueTexture(tilesetMapLoc, tilesetIndex64Texture)

  # guiLoadStyleJungle()

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
