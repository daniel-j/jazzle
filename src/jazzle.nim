import std/math
import std/os
import raylib, rlgl, raygui

import jazzle/format/level

import ./jazzle/gui
import ./jazzle/state
import ./jazzle/shaders
import ./jazzle/actions

const
  screenWidth = 1280
  screenHeight = 720
  levelFile = "Tube2.j2l"


var lastCurrentMonitor: int32 = 0

var mouseUpdated = true
var lastMousePos = Vector2()

var scrollParallaxPos = Rectangle(x: 335, y: 20, width: 1, height: 1)
var scrollTilesetPos = Rectangle(x: 0, y: 20, width: 334, height: 1)
var scrollAnimPos = Rectangle(x: 0, y: 20, width: 334, height: 1)

proc monitorChanged(monitor: int32) =
  setTargetFPS(getMonitorRefreshRate(monitor)) # Set our game to run at display framerate frames-per-second

proc update() =
  let t = getTime()
  globalState.time = t

  when defined(emscripten):
    if isWindowResized():
      setWindowSize(getScreenWidth(), getScreenHeight())

  let mousePos = getMousePosition()
  if lastMousePos != mousePos:
    mouseUpdated = true
  lastMousePos = mousePos

  channelUpdate.pub(t)


proc draw() =
  # if not animsUpdated and not mouseUpdated: return
  beginDrawing()
  clearBackground(getColor(guiGetStyle(GuiControl.Default, BackgroundColor).uint32))

  scrollAnimPos.height = 200
  scrollAnimPos.y = getRenderHeight().float - scrollAnimPos.height
  scrollTilesetPos.height = getRenderHeight().float - scrollAnimPos.height - 19
  scrollParallaxPos.width = getRenderWidth().float - scrollParallaxPos.x
  scrollParallaxPos.height = getRenderHeight().float - scrollParallaxPos.y

  if isMainMenuActive or tilesetDropdownOpened or parallaxResolutionOpened:
    guiLock()

  showTilesetPane(scrollTilesetPos)
  showAnimPane(scrollAnimPos)
  showParallaxPane(scrollParallaxPos)

  showTilesetControls(scrollTilesetPos)
  showAnimControls(scrollAnimPos)
  showParallaxControls(scrollParallaxPos)

  # var i = 0
  # for icon in GuiIconName:
  #   let x = (i mod 16) + 1
  #   let y = (i div 16) + 1
  #   drawIcon(icon, int32 x * 32, int32 y * 32, 2, White)
  #   inc(i)

  guiUnlock()

  case showMenu(mainMenu, 20):
  of MenuNone: discard
  of MenuFileNew: createNewLevel()
  of MenuFileOpen: openFilePicker()
  of MenuLevelProperties: discard
  of MenuFileSave: saveFile()

  # discard GuiButton(Rectangle(x: 25, y: 255, width: 125, height: 30), GuiIconText(ICON_FILE_SAVE.cint, "Save File".cstring))
  # let mbox = GuiMessageBox(Rectangle(x: 85, y: 70, width: 250, height: 100), "#191#Message Box", "Hi! This is a message!", "Nice;Cool")
  # if mbox != -1: echo mbox

  drawText("FPS: " & $getFPS(), getRenderWidth() - 100, 1, 20, Gold)

  endDrawing()
  mouseUpdated = false


proc updateDrawFrame {.cdecl.} =
  update()
  draw()

proc main =

  jcsEvents = loadJcsIni("assets/JCS.ini")

  # initialize window
  const f = flags(WindowResizable, VsyncHint)
  setConfigFlags(f)
  initWindow(screenWidth, screenHeight, "JazzLE")
  defer: closeWindow()
  setExitKey(KeyboardKey.Null)
  setWindowMinSize(320, 240)
  # maximizeWindow()

  guiSetStyle(GuiControl.Default, BorderColorNormal, cast[int32](0x898988ff))
  guiSetStyle(GuiControl.Default, BaseColorNormal, cast[int32](0x292929ff))
  guiSetStyle(GuiControl.Default, TextColorNormal, cast[int32](0xd4d4d4ff))
  guiSetStyle(GuiControl.Default, BorderColorFocused, cast[int32](0xeb891dff))
  guiSetStyle(GuiControl.Default, BaseColorFocused, cast[int32](0x292929ff))
  guiSetStyle(GuiControl.Default, TextColorFocused, cast[int32](0xffffffff))
  guiSetStyle(GuiControl.Default, BorderColorPressed, cast[int32](0xf1cf9dff))
  guiSetStyle(GuiControl.Default, BaseColorPressed, cast[int32](0xf39333ff))
  guiSetStyle(GuiControl.Default, TextColorPressed, cast[int32](0x282020ff))
  guiSetStyle(GuiControl.Default, BorderColorDisabled, cast[int32](0x6a6a6aff))
  guiSetStyle(GuiControl.Default, BaseColorDisabled, cast[int32](0x818181ff))
  guiSetStyle(GuiControl.Default, TextColorDisabled, cast[int32](0x606060ff))
  #guiSetStyle(GuiControl.Default, TextSize, cast[int32](0x00000010))
  guiSetStyle(GuiControl.Default, LineColor, cast[int32](0xef922aff))
  guiSetStyle(GuiControl.Default, BackgroundColor, cast[int32](0x333333ff))
  #guiSetStyle(GuiControl.Default, TextLineSpacing, cast[int32](0x00000018))
  guiSetStyle(GuiControl.Slider, TextColorPressed, cast[int32](0xd4d4d4ff))
  guiSetStyle(GuiControl.ProgressBar, TextColorPressed, cast[int32](0xd4d4d4ff))

  guiSetStyle(GuiControl.Scrollbar, ArrowsVisible, 1)

  for i in 0..<10:
    beginDrawing()
    drawText("Loading...", getRenderWidth() div 2 - measureText("Loading...", 96) div 2, getRenderHeight() div 2 + 96 div 2, 96, Gold)
    let icon = loadTexture("assets/icon.png")
    drawTexture(icon, getRenderWidth() div 2 - icon.width div 2, getRenderHeight() div 2 - icon.height + 30, White)
    endDrawing()

  initShaders()

  updateTilesetList()

  loadLevelFilename(globalState.resourcePath / levelFile)

  when defined(emscripten):
    setWindowSize(getScreenWidth(), getScreenHeight())
    emscriptenSetMainLoop(updateDrawFrame, 0, 1)
  else:
    # lastCurrentMonitor = getCurrentMonitor()
    # monitorChanged(lastCurrentMonitor)

    # Main game loop
    while not windowShouldClose(): # Detect window close button
      # let currentMonitor = getCurrentMonitor()
      # if lastCurrentMonitor != currentMonitor:
      #   lastCurrentMonitor = currentMonitor
      #   monitorChanged(currentMonitor)

      updateDrawFrame()

when isMainModule:
  main()
