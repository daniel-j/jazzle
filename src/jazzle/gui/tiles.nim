import raylib, rlgl
import ../shaders

proc drawTiles*(texture: Texture2D; position: Vector2; viewRect: Rectangle; tileWidth: bool = false; tileHeight: bool = false; alpha: uint8 = 255) =
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
