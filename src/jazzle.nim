
import raylib, rlgl, raygui
import jazzle/tileset
import jazzle/level
import std/math
import std/os
import std/sequtils
import std/strutils

import ./jazzle/gui

const
  screenWidth = 1280
  screenHeight = 720
  levelFile = "Tube2.j2l"
  shaderIndexedFs = staticRead("jazzle/shaders/indexed.fs")
  shaderTileFs = staticRead("jazzle/shaders/tile.fs")

type
  GrayAlpha {.packed.} = object
    gray: uint8
    alpha: uint8

var resourcePath = "assets"

var lastCurrentMonitor: int32 = 0
var currentTileset: Tileset
var currentLevel = NewLevel
var paletteTexture: Texture2D
var tilesetImage: Texture2D
var tilesetMask: Texture2D
var tilesetGrid: Texture2D
var tilesetIndex64Texture: Texture2D
var layerTextures: seq[Texture2D]
var tilesetMapData: array[64*64, uint16]
var animTiles: array[256, Tile]
var animGrid: Texture2D

var shaderTile: Shader
var shaderTilePaletteLoc: ShaderLocation
var shaderTileTilesetImageLoc: ShaderLocation
var shaderTileLayerSizeLoc: ShaderLocation
var shaderTileTilesetMapLoc: ShaderLocation

var shaderIndexed: Shader
var shaderIndexedPaletteLoc: ShaderLocation

var animsUpdated = true
var mouseUpdated = true
var lastMousePos = Vector2()

var scrollParallaxPos = Rectangle(x: 335, y: 20, width: 1, height: 1)
var scrollParallaxView = Rectangle()
var scrollParallaxContent = Rectangle()
var scrollParallax = Vector2()
var showParallaxLayers = true
var showParallaxEvents = true
var showParallaxGrid = true
var showParallaxMask = false
var parallaxCurrentLayer: int32 = SpriteLayerNum.int32
const parallaxResolutions = [
  (-1, -1), # none
  (320, 200),
  (320, 240),
  (512, 384),
  (640, 400),
  (640, 480),
  (800, 450),
  (800, 600)
]
const parallaxResolutionsStr = parallaxResolutions.map(proc (res: (int, int)): string =
    if res[0] == -1: "(none)" else: $res[0] & "x" & $res[1]
  ).join(";")
var parallaxResolutionSelection: int32 = 0
var parallaxResolutionOpened = false

var scrollTilesetPos = Rectangle(x: 0, y: 20, width: 334, height: 1)
var scrollTilesetView = Rectangle()
var scrollTileset = Vector2()
var showTilesetGrid = true
var showTilesetMask = false
var showTilesetEvents = false

var scrollAnimPos = Rectangle(x: 0, y: 20, width: 334, height: 1)
var scrollAnimView = Rectangle()
var scrollAnim = Vector2()
var showAnimGrid = true
var showAnimMask = false
var showAnimEvents = false

type
  MainMenuValues = enum
    MenuNone
    MenuFileNew
    MenuFileOpen
    MenuFileSave
    MenuLevelProperties

  MainMenu = Menu[MainMenuValues]

var mainMenu = MainMenu(items: @[
  MainMenu(
    text: "_File",
    width: 100,
    items: @[
      MainMenu(text: "#08# New", id: MenuFileNew),
      MainMenu(text: "#01# Open", id: MenuFileOpen),
      MainMenu(text: "#02# Save", id: MenuFileSave)
    ]
  ),
  MainMenu(
    text: "_Edit",
    width: 200,
    items: @[
      MainMenu(text: "#59# Level properties", id: MenuLevelProperties)
    ]
  )
])

proc monitorChanged(monitor: int32) =
  setTargetFPS(getMonitorRefreshRate(monitor)) # Set our game to run at display framerate frames-per-second

