
when defined(emscripten):
  --define:GraphicsApiOpenGlEs2
  #--define:GraphicsApiOpenGlEs3
  --define:NaylibWebResources
  switch("define", "NaylibWebResourcesPath=assets")
  #switch("define", "NaylibWebPthreadPoolSize=2")
  #--define:NaylibWebAsyncify
  --os:linux
  --cpu:wasm32
  --cc:clang
  --debugger:native
  when buildOS == "windows":
    --clang.exe:emcc.bat
    --clang.linkerexe:emcc.bat
    --clang.cpp.exe:emcc.bat
    --clang.cpp.linkerexe:emcc.bat
  else:
    --clang.exe:emcc
    --clang.linkerexe:emcc
    --clang.cpp.exe:emcc
    --clang.cpp.linkerexe:emcc
  --mm:orc
  --threads:on
  --panics:on
  --define:noSignalHandler
  --passL:"-sSTACK_SIZE=1mb"
  --passL:"-o build/index.html"
  # Use raylib/src/shell.html or raylib/src/minshell.html
  --passL:"--shell-file tests/minshell.html"
  when not defined(release):
    --passL:"-gsource-map"
