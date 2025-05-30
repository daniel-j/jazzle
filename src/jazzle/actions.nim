import raylib, rlgl
import ./format/level, ./format/tileset
import ./state
import std/os

when not defined(emscripten):
  import ./gui/tinyfiledialogs

type
  GrayAlpha {.packed.} = object
    gray: uint8
    alpha: uint8

  PubSub*[T] = object
    callbacks*: seq[proc (message: T)]

proc pub*[T](self: PubSub; message: T) =
  for cb in self.callbacks:
    cb(message)
proc sub*[T](self: var PubSub; cb: proc (message: T)) =
  self.callbacks.add(cb)

var channelTilesetFilename*: PubSub[string]
var channelLevelFilename*: PubSub[string]
var channelUpdate*: PubSub[float64]

proc loadTilesetData*() =
  const width = 64 * 32
  const height = 64 * 32
  var imageData = newSeq[GrayAlpha](width * height)
  var maskData = newSeq[GrayAlpha](width * height)
  let tileset10Height = (globalState.currentTileset.tiles.len + 9) div 10

  for i, tile in globalState.currentTileset.tiles:
    if i == 0: continue
    globalState.tilesetMapData[i] = uint16 i
    let alpha = if globalState.currentLevel.tileTypes[i] == Translucent: 180'u8 else: 255'u8
    for j in 0..<32*32:
      let x = (i mod 64) * 32 + (j mod 32)
      let y = (i div 64) * 32 + (j div 32)
      let index = x + y * width
      imageData[index].gray = tile[j].color
      imageData[index].alpha = if tile[j].transMask: alpha else: 0'u8
      maskData[index].gray = 0
      maskData[index].alpha = if tile[j].mask: 255'u8 else: 0'u8

  globalState.textures.tilesetImage = Texture2D(
    id: rlgl.loadTexture(imageData[0].addr, width.int32, height.int32, UncompressedGrayAlpha.int32, 1),
    width: width.int32,
    height: height.int32,
    mipmaps: 1,
    format: UncompressedGrayAlpha
  )
  globalState.textures.tilesetImage.setTextureFilter(Point)
  globalState.textures.tilesetImage.setTextureWrap(Clamp)
  globalState.textures.tilesetMask = Texture2D(
    id: rlgl.loadTexture(maskData[0].addr, width.int32, height.int32, UncompressedGrayAlpha.int32, 1),
    width: width.int32,
    height: height.int32,
    mipmaps: 1,
    format: UncompressedGrayAlpha
  )
  globalState.textures.tilesetMask.setTextureFilter(Point)
  globalState.textures.tilesetMask.setTextureWrap(Clamp)
  imageData.reset()
  maskData.reset()

  globalState.textures.tilesetGrid = Texture2D(
    id: rlgl.loadTexture(globalState.tilesetMapData[0].addr, 10, tileset10Height.int32, UncompressedGrayAlpha.int32, 1),
    width: 10,
    height: tileset10Height.int32,
    mipmaps: 1,
    format: UncompressedGrayAlpha
  )
  globalState.textures.tilesetGrid.setTextureFilter(Point)
  globalState.textures.tilesetGrid.setTextureWrap(Clamp)

  globalState.textures.staticTileLUT = Texture2D(
    id: rlgl.loadTexture(globalState.tilesetMapData[0].addr, 64, 64, UncompressedGrayAlpha.int32, 1),
    width: 64,
    height: 64,
    mipmaps: 1,
    format: UncompressedGrayAlpha
  )
  globalState.textures.staticTileLUT.setTextureFilter(Point)
  globalState.textures.staticTileLUT.setTextureWrap(Clamp)

  globalState.textures.palette = Texture2D(
    id: rlgl.loadTexture(globalState.currentTileset.palette[0].addr, 256, 1, UncompressedR8g8b8a8.int32, 1),
    width: 256.int32,
    height: 1.int32,
    mipmaps: 1,
    format: UncompressedR8g8b8a8
  )
  globalState.textures.palette.setTextureFilter(Point)
  globalState.textures.palette.setTextureWrap(Clamp)

  # shaderTile.setShaderValueTexture(shaderTileTilesetImageLoc, tilesetImage)
  # shaderTile.setShaderValueTexture(shaderTileTilesetMapLoc, tilesetIndex64Texture)
  # shaderTile.setShaderValueTexture(shaderTilePaletteLoc, paletteTexture)

  # shaderIndexed.setShaderValueTexture(shaderIndexedPaletteLoc, paletteTexture)

