# Package

version       = "0.1.0"
author        = "djazz"
description   = "Jazz Jackrabbit Level Editor"
license       = "MIT"
srcDir        = "src"
bin           = @["jazzle"]
backend       = "c"

# Dependencies

requires "nim >= 2.0.0"
requires "naylib >= 24.41"
requires "zippy >= 0.10.16"
requires "pixie >= 5.0.7"
requires "parseini >= 0.3.0"

task wasm, "Compile to WASM using Emscripten":
  mkDir("assets")
  mkDir("build")
  exec("nim " & backend & " -d:emscripten " & srcDir & "/jazzle")
