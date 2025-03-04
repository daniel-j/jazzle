import raylib, rlgl

const
  shaderIndexedFs = staticRead("shaders/indexed.fs")
  shaderTileFs = staticRead("shaders/tile.fs")

var
  shaderTile*: Shader
  shaderTilePaletteLoc*: ShaderLocation
  shaderTileTilesetImageLoc*: ShaderLocation
  shaderTileLayerSizeLoc*: ShaderLocation
  shaderTileTilesetMapLoc*: ShaderLocation

  shaderIndexed*: Shader
  shaderIndexedPaletteLoc*: ShaderLocation

proc initShaders*() =
  echo rlgl.getVersion()
  let shaderPrefix = case rlgl.getVersion():
  of OpenGl43, OpenGl33: "#version 330\nout vec4 finalColor;\n"
  of OpenGlEs20: "#version 100\nprecision mediump float;\n#define texture texture2D\n#define finalColor gl_FragColor\n#define in varying\n"
  of OpenGlEs30: "#version 300 es\nprecision mediump float;\nout vec4 finalColor;\n"
  else: ""

  shaderTile = loadShaderFromMemory("", shaderPrefix & shaderTileFs)
  shaderTilePaletteLoc = shaderTile.getShaderLocation("texture1")
  shaderTileTilesetImageLoc = shaderTile.getShaderLocation("texture2")
  shaderTileTilesetMapLoc = shaderTile.getShaderLocation("texture3")
  shaderTileLayerSizeLoc = shaderTile.getShaderLocation("layerSize")

  shaderIndexed = loadShaderFromMemory("", shaderPrefix & shaderIndexedFs)
  shaderIndexedPaletteLoc = shaderIndexed.getShaderLocation("texture1")