proc loadTilesetData() =
  const width = 64 * 32
  const height = 64 * 32
  var imageData = newSeq[GrayAlpha](width * height)
  var maskData = newSeq[GrayAlpha](width * height)
  let tileset10Height = (currentTileset.tiles.len + 9) div 10

  for i, tile in currentTileset.tiles:
    if i == 0: continue
    tilesetMapData[i] = uint16 i
    let alpha = if currentLevel.tileTypes[i] == Translucent: 180'u8 else: 255'u8
    for j in 0..<32*32:
      let x = (i mod 64) * 32 + (j mod 32)
      let y = (i div 64) * 32 + (j div 32)
      let index = x + y * width
      imageData[index].gray = tile[j].color
      imageData[index].alpha = if tile[j].transMask: alpha else: 0'u8
      maskData[index].gray = 0
      maskData[index].alpha = if tile[j].mask: 255'u8 else: 0'u8

  tilesetImage = Texture2D(
    id: rlgl.loadTexture(imageData[0].addr, width.int32, height.int32, UncompressedGrayAlpha.int32, 1),
    width: width.int32,
    height: height.int32,
    mipmaps: 1,
    format: UncompressedGrayAlpha
  )
  tilesetImage.setTextureFilter(Point)
  tilesetImage.setTextureWrap(Clamp)
  tilesetMask = Texture2D(
    id: rlgl.loadTexture(maskData[0].addr, width.int32, height.int32, UncompressedGrayAlpha.int32, 1),
    width: width.int32,
    height: height.int32,
    mipmaps: 1,
    format: UncompressedGrayAlpha
  )
  tilesetMask.setTextureFilter(Point)
  tilesetMask.setTextureWrap(Clamp)
  imageData.reset()
  maskData.reset()

  tilesetGrid = Texture2D(
    id: rlgl.loadTexture(tilesetMapData[0].addr, 10, tileset10Height.int32, UncompressedGrayAlpha.int32, 1),
    width: 10,
    height: tileset10Height.int32,
    mipmaps: 1,
    format: UncompressedGrayAlpha
  )
  tilesetGrid.setTextureFilter(Point)
  tilesetGrid.setTextureWrap(Clamp)

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

  # shaderTile.setShaderValueTexture(shaderTileTilesetImageLoc, tilesetImage)
  # shaderTile.setShaderValueTexture(shaderTileTilesetMapLoc, tilesetIndex64Texture)
  # shaderTile.setShaderValueTexture(shaderTilePaletteLoc, paletteTexture)

  # shaderIndexed.setShaderValueTexture(shaderIndexedPaletteLoc, paletteTexture)

proc loadTilesetFilename(filename: string) =
  if currentTileset.load(filename):
    currentTileset.cleanup() # clears tileoffset and data buffers, not used anymore
    loadTilesetData()

proc loadLevelData() =
  layerTextures.setLen(8)
  for i in 0 ..< 8:
    let layer = currentLevel.layers[i].addr
    var layerData = newSeq[uint16](layer.width * layer.height)
    let realWidth = ((layer.realWidth + 3) div 4) * 4
    if layer.haveAnyTiles:
      for j, wordId in layer.tileCache.pairs:
        if wordId == 0: continue
        let word = currentLevel.dictionary[wordId]
        for t, rawtile in word.pairs:
          if rawtile == 0: continue
          let tile = currentLevel.parseTile(rawtile)
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

  if currentLevel.anims.len > 0:
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
  else:
    animGrid = Texture2D(
      id: rlgl.loadTexture(nil, 0, 0, UncompressedGrayAlpha.int32, 1),
      width: 0,
      height: 0,
      mipmaps: 1,
      format: UncompressedGrayAlpha
    )
  animsUpdated = true

  scrollParallax.x = -currentLevel.lastHorizontalOffset.float
  scrollParallax.y = -currentLevel.lastVerticalOffset.float

  let tilesetFilename = lastPathPart(currentLevel.tileset)
  if tilesetFilename == "":
    currentTileset = NoTileset
    loadTilesetData()
  else:
    loadTilesetFilename(resourcePath / tilesetFilename)

