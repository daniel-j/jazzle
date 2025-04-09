import raylib, raygui
import std/strutils
import std/sequtils
import std/math
import ./tiles
import ./events
import ./selection
import ../format/level
import ../state
import ../actions
import ../shaders

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
var parallaxResolutionOpened* = false

channelLevelFilename.sub(proc (filename: string) =
  scrollParallax.x = -globalState.currentLevel.lastHorizontalOffset.float
  scrollParallax.y = -globalState.currentLevel.lastVerticalOffset.float
)

proc calculateParallaxLayerOffset(scrollOffset: Vector2; scrollRect: Rectangle; viewSize: Vector2; layerNum: int; referenceLayerNum: int = parallaxCurrentLayer): Vector2 =
  let currentLayer = globalState.currentLevel.layers[referenceLayerNum].addr
  let layer = globalState.currentLevel.layers[layerNum].addr

  let alignment = Vector2(
    x: (viewSize.x - 320) / 2,
    y: (viewSize.y - 200) / 2
  )
  let heightMultiplier = (layer.properties.limitVisibleRegion and not layer.properties.tileHeight).float + 1

  let speed = Vector2(
    x: if layer.speedX == currentLayer.speedX: 1 else: layer.speedX / currentLayer.speedX,
    y: if layer.speedY == currentLayer.speedY: 1 else: layer.speedY / currentLayer.speedY
  )

  var offset = Vector2(
    x: floor(speed.x * (scrollOffset.x - alignment.x) + alignment.x),
    y: floor(speed.y * (scrollOffset.y - alignment.y) + alignment.y * heightMultiplier)
  )
  return offset

proc showParallaxPane*(scrollParallaxPos: Rectangle) =
  var mouseCell = Vector2()
  let mousePos = getMousePosition()
  scrollPanel(scrollParallaxPos, "Parallax View", scrollParallaxContent, scrollParallax, scrollParallaxView)
  let currentLayer = globalState.currentLevel.layers[parallaxCurrentLayer].addr
  let viewSize = if parallaxResolutionSelection > 0:
      Vector2(x: min(parallaxResolutions[parallaxResolutionSelection][0].float, scrollParallaxView.width), y: min(parallaxResolutions[parallaxResolutionSelection][1].float, scrollParallaxView.height))
    else:
      Vector2(x: scrollParallaxView.width, y: scrollParallaxView.height)

  # echo (scrollParallaxPos, scrollParallaxView)
  let drawOffset = Vector2(
    x: floor(scrollParallaxView.width / 2 - viewSize.x / 2),
    y: floor(scrollParallaxView.height / 2 - viewSize.y / 2)
  )
  var currentLayerOffset = calculateParallaxLayerOffset(scrollParallax, scrollParallaxView, viewSize, parallaxCurrentLayer)
  currentLayerOffset.x += drawOffset.x
  currentLayerOffset.y += drawOffset.y
  scrollParallaxContent = Rectangle(x: 0, y: 0, width: globalState.textures.layerTextures[parallaxCurrentLayer].width.float32*32 + max(0, scrollParallaxView.width - viewSize.x), height: globalState.textures.layerTextures[parallaxCurrentLayer].height.float32*32 + max(0, scrollParallaxView.height - viewSize.y))
  scissorMode(scrollParallaxView.x.int32, scrollParallaxView.y.int32, scrollParallaxView.width.int32, scrollParallaxView.height.int32):
    clearBackground(Color(r: 72, g: 48, b: 168, a: 255))
    for i in countdown(globalState.currentLevel.layers.len - 1, 0):
      if (not showParallaxLayers and parallaxCurrentLayer != i) or (showParallaxMask and showParallaxLayers and i != SpriteLayerNum):
        continue

      let layer = globalState.currentLevel.layers[i].addr
      var offset = calculateParallaxLayerOffset(scrollParallax, scrollParallaxView, viewSize, i)
      offset.x += drawOffset.x
      offset.y += drawOffset.y

      shaderMode(shaderTile):
        shaderTile.setShaderValueTexture(shaderTilePaletteLoc, globalState.textures.palette)
        shaderTile.setShaderValueTexture(shaderTileTilesetMapLoc, globalState.textures.staticTileLUT)
        if showParallaxMask:
          shaderTile.setShaderValueTexture(shaderTileTilesetImageLoc, globalState.textures.tilesetMask)
        else:
          shaderTile.setShaderValueTexture(shaderTileTilesetImageLoc, globalState.textures.tilesetImage)
        drawTiles(globalState.textures.layerTextures[i], offset, scrollParallaxView, layer.properties.tileWidth, layer.properties.tileHeight)

    if showParallaxEvents:
      var spriteLayerOffset = calculateParallaxLayerOffset(scrollParallax, scrollParallaxView, viewSize, SpriteLayerNum)
      spriteLayerOffset.x += drawOffset.x
      spriteLayerOffset.y += drawOffset.y
      eventStyle:
        drawEvents(scrollParallaxView, spriteLayerOffset, globalState.currentLevel.events)
    if showParallaxGrid:
      grid(Rectangle(x: scrollParallaxView.x + currentLayerOffset.x, y: scrollParallaxView.y + currentLayerOffset.y, width: currentLayer.width.float * 32, height: currentLayer.height.float * 32), "", 32*4, 4, mouseCell)

    if not guiIsLocked():
      drawSelection(scrollParallaxView, currentLayerOffset)

    # drawRectangleLines(Rectangle(
    #   x: scrollParallaxView.x + scrollParallaxView.width / 2 - viewSize.x / 2 - 1024,
    #   y: scrollParallaxView.y + scrollParallaxView.height / 2 - viewSize.y / 2 - 1024,
    #   width: viewSize.x + 1024*2,
    #   height: viewSize.y + 1024*2
    # ), 1024, Black)

    drawRectangleLines(Rectangle(
      x: scrollParallaxView.x + drawOffset.x - 1,
      y: scrollParallaxView.y + drawOffset.y - 1,
      width: viewSize.x + 2,
      height: viewSize.y + 2
    ), 1, White)

