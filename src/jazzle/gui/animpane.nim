import raylib, raygui, rlgl
import ../format/level
import ../state
import ../actions
import ../shaders
import ./tiles
import ./events

var animGrid: Texture2D
var animsUpdated = true
var scrollAnimView = Rectangle()
var scrollAnim = Vector2()
var showAnimGrid = true
var showAnimMask = false
var showAnimEvents = true

channelLevelFilename.sub(proc (filename: string) =
  if globalState.currentLevel.anims.len > 0:
    let width = 10
    let height = (globalState.currentLevel.anims.len + width - 1) div width
    var animGridData = newSeq[uint16](width * height)
    for i in 0 ..< globalState.currentLevel.anims.len:
      let tileId = globalState.currentLevel.animOffset.int + i
      animGridData[i] = uint16 tileId

    animGrid = Texture2D(
      id: rlgl.loadTexture(animGridData[0].addr, int32 width, int32 height, UncompressedGrayAlpha.int32, 1),
      width: int32 width,
      height: int32 height,
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
)
channelUpdate.sub(proc (t: float64) =

  animsUpdated = globalState.currentLevel.updateAnims(t) or animsUpdated

  if animsUpdated:
    let offset = globalState.currentLevel.animOffset.int
    for i, anim in globalState.currentLevel.anims:
      let tile = globalState.currentLevel.calculateAnimTile(i.uint16)
      globalState.animTiles[i] = tile
      let tileId = tile.tileId + tile.hflipped.uint16 * 0x1000 + tile.vflipped.uint16 * 0x2000
      globalState.tilesetMapData[offset + i] = tileId
    rlgl.updateTexture(globalState.textures.staticTileLUT.id, 0, 0, 64, 64, UncompressedGrayAlpha, globalState.tilesetMapData[0].addr)
    animsUpdated = false
)

proc showAnimPane*(scrollAnimPos: Rectangle) =
  var mouseCell = Vector2()
  let animRec = Rectangle(x: 0, y: 0, width: float32 animGrid.width * 32, height: float32 animGrid.height * 32)
  scrollPanel(scrollAnimPos, "Animations", animRec, scrollAnim, scrollAnimView)
  scissorMode(scrollAnimView.x.int32, scrollAnimView.y.int32, scrollAnimView.width.int32, scrollAnimView.height.int32):
    clearBackground(Color(r: 31, g: 24, b: 81, a: 255))
    # if showAnimGrid:
    #   grid(Rectangle(x: scrollAnimView.x + scrollAnim.x, y: scrollAnimView.y + scrollAnim.y, width: animRec.width, height: animRec.height), "", 32, 1, mouseCell)
    # shaderMode(shaderTile):
    #   shaderTile.setShaderValueTexture(shaderTilePaletteLoc, globalState.textures.palette)
    #   shaderTile.setShaderValueTexture(shaderTileTilesetMapLoc, globalState.textures.staticTileLUT)
    #   if showAnimMask:
    #     shaderTile.setShaderValueTexture(shaderTileTilesetImageLoc, globalState.textures.tilesetMask)
    #   else:
    #     shaderTile.setShaderValueTexture(shaderTileTilesetImageLoc, globalState.textures.tilesetImage)
    #   drawTiles(animGrid, scrollAnim, scrollAnimView)
    shaderMode(shaderIndexed):
      shaderIndexed.setShaderValueTexture(shaderIndexedPaletteLoc, globalState.textures.palette)
      let texture = if showAnimMask:
        globalState.textures.tilesetMask.addr
      else:
        globalState.textures.tilesetImage.addr
      for i, anim in globalState.currentLevel.anims:
        let dest = Rectangle(
          x: (i mod 10).float * 32 + scrollAnimView.x + scrollAnim.x,
          y: (i div 10).float * 32 + scrollAnimView.y + scrollAnim.y,
          width: 32, height: 32
        )
        if not checkCollisionRecs(scrollAnimView, dest): continue
        let tile = globalState.animTiles[i]
        if tile.tileId == 0: continue
        let src = Rectangle(
          x: float (tile.tileId mod 64) * 32,
          y: float (tile.tileId div 64) * 32,
          width: if tile.hflipped: -32 else: 32,
          height: if tile.vflipped: -32 else: 32
        )
        drawRectangle(dest, Color(r: 72, g: 48, b: 168, a: 255))
        drawTexture(texture[], src, dest, Vector2(), 0, White)
    if showAnimEvents:
      eventStyle:
        for i, anim in globalState.currentLevel.anims:
          let offset = Vector2(
            x: scrollAnim.x + (i mod 10).float * 32,
            y: scrollAnim.y + (i div 10).float * 32
          )
          drawEvent(scrollAnimView, offset, anim.event)

proc showAnimControls*(scrollAnimPos: Rectangle) =
  enableTooltip()
  # anim controls
  setTooltip("Grid")
  toggle(Rectangle(x: scrollAnimPos.x + scrollAnimPos.width - 20 - 2*1, y: scrollAnimPos.y + 2, width: 20, height: 20), iconText(Grid), showAnimGrid)
  setTooltip("Collision mask")
  toggle(Rectangle(x: scrollAnimPos.x + scrollAnimPos.width - 20 - 20 - 2*2, y: scrollAnimPos.y + 2, width: 20, height: 20), iconText(BoxCircleMask), showAnimMask)
  setTooltip("Events")
  toggle(Rectangle(x: scrollAnimPos.x + scrollAnimPos.width - 20 - 20 - 20 - 2*3, y: scrollAnimPos.y + 2, width: 20, height: 20), iconText(PlayerJump), showAnimEvents)
  disableTooltip()