proc loadLevelFilename(filename: string) =
  echo "trying to load file ", filename
  if currentLevel.load(filename):
    echo "loaded ", currentLevel.filename
    loadLevelData()
  else:
    echo "couldnt load level!"

proc createNewLevel() =
  currentLevel = NewLevel
  loadLevelData()

when defined(emscripten):
  when defined(cpp):
    {.pragma: EMSCRIPTEN_KEEPALIVE, cdecl, exportc, codegenDecl: "__attribute__((used)) extern \"C\" $# $#$#".}
  else:
    {.pragma: EMSCRIPTEN_KEEPALIVE, cdecl, exportc, codegenDecl: "__attribute__((used)) $# $#$#".}

  proc openFilePicker() {.importc.}
  proc openSavePicker(filename: cstring; filenameLen: int; data: cstring; dataLen: int) {.importc.}

  proc openFileCompleted(name: cstring; length: int; data: ptr uint8) {.EMSCRIPTEN_KEEPALIVE.} =
    echo "file completed", name
    echo (length)
    var str = newString(length)
    copyMem(str[0].addr, data, str.len)
    createDir("/uploads")
    writeFile("/uploads/" & $name, str)
    loadLevelFilename("/uploads/" & $name)

  proc saveFile() =
    echo currentLevel.filename
    echo extractFilename(currentLevel.filename)
    currentLevel.save("/level_saved.j2l")
    let data = readFile("/level_saved.j2l")
    let filename = extractFilename(currentLevel.filename)
    echo filename
    openSavePicker(filename.cstring, filename.len, data.cstring, data.len)

else:
  {.pragma: EMSCRIPTEN_KEEPALIVE, cdecl, exportc.}

  proc openFilePicker() =
    discard

  proc saveFile() =
    currentLevel.save("level_saved.j2l")




proc drawTiles(texture: Texture2D; position: Vector2; viewRect: Rectangle; tileWidth: bool = false; tileHeight: bool = false; alpha: uint8 = 255) =
  if texture.id == 0: return

  var tint = White
  tint.a = alpha

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

  shaderTile.setShaderValue(shaderTileLayerSizeLoc, Vector2(x: width, y: height))

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

proc calculateParallaxLayerOffset(viewSize: Vector2; alignment: Vector2; layerNum: int): Vector2 =
  let currentLayer = currentLevel.layers[parallaxCurrentLayer].addr
  let layer = currentLevel.layers[layerNum].addr

  let speed = Vector2(
    x: if layer.speedX == currentLayer.speedX: 1 else: layer.speedX / currentLayer.speedX,
    y: if layer.speedY == currentLayer.speedY: 1 else: layer.speedY / currentLayer.speedY
  )
  let heightMultiplier = (layer.properties.limitVisibleRegion and not layer.properties.tileHeight).float + 1
  var offset = Vector2(
    x: speed.x * (scrollParallax.x - alignment.x) + alignment.x,
    y: speed.y * (scrollParallax.y - alignment.y) + alignment.y * heightMultiplier
  )
  offset.x = floor(offset.x + scrollParallaxView.width / 2 - viewSize.x / 2)
  offset.y = floor(offset.y + scrollParallaxView.height / 2 - viewSize.y / 2)
  return offset

