# Package

version       = "0.1.0"
author        = "djazz"
description   = "Jazz Level Editor"
license       = "MIT"
srcDir        = "src"
bin           = @["jazzle"]
backend       = "c"

# Dependencies

requires "nim >= 1.0.0"
requires "nimgl >= 1.3.2"
requires "imgui >= 1.91.1"
