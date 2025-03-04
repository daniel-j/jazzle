import std/math
import raylib, raygui
import ../format/level
import ../state

template eventStyle*(body: untyped) =
  let labelStye = guiGetStyle(Label, TextColorNormal)
  let alignment = guiGetStyle(Label, TextAlignment)
  let textSize = guiGetStyle(GuiControl.Default, TextSize)
  let textLineSpacing = guiGetStyle(GuiControl.Default, TextLineSpacing)
  guiSetStyle(Label, TextColorNormal, cast[int32](0xffffffff'u32))
  guiSetStyle(Label, TextAlignment, Center)
  guiSetStyle(Default, TextSize, 10)
  #guiSetStyle(Default, TextLineSpacing, 14)
  try:
    body
  finally:
    guiSetStyle(Label, TextAlignment, alignment)
    guiSetStyle(Label, TextColorNormal, labelStye)
    guiSetStyle(Default, TextSize, textSize)
    guiSetStyle(Default, TextLineSpacing, textLineSpacing)

proc drawEvent*(bounds: Rectangle; offset: Vector2; evt: Event) =
  if evt.eventId == None:
    return
  let rect = Rectangle(
    x: bounds.x + offset.x,
    y: bounds.y + offset.y,
    width: 32,
    height: 32
  )
  if not checkCollisionRecs(bounds, rect):
    return

  let t = globalState.time
  let isGenerator = evt.eventId == Generator
  var eventId = evt.eventId
  let params = evt.params
  if isGenerator:
    eventId = params[0].EventId

  let rectOuter = Rectangle(
    x: rect.x - 6,
    y: rect.y,
    width: rect.width + 12,
    height: rect.height
  )

  drawRectangle(rect, Color(r: 0, g: 0, b: 0, a: 70))

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

proc drawEvents*(bounds: Rectangle; offset: Vector2; events: seq[seq[Event]]) =
  for y in 0..<events.len:
    for x in 0..<events[y].len:
      let evt = events[y][x]
      drawEvent(bounds, Vector2(x: offset.x + x.float * 32, y: offset.y + y.float * 32), evt)

proc drawEvents*(bounds: Rectangle; offset: Vector2; width: int; events: openArray[Event]) =
  for i in 0..<events.len:
    let x = i mod width
    let y = i div width
    let evt = events[i]
    drawEvent(bounds, Vector2(x: offset.x + x.float * 32, y: offset.y + y.float * 32), evt)
