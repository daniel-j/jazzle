
when defined(emscripten):
  --define:release
  #--define:GraphicsApiOpenGlEs2
  --define:GraphicsApiOpenGlEs3
  --define:NaylibWebResources
  switch("define", "NaylibWebResourcesPath=assets")
  switch("define", "NaylibWebPthreadPoolSize=2")
  --define:NaylibWebAsyncify
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
  --passL:"-s STACK_SIZE=4mb"
  #--passL:"-sALLOW_MEMORY_GROWTH=1"
  --passL:"-s INITIAL_MEMORY=128mb"
  #--passL:"-s MAXIMUM_MEMORY=500mb"
  --passL:"-o build/index.html"
  --passL:"--shell-file tests/minshell.html"
  --passC:"--cache wasmcache/emcc"
  --passL:"--cache wasmcache/emcc"
  when not defined(release):
    --passL:"-gsource-map"
