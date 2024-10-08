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
requires "naylib >= 24.40"
requires "zippy >= 0.10.16"
requires "pixie >= 5.0.7"
requires "parseini >= 0.3.0"
