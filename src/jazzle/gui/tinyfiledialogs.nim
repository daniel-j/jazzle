## TinyFileDialogs Nim
## ===================
##
## TinyFileDialogs wrapper for Nim.
##
## Cross-platform InputBox, PasswordBox, MessageBox, OpenFileDialog, SaveFileDialog, SelectFolderDialog.
## Native dialogs for Windows, Mac, OSX, GTK+, Qt, Console.
## SSH supported via automatic switch to console mode or X11 forwarding.
##
## Widgets:
## --------
##
## - Beep Sound.
## - Notify popup.
## - Message Dialog.
## - Question Dialog.
## - Input Dialog.
## - Password Dialog.
## - Save file Dialog.
## - Open file Dialog.
## - Select folder Dialog.
## - Color picker.
##
## API
## ---
##
## - ``aDialogType`` must be one of ``"ok"``, ``"okcancel"``, ``"yesno"``, ``"yesnocancel"``, ``string`` type.
## - ``aIconType`` must be one of ``"info"``, ``"warning"``, ``"error"``, ``"question"``, ``string`` type.
## - ``aDefaultButton`` must be one of ``0`` (for Cancel), ``1`` (for Ok), ``2`` (for No), ``range[0..2]`` type.
## - ``aDefaultInput`` must be ``nil`` (for Password entry field) or any string for plain text entry field with a default value, ``string`` or ``nil`` type.
## - ``aAllowMultipleSelects`` must be ``0`` (false) or ``1`` (true), multiple selection returns 1 ``string`` with paths divided by ``|``, ``int`` type.
# All Credit for TinyFileDialogs lib goes to TinyFileDialogs Authors. This is just a tiny wrapper. Feel free to use your own "tinyfiledialogs.c" too.

{.compile: "../external/tinyfiledialogs/tinyfiledialogs.c".}

proc tinyfd_beep*(): void {.importc: "tinyfd_beep".}

proc tinyfd_notifyPopup*(aTitle: cstring, aMessage: cstring, aIconType: cstring): cint {.importc: "tinyfd_notifyPopup".}

proc tinyfd_messageBox*(aTitle: cstring, aMessage: cstring, aDialogType: cstring, aIconType: cstring, aDefaultButton: range[0..2]): cint {.importc: "tinyfd_messageBox".}

proc tinyfd_inputBox*(aTitle: cstring, aMessage: cstring, aDefaultInput: cstring = nil): cstring {.importc: "tinyfd_inputBox".}

proc tinyfd_saveFileDialog*(aTitle: cstring, aDefaultPathAndFile: cstring, aNumOfFilterPatterns: cint = 0, aFilterPatterns: ptr UncheckedArray[cstring], aSingleFilterDescription: cstring = "", aAllowMultipleSelects: cint = 0): cstring {.importc: "tinyfd_saveFileDialog".}

proc tinyfd_openFileDialog*(aTitle: cstring, aDefaultPathAndFile: cstring, aNumOfFilterPatterns: cint = 0, aFilterPatterns: ptr UncheckedArray[cstring], aSingleFilterDescription: cstring = "", aAllowMultipleSelects: cint = 0): cstring {.importc: "tinyfd_openFileDialog".}

proc tinyfd_selectFolderDialog*(aTitle: cstring, aDefaultPath: cstring): cstring {.importc: "tinyfd_selectFolderDialog".}

proc tinyfd_colorChooser*(aTitle: cstring, aDefaultHexRGB: cstring; aDefaultRGB: array[3, uint8], aoResultRGB: var array[3, uint8]): cstring {.importc: "tinyfd_colorChooser".}


proc tinyfd_saveFileDialogEx*(aTitle: cstring, aDefaultPathAndFile: cstring, aFilterPatterns: openArray[cstring], aSingleFilterDescription: cstring = "", aAllowMultipleSelects: bool = false): cstring =
  tinyfd_saveFileDialog(aTitle, aDefaultPathAndFile, aFilterPatterns.len.cint, if aFilterPatterns.len > 0: cast[ptr UncheckedArray[cstring]](aFilterPatterns[0].addr) else: nil, aSingleFilterDescription, aAllowMultipleSelects.cint)

proc tinyfd_openFileDialogEx*(aTitle: cstring, aDefaultPathAndFile: cstring, aFilterPatterns: openArray[cstring], aSingleFilterDescription: cstring = "", aAllowMultipleSelects: bool = false): cstring =
  tinyfd_openFileDialog(aTitle, aDefaultPathAndFile, aFilterPatterns.len.cint, if aFilterPatterns.len > 0: cast[ptr UncheckedArray[cstring]](aFilterPatterns[0].addr) else: nil, aSingleFilterDescription, aAllowMultipleSelects.cint)

runnableExamples:
  tinyfd_beep()
  echo tinyfd_notifyPopup("Title", "aMessage", "info")
  echo tinyfd_messageBox("Title", "aMessage", "yesnocancel", "info", 1)
  echo tinyfd_inputBox("a password box", "some message")               # Password.
  echo tinyfd_inputBox("plain text box", "some message", "any string") # Plain Text.
  echo tinyfd_openFileDialog("You can Open Files with this", "")
  echo tinyfd_saveFileDialog("You can Save Files with this", "")
  echo tinyfd_selectFolderDialog("You can Open Folders with this", "")
  var colorOut: array[3, uint8]
  echo tinyfd_colorChooser("Color Picker", "#FF0000", [0.uint8 , 128 , 255], colorOut), " ", colorOut