proc loadTilesetFilename*(filename: string) =
  if globalState.currentTileset.load(filename):
    globalState.currentTileset.cleanup() # clears tileoffset and data buffers, not used anymore
    loadTilesetData()
    channelTilesetFilename.pub(filename.lastPathPart)

proc loadLevelData*() =
  for i, layer in globalState.currentLevel.layers:
    var layerData = newSeq[uint16](layer.width * layer.height)
    let realWidth = ((layer.realWidth + 3) div 4) * 4
    if layer.haveAnyTiles:
      for y in 0..<layer.height:
        for x in 0..<layer.width:
          let tile = layer.map[y][x]
          var tileId = tile.tileId
          if tile.animated: tileId += globalState.currentLevel.animOffset
          tileId += tile.hflipped.uint16 * 0x1000 + tile.vflipped.uint16 * 0x2000
          let index = x + y * layer.width
          layerData[index] = tileId

    globalState.textures.layerTextures[i] = Texture2D(
      id: rlgl.loadTexture(layerData[0].addr, layer.width.int32, layer.height.int32, UncompressedGrayAlpha.int32, 1),
      width: layer.width.int32,
      height: layer.height.int32,
      mipmaps: 1,
      format: UncompressedGrayAlpha
    )

  let tilesetFilename = lastPathPart(globalState.currentLevel.tileset)
  if tilesetFilename == "":
    globalState.currentTileset = NoTileset
    loadTilesetData()
    channelTilesetFilename.pub("")
  else:
    if fileExists(globalState.resourcePath / tilesetFilename):
      loadTilesetFilename(globalState.resourcePath / tilesetFilename)

  channelLevelFilename.pub(globalState.currentLevel.filename.lastPathPart)

# import taskpools

proc loadLevelFilename*(filename: string) =
  echo "trying to load file ", filename
  # var tp = Taskpool.new()
  #let level = tp.spawn(loadLevel(filename, jcsEvents))
  # discard tp.spawn tasker(filename)
  # tp.syncAll()
  # tp.shutdown()
  if globalState.currentLevel.load(filename, jcsEvents):
    echo "loaded ", globalState.currentLevel.filename
    loadLevelData()
  else:
    echo "couldnt load level!"

proc createNewLevel*() =
  globalState.currentLevel = newLevel()
  loadLevelData()

when defined(emscripten):
  when defined(cpp):
    {.pragma: EMSCRIPTEN_KEEPALIVE, cdecl, exportc, codegenDecl: "__attribute__((used)) extern \"C\" $# $#$#".}
  else:
    {.pragma: EMSCRIPTEN_KEEPALIVE, cdecl, exportc, codegenDecl: "__attribute__((used)) $# $#$#".}

  proc openFilePicker*() {.importc.}
  proc openSavePicker*(filename: cstring; filenameLen: int; data: cstring; dataLen: int) {.importc.}

  proc openFileCompleted(name: cstring; length: int; data: ptr uint8) {.EMSCRIPTEN_KEEPALIVE.} =
    echo "file completed", name
    echo (length)
    var str = newString(length)
    copyMem(str[0].addr, data, str.len)
    createDir("/uploads")
    writeFile("/uploads/" & $name, str)
    loadLevelFilename("/uploads/" & $name)

  proc saveFile*() =
    echo globalState.currentLevel.filename
    echo extractFilename(globalState.currentLevel.filename)
    globalState.currentLevel.save("/level_saved.j2l")
    let data = readFile("/level_saved.j2l")
    let filename = extractFilename(globalState.currentLevel.filename)
    echo filename
    openSavePicker(filename.cstring, filename.len, data.cstring, data.len)

else:
  {.pragma: EMSCRIPTEN_KEEPALIVE, cdecl, exportc.}

  proc openFilePicker*() =
    let openFilename = tinyfd_openFileDialogEx("Open Jazz2 Level", "", ["*.j2l".cstring], "Jazz2 Level")
    if openFilename.isNil:
      return
    loadLevelFilename($openFilename)

  proc openSavePicker*() =
    let saveFilename = tinyfd_saveFileDialogEx("Save Jazz2 Level", "", ["*.j2l".cstring], "Jazz2 Level")
    if saveFilename.isNil:
      return
    globalState.currentLevel.save($saveFilename)


  proc saveFile*() =
    openSavePicker()
    #globalState.currentLevel.save("level_saved.j2l")
