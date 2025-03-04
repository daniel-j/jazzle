import std/os
import std/strutils
import std/sequtils
import raylib, raygui
import ../format/tileset
import ../shaders
import ../state
import ../actions
import ./tiles
import ./events

var scrollTilesetView = Rectangle()
var scrollTileset = Vector2()
var showTilesetGrid = true
var showTilesetMask = false
var showTilesetEvents = true
var tilesetDropdown: seq[(string, string)]
var tilesetDropdownStr: string
var tilesetDropdownSelection: int32 = 0
var tilesetDropdownOpened = false

proc updateTilesetList*() =
  var currentTilesetFilename = ""
  if tilesetDropdown.len < tilesetDropdownSelection:
    currentTilesetFilename = tilesetDropdown[tilesetDropdownSelection][0]
  tilesetDropdown = @[("", "<< No tileset >>")]
  tilesetDropdownSelection = 0
  var tileset: Tileset
  for w in walkDir(globalState.resourcePath):
    if w.kind != pcFile: continue
    let path = w.path.splitFile()
    if path.ext.toLower == ".j2t":
      if tileset.load(w.path, infoOnly = true):
        let f = w.path.lastPathPart
        if f == currentTilesetFilename:
          tilesetDropdownSelection = tilesetDropdown.len.int32
        tilesetDropdown.add((f, tileset.title))
  tilesetDropdownStr = tilesetDropdown.map(proc (res: (string, string)): string =
    res[1].replace(";", "")
  ).join(";")

channelTilesetFilename.sub(proc (tilesetFilename: string) =
  if tilesetFilename == "":
    tilesetDropdownSelection = 0
  for i, tileset in tilesetDropdown:
    if tileset[0] == tilesetFilename:
      tilesetDropdownSelection = i.int32
      break
)

proc showTilesetPane*(scrollTilesetPos: Rectangle) =
  var mouseCell = Vector2()
  let tilesetRec = Rectangle(x: 0, y: 0, width: float32 globalState.textures.tilesetGrid.width * 32, height: float32 globalState.textures.tilesetGrid.height * 32)

  scrollPanel(scrollTilesetPos, "Tileset", tilesetRec, scrollTileset, scrollTilesetView)
  scissorMode(scrollTilesetView.x.int32, scrollTilesetView.y.int32, scrollTilesetView.width.int32, scrollTilesetView.height.int32):
    clearBackground(Color(r: 72, g: 48, b: 168, a: 255))
    if showTilesetGrid:
      grid(Rectangle(x: scrollTilesetView.x + scrollTileset.x, y: scrollTilesetView.y + scrollTileset.y, width: tilesetRec.width, height: tilesetRec.height), "", 32*5, 5, mouseCell)
    shaderMode(shaderTile):
      shaderTile.setShaderValueTexture(shaderTilePaletteLoc, globalState.textures.palette)
      shaderTile.setShaderValueTexture(shaderTileTilesetMapLoc, globalState.textures.staticTileLUT)
      if showTilesetMask:
        shaderTile.setShaderValueTexture(shaderTileTilesetImageLoc, globalState.textures.tilesetMask)
      else:
        shaderTile.setShaderValueTexture(shaderTileTilesetImageLoc, globalState.textures.tilesetImage)
      drawTiles(globalState.textures.tilesetGrid, scrollTileset, scrollTilesetView)
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
    if showTilesetEvents:
      eventStyle:
        drawEvents(scrollTilesetView, scrollTileset, 10, globalState.currentLevel.tilesetEvents)

proc showTilesetControls*(scrollTilesetPos: Rectangle) =
  enableTooltip()
  # tileset controls
  setTooltip("Grid")
  toggle(Rectangle(x: scrollTilesetPos.x + scrollTilesetPos.width - 20 - 2*1, y: scrollTilesetPos.y + 2, width: 20, height: 20), iconText(Grid), showTilesetGrid)
  setTooltip("Collision mask")
  toggle(Rectangle(x: scrollTilesetPos.x + scrollTilesetPos.width - 20 - 20 - 2*2, y: scrollTilesetPos.y + 2, width: 20, height: 20), iconText(BoxCircleMask), showTilesetMask)
  setTooltip("Events")
  toggle(Rectangle(x: scrollTilesetPos.x + scrollTilesetPos.width - 20 - 20 - 20 - 2*3, y: scrollTilesetPos.y + 2, width: 20, height: 20), iconText(PlayerJump), showTilesetEvents)
  setTooltip("")
  let lastSelectedTileset = tilesetDropdownSelection
  if dropdownBox(Rectangle(x: scrollTilesetPos.x + scrollTilesetPos.width - 200 - 20 - 20 - 20 - 2*5, y: scrollTilesetPos.y + 2, width: 200, height: 20), tilesetDropdownStr, tilesetDropdownSelection, tilesetDropdownOpened):
    tilesetDropdownOpened = not tilesetDropdownOpened
    if not tilesetDropdownOpened and tilesetDropdownSelection != lastSelectedTileset:
      if tilesetDropdownSelection == 0:
        globalState.currentTileset = NoTileset
        loadTilesetData()
      else:
        loadTilesetFilename(globalState.resourcePath / tilesetDropdown[tilesetDropdownSelection][0])
  disableTooltip()
