
import raylib, rlgl, raygui
import jazzle/tileset
import jazzle/level
import std/math

import ./jazzle/gui

const
  screenWidth = 1280
  screenHeight = 720
  levelFile = "assets/Tube2.j2l"
  tileShaderFs = staticRead("jazzle/shaders/tile.fs")

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
var animsUpdated = true
var mouseUpdated = true
var lastMousePos = Vector2()

var scrollParallaxPos = Rectangle(x: 335, y: 20, width: 1, height: 1)
var scrollParallaxView = Rectangle()
var scrollParallax = Vector2()

var scrollTilesetPos = Rectangle(x: 0, y: 20, width: 334, height: 1)
var scrollTilesetView = Rectangle()
var scrollTileset = Vector2()

var scrollAnimPos = Rectangle(x: 0, y: 20, width: 334, height: 1)
var scrollAnimView = Rectangle()
var scrollAnim = Vector2()

type
  MainMenuValues = enum
    MenuNone
    MenuFileNew
    MenuFileOpen
    MenuLevelProperties

  MainMenu = Menu[MainMenuValues]

var mainMenu = MainMenu(items: @[
  MainMenu(
    text: "_File",
    width: 100,
    items: @[
      MainMenu(text: " _New", id: MenuFileNew),
      MainMenu(text: "#05# _Open", id: MenuFileOpen)
    ]
  ),
  MainMenu(
    text: "_Edit",
    width: 200,
    items: @[
      MainMenu(text: "#56# Level _properties", id: MenuLevelProperties)
    ]
  )
])

proc monitorChanged(monitor: int32) =
  setTargetFPS(getMonitorRefreshRate(monitor)) # Set our game to run at display framerate frames-per-second

when defined(emscripten):
  when defined(cpp):
    {.pragma: EMSCRIPTEN_KEEPALIVE, exportc, codegenDecl: "__attribute__((used)) extern \"C\" $# $#$#".}
  else:
    {.pragma: EMSCRIPTEN_KEEPALIVE, exportc, codegenDecl: "__attribute__((used)) $# $#$#".}

  proc browserCheckFileOpen() {.EMSCRIPTEN_KEEPALIVE.} =
    case showMenu(mainMenu, 20):
    of MenuFileOpen: echo "menu click open2"
    else: echo "unknown button!"

proc drawTiles(texture: Texture2D; position: Vector2; viewRect: Rectangle; tileWidth: bool = false; tileHeight: bool = false) =
  if texture.id == 0: return

  let tint = White

  # texture size
  let width = texture.width.float
  let height = texture.height.float

  # quad corner vertices
  var left = viewRect.x
  var top = viewRect.y
  var right = viewRect.x + viewRect.width
  var bottom = viewRect.y + viewRect.height

  var source = Rectangle(
    x: -position.x / 32,
    y: -position.y / 32,
    width: viewRect.width / 32,
    height: viewRect.height / 32
  )

  if not tileWidth:
    left = max(viewRect.x, viewRect.x + position.x)
    right = min(viewRect.x + viewRect.width, viewRect.x + position.x + width * 32)
    source.x = max(0, source.x)
    source.width = (right - left) / 32
  if not tileHeight:
    top = max(viewRect.y, viewRect.y + position.y)
    bottom = min(viewRect.y + viewRect.height, viewRect.y + position.y + height * 32)
    source.y = max(0, source.y)
    source.height = (bottom - top) / 32

  shader.setShaderValue(layerSizeLoc, Vector2(x: width, y: height))

  rlgl.setTexture(texture.id)
  rlgl.drawMode(Quads):
    rlgl.color4ub(tint.r, tint.g, tint.b, tint.a)
    rlgl.normal3f(0.0, 0.0, 1.0) # Normal vector pointing towards viewer

    # Top-left corner for texture and quad
    rlgl.texCoord2f(source.x/width, source.y/height);
    rlgl.vertex2f(left, top)

    # Bottom-left corner for texture and quad
    rlgl.texCoord2f(source.x/width, (source.y + source.height)/height)
    rlgl.vertex2f(left, bottom)

    # Bottom-right corner for texture and quad
    rlgl.texCoord2f((source.x + source.width)/width, (source.y + source.height)/height)
    rlgl.vertex2f(right, bottom)

    # Top-right corner for texture and quad
    rlgl.texCoord2f((source.x + source.width)/width, source.y/height)
    rlgl.vertex2f(right, top)
  rlgl.setTexture(0)