proc drawParallaxEvents(offset: Vector2) =
  let layer = currentLevel.layers[SpriteLayerNum].addr

  let labelStye = guiGetStyle(Label, TextColorNormal)
  let alignment = guiGetStyle(Label, TextAlignment)
  let textSize = guiGetStyle(GuiControl.Default, TextSize)
  guiSetStyle(Label, TextColorNormal, cast[int32](0xffffffff'u32))
  guiSetStyle(Label, TextAlignment, Center)
  guiSetStyle(Default, TextSize, 10)
  for y in 0..<layer.height:
    for x in 0..<layer.width:
      let evt = currentLevel.events[y][x]
      if evt.eventId == None: continue
      let isGenerator = evt.eventId == Generator
      var eventId = evt.eventId
      let params = evt.params
      if isGenerator:
        eventId = params[0].EventId

      let rect = Rectangle(
        x: scrollParallaxView.x + offset.x + x.float * 32,
        y: scrollParallaxView.y + offset.y + y.float * 32,
        width: 32,
        height: 32
      )

      if not checkCollisionRecs(scrollParallaxView, rect): continue

      let rectOuter = Rectangle(
        x: rect.x - 6,
        y: rect.y,
        width: rect.width + 12,
        height: rect.height
      )
      drawRectangle(rect, Color(r: 0, g: 0, b: 0, a: 70))
      let t = getTime()
      case eventId:
      of JazzLevelStart, SpazLevelStart, LoriLevelStart, MultiplayerLevelStart:
        let color = case eventId:
          of JazzLevelStart: Green
          of SpazLevelStart: Red
          of LoriLevelStart: Yellow
          else: Blue
        drawIcon(Player, rect.x.int32, rect.y.int32, 2, color)
      of AreaEndOfLevel, AreaWarpEOL, AreaWarpSecret:
        drawIcon(Exit, rect.x.int32, rect.y.int32, 2, LightGray)
      of SilverCoin, GoldCoin:
        drawIcon(Coin, rect.x.int32, rect.y.int32, 2, if eventId == SilverCoin: LightGray else: Gold)
      of CarrotEnergy1, FullEnergy:
        drawIcon(Heart, rect.x.int32, rect.y.int32, 2, if eventId == CarrotEnergy1: Orange else: Gold)
      of ExtraLife:
        drawIcon(Icon1up, rect.x.int32, rect.y.int32, 2, Green)
      of BouncerAmmo3, FreezerAmmo3, SeekerAmmo3, RFAmmo3, ToasterAmmo3, TNTAmmo3, Gun8Ammo3, Gun9Ammo3:
        let color = case eventId:
          of BouncerAmmo3: Blue
          of FreezerAmmo3: SkyBlue
          of SeekerAmmo3: Red
          of RFAmmo3: Green
          of ToasterAmmo3: Orange
          of TNTAmmo3: Maroon
          of Gun8Ammo3: Beige
          of Gun9Ammo3: Gold
          else: LightGray
        drawIcon(Crack, rect.x.int32 + 8, rect.y.int32 + 8, 1, color)
      of BlasterPowerUp, BouncerPowerUp, FreezerPowerUp, SeekerPowerUp, RFPowerUp, ToasterPowerUp, Gun8PowerUp, Gun9PowerUp:
        let color = case eventId:
          of BlasterPowerUp: LightGray
          of BouncerPowerUp: Blue
          of FreezerPowerUp: SkyBlue
          of SeekerPowerUp: Red
          of RFPowerUp: Green
          of TNTPowerUp: Maroon
          of ToasterPowerUp: Orange
          of Gun8PowerUp: Beige
          of Gun9PowerUp: Gold
          else: LightGray
        drawIcon(Monitor, rect.x.int32, rect.y.int32, 2, color)
      of DestructScenery:
        let weapon = params[2]
        let color = case weapon:
        of 1: Gray
        of 2: Blue
        of 3: SkyBlue
        of 4: Red
        of 5: Green
        of 6: Orange
        of 7: Maroon
        of 8: Beige
        of 9: Gold
        else: White
        drawIcon(Star, rect.x.int32, rect.y.int32, 2, color)
      of SuckerTube:
        if not isGenerator:
          let xpos = floorMod((t * (params[0].float * 3)) + 16, 32) - 2
          let ypos = floorMod((t * (params[1].float * 3)) + 16, 32) - 2
          drawRectangle(Rectangle(x: rect.x + xpos, y: rect.y + ypos, width: 4, height: 4), White)
      else: discard
      drawRectangle(rect, Color(r: 0, g: 0, b: 0, a: 50))
      if isGenerator:
        drawTriangle(Vector2(x: rect.x, y: rect.y), Vector2(x: rect.x, y: rect.y + 7), Vector2(x: rect.x + 7, y: rect.y), Color(r: 255, g: 255, b: 255, a: 140))
        drawTriangleLines(Vector2(x: rect.x, y: rect.y), Vector2(x: rect.x, y: rect.y + 9), Vector2(x: rect.x + 9, y: rect.y), Black)

      let text = jcsEvents[eventId].label
      label(rectOuter, text)
  guiSetStyle(Label, TextAlignment, alignment)
  guiSetStyle(Label, TextColorNormal, labelStye)
  guiSetStyle(Default, TextSize, textSize)

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
      animTiles[i] = tile
      let tileId = tile.tileId + tile.hflipped.uint16 * 0x1000 + tile.vflipped.uint16 * 0x2000
      tilesetMapData[offset + i] = tileId
    rlgl.updateTexture(tilesetIndex64Texture.id, 0, 0, 64, 64, UncompressedGrayAlpha, tilesetMapData[0].addr)
    animsUpdated = false

proc draw() =
  # if not animsUpdated and not mouseUpdated: return
  beginDrawing()
  clearBackground(getColor(guiGetStyle(GuiControl.Default, BackgroundColor).uint32))

  let tilesetRec = Rectangle(x: 0, y: 0, width: float32 tilesetGrid.width * 32, height: float32 tilesetGrid.height * 32)
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
    if showTilesetGrid:
      grid(Rectangle(x: scrollTilesetView.x + scrollTileset.x, y: scrollTilesetView.y + scrollTileset.y, width: tilesetRec.width, height: tilesetRec.height), "", 32*5, 5, mouseCell)
    shaderMode(shaderTile):
      shaderTile.setShaderValueTexture(shaderTilePaletteLoc, paletteTexture)
      shaderTile.setShaderValueTexture(shaderTileTilesetMapLoc, tilesetIndex64Texture)
      if showTilesetMask:
        shaderTile.setShaderValueTexture(shaderTileTilesetImageLoc, tilesetMask)
      else:
        shaderTile.setShaderValueTexture(shaderTileTilesetImageLoc, tilesetImage)
      drawTiles(tilesetGrid, scrollTileset, scrollTilesetView)
    # shaderMode(shaderIndexed):
    #   for i, tile in currentTileset.tiles:
    #     if i == 0: continue
    #     let dest = Rectangle(
    #       x: (i mod 10).float * 32 + scrollTilesetView.x + scrollTileset.x,
    #       y: (i div 10).float * 32 + scrollTilesetView.y + scrollTileset.y,
    #       width: 32, height: 32
    #     )
    #     if not checkCollisionRecs(dest, scrollTilesetView): continue
    #     let src = Rectangle(
    #       x: float (i mod 64) * 32,
    #       y: float (i div 64) * 32,
    #       width: 32, height: 32
    #     )
    #     drawTexture(tilesetImage, src, dest, Vector2(), 0, White)

  enableTooltip()
  setTooltip("Grid")
  toggle(Rectangle(x: scrollTilesetPos.x + scrollTilesetPos.width - 20 - 2*1, y: scrollTilesetPos.y + 2, width: 20, height: 20), iconText(Grid), showTilesetGrid)
  setTooltip("Collision mask")
  toggle(Rectangle(x: scrollTilesetPos.x + scrollTilesetPos.width - 20 - 20 - 2*2, y: scrollTilesetPos.y + 2, width: 20, height: 20), iconText(BoxCircleMask), showTilesetMask)
  setTooltip("Events")
  toggle(Rectangle(x: scrollTilesetPos.x + scrollTilesetPos.width - 20 - 20 - 20 - 2*3, y: scrollTilesetPos.y + 2, width: 20, height: 20), iconText(PlayerJump), showTilesetEvents)
  disableTooltip()

  scrollPanel(scrollAnimPos, "Animations", animRec, scrollAnim, scrollAnimView)
  scissorMode(scrollAnimView.x.int32, scrollAnimView.y.int32, scrollAnimView.width.int32, scrollAnimView.height.int32):
    clearBackground(Color(r: 72, g: 48, b: 168, a: 255))
    if showAnimGrid:
      grid(Rectangle(x: scrollAnimView.x + scrollAnim.x, y: scrollAnimView.y + scrollAnim.y, width: animRec.width, height: animRec.height), "", 32*5, 5, mouseCell)
    shaderMode(shaderTile):
      shaderTile.setShaderValueTexture(shaderTilePaletteLoc, paletteTexture)
      shaderTile.setShaderValueTexture(shaderTileTilesetMapLoc, tilesetIndex64Texture)
      if showAnimMask:
        shaderTile.setShaderValueTexture(shaderTileTilesetImageLoc, tilesetMask)
      else:
        shaderTile.setShaderValueTexture(shaderTileTilesetImageLoc, tilesetImage)
      drawTiles(animGrid, scrollAnim, scrollAnimView)
    # shaderMode(shaderIndexed):
    #   for i, anim in currentLevel.anims:
    #     let dest = Rectangle(
    #       x: (i mod 10).float * 32 + scrollAnimView.x + scrollAnim.x,
    #       y: (i div 10).float * 32 + scrollAnimView.y + scrollAnim.y,
    #       width: 32, height: 32
    #     )
    #     if not checkCollisionRecs(dest, scrollAnimView): continue
    #     let tile = animTiles[i]
    #     if tile.tileId == 0: continue
    #     let src = Rectangle(
    #       x: float (tile.tileId mod 64) * 32,
    #       y: float (tile.tileId div 64) * 32,
    #       width: if tile.hflipped: -32 else: 32,
    #       height: if tile.vflipped: -32 else: 32
    #     )
    #     drawTexture(tilesetImage, src, dest, Vector2(), 0, White)

  enableTooltip()
  setTooltip("Grid")
  toggle(Rectangle(x: scrollAnimPos.x + scrollAnimPos.width - 20 - 2*1, y: scrollAnimPos.y + 2, width: 20, height: 20), iconText(Grid), showAnimGrid)
  setTooltip("Collision mask")
  toggle(Rectangle(x: scrollAnimPos.x + scrollAnimPos.width - 20 - 20 - 2*2, y: scrollAnimPos.y + 2, width: 20, height: 20), iconText(BoxCircleMask), showAnimMask)
  setTooltip("Events")
  toggle(Rectangle(x: scrollAnimPos.x + scrollAnimPos.width - 20 - 20 - 20 - 2*3, y: scrollAnimPos.y + 2, width: 20, height: 20), iconText(PlayerJump), showAnimEvents)
  disableTooltip()

  scrollPanel(scrollParallaxPos, "Parallax View", scrollParallaxContent, scrollParallax, scrollParallaxView)
  let mousePos = getMousePosition()
  let currentLayer = currentLevel.layers[parallaxCurrentLayer].addr
  let viewSize = if parallaxResolutionSelection > 0:
      Vector2(x: min(parallaxResolutions[parallaxResolutionSelection][0].float, scrollParallaxView.width), y: min(parallaxResolutions[parallaxResolutionSelection][1].float, scrollParallaxView.height))
    else:
      Vector2(x: scrollParallaxView.width, y: scrollParallaxView.height)
  let alignment = Vector2(
    x: (viewSize.x - 320) / 2,
    y: (viewSize.y - 200) / 2
  )

  # echo (scrollParallaxPos, scrollParallaxView)
  let currentLayerOffset = calculateParallaxLayerOffset(viewSize, alignment, parallaxCurrentLayer)
  scrollParallaxContent = Rectangle(x: 0, y: 0, width: layerTextures[parallaxCurrentLayer].width.float32*32 + max(0, scrollParallaxView.width - viewSize.x), height: layerTextures[parallaxCurrentLayer].height.float32*32 + max(0, scrollParallaxView.height - viewSize.y))
  scissorMode(scrollParallaxView.x.int32, scrollParallaxView.y.int32, scrollParallaxView.width.int32, scrollParallaxView.height.int32):
    clearBackground(Color(r: 72, g: 48, b: 168, a: 255))
    for i in countdown(currentLevel.layers.len - 1, 0):
      if (not showParallaxLayers and parallaxCurrentLayer != i) or (showParallaxMask and showParallaxLayers and i != SpriteLayerNum):
        continue

      let layer = currentLevel.layers[i].addr
      let offset = calculateParallaxLayerOffset(viewSize, alignment, i)

      shaderMode(shaderTile):
        shaderTile.setShaderValueTexture(shaderTilePaletteLoc, paletteTexture)
        shaderTile.setShaderValueTexture(shaderTileTilesetMapLoc, tilesetIndex64Texture)
        if showParallaxMask:
          shaderTile.setShaderValueTexture(shaderTileTilesetImageLoc, tilesetMask)
        else:
          shaderTile.setShaderValueTexture(shaderTileTilesetImageLoc, tilesetImage)
        drawTiles(layerTextures[i], offset, scrollParallaxView, layer.properties.tileWidth, layer.properties.tileHeight)

    if showParallaxGrid:
      grid(Rectangle(x: scrollParallaxView.x + currentLayerOffset.x, y: scrollParallaxView.y + currentLayerOffset.y, width: currentLayer.width.float * 32, height: currentLayer.height.float * 32), "", 32*4, 4, mouseCell)
    if showParallaxEvents and parallaxCurrentLayer == SpriteLayerNum:
      drawParallaxEvents(currentLayerOffset)

    let mousePosTile = Vector2(x: (mousePos.x - scrollParallaxView.x - currentLayerOffset.x) / 32, y: (mousePos.y - scrollParallaxView.y - currentLayerOffset.y) / 32)
    drawRectangleLines(Rectangle(x: scrollParallaxView.x + currentLayerOffset.x + floor(mousePosTile.x) * 32, y: scrollParallaxView.y + currentLayerOffset.y + floor(mousePosTile.y) * 32, width: 32, height: 32), 1, Pink)

    # drawRectangleLines(Rectangle(
    #   x: scrollParallaxView.x + scrollParallaxView.width / 2 - viewSize.x / 2 - 1024,
    #   y: scrollParallaxView.y + scrollParallaxView.height / 2 - viewSize.y / 2 - 1024,
    #   width: viewSize.x + 1024*2,
    #   height: viewSize.y + 1024*2
    # ), 1024, Black)

    drawRectangleLines(Rectangle(
      x: scrollParallaxView.x + scrollParallaxView.width / 2 - viewSize.x / 2 - 1,
      y: scrollParallaxView.y + scrollParallaxView.height / 2 - viewSize.y / 2 - 1,
      width: viewSize.x + 2,
      height: viewSize.y + 2
    ), 1, White)

  if dropdownBox(Rectangle(x: scrollParallaxPos.x + scrollParallaxPos.width - 80 - 2, y: scrollParallaxPos.y + 2, width: 80, height: 20), parallaxResolutionsStr, parallaxResolutionSelection, parallaxResolutionOpened):
    parallaxResolutionOpened = not parallaxResolutionOpened

  enableTooltip()
  setTooltip("Grid")
  toggle(Rectangle(x: scrollParallaxPos.x + scrollParallaxPos.width - 20 - 80 - 2*3, y: scrollParallaxPos.y + 2, width: 20, height: 20), iconText(Grid), showParallaxGrid)
  setTooltip("Collision mask")
  toggle(Rectangle(x: scrollParallaxPos.x + scrollParallaxPos.width - 20 - 20 - 80 - 2*4, y: scrollParallaxPos.y + 2, width: 20, height: 20), iconText(BoxCircleMask), showParallaxMask)
  setTooltip("Events")
  toggle(Rectangle(x: scrollParallaxPos.x + scrollParallaxPos.width - 20 - 20 - 20 - 80 - 2*5, y: scrollParallaxPos.y + 2, width: 20, height: 20), iconText(PlayerJump), showParallaxEvents)
  setTooltip("Parallax layers")
  toggle(Rectangle(x: scrollParallaxPos.x + scrollParallaxPos.width - 20 - 20 - 20 - 20 - 80 - 2*6, y: scrollParallaxPos.y + 2, width: 20, height: 20), iconText(LayersIso), showParallaxLayers)
  disableTooltip()

  toggleGroup(Rectangle(x: scrollParallaxPos.x + scrollParallaxPos.width - 8*(18+2) - 20 - 20 - 20 - 20 - 80 - 2*8, y: scrollParallaxPos.y + 2, width: 18, height: 20), "1;2;3;4;5;6;7;8", parallaxCurrentLayer)

  # var i = 0
  # for icon in GuiIconName:
  #   let x = (i mod 16) + 1
  #   let y = (i div 16) + 1
  #   drawIcon(icon, int32 x * 32, int32 y * 32, 2, White)
  #   inc(i)

  case showMenu(mainMenu, 20):
  of MenuNone: discard
  of MenuFileNew: createNewLevel()
  of MenuFileOpen: openFilePicker()
  of MenuLevelProperties: discard
  of MenuFileSave: saveFile()

  # discard GuiButton(Rectangle(x: 25, y: 255, width: 125, height: 30), GuiIconText(ICON_FILE_SAVE.cint, "Save File".cstring))
  # let mbox = GuiMessageBox(Rectangle(x: 85, y: 70, width: 250, height: 100), "#191#Message Box", "Hi! This is a message!", "Nice;Cool")
  # if mbox != -1: echo mbox

  drawText("FPS: " & $getFPS(), getRenderWidth() - 100, 1, 20, DarkGray)

  endDrawing()
  mouseUpdated = false


proc updateDrawFrame {.cdecl.} =
  update()
  draw()

proc main =

  loadJcsIni("assets/JCS.ini")

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

  shaderTile = loadShaderFromMemory("", shaderPrefix & shaderTileFs)
  shaderTilePaletteLoc = shaderTile.getShaderLocation("texture1")
  shaderTileTilesetImageLoc = shaderTile.getShaderLocation("texture2")
  shaderTileTilesetMapLoc = shaderTile.getShaderLocation("texture3")
  shaderTileLayerSizeLoc = shaderTile.getShaderLocation("layerSize")

  shaderIndexed = loadShaderFromMemory("", shaderPrefix & shaderIndexedFs)
  shaderIndexedPaletteLoc = shaderIndexed.getShaderLocation("texture1")

  block:
    beginDrawing()
    drawText("Loading...", getRenderWidth() div 2 - measureText("Loading...", 96) div 2, getRenderHeight() div 2 + 96 div 2, 96, Gold)
    let icon = loadTexture("assets/icon.png")
    drawTexture(icon, getRenderWidth() div 2 - icon.width div 2, getRenderHeight() div 2 - icon.height + 30, White)
    endDrawing()

  loadLevelFilename(resourcePath / levelFile)

  # guiLoadStyleJungle()

  when defined(emscripten):
    setWindowSize(getScreenWidth(), getScreenHeight())
    emscriptenSetMainLoop(updateDrawFrame, 0, 1)
  else:
    # lastCurrentMonitor = getCurrentMonitor()
    # monitorChanged(lastCurrentMonitor)

    # Main game loop
    while not windowShouldClose(): # Detect window close button
      # let currentMonitor = getCurrentMonitor()
      # if lastCurrentMonitor != currentMonitor:
      #   lastCurrentMonitor = currentMonitor
      #   monitorChanged(currentMonitor)

      updateDrawFrame()

main()
