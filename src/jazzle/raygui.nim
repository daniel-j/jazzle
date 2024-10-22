import raylib

{.passC: "-I./csource".}
{.compile: "csource/raygui.c".}

#type rlRectangle = Rectangle

when defined(futharkRebuild):
  import futhark, strutils
  const raylibSrc = staticExec("nimble path naylib").split("\n")[0].strip() & "/raylib"
  importc:
    outputPath "src/jazzle/futhark_raygui.nim"
    path "../../csource"
    sysPath raylibSrc
    sysPath getClangIncludePath()
    rename rlRectangle, Rectangle
    "raygui.h"
    "style_dark.h"
else:
  include ./futhark_raygui