proc update() =
  let t = getTime()

  when defined(emscripten):
    if isWindowResized():
      setWindowSize(getScreenWidth(), getScreenHeight())

  let mousePos = getMousePosition()
  if lastMousePos != mousePos:
    mouseUpdated = true
  lastMousePos = mousePos

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
  clearBackground(getColor(guiGetStyle(GuiControl.Default, BackgroundColor).uint32))

  let tilesetRec = Rectangle(x: 0, y: 0, width: float32 tilesetIndex10Texture.width * 32, height: float32 tilesetIndex10Texture.height * 32)
  let animRec = Rectangle(x: 0, y: 0, width: float32 animGrid.width * 32, height: float32 animGrid.height * 32)

  scrollAnimPos.height = 200
  scrollAnimPos.y = getRenderHeight().float - scrollAnimPos.height
  scrollTilesetPos.height = getRenderHeight().float - scrollAnimPos.height - 19
  scrollParallaxPos.width = getRenderWidth().float - scrollParallaxPos.x
  scrollParallaxPos.height = getRenderHeight().float - scrollParallaxPos.y

  var mouseCell = Vector2()

  scrollPanel(scrollTilesetPos, "Tileset", tilesetRec, scrollTileset, scrollTilesetView)
  scissorMode(scrollTilesetView.x.int32, scrollTilesetView.y.int32, scrollTilesetView.width.int32, scrollTilesetView.height.int32):
    clearBackground(Color(r: 72, g: 48, b: 168, a: 255))
    grid(Rectangle(x: scrollTilesetView.x + scrollTileset.x, y: scrollTilesetView.y + scrollTileset.y, width: tilesetRec.width, height: tilesetRec.height), "", 32*5, 5, mouseCell)
    shaderMode(shader):
      drawTiles(tilesetIndex10Texture, scrollTileset, scrollTilesetView)

  scrollPanel(scrollAnimPos, "Animations", animRec, scrollAnim, scrollAnimView)
  scissorMode(scrollAnimView.x.int32, scrollAnimView.y.int32, scrollAnimView.width.int32, scrollAnimView.height.int32):
    clearBackground(Color(r: 72, g: 48, b: 168, a: 255))
    grid(Rectangle(x: scrollAnimView.x + scrollAnim.x, y: scrollAnimView.y + scrollAnim.y, width: animRec.width, height: animRec.height), "", 32*5, 5, mouseCell)
    shaderMode(shader):
      drawTiles(animGrid, scrollAnim, scrollAnimView)

  let viewSize = Vector2(x: min(800, scrollParallaxView.width), y: min(600, scrollParallaxView.height))
  let parallaxRec = Rectangle(x: 0, y: 0, width: layerTextures[3].width.float32*32 + scrollParallaxView.width - viewSize.x, height: layerTextures[3].height.float32*32 + scrollParallaxView.height - viewSize.y)
  let alignment = Vector2(
    x: (viewSize.x - 320) / 2,
    y: (viewSize.y - 200) / 2
  )

  scrollPanel(scrollParallaxPos, "Parallax View", parallaxRec, scrollParallax, scrollParallaxView)
  scissorMode(scrollParallaxView.x.int32, scrollParallaxView.y.int32, scrollParallaxView.width.int32, scrollParallaxView.height.int32):
    clearBackground(Color(r: 72, g: 48, b: 168, a: 255))
    for i in countdown(currentLevel.layers.len - 1, 0):
      if i == 3:
        grid(Rectangle(x: scrollParallaxView.x + scrollParallax.x, y: scrollParallaxView.y + scrollParallax.y, width: parallaxRec.width, height: parallaxRec.height), "", 32*4, 4, mouseCell)
      let layer = currentLevel.layers[i].addr

      let speed = Vector2(
        x: layer.speedX / 65536,
        y: layer.speedY / 65536
      )
      let heightMultiplier = (layer.properties.limitVisibleRegion and not layer.properties.tileHeight).float + 1
      var pos = Vector2(
        x: speed.x * (scrollParallax.x - alignment.x) + alignment.x,
        y: speed.y * (scrollParallax.y - alignment.y) + alignment.y * heightMultiplier
      )
      pos.x = floor(pos.x + scrollParallaxView.width / 2 - viewSize.x / 2)
      pos.y = floor(pos.y + scrollParallaxView.height / 2 - viewSize.y / 2)

      shaderMode(shader):
        drawTiles(layerTextures[i], pos, scrollParallaxView, layer.properties.tileWidth, layer.properties.tileHeight)

      drawRectangleLines(Rectangle(
        x: scrollParallaxView.x + scrollParallaxView.width / 2 - viewSize.x / 2 - 1,
        y: scrollParallaxView.y + scrollParallaxView.height / 2 - viewSize.y / 2 - 1,
        width: viewSize.x + 2,
        height: viewSize.y + 2
      ), 1, White)

  case showMenu(mainMenu, 20):
  of MenuNone: discard
  of MenuFileNew: discard
  of MenuFileOpen: echo "menu click open1"
  of MenuLevelProperties: discard

  # discard GuiButton(Rectangle(x: 25, y: 255, width: 125, height: 30), GuiIconText(ICON_FILE_SAVE.cint, "Save File".cstring))
  # let mbox = GuiMessageBox(Rectangle(x: 85, y: 70, width: 250, height: 100), "#191#Message Box", "Hi! This is a message!", "Nice;Cool")
  # if mbox != -1: echo mbox

  drawText("FPS: " & $getFPS(), getRenderWidth() - 100, 1, 20, Gold)

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
  setWindowMinSize(320, 240)
  # maximizeWindow()

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

  block:
    beginDrawing()
    drawText("Loading...", getRenderWidth() div 2 - measureText("Loading...", 96) div 2, getRenderHeight() div 2 + 96 div 2, 96, Gold)
    let icon = loadTexture("assets/icon.png")
    drawTexture(icon, getRenderWidth() div 2 - icon.width div 2, getRenderHeight() div 2 - icon.height + 30, White)
    endDrawing()

  currentLevel = Level()
  if currentLevel.load(levelFile):
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

    scrollParallax.x = -currentLevel.lastHorizontalOffset.float
    scrollParallax.y = -currentLevel.lastVerticalOffset.float

    currentTileset = Tileset()
    if currentTileset.load("assets/" & currentLevel.tileset):
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
        let alpha = if currentLevel.tileTypes[i] == Translucent: 180'u8 else: 255'u8
        for j in 0..<1024:
          let x = (i mod 64) * 32 + (j mod 32)
          let y = (i div 64) * 32 + (j div 32)
          let index = x + y * width
          imageData[index].gray = currentTileset.tileImage[tileId][j]
          imageData[index].alpha = if currentTileset.tileTransMask[transOffset][j]: alpha else: 0'u8

      tilesetImage = Texture2D(
        id: rlgl.loadTexture(imageData[0].addr, width.int32, height.int32, format.int32, 1),
        width: width.int32,
        height: height.int32,
        mipmaps: 1,
        format: format
      )
      tilesetImage.setTextureFilter(Point)
      tilesetImage.setTextureWrap(Clamp)
      imageData.reset()

      tilesetIndex10Texture = Texture2D(
        id: rlgl.loadTexture(tilesetMapData[0].addr, 10, tileset10Height.int32, UncompressedGrayAlpha.int32, 1),
        width: 10,
        height: tileset10Height.int32,
        mipmaps: 1,
        format: UncompressedGrayAlpha
      )
      tilesetIndex10Texture.setTextureFilter(Point)
      tilesetIndex10Texture.setTextureWrap(Clamp)

      tilesetIndex64Texture = Texture2D(
        id: rlgl.loadTexture(tilesetMapData[0].addr, 64, 64, UncompressedGrayAlpha.int32, 1),
        width: 64,
        height: 64,
        mipmaps: 1,
        format: UncompressedGrayAlpha
      )
      tilesetIndex64Texture.setTextureFilter(Point)
      tilesetIndex64Texture.setTextureWrap(Clamp)

      paletteTexture = Texture2D(
        id: rlgl.loadTexture(currentTileset.palette[0].addr, 256, 1, UncompressedR8g8b8a8.int32, 1),
        width: 256.int32,
        height: 1.int32,
        mipmaps: 1,
        format: UncompressedR8g8b8a8
      )
      paletteTexture.setTextureFilter(Point)
      paletteTexture.setTextureWrap(Clamp)

  shader.setShaderValueTexture(paletteLoc, paletteTexture)
  shader.setShaderValueTexture(tilesetImageLoc, tilesetImage)
  shader.setShaderValueTexture(tilesetMapLoc, tilesetIndex64Texture)

  # guiLoadStyleJungle()

  when defined(emscripten):
    setWindowSize(getScreenWidth(), getScreenHeight())
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
