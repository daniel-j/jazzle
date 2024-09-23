import nimgl/[glfw, opengl]
import imgui, imgui/[impl_opengl, impl_glfw]

proc keyCallback(window: GLFWWindow; key: int32; scancode: int32,
             action: int32; mods: int32) {.cdecl.} =
  echo "key: ", (key, scancode, action, mods)
  if key == GLFWKey.ESCAPE and action == GLFWPress:
    window.setWindowShouldClose(true)

proc framebufferSizeCallback(window: GLFWWindow, width, height: int32) {.cdecl.} =
  echo "framebuffer size: ", (width, height)
  glViewport(0, 0, width, height)

proc cursorPosCallback(window: GLFWWindow; xpos, ypos: float64) {.cdecl.} =
  #echo "cursor position: ", (xpos, ypos)
  discard

proc mouseButtonCallback(window: GLFWWindow; button, action, mods: int32) {.cdecl.} =
  echo "mouse button: ", (button, action, mods)

proc scrollCallback(window: GLFWWindow; xoffset, yoffset: float64) {.cdecl.} =
  echo "scroll: ", (xoffset, yoffset)

proc cursorEnterCallback(window: GLFWWindow; entered: bool) {.cdecl.} =
  echo "entered: ", entered

proc main() =
  assert glfwInit()
  defer: glfwTerminate()

  glfwWindowHint(GLFWContextVersionMajor, 3)
  glfwWindowHint(GLFWContextVersionMinor, 3)
  glfwWindowHint(GLFWOpenglForwardCompat, GLFW_TRUE) # Used for Mac
  glfwWindowHint(GLFWDoublebuffer, 1)
  glfwWindowHint(GLFWDepthBits, 24)
  glfwWindowHint(GLFWStencilBits, 8)
  glfwWindowHint(GLFWOpenglProfile, GLFW_OPENGL_CORE_PROFILE)
  glfwWindowHint(GLFWResizable, GLFW_TRUE)

  block:
    let w: GLFWWindow = glfwCreateWindow(800, 600, "JazzLE")
    if w == nil:
      return

    defer: w.destroyWindow()

    discard w.setKeyCallback(keyCallback)
    discard w.setFramebufferSizeCallback(framebufferSizeCallback)
    discard w.setCursorEnterCallback(cursorEnterCallback)
    discard w.setCursorPosCallback(cursorPosCallback)
    discard w.setMouseButtonCallback(mouseButtonCallback)
    discard w.setScrollCallback(scrollCallback)
    w.makeContextCurrent()

    glfwSwapInterval(1)

    assert glInit()

    let context = igCreateContext()
    defer: context.igDestroyContext()
    doAssert igGlfwInitForOpenGL(w, true)
    defer: igGlfwShutdown()
    doAssert igOpenGL3Init()
    defer: igOpenGL3Shutdown()
    # let io = igGetIO()

    igStyleColorsCherry()


    var windowWidth, windowHeight: int32 = 0
    w.getWindowSize(windowWidth.addr, windowHeight.addr)
    glViewport(0, 0, windowWidth, windowHeight)

    var show_demo: bool = true

    while not w.windowShouldClose:
      glfwPollEvents()

      igOpenGL3NewFrame()
      igGlfwNewFrame()
      igNewFrame()

      #igBegin("Hello, world!")

      if show_demo:
        igShowDemoWindow(show_demo.addr)

      #igEnd()
      igRender()

      glClearColor(0.68f, 1f, 0.34f, 1f)
      glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT)

      igOpenGL3RenderDrawData(igGetDrawData())

      w.swapBuffers()

main()
