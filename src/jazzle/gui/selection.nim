import std/math
import raylib

proc drawSelection*(view: Rectangle; offset: Vector2) =
  let mousePos = getMousePosition()
  let mousePosTile = Vector2(x: (mousePos.x - view.x - offset.x) / 32, y: (mousePos.y - view.y - offset.y) / 32)
  drawRectangleLines(Rectangle(x: view.x + offset.x + floor(mousePosTile.x) * 32, y: view.y + offset.y + floor(mousePosTile.y) * 32, width: 32, height: 32), 1, Pink)
