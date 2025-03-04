import raylib, raygui
import std/strutils
import std/sequtils
import std/math
import ./tiles
import ./events
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
var parallaxResolutionOpened = false

channelLevelFilename.sub(proc (filename: string) =
  scrollParallax.x = -globalState.currentLevel.lastHorizontalOffset.float
  scrollParallax.y = -globalState.currentLevel.lastVerticalOffset.float
)

proc calculateParallaxLayerOffset(viewSize: Vector2; alignment: Vector2; layerNum: int): Vector2 =
  let currentLayer = globalState.currentLevel.layers[parallaxCurrentLayer].addr
  let layer = globalState.currentLevel.layers[layerNum].addr

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

proc showParallaxPane*(scrollParallaxPos: Rectangle) =
  var mouseCell = Vector2()
  scrollPanel(scrollParallaxPos, "Parallax View", scrollParallaxContent, scrollParallax, scrollParallaxView)
  let mousePos = getMousePosition()
  let currentLayer = globalState.currentLevel.layers[parallaxCurrentLayer].addr
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
  scrollParallaxContent = Rectangle(x: 0, y: 0, width: globalState.textures.layerTextures[parallaxCurrentLayer].width.float32*32 + max(0, scrollParallaxView.width - viewSize.x), height: globalState.textures.layerTextures[parallaxCurrentLayer].height.float32*32 + max(0, scrollParallaxView.height - viewSize.y))
  scissorMode(scrollParallaxView.x.int32, scrollParallaxView.y.int32, scrollParallaxView.width.int32, scrollParallaxView.height.int32):
    clearBackground(Color(r: 72, g: 48, b: 168, a: 255))
    for i in countdown(globalState.currentLevel.layers.len - 1, 0):
      if (not showParallaxLayers and parallaxCurrentLayer != i) or (showParallaxMask and showParallaxLayers and i != SpriteLayerNum):
        continue

      let layer = globalState.currentLevel.layers[i].addr
      let offset = calculateParallaxLayerOffset(viewSize, alignment, i)

      shaderMode(shaderTile):
        shaderTile.setShaderValueTexture(shaderTilePaletteLoc, globalState.textures.palette)
        shaderTile.setShaderValueTexture(shaderTileTilesetMapLoc, globalState.textures.staticTileLUT)
        if showParallaxMask:
          shaderTile.setShaderValueTexture(shaderTileTilesetImageLoc, globalState.textures.tilesetMask)
        else:
          shaderTile.setShaderValueTexture(shaderTileTilesetImageLoc, globalState.textures.tilesetImage)
        drawTiles(globalState.textures.layerTextures[i], offset, scrollParallaxView, layer.properties.tileWidth, layer.properties.tileHeight)

    if showParallaxGrid:
      grid(Rectangle(x: scrollParallaxView.x + currentLayerOffset.x, y: scrollParallaxView.y + currentLayerOffset.y, width: currentLayer.width.float * 32, height: currentLayer.height.float * 32), "", 32*4, 4, mouseCell)
    if showParallaxEvents and parallaxCurrentLayer == SpriteLayerNum:
      eventStyle:
        drawEvents(scrollParallaxView, currentLayerOffset, globalState.currentLevel.events)

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
  toggleGroup(Rectangle(x: scrollParallaxPos.x + scrollParallaxPos.width - 8*(18+2) - 20 - 20 - 20 - 20 - 80 - 2*8, y: scrollParallaxPos.y + 2, width: 18, height: 20), "1;2;3;4;5;6;7;8", parallaxCurrentLayer)
  disableTooltip()