proc showParallaxControls*(scrollParallaxPos: Rectangle) =
  enableTooltip()
  # parallax controls
  setTooltip("")
  if dropdownBox(Rectangle(x: scrollParallaxPos.x + scrollParallaxPos.width - 80 - 2, y: scrollParallaxPos.y + 2, width: 80, height: 20), parallaxResolutionsStr, parallaxResolutionSelection, parallaxResolutionOpened):
    parallaxResolutionOpened = not parallaxResolutionOpened
  setTooltip("Grid")
  toggle(Rectangle(x: scrollParallaxPos.x + scrollParallaxPos.width - 20 - 80 - 2*3, y: scrollParallaxPos.y + 2, width: 20, height: 20), iconText(Grid), showParallaxGrid)
  setTooltip("Collision mask")
  toggle(Rectangle(x: scrollParallaxPos.x + scrollParallaxPos.width - 20 - 20 - 80 - 2*4, y: scrollParallaxPos.y + 2, width: 20, height: 20), iconText(BoxCircleMask), showParallaxMask)
  setTooltip("Events")
  toggle(Rectangle(x: scrollParallaxPos.x + scrollParallaxPos.width - 20 - 20 - 20 - 80 - 2*5, y: scrollParallaxPos.y + 2, width: 20, height: 20), iconText(PlayerJump), showParallaxEvents)
  setTooltip("Parallax layers")
  toggle(Rectangle(x: scrollParallaxPos.x + scrollParallaxPos.width - 20 - 20 - 20 - 20 - 80 - 2*6, y: scrollParallaxPos.y + 2, width: 20, height: 20), iconText(LayersIso), showParallaxLayers)
  setTooltip("")
  let lastLayer = parallaxCurrentLayer
  toggleGroup(Rectangle(x: scrollParallaxPos.x + scrollParallaxPos.width - 8*(18+2) - 20 - 20 - 20 - 20 - 80 - 2*8, y: scrollParallaxPos.y + 2, width: 18, height: 20), "1;2;3;4;5;6;7;8", parallaxCurrentLayer)
  if lastLayer != parallaxCurrentLayer:
    let viewSize = if parallaxResolutionSelection > 0:
      Vector2(x: min(parallaxResolutions[parallaxResolutionSelection][0].float, scrollParallaxView.width), y: min(parallaxResolutions[parallaxResolutionSelection][1].float, scrollParallaxView.height))
    else:
      Vector2(x: scrollParallaxView.width, y: scrollParallaxView.height)
    scrollParallax = calculateParallaxLayerOffset(scrollParallax, scrollParallaxView, viewSize, parallaxCurrentLayer, lastLayer)
  disableTooltip()
