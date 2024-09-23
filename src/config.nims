import std/os, std/compilesettings
import imgui/helpers

const backend = querySetting(SingleValueSetting.backend)

when backend != "cpp" or defined(cimguiDLL):
  echo "copying " & imgui_dll & " to " & getCurrentDir()
  cpFile(imgui_dll_path / imgui_dll, getCurrentDir() / imgui_dll)
