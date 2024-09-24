

import raylib

const
  screenWidth = 800
  screenHeight = 600

var lastCurrentMonitor: int32 = 0

proc monitorChanged(monitor: int32) =
  setTargetFPS(getMonitorRefreshRate(monitor)) # Set our game to run at display framerate frames-per-second

proc updateDrawFrame {.cdecl.} =
  # Update and draw
  # --------------------------------------------------------------------------------------
  beginDrawing()
  clearBackground(RayWhite)
  drawText("Congrats! You created your first window!", 190, 100, 20, LightGray)
  drawText(cstring "FPS: " & $getFPS(), 190, 130, 20, Black)
  endDrawing()
  # --------------------------------------------------------------------------------------


proc main =

  # initialize window
  const f = flags(WindowResizable, VsyncHint)
  setConfigFlags(f)
  initWindow(screenWidth, screenHeight, "JazzLE")
  defer: closeWindow()
  setExitKey(KeyboardKey.Null)
  setWindowMinSize(320, 100)
  # maximizeWindow()

  when defined(emscripten):
    emscriptenSetMainLoop(updateDrawFrame, 0, 1)
  else:
    # lastCurrentMonitor = getCurrentMonitor()
    # monitorChanged(lastCurrentMonitor)

    # Main game loop
    while not windowShouldClose(): # Detect window close button or ESC key
      # let currentMonitor = getCurrentMonitor()
      # if lastCurrentMonitor != currentMonitor:
      #   lastCurrentMonitor = currentMonitor
      #   monitorChanged(currentMonitor)

      updateDrawFrame()

main()
