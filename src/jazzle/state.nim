import raylib
import ./format/tileset
import ./format/level

type
  Textures* = object
    palette*: Texture2D
    staticTileLUT*: Texture2D
    tilesetImage*: Texture2D
    tilesetMask*: Texture2D
    tilesetGrid*: Texture2D
    layerTextures*: array[8, Texture2D]

  State* = object
    resourcePath*: string
    time*: float64
    currentTileset*: Tileset
    currentLevel*: Level
    animTiles*: array[256, Tile]
    tilesetMapData*: array[64*64, uint16]
    textures*: Textures

var globalState* = State(
  resourcePath: "assets",
  currentTileset: NoTileset,
  currentLevel: newLevel()
)
