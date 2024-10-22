
{.warning[UnusedImport]: off.}
{.hint[XDeclaredButNotUsed]: off.}
from macros import hint, warning, newLit, getSize

from os import parentDir

macro ownSizeof(x: typed): untyped =
  newLit(x.getSize)

type
  enum_GuiState_536871372* {.size: sizeof(cuint).} = enum
    STATE_NORMAL = 0, STATE_FOCUSED = 1, STATE_PRESSED = 2, STATE_DISABLED = 3
type
  enum_GuiTextAlignment_536871376* {.size: sizeof(cuint).} = enum
    TEXT_ALIGN_LEFT = 0, TEXT_ALIGN_CENTER = 1, TEXT_ALIGN_RIGHT = 2
type
  enum_GuiTextAlignmentVertical_536871380* {.size: sizeof(cuint).} = enum
    TEXT_ALIGN_TOP = 0, TEXT_ALIGN_MIDDLE = 1, TEXT_ALIGN_BOTTOM = 2
type
  enum_GuiTextWrapMode_536871384* {.size: sizeof(cuint).} = enum
    TEXT_WRAP_NONE = 0, TEXT_WRAP_CHAR = 1, TEXT_WRAP_WORD = 2
type
  enum_GuiControl_536871388* {.size: sizeof(cuint).} = enum
    DEFAULT = 0, LABEL = 1, BUTTON = 2, TOGGLE = 3, SLIDER = 4, PROGRESSBAR = 5,
    CHECKBOX = 6, COMBOBOX = 7, DROPDOWNBOX = 8, TEXTBOX = 9, VALUEBOX = 10,
    SPINNER = 11, LISTVIEW = 12, COLORPICKER = 13, SCROLLBAR = 14,
    STATUSBAR = 15
type
  enum_GuiControlProperty_536871392* {.size: sizeof(cuint).} = enum
    BORDER_COLOR_NORMAL = 0, BASE_COLOR_NORMAL = 1, TEXT_COLOR_NORMAL = 2,
    BORDER_COLOR_FOCUSED = 3, BASE_COLOR_FOCUSED = 4, TEXT_COLOR_FOCUSED = 5,
    BORDER_COLOR_PRESSED = 6, BASE_COLOR_PRESSED = 7, TEXT_COLOR_PRESSED = 8,
    BORDER_COLOR_DISABLED = 9, BASE_COLOR_DISABLED = 10,
    TEXT_COLOR_DISABLED = 11, BORDER_WIDTH = 12, TEXT_PADDING = 13,
    TEXT_ALIGNMENT = 14
type
  enum_GuiDefaultProperty_536871396* {.size: sizeof(cuint).} = enum
    TEXT_SIZE = 16, TEXT_SPACING = 17, LINE_COLOR = 18, BACKGROUND_COLOR = 19,
    TEXT_LINE_SPACING = 20, TEXT_ALIGNMENT_VERTICAL = 21, TEXT_WRAP_MODE = 22
type
  enum_GuiToggleProperty_536871400* {.size: sizeof(cuint).} = enum
    GROUP_PADDING = 16
type
  enum_GuiSliderProperty_536871404* {.size: sizeof(cuint).} = enum
    SLIDER_WIDTH = 16, SLIDER_PADDING = 17
type
  enum_GuiProgressBarProperty_536871408* {.size: sizeof(cuint).} = enum
    PROGRESS_PADDING = 16
type
  enum_GuiScrollBarProperty_536871412* {.size: sizeof(cuint).} = enum
    ARROWS_SIZE = 16, ARROWS_VISIBLE = 17, SCROLL_SLIDER_PADDING = 18,
    SCROLL_SLIDER_SIZE = 19, SCROLL_PADDING = 20, SCROLL_SPEED = 21
type
  enum_GuiCheckBoxProperty_536871416* {.size: sizeof(cuint).} = enum
    CHECK_PADDING = 16
type
  enum_GuiComboBoxProperty_536871420* {.size: sizeof(cuint).} = enum
    COMBO_BUTTON_WIDTH = 16, COMBO_BUTTON_SPACING = 17
type
  enum_GuiDropdownBoxProperty_536871424* {.size: sizeof(cuint).} = enum
    ARROW_PADDING = 16, DROPDOWN_ITEMS_SPACING = 17, DROPDOWN_ARROW_HIDDEN = 18,
    DROPDOWN_ROLL_UP = 19
type
  enum_GuiTextBoxProperty_536871428* {.size: sizeof(cuint).} = enum
    TEXT_READONLY = 16
type
  enum_GuiSpinnerProperty_536871432* {.size: sizeof(cuint).} = enum
    SPIN_BUTTON_WIDTH = 16, SPIN_BUTTON_SPACING = 17
type
  enum_GuiListViewProperty_536871436* {.size: sizeof(cuint).} = enum
    LIST_ITEMS_HEIGHT = 16, LIST_ITEMS_SPACING = 17, SCROLLBAR_WIDTH = 18,
    SCROLLBAR_SIDE = 19, LIST_ITEMS_BORDER_WIDTH = 20
type
  enum_GuiColorPickerProperty_536871440* {.size: sizeof(cuint).} = enum
    COLOR_SELECTOR_SIZE = 16, HUEBAR_WIDTH = 17, HUEBAR_PADDING = 18,
    HUEBAR_SELECTOR_HEIGHT = 19, HUEBAR_SELECTOR_OVERFLOW = 20
type
  enum_GuiIconName_536871452* {.size: sizeof(cuint).} = enum
    ICON_NONE = 0, ICON_FOLDER_FILE_OPEN = 1, ICON_FILE_SAVE_CLASSIC = 2,
    ICON_FOLDER_OPEN = 3, ICON_FOLDER_SAVE = 4, ICON_FILE_OPEN = 5,
    ICON_FILE_SAVE = 6, ICON_FILE_EXPORT = 7, ICON_FILE_ADD = 8,
    ICON_FILE_DELETE = 9, ICON_FILETYPE_TEXT = 10, ICON_FILETYPE_AUDIO = 11,
    ICON_FILETYPE_IMAGE = 12, ICON_FILETYPE_PLAY = 13, ICON_FILETYPE_VIDEO = 14,
    ICON_FILETYPE_INFO = 15, ICON_FILE_COPY = 16, ICON_FILE_CUT = 17,
    ICON_FILE_PASTE = 18, ICON_CURSOR_HAND = 19, ICON_CURSOR_POINTER = 20,
    ICON_CURSOR_CLASSIC = 21, ICON_PENCIL = 22, ICON_PENCIL_BIG = 23,
    ICON_BRUSH_CLASSIC = 24, ICON_BRUSH_PAINTER = 25, ICON_WATER_DROP = 26,
    ICON_COLOR_PICKER = 27, ICON_RUBBER = 28, ICON_COLOR_BUCKET = 29,
    ICON_TEXT_T = 30, ICON_TEXT_A = 31, ICON_SCALE = 32, ICON_RESIZE = 33,
    ICON_FILTER_POINT = 34, ICON_FILTER_BILINEAR = 35, ICON_CROP = 36,
    ICON_CROP_ALPHA = 37, ICON_SQUARE_TOGGLE = 38, ICON_SYMMETRY = 39,
    ICON_SYMMETRY_HORIZONTAL = 40, ICON_SYMMETRY_VERTICAL = 41, ICON_LENS = 42,
    ICON_LENS_BIG = 43, ICON_EYE_ON = 44, ICON_EYE_OFF = 45,
    ICON_FILTER_TOP = 46, ICON_FILTER = 47, ICON_TARGET_POINT = 48,
    ICON_TARGET_SMALL = 49, ICON_TARGET_BIG = 50, ICON_TARGET_MOVE = 51,
    ICON_CURSOR_MOVE = 52, ICON_CURSOR_SCALE = 53, ICON_CURSOR_SCALE_RIGHT = 54,
    ICON_CURSOR_SCALE_LEFT = 55, ICON_UNDO = 56, ICON_REDO = 57,
    ICON_REREDO = 58, ICON_MUTATE = 59, ICON_ROTATE = 60, ICON_REPEAT = 61,
    ICON_SHUFFLE = 62, ICON_EMPTYBOX = 63, ICON_TARGET = 64,
    ICON_TARGET_SMALL_FILL = 65, ICON_TARGET_BIG_FILL = 66,
    ICON_TARGET_MOVE_FILL = 67, ICON_CURSOR_MOVE_FILL = 68,
    ICON_CURSOR_SCALE_FILL = 69, ICON_CURSOR_SCALE_RIGHT_FILL = 70,
    ICON_CURSOR_SCALE_LEFT_FILL = 71, ICON_UNDO_FILL = 72, ICON_REDO_FILL = 73,
    ICON_REREDO_FILL = 74, ICON_MUTATE_FILL = 75, ICON_ROTATE_FILL = 76,
    ICON_REPEAT_FILL = 77, ICON_SHUFFLE_FILL = 78, ICON_EMPTYBOX_SMALL = 79,
    ICON_BOX = 80, ICON_BOX_TOP = 81, ICON_BOX_TOP_RIGHT = 82,
    ICON_BOX_RIGHT = 83, ICON_BOX_BOTTOM_RIGHT = 84, ICON_BOX_BOTTOM = 85,
    ICON_BOX_BOTTOM_LEFT = 86, ICON_BOX_LEFT = 87, ICON_BOX_TOP_LEFT = 88,
    ICON_BOX_CENTER = 89, ICON_BOX_CIRCLE_MASK = 90, ICON_POT = 91,
    ICON_ALPHA_MULTIPLY = 92, ICON_ALPHA_CLEAR = 93, ICON_DITHERING = 94,
    ICON_MIPMAPS = 95, ICON_BOX_GRID = 96, ICON_GRID = 97,
    ICON_BOX_CORNERS_SMALL = 98, ICON_BOX_CORNERS_BIG = 99,
    ICON_FOUR_BOXES = 100, ICON_GRID_FILL = 101, ICON_BOX_MULTISIZE = 102,
    ICON_ZOOM_SMALL = 103, ICON_ZOOM_MEDIUM = 104, ICON_ZOOM_BIG = 105,
    ICON_ZOOM_ALL = 106, ICON_ZOOM_CENTER = 107, ICON_BOX_DOTS_SMALL = 108,
    ICON_BOX_DOTS_BIG = 109, ICON_BOX_CONCENTRIC = 110, ICON_BOX_GRID_BIG = 111,
    ICON_OK_TICK = 112, ICON_CROSS = 113, ICON_ARROW_LEFT = 114,
    ICON_ARROW_RIGHT = 115, ICON_ARROW_DOWN = 116, ICON_ARROW_UP = 117,
    ICON_ARROW_LEFT_FILL = 118, ICON_ARROW_RIGHT_FILL = 119,
    ICON_ARROW_DOWN_FILL = 120, ICON_ARROW_UP_FILL = 121, ICON_AUDIO = 122,
    ICON_FX = 123, ICON_WAVE = 124, ICON_WAVE_SINUS = 125,
    ICON_WAVE_SQUARE = 126, ICON_WAVE_TRIANGULAR = 127, ICON_CROSS_SMALL = 128,
    ICON_PLAYER_PREVIOUS = 129, ICON_PLAYER_PLAY_BACK = 130,
    ICON_PLAYER_PLAY = 131, ICON_PLAYER_PAUSE = 132, ICON_PLAYER_STOP = 133,
    ICON_PLAYER_NEXT = 134, ICON_PLAYER_RECORD = 135, ICON_MAGNET = 136,
    ICON_LOCK_CLOSE = 137, ICON_LOCK_OPEN = 138, ICON_CLOCK = 139,
    ICON_TOOLS = 140, ICON_GEAR = 141, ICON_GEAR_BIG = 142, ICON_BIN = 143,
    ICON_HAND_POINTER = 144, ICON_LASER = 145, ICON_COIN = 146,
    ICON_EXPLOSION = 147, ICON_1UP = 148, ICON_PLAYER = 149,
    ICON_PLAYER_JUMP = 150, ICON_KEY = 151, ICON_DEMON = 152,
    ICON_TEXT_POPUP = 153, ICON_GEAR_EX = 154, ICON_CRACK = 155,
    ICON_CRACK_POINTS = 156, ICON_STAR = 157, ICON_DOOR = 158, ICON_EXIT = 159,
    ICON_MODE_2D = 160, ICON_MODE_3D = 161, ICON_CUBE = 162,
    ICON_CUBE_FACE_TOP = 163, ICON_CUBE_FACE_LEFT = 164,
    ICON_CUBE_FACE_FRONT = 165, ICON_CUBE_FACE_BOTTOM = 166,
    ICON_CUBE_FACE_RIGHT = 167, ICON_CUBE_FACE_BACK = 168, ICON_CAMERA = 169,
    ICON_SPECIAL = 170, ICON_LINK_NET = 171, ICON_LINK_BOXES = 172,
    ICON_LINK_MULTI = 173, ICON_LINK = 174, ICON_LINK_BROKE = 175,
    ICON_TEXT_NOTES = 176, ICON_NOTEBOOK = 177, ICON_SUITCASE = 178,
    ICON_SUITCASE_ZIP = 179, ICON_MAILBOX = 180, ICON_MONITOR = 181,
    ICON_PRINTER = 182, ICON_PHOTO_CAMERA = 183, ICON_PHOTO_CAMERA_FLASH = 184,
    ICON_HOUSE = 185, ICON_HEART = 186, ICON_CORNER = 187,
    ICON_VERTICAL_BARS = 188, ICON_VERTICAL_BARS_FILL = 189,
    ICON_LIFE_BARS = 190, ICON_INFO = 191, ICON_CROSSLINE = 192,
    ICON_HELP = 193, ICON_FILETYPE_ALPHA = 194, ICON_FILETYPE_HOME = 195,
    ICON_LAYERS_VISIBLE = 196, ICON_LAYERS = 197, ICON_WINDOW = 198,
    ICON_HIDPI = 199, ICON_FILETYPE_BINARY = 200, ICON_HEX = 201,
    ICON_SHIELD = 202, ICON_FILE_NEW = 203, ICON_FOLDER_ADD = 204,
    ICON_ALARM = 205, ICON_CPU = 206, ICON_ROM = 207, ICON_STEP_OVER = 208,
    ICON_STEP_INTO = 209, ICON_STEP_OUT = 210, ICON_RESTART = 211,
    ICON_BREAKPOINT_ON = 212, ICON_BREAKPOINT_OFF = 213, ICON_BURGER_MENU = 214,
    ICON_CASE_SENSITIVE = 215, ICON_REG_EXP = 216, ICON_FOLDER = 217,
    ICON_FILE = 218, ICON_SAND_TIMER = 219, ICON_WARNING = 220,
    ICON_HELP_BOX = 221, ICON_INFO_BOX = 222, ICON_PRIORITY = 223,
    ICON_LAYERS_ISO = 224, ICON_LAYERS2 = 225, ICON_MLAYERS = 226,
    ICON_MAPS = 227, ICON_HOT = 228, ICON_229 = 229, ICON_230 = 230,
    ICON_231 = 231, ICON_232 = 232, ICON_233 = 233, ICON_234 = 234,
    ICON_235 = 235, ICON_236 = 236, ICON_237 = 237, ICON_238 = 238,
    ICON_239 = 239, ICON_240 = 240, ICON_241 = 241, ICON_242 = 242,
    ICON_243 = 243, ICON_244 = 244, ICON_245 = 245, ICON_246 = 246,
    ICON_247 = 247, ICON_248 = 248, ICON_249 = 249, ICON_250 = 250,
    ICON_251 = 251, ICON_252 = 252, ICON_253 = 253, ICON_254 = 254,
    ICON_255 = 255
type
  Rectangle_536871365 = struct_rlRectangle_536871466 ## Generated based on /home/djazz/.nimble/pkgs2/naylib-24.41-14ddf84cbfb248aabc7c9ff1cf1be35d32469937/raylib/raylib.h:254:3
  struct_GuiStyleProp_536871368 {.pure, inheritable, bycopy.} = object
    controlId*: cushort      ## Generated based on /home/djazz/code/nim/jazzle/csource/raygui.h:465:16
    propertyId*: cushort
    propertyValue*: cint
  GuiStyleProp_536871370 = struct_GuiStyleProp_536871369 ## Generated based on /home/djazz/code/nim/jazzle/csource/raygui.h:469:3
  GuiState_536871374 = enum_GuiState_536871373 ## Generated based on /home/djazz/code/nim/jazzle/csource/raygui.h:490:3
  GuiTextAlignment_536871378 = enum_GuiTextAlignment_536871377 ## Generated based on /home/djazz/code/nim/jazzle/csource/raygui.h:497:3
  GuiTextAlignmentVertical_536871382 = enum_GuiTextAlignmentVertical_536871381 ## Generated based on /home/djazz/code/nim/jazzle/csource/raygui.h:505:3
  GuiTextWrapMode_536871386 = enum_GuiTextWrapMode_536871385 ## Generated based on /home/djazz/code/nim/jazzle/csource/raygui.h:513:3
  GuiControl_536871390 = enum_GuiControl_536871389 ## Generated based on /home/djazz/code/nim/jazzle/csource/raygui.h:536:3
  GuiControlProperty_536871394 = enum_GuiControlProperty_536871393 ## Generated based on /home/djazz/code/nim/jazzle/csource/raygui.h:560:3
  GuiDefaultProperty_536871398 = enum_GuiDefaultProperty_536871397 ## Generated based on /home/djazz/code/nim/jazzle/csource/raygui.h:583:3
  GuiToggleProperty_536871402 = enum_GuiToggleProperty_536871401 ## Generated based on /home/djazz/code/nim/jazzle/csource/raygui.h:598:3
  GuiSliderProperty_536871406 = enum_GuiSliderProperty_536871405 ## Generated based on /home/djazz/code/nim/jazzle/csource/raygui.h:604:3
  GuiProgressBarProperty_536871410 = enum_GuiProgressBarProperty_536871409 ## Generated based on /home/djazz/code/nim/jazzle/csource/raygui.h:609:3
  GuiScrollBarProperty_536871414 = enum_GuiScrollBarProperty_536871413 ## Generated based on /home/djazz/code/nim/jazzle/csource/raygui.h:619:3
  GuiCheckBoxProperty_536871418 = enum_GuiCheckBoxProperty_536871417 ## Generated based on /home/djazz/code/nim/jazzle/csource/raygui.h:624:3
  GuiComboBoxProperty_536871422 = enum_GuiComboBoxProperty_536871421 ## Generated based on /home/djazz/code/nim/jazzle/csource/raygui.h:630:3
  GuiDropdownBoxProperty_536871426 = enum_GuiDropdownBoxProperty_536871425 ## Generated based on /home/djazz/code/nim/jazzle/csource/raygui.h:638:3
  GuiTextBoxProperty_536871430 = enum_GuiTextBoxProperty_536871429 ## Generated based on /home/djazz/code/nim/jazzle/csource/raygui.h:643:3
  GuiSpinnerProperty_536871434 = enum_GuiSpinnerProperty_536871433 ## Generated based on /home/djazz/code/nim/jazzle/csource/raygui.h:649:3
  GuiListViewProperty_536871438 = enum_GuiListViewProperty_536871437 ## Generated based on /home/djazz/code/nim/jazzle/csource/raygui.h:658:3
  GuiColorPickerProperty_536871442 = enum_GuiColorPickerProperty_536871441 ## Generated based on /home/djazz/code/nim/jazzle/csource/raygui.h:667:3
  Font_536871444 = struct_Font_536871468 ## Generated based on /home/djazz/.nimble/pkgs2/naylib-24.41-14ddf84cbfb248aabc7c9ff1cf1be35d32469937/raylib/raylib.h:317:3
  Color_536871446 = struct_Color_536871470 ## Generated based on /home/djazz/.nimble/pkgs2/naylib-24.41-14ddf84cbfb248aabc7c9ff1cf1be35d32469937/raylib/raylib.h:246:3
  Vector2_536871448 = struct_Vector2_536871472 ## Generated based on /home/djazz/.nimble/pkgs2/naylib-24.41-14ddf84cbfb248aabc7c9ff1cf1be35d32469937/raylib/raylib.h:212:3
  Vector3_536871450 = struct_Vector3_536871474 ## Generated based on /home/djazz/.nimble/pkgs2/naylib-24.41-14ddf84cbfb248aabc7c9ff1cf1be35d32469937/raylib/raylib.h:219:3
  GuiIconName_536871461 = enum_GuiIconName_536871460 ## Generated based on /home/djazz/code/nim/jazzle/csource/raygui.h:1030:3
  GlyphInfo_536871463 = struct_GlyphInfo_536871476 ## Generated based on /home/djazz/.nimble/pkgs2/naylib-24.41-14ddf84cbfb248aabc7c9ff1cf1be35d32469937/raylib/raylib.h:307:3
  struct_rlRectangle_536871465 {.pure, inheritable, bycopy.} = object
    x*: cfloat               ## Generated based on /home/djazz/.nimble/pkgs2/naylib-24.41-14ddf84cbfb248aabc7c9ff1cf1be35d32469937/raylib/raylib.h:249:16
    y*: cfloat
    width*: cfloat
    height*: cfloat
  struct_Font_536871467 {.pure, inheritable, bycopy.} = object
    baseSize*: cint          ## Generated based on /home/djazz/.nimble/pkgs2/naylib-24.41-14ddf84cbfb248aabc7c9ff1cf1be35d32469937/raylib/raylib.h:310:16
    glyphCount*: cint
    glyphPadding*: cint
    texture*: Texture2D_536871478
    recs*: ptr Rectangle_536871367
    glyphs*: ptr GlyphInfo_536871464
  struct_Color_536871469 {.pure, inheritable, bycopy.} = object
    r*: uint8                ## Generated based on /home/djazz/.nimble/pkgs2/naylib-24.41-14ddf84cbfb248aabc7c9ff1cf1be35d32469937/raylib/raylib.h:241:16
    g*: uint8
    b*: uint8
    a*: uint8
  struct_Vector2_536871471 {.pure, inheritable, bycopy.} = object
    x*: cfloat               ## Generated based on /home/djazz/.nimble/pkgs2/naylib-24.41-14ddf84cbfb248aabc7c9ff1cf1be35d32469937/raylib/raylib.h:209:16
    y*: cfloat
  struct_Vector3_536871473 {.pure, inheritable, bycopy.} = object
    x*: cfloat               ## Generated based on /home/djazz/.nimble/pkgs2/naylib-24.41-14ddf84cbfb248aabc7c9ff1cf1be35d32469937/raylib/raylib.h:215:16
    y*: cfloat
    z*: cfloat
  struct_GlyphInfo_536871475 {.pure, inheritable, bycopy.} = object
    value*: cint             ## Generated based on /home/djazz/.nimble/pkgs2/naylib-24.41-14ddf84cbfb248aabc7c9ff1cf1be35d32469937/raylib/raylib.h:301:16
    offsetX*: cint
    offsetY*: cint
    advanceX*: cint
    image*: Image_536871480
  Texture2D_536871477 = Texture_536871482 ## Generated based on /home/djazz/.nimble/pkgs2/naylib-24.41-14ddf84cbfb248aabc7c9ff1cf1be35d32469937/raylib/raylib.h:275:17
  Image_536871479 = struct_Image_536871484 ## Generated based on /home/djazz/.nimble/pkgs2/naylib-24.41-14ddf84cbfb248aabc7c9ff1cf1be35d32469937/raylib/raylib.h:263:3
  Texture_536871481 = struct_Texture_536871486 ## Generated based on /home/djazz/.nimble/pkgs2/naylib-24.41-14ddf84cbfb248aabc7c9ff1cf1be35d32469937/raylib/raylib.h:272:3
  struct_Image_536871483 {.pure, inheritable, bycopy.} = object
    data*: pointer           ## Generated based on /home/djazz/.nimble/pkgs2/naylib-24.41-14ddf84cbfb248aabc7c9ff1cf1be35d32469937/raylib/raylib.h:257:16
    width*: cint
    height*: cint
    mipmaps*: cint
    format*: cint
  struct_Texture_536871485 {.pure, inheritable, bycopy.} = object
    id*: cuint               ## Generated based on /home/djazz/.nimble/pkgs2/naylib-24.41-14ddf84cbfb248aabc7c9ff1cf1be35d32469937/raylib/raylib.h:266:16
    width*: cint
    height*: cint
    mipmaps*: cint
    format*: cint
  enum_GuiDefaultProperty_536871397 = (when declared(enum_GuiDefaultProperty):
    when ownSizeof(enum_GuiDefaultProperty) !=
        ownSizeof(enum_GuiDefaultProperty_536871396):
      static :
        warning("Declaration of " & "enum_GuiDefaultProperty" &
            " exists but with different size")
    enum_GuiDefaultProperty
   else:
    enum_GuiDefaultProperty_536871396)
  struct_rlRectangle_536871466 = (when declared(struct_rlRectangle):
    when ownSizeof(struct_rlRectangle) != ownSizeof(struct_rlRectangle_536871465):
      static :
        warning("Declaration of " & "struct_rlRectangle" &
            " exists but with different size")
    struct_rlRectangle
   else:
    struct_rlRectangle_536871465)
  GuiColorPickerProperty_536871443 = (when declared(GuiColorPickerProperty):
    when ownSizeof(GuiColorPickerProperty) != ownSizeof(GuiColorPickerProperty_536871442):
      static :
        warning("Declaration of " & "GuiColorPickerProperty" &
            " exists but with different size")
    GuiColorPickerProperty
   else:
    GuiColorPickerProperty_536871442)
  enum_GuiTextAlignmentVertical_536871381 = (when declared(
      enum_GuiTextAlignmentVertical):
    when ownSizeof(enum_GuiTextAlignmentVertical) !=
        ownSizeof(enum_GuiTextAlignmentVertical_536871380):
      static :
        warning("Declaration of " & "enum_GuiTextAlignmentVertical" &
            " exists but with different size")
    enum_GuiTextAlignmentVertical
   else:
    enum_GuiTextAlignmentVertical_536871380)
  GuiIconName_536871462 = (when declared(GuiIconName):
    when ownSizeof(GuiIconName) != ownSizeof(GuiIconName_536871461):
      static :
        warning("Declaration of " & "GuiIconName" &
            " exists but with different size")
    GuiIconName
   else:
    GuiIconName_536871461)
  enum_GuiColorPickerProperty_536871441 = (when declared(
      enum_GuiColorPickerProperty):
    when ownSizeof(enum_GuiColorPickerProperty) !=
        ownSizeof(enum_GuiColorPickerProperty_536871440):
      static :
        warning("Declaration of " & "enum_GuiColorPickerProperty" &
            " exists but with different size")
    enum_GuiColorPickerProperty
   else:
    enum_GuiColorPickerProperty_536871440)
  Texture2D_536871478 = (when declared(Texture2D):
    when ownSizeof(Texture2D) != ownSizeof(Texture2D_536871477):
      static :
        warning("Declaration of " & "Texture2D" &
            " exists but with different size")
    Texture2D
   else:
    Texture2D_536871477)
  enum_GuiSliderProperty_536871405 = (when declared(enum_GuiSliderProperty):
    when ownSizeof(enum_GuiSliderProperty) != ownSizeof(enum_GuiSliderProperty_536871404):
      static :
        warning("Declaration of " & "enum_GuiSliderProperty" &
            " exists but with different size")
    enum_GuiSliderProperty
   else:
    enum_GuiSliderProperty_536871404)
  GuiStyleProp_536871371 = (when declared(GuiStyleProp):
    when ownSizeof(GuiStyleProp) != ownSizeof(GuiStyleProp_536871370):
      static :
        warning("Declaration of " & "GuiStyleProp" &
            " exists but with different size")
    GuiStyleProp
   else:
    GuiStyleProp_536871370)
  enum_GuiListViewProperty_536871437 = (when declared(enum_GuiListViewProperty):
    when ownSizeof(enum_GuiListViewProperty) !=
        ownSizeof(enum_GuiListViewProperty_536871436):
      static :
        warning("Declaration of " & "enum_GuiListViewProperty" &
            " exists but with different size")
    enum_GuiListViewProperty
   else:
    enum_GuiListViewProperty_536871436)
  Vector2_536871449 = (when declared(Vector2):
    when ownSizeof(Vector2) != ownSizeof(Vector2_536871448):
      static :
        warning("Declaration of " & "Vector2" &
            " exists but with different size")
    Vector2
   else:
    Vector2_536871448)
  GuiScrollBarProperty_536871415 = (when declared(GuiScrollBarProperty):
    when ownSizeof(GuiScrollBarProperty) != ownSizeof(GuiScrollBarProperty_536871414):
      static :
        warning("Declaration of " & "GuiScrollBarProperty" &
            " exists but with different size")
    GuiScrollBarProperty
   else:
    GuiScrollBarProperty_536871414)
  enum_GuiDropdownBoxProperty_536871425 = (when declared(
      enum_GuiDropdownBoxProperty):
    when ownSizeof(enum_GuiDropdownBoxProperty) !=
        ownSizeof(enum_GuiDropdownBoxProperty_536871424):
      static :
        warning("Declaration of " & "enum_GuiDropdownBoxProperty" &
            " exists but with different size")
    enum_GuiDropdownBoxProperty
   else:
    enum_GuiDropdownBoxProperty_536871424)
  Rectangle_536871367 = (when declared(Rectangle):
    when ownSizeof(Rectangle) != ownSizeof(Rectangle_536871365):
      static :
        warning("Declaration of " & "Rectangle" &
            " exists but with different size")
    Rectangle
   else:
    Rectangle_536871365)
  struct_Font_536871468 = (when declared(struct_Font):
    when ownSizeof(struct_Font) != ownSizeof(struct_Font_536871467):
      static :
        warning("Declaration of " & "struct_Font" &
            " exists but with different size")
    struct_Font
   else:
    struct_Font_536871467)
  GuiComboBoxProperty_536871423 = (when declared(GuiComboBoxProperty):
    when ownSizeof(GuiComboBoxProperty) != ownSizeof(GuiComboBoxProperty_536871422):
      static :
        warning("Declaration of " & "GuiComboBoxProperty" &
            " exists but with different size")
    GuiComboBoxProperty
   else:
    GuiComboBoxProperty_536871422)
  GuiState_536871375 = (when declared(GuiState):
    when ownSizeof(GuiState) != ownSizeof(GuiState_536871374):
      static :
        warning("Declaration of " & "GuiState" &
            " exists but with different size")
    GuiState
   else:
    GuiState_536871374)
  GuiControlProperty_536871395 = (when declared(GuiControlProperty):
    when ownSizeof(GuiControlProperty) != ownSizeof(GuiControlProperty_536871394):
      static :
        warning("Declaration of " & "GuiControlProperty" &
            " exists but with different size")
    GuiControlProperty
   else:
    GuiControlProperty_536871394)
  struct_GlyphInfo_536871476 = (when declared(struct_GlyphInfo):
    when ownSizeof(struct_GlyphInfo) != ownSizeof(struct_GlyphInfo_536871475):
      static :
        warning("Declaration of " & "struct_GlyphInfo" &
            " exists but with different size")
    struct_GlyphInfo
   else:
    struct_GlyphInfo_536871475)
  Image_536871480 = (when declared(Image):
    when ownSizeof(Image) != ownSizeof(Image_536871479):
      static :
        warning("Declaration of " & "Image" & " exists but with different size")
    Image
   else:
    Image_536871479)
  enum_GuiToggleProperty_536871401 = (when declared(enum_GuiToggleProperty):
    when ownSizeof(enum_GuiToggleProperty) != ownSizeof(enum_GuiToggleProperty_536871400):
      static :
        warning("Declaration of " & "enum_GuiToggleProperty" &
            " exists but with different size")
    enum_GuiToggleProperty
   else:
    enum_GuiToggleProperty_536871400)
  enum_GuiScrollBarProperty_536871413 = (when declared(enum_GuiScrollBarProperty):
    when ownSizeof(enum_GuiScrollBarProperty) !=
        ownSizeof(enum_GuiScrollBarProperty_536871412):
      static :
        warning("Declaration of " & "enum_GuiScrollBarProperty" &
            " exists but with different size")
    enum_GuiScrollBarProperty
   else:
    enum_GuiScrollBarProperty_536871412)
  GuiTextAlignment_536871379 = (when declared(GuiTextAlignment):
    when ownSizeof(GuiTextAlignment) != ownSizeof(GuiTextAlignment_536871378):
      static :
        warning("Declaration of " & "GuiTextAlignment" &
            " exists but with different size")
    GuiTextAlignment
   else:
    GuiTextAlignment_536871378)
  GuiTextWrapMode_536871387 = (when declared(GuiTextWrapMode):
    when ownSizeof(GuiTextWrapMode) != ownSizeof(GuiTextWrapMode_536871386):
      static :
        warning("Declaration of " & "GuiTextWrapMode" &
            " exists but with different size")
    GuiTextWrapMode
   else:
    GuiTextWrapMode_536871386)
  GuiDefaultProperty_536871399 = (when declared(GuiDefaultProperty):
    when ownSizeof(GuiDefaultProperty) != ownSizeof(GuiDefaultProperty_536871398):
      static :
        warning("Declaration of " & "GuiDefaultProperty" &
            " exists but with different size")
    GuiDefaultProperty
   else:
    GuiDefaultProperty_536871398)
  enum_GuiSpinnerProperty_536871433 = (when declared(enum_GuiSpinnerProperty):
    when ownSizeof(enum_GuiSpinnerProperty) !=
        ownSizeof(enum_GuiSpinnerProperty_536871432):
      static :
        warning("Declaration of " & "enum_GuiSpinnerProperty" &
            " exists but with different size")
    enum_GuiSpinnerProperty
   else:
    enum_GuiSpinnerProperty_536871432)
  GuiToggleProperty_536871403 = (when declared(GuiToggleProperty):
    when ownSizeof(GuiToggleProperty) != ownSizeof(GuiToggleProperty_536871402):
      static :
        warning("Declaration of " & "GuiToggleProperty" &
            " exists but with different size")
    GuiToggleProperty
   else:
    GuiToggleProperty_536871402)
  enum_GuiComboBoxProperty_536871421 = (when declared(enum_GuiComboBoxProperty):
    when ownSizeof(enum_GuiComboBoxProperty) !=
        ownSizeof(enum_GuiComboBoxProperty_536871420):
      static :
        warning("Declaration of " & "enum_GuiComboBoxProperty" &
            " exists but with different size")
    enum_GuiComboBoxProperty
   else:
    enum_GuiComboBoxProperty_536871420)
  enum_GuiState_536871373 = (when declared(enum_GuiState):
    when ownSizeof(enum_GuiState) != ownSizeof(enum_GuiState_536871372):
      static :
        warning("Declaration of " & "enum_GuiState" &
            " exists but with different size")
    enum_GuiState
   else:
    enum_GuiState_536871372)
  GuiTextBoxProperty_536871431 = (when declared(GuiTextBoxProperty):
    when ownSizeof(GuiTextBoxProperty) != ownSizeof(GuiTextBoxProperty_536871430):
      static :
        warning("Declaration of " & "GuiTextBoxProperty" &
            " exists but with different size")
    GuiTextBoxProperty
   else:
    GuiTextBoxProperty_536871430)
  enum_GuiControl_536871389 = (when declared(enum_GuiControl):
    when ownSizeof(enum_GuiControl) != ownSizeof(enum_GuiControl_536871388):
      static :
        warning("Declaration of " & "enum_GuiControl" &
            " exists but with different size")
    enum_GuiControl
   else:
    enum_GuiControl_536871388)
  GuiCheckBoxProperty_536871419 = (when declared(GuiCheckBoxProperty):
    when ownSizeof(GuiCheckBoxProperty) != ownSizeof(GuiCheckBoxProperty_536871418):
      static :
        warning("Declaration of " & "GuiCheckBoxProperty" &
            " exists but with different size")
    GuiCheckBoxProperty
   else:
    GuiCheckBoxProperty_536871418)
  enum_GuiTextAlignment_536871377 = (when declared(enum_GuiTextAlignment):
    when ownSizeof(enum_GuiTextAlignment) != ownSizeof(enum_GuiTextAlignment_536871376):
      static :
        warning("Declaration of " & "enum_GuiTextAlignment" &
            " exists but with different size")
    enum_GuiTextAlignment
   else:
    enum_GuiTextAlignment_536871376)
  GuiListViewProperty_536871439 = (when declared(GuiListViewProperty):
    when ownSizeof(GuiListViewProperty) != ownSizeof(GuiListViewProperty_536871438):
      static :
        warning("Declaration of " & "GuiListViewProperty" &
            " exists but with different size")
    GuiListViewProperty
   else:
    GuiListViewProperty_536871438)
  Vector3_536871451 = (when declared(Vector3):
    when ownSizeof(Vector3) != ownSizeof(Vector3_536871450):
      static :
        warning("Declaration of " & "Vector3" &
            " exists but with different size")
    Vector3
   else:
    Vector3_536871450)
  struct_Vector2_536871472 = (when declared(struct_Vector2):
    when ownSizeof(struct_Vector2) != ownSizeof(struct_Vector2_536871471):
      static :
        warning("Declaration of " & "struct_Vector2" &
            " exists but with different size")
    struct_Vector2
   else:
    struct_Vector2_536871471)
  Font_536871445 = (when declared(Font):
    when ownSizeof(Font) != ownSizeof(Font_536871444):
      static :
        warning("Declaration of " & "Font" & " exists but with different size")
    Font
   else:
    Font_536871444)
  struct_Texture_536871486 = (when declared(struct_Texture):
    when ownSizeof(struct_Texture) != ownSizeof(struct_Texture_536871485):
      static :
        warning("Declaration of " & "struct_Texture" &
            " exists but with different size")
    struct_Texture
   else:
    struct_Texture_536871485)
  GlyphInfo_536871464 = (when declared(GlyphInfo):
    when ownSizeof(GlyphInfo) != ownSizeof(GlyphInfo_536871463):
      static :
        warning("Declaration of " & "GlyphInfo" &
            " exists but with different size")
    GlyphInfo
   else:
    GlyphInfo_536871463)
  Texture_536871482 = (when declared(Texture):
    when ownSizeof(Texture) != ownSizeof(Texture_536871481):
      static :
        warning("Declaration of " & "Texture" &
            " exists but with different size")
    Texture
   else:
    Texture_536871481)
  struct_Image_536871484 = (when declared(struct_Image):
    when ownSizeof(struct_Image) != ownSizeof(struct_Image_536871483):
      static :
        warning("Declaration of " & "struct_Image" &
            " exists but with different size")
    struct_Image
   else:
    struct_Image_536871483)
  GuiControl_536871391 = (when declared(GuiControl):
    when ownSizeof(GuiControl) != ownSizeof(GuiControl_536871390):
      static :
        warning("Declaration of " & "GuiControl" &
            " exists but with different size")
    GuiControl
   else:
    GuiControl_536871390)
  GuiSpinnerProperty_536871435 = (when declared(GuiSpinnerProperty):
    when ownSizeof(GuiSpinnerProperty) != ownSizeof(GuiSpinnerProperty_536871434):
      static :
        warning("Declaration of " & "GuiSpinnerProperty" &
            " exists but with different size")
    GuiSpinnerProperty
   else:
    GuiSpinnerProperty_536871434)
  struct_Vector3_536871474 = (when declared(struct_Vector3):
    when ownSizeof(struct_Vector3) != ownSizeof(struct_Vector3_536871473):
      static :
        warning("Declaration of " & "struct_Vector3" &
            " exists but with different size")
    struct_Vector3
   else:
    struct_Vector3_536871473)
  enum_GuiCheckBoxProperty_536871417 = (when declared(enum_GuiCheckBoxProperty):
    when ownSizeof(enum_GuiCheckBoxProperty) !=
        ownSizeof(enum_GuiCheckBoxProperty_536871416):
      static :
        warning("Declaration of " & "enum_GuiCheckBoxProperty" &
            " exists but with different size")
    enum_GuiCheckBoxProperty
   else:
    enum_GuiCheckBoxProperty_536871416)
  GuiDropdownBoxProperty_536871427 = (when declared(GuiDropdownBoxProperty):
    when ownSizeof(GuiDropdownBoxProperty) != ownSizeof(GuiDropdownBoxProperty_536871426):
      static :
        warning("Declaration of " & "GuiDropdownBoxProperty" &
            " exists but with different size")
    GuiDropdownBoxProperty
   else:
    GuiDropdownBoxProperty_536871426)
  struct_GuiStyleProp_536871369 = (when declared(struct_GuiStyleProp):
    when ownSizeof(struct_GuiStyleProp) != ownSizeof(struct_GuiStyleProp_536871368):
      static :
        warning("Declaration of " & "struct_GuiStyleProp" &
            " exists but with different size")
    struct_GuiStyleProp
   else:
    struct_GuiStyleProp_536871368)
  GuiSliderProperty_536871407 = (when declared(GuiSliderProperty):
    when ownSizeof(GuiSliderProperty) != ownSizeof(GuiSliderProperty_536871406):
      static :
        warning("Declaration of " & "GuiSliderProperty" &
            " exists but with different size")
    GuiSliderProperty
   else:
    GuiSliderProperty_536871406)
  GuiTextAlignmentVertical_536871383 = (when declared(GuiTextAlignmentVertical):
    when ownSizeof(GuiTextAlignmentVertical) !=
        ownSizeof(GuiTextAlignmentVertical_536871382):
      static :
        warning("Declaration of " & "GuiTextAlignmentVertical" &
            " exists but with different size")
    GuiTextAlignmentVertical
   else:
    GuiTextAlignmentVertical_536871382)
  enum_GuiTextWrapMode_536871385 = (when declared(enum_GuiTextWrapMode):
    when ownSizeof(enum_GuiTextWrapMode) != ownSizeof(enum_GuiTextWrapMode_536871384):
      static :
        warning("Declaration of " & "enum_GuiTextWrapMode" &
            " exists but with different size")
    enum_GuiTextWrapMode
   else:
    enum_GuiTextWrapMode_536871384)
  enum_GuiProgressBarProperty_536871409 = (when declared(
      enum_GuiProgressBarProperty):
    when ownSizeof(enum_GuiProgressBarProperty) !=
        ownSizeof(enum_GuiProgressBarProperty_536871408):
      static :
        warning("Declaration of " & "enum_GuiProgressBarProperty" &
            " exists but with different size")
    enum_GuiProgressBarProperty
   else:
    enum_GuiProgressBarProperty_536871408)
  Color_536871447 = (when declared(Color):
    when ownSizeof(Color) != ownSizeof(Color_536871446):
      static :
        warning("Declaration of " & "Color" & " exists but with different size")
    Color
   else:
    Color_536871446)
  enum_GuiControlProperty_536871393 = (when declared(enum_GuiControlProperty):
    when ownSizeof(enum_GuiControlProperty) !=
        ownSizeof(enum_GuiControlProperty_536871392):
      static :
        warning("Declaration of " & "enum_GuiControlProperty" &
            " exists but with different size")
    enum_GuiControlProperty
   else:
    enum_GuiControlProperty_536871392)
  enum_GuiIconName_536871460 = (when declared(enum_GuiIconName):
    when ownSizeof(enum_GuiIconName) != ownSizeof(enum_GuiIconName_536871452):
      static :
        warning("Declaration of " & "enum_GuiIconName" &
            " exists but with different size")
    enum_GuiIconName
   else:
    enum_GuiIconName_536871452)
  GuiProgressBarProperty_536871411 = (when declared(GuiProgressBarProperty):
    when ownSizeof(GuiProgressBarProperty) != ownSizeof(GuiProgressBarProperty_536871410):
      static :
        warning("Declaration of " & "GuiProgressBarProperty" &
            " exists but with different size")
    GuiProgressBarProperty
   else:
    GuiProgressBarProperty_536871410)
  enum_GuiTextBoxProperty_536871429 = (when declared(enum_GuiTextBoxProperty):
    when ownSizeof(enum_GuiTextBoxProperty) !=
        ownSizeof(enum_GuiTextBoxProperty_536871428):
      static :
        warning("Declaration of " & "enum_GuiTextBoxProperty" &
            " exists but with different size")
    enum_GuiTextBoxProperty
   else:
    enum_GuiTextBoxProperty_536871428)
  struct_Color_536871470 = (when declared(struct_Color):
    when ownSizeof(struct_Color) != ownSizeof(struct_Color_536871469):
      static :
        warning("Declaration of " & "struct_Color" &
            " exists but with different size")
    struct_Color
   else:
    struct_Color_536871469)
when not declared(enum_GuiDefaultProperty):
  type
    enum_GuiDefaultProperty* = enum_GuiDefaultProperty_536871396
else:
  static :
    hint("Declaration of " & "enum_GuiDefaultProperty" &
        " already exists, not redeclaring")
when not declared(struct_rlRectangle):
  type
    struct_rlRectangle* = struct_rlRectangle_536871465
else:
  static :
    hint("Declaration of " & "struct_rlRectangle" &
        " already exists, not redeclaring")
when not declared(GuiColorPickerProperty):
  type
    GuiColorPickerProperty* = GuiColorPickerProperty_536871442
else:
  static :
    hint("Declaration of " & "GuiColorPickerProperty" &
        " already exists, not redeclaring")
when not declared(enum_GuiTextAlignmentVertical):
  type
    enum_GuiTextAlignmentVertical* = enum_GuiTextAlignmentVertical_536871380
else:
  static :
    hint("Declaration of " & "enum_GuiTextAlignmentVertical" &
        " already exists, not redeclaring")
when not declared(GuiIconName):
  type
    GuiIconName* = GuiIconName_536871461
else:
  static :
    hint("Declaration of " & "GuiIconName" & " already exists, not redeclaring")
when not declared(enum_GuiColorPickerProperty):
  type
    enum_GuiColorPickerProperty* = enum_GuiColorPickerProperty_536871440
else:
  static :
    hint("Declaration of " & "enum_GuiColorPickerProperty" &
        " already exists, not redeclaring")
when not declared(Texture2D):
  type
    Texture2D* = Texture2D_536871477
else:
  static :
    hint("Declaration of " & "Texture2D" & " already exists, not redeclaring")
when not declared(enum_GuiSliderProperty):
  type
    enum_GuiSliderProperty* = enum_GuiSliderProperty_536871404
else:
  static :
    hint("Declaration of " & "enum_GuiSliderProperty" &
        " already exists, not redeclaring")
when not declared(GuiStyleProp):
  type
    GuiStyleProp* = GuiStyleProp_536871370
else:
  static :
    hint("Declaration of " & "GuiStyleProp" & " already exists, not redeclaring")
when not declared(enum_GuiListViewProperty):
  type
    enum_GuiListViewProperty* = enum_GuiListViewProperty_536871436
else:
  static :
    hint("Declaration of " & "enum_GuiListViewProperty" &
        " already exists, not redeclaring")
when not declared(Vector2):
  type
    Vector2* = Vector2_536871448
else:
  static :
    hint("Declaration of " & "Vector2" & " already exists, not redeclaring")
when not declared(GuiScrollBarProperty):
  type
    GuiScrollBarProperty* = GuiScrollBarProperty_536871414
else:
  static :
    hint("Declaration of " & "GuiScrollBarProperty" &
        " already exists, not redeclaring")
when not declared(enum_GuiDropdownBoxProperty):
  type
    enum_GuiDropdownBoxProperty* = enum_GuiDropdownBoxProperty_536871424
else:
  static :
    hint("Declaration of " & "enum_GuiDropdownBoxProperty" &
        " already exists, not redeclaring")
when not declared(Rectangle):
  type
    Rectangle* = Rectangle_536871365
else:
  static :
    hint("Declaration of " & "Rectangle" & " already exists, not redeclaring")
when not declared(struct_Font):
  type
    struct_Font* = struct_Font_536871467
else:
  static :
    hint("Declaration of " & "struct_Font" & " already exists, not redeclaring")
when not declared(GuiComboBoxProperty):
  type
    GuiComboBoxProperty* = GuiComboBoxProperty_536871422
else:
  static :
    hint("Declaration of " & "GuiComboBoxProperty" &
        " already exists, not redeclaring")
when not declared(GuiState):
  type
    GuiState* = GuiState_536871374
else:
  static :
    hint("Declaration of " & "GuiState" & " already exists, not redeclaring")
when not declared(GuiControlProperty):
  type
    GuiControlProperty* = GuiControlProperty_536871394
else:
  static :
    hint("Declaration of " & "GuiControlProperty" &
        " already exists, not redeclaring")
when not declared(struct_GlyphInfo):
  type
    struct_GlyphInfo* = struct_GlyphInfo_536871475
else:
  static :
    hint("Declaration of " & "struct_GlyphInfo" &
        " already exists, not redeclaring")
when not declared(Image):
  type
    Image* = Image_536871479
else:
  static :
    hint("Declaration of " & "Image" & " already exists, not redeclaring")
when not declared(enum_GuiToggleProperty):
  type
    enum_GuiToggleProperty* = enum_GuiToggleProperty_536871400
else:
  static :
    hint("Declaration of " & "enum_GuiToggleProperty" &
        " already exists, not redeclaring")
when not declared(enum_GuiScrollBarProperty):
  type
    enum_GuiScrollBarProperty* = enum_GuiScrollBarProperty_536871412
else:
  static :
    hint("Declaration of " & "enum_GuiScrollBarProperty" &
        " already exists, not redeclaring")
when not declared(GuiTextAlignment):
  type
    GuiTextAlignment* = GuiTextAlignment_536871378
else:
  static :
    hint("Declaration of " & "GuiTextAlignment" &
        " already exists, not redeclaring")
when not declared(GuiTextWrapMode):
  type
    GuiTextWrapMode* = GuiTextWrapMode_536871386
else:
  static :
    hint("Declaration of " & "GuiTextWrapMode" &
        " already exists, not redeclaring")
when not declared(GuiDefaultProperty):
  type
    GuiDefaultProperty* = GuiDefaultProperty_536871398
else:
  static :
    hint("Declaration of " & "GuiDefaultProperty" &
        " already exists, not redeclaring")
when not declared(enum_GuiSpinnerProperty):
  type
    enum_GuiSpinnerProperty* = enum_GuiSpinnerProperty_536871432
else:
  static :
    hint("Declaration of " & "enum_GuiSpinnerProperty" &
        " already exists, not redeclaring")
when not declared(GuiToggleProperty):
  type
    GuiToggleProperty* = GuiToggleProperty_536871402
else:
  static :
    hint("Declaration of " & "GuiToggleProperty" &
        " already exists, not redeclaring")
when not declared(enum_GuiComboBoxProperty):
  type
    enum_GuiComboBoxProperty* = enum_GuiComboBoxProperty_536871420
else:
  static :
    hint("Declaration of " & "enum_GuiComboBoxProperty" &
        " already exists, not redeclaring")
when not declared(enum_GuiState):
  type
    enum_GuiState* = enum_GuiState_536871372
else:
  static :
    hint("Declaration of " & "enum_GuiState" &
        " already exists, not redeclaring")
when not declared(GuiTextBoxProperty):
  type
    GuiTextBoxProperty* = GuiTextBoxProperty_536871430
else:
  static :
    hint("Declaration of " & "GuiTextBoxProperty" &
        " already exists, not redeclaring")
when not declared(enum_GuiControl):
  type
    enum_GuiControl* = enum_GuiControl_536871388
else:
  static :
    hint("Declaration of " & "enum_GuiControl" &
        " already exists, not redeclaring")
when not declared(GuiCheckBoxProperty):
  type
    GuiCheckBoxProperty* = GuiCheckBoxProperty_536871418
else:
  static :
    hint("Declaration of " & "GuiCheckBoxProperty" &
        " already exists, not redeclaring")
when not declared(enum_GuiTextAlignment):
  type
    enum_GuiTextAlignment* = enum_GuiTextAlignment_536871376
else:
  static :
    hint("Declaration of " & "enum_GuiTextAlignment" &
        " already exists, not redeclaring")
when not declared(GuiListViewProperty):
  type
    GuiListViewProperty* = GuiListViewProperty_536871438
else:
  static :
    hint("Declaration of " & "GuiListViewProperty" &
        " already exists, not redeclaring")
when not declared(Vector3):
  type
    Vector3* = Vector3_536871450
else:
  static :
    hint("Declaration of " & "Vector3" & " already exists, not redeclaring")
when not declared(struct_Vector2):
  type
    struct_Vector2* = struct_Vector2_536871471
else:
  static :
    hint("Declaration of " & "struct_Vector2" &
        " already exists, not redeclaring")
when not declared(Font):
  type
    Font* = Font_536871444
else:
  static :
    hint("Declaration of " & "Font" & " already exists, not redeclaring")
when not declared(struct_Texture):
  type
    struct_Texture* = struct_Texture_536871485
else:
  static :
    hint("Declaration of " & "struct_Texture" &
        " already exists, not redeclaring")
when not declared(GlyphInfo):
  type
    GlyphInfo* = GlyphInfo_536871463
else:
  static :
    hint("Declaration of " & "GlyphInfo" & " already exists, not redeclaring")
when not declared(Texture):
  type
    Texture* = Texture_536871481
else:
  static :
    hint("Declaration of " & "Texture" & " already exists, not redeclaring")
when not declared(struct_Image):
  type
    struct_Image* = struct_Image_536871483
else:
  static :
    hint("Declaration of " & "struct_Image" & " already exists, not redeclaring")
when not declared(GuiControl):
  type
    GuiControl* = GuiControl_536871390
else:
  static :
    hint("Declaration of " & "GuiControl" & " already exists, not redeclaring")
when not declared(GuiSpinnerProperty):
  type
    GuiSpinnerProperty* = GuiSpinnerProperty_536871434
else:
  static :
    hint("Declaration of " & "GuiSpinnerProperty" &
        " already exists, not redeclaring")
when not declared(struct_Vector3):
  type
    struct_Vector3* = struct_Vector3_536871473
else:
  static :
    hint("Declaration of " & "struct_Vector3" &
        " already exists, not redeclaring")
when not declared(enum_GuiCheckBoxProperty):
  type
    enum_GuiCheckBoxProperty* = enum_GuiCheckBoxProperty_536871416
else:
  static :
    hint("Declaration of " & "enum_GuiCheckBoxProperty" &
        " already exists, not redeclaring")
when not declared(GuiDropdownBoxProperty):
  type
    GuiDropdownBoxProperty* = GuiDropdownBoxProperty_536871426
else:
  static :
    hint("Declaration of " & "GuiDropdownBoxProperty" &
        " already exists, not redeclaring")
when not declared(struct_GuiStyleProp):
  type
    struct_GuiStyleProp* = struct_GuiStyleProp_536871368
else:
  static :
    hint("Declaration of " & "struct_GuiStyleProp" &
        " already exists, not redeclaring")
when not declared(GuiSliderProperty):
  type
    GuiSliderProperty* = GuiSliderProperty_536871406
else:
  static :
    hint("Declaration of " & "GuiSliderProperty" &
        " already exists, not redeclaring")
when not declared(GuiTextAlignmentVertical):
  type
    GuiTextAlignmentVertical* = GuiTextAlignmentVertical_536871382
else:
  static :
    hint("Declaration of " & "GuiTextAlignmentVertical" &
        " already exists, not redeclaring")
when not declared(enum_GuiTextWrapMode):
  type
    enum_GuiTextWrapMode* = enum_GuiTextWrapMode_536871384
else:
  static :
    hint("Declaration of " & "enum_GuiTextWrapMode" &
        " already exists, not redeclaring")
when not declared(enum_GuiProgressBarProperty):
  type
    enum_GuiProgressBarProperty* = enum_GuiProgressBarProperty_536871408
else:
  static :
    hint("Declaration of " & "enum_GuiProgressBarProperty" &
        " already exists, not redeclaring")
when not declared(Color):
  type
    Color* = Color_536871446
else:
  static :
    hint("Declaration of " & "Color" & " already exists, not redeclaring")
when not declared(enum_GuiControlProperty):
  type
    enum_GuiControlProperty* = enum_GuiControlProperty_536871392
else:
  static :
    hint("Declaration of " & "enum_GuiControlProperty" &
        " already exists, not redeclaring")
when not declared(enum_GuiIconName):
  type
    enum_GuiIconName* = enum_GuiIconName_536871452
else:
  static :
    hint("Declaration of " & "enum_GuiIconName" &
        " already exists, not redeclaring")
when not declared(GuiProgressBarProperty):
  type
    GuiProgressBarProperty* = GuiProgressBarProperty_536871410
else:
  static :
    hint("Declaration of " & "GuiProgressBarProperty" &
        " already exists, not redeclaring")
when not declared(enum_GuiTextBoxProperty):
  type
    enum_GuiTextBoxProperty* = enum_GuiTextBoxProperty_536871428
else:
  static :
    hint("Declaration of " & "enum_GuiTextBoxProperty" &
        " already exists, not redeclaring")
when not declared(struct_Color):
  type
    struct_Color* = struct_Color_536871469
else:
  static :
    hint("Declaration of " & "struct_Color" & " already exists, not redeclaring")
when not declared(RAYGUI_VERSION_MAJOR):
  when 4 is static:
    const
      RAYGUI_VERSION_MAJOR* = 4 ## Generated based on /home/djazz/code/nim/jazzle/csource/raygui.h:334:9
  else:
    let RAYGUI_VERSION_MAJOR* = 4 ## Generated based on /home/djazz/code/nim/jazzle/csource/raygui.h:334:9
else:
  static :
    hint("Declaration of " & "RAYGUI_VERSION_MAJOR" &
        " already exists, not redeclaring")
when not declared(RAYGUI_VERSION_MINOR):
  when 5 is static:
    const
      RAYGUI_VERSION_MINOR* = 5 ## Generated based on /home/djazz/code/nim/jazzle/csource/raygui.h:335:9
  else:
    let RAYGUI_VERSION_MINOR* = 5 ## Generated based on /home/djazz/code/nim/jazzle/csource/raygui.h:335:9
else:
  static :
    hint("Declaration of " & "RAYGUI_VERSION_MINOR" &
        " already exists, not redeclaring")
when not declared(RAYGUI_VERSION_PATCH):
  when 0 is static:
    const
      RAYGUI_VERSION_PATCH* = 0 ## Generated based on /home/djazz/code/nim/jazzle/csource/raygui.h:336:9
  else:
    let RAYGUI_VERSION_PATCH* = 0 ## Generated based on /home/djazz/code/nim/jazzle/csource/raygui.h:336:9
else:
  static :
    hint("Declaration of " & "RAYGUI_VERSION_PATCH" &
        " already exists, not redeclaring")
when not declared(RAYGUI_VERSION):
  when "4.5-dev" is static:
    const
      RAYGUI_VERSION* = "4.5-dev" ## Generated based on /home/djazz/code/nim/jazzle/csource/raygui.h:337:9
  else:
    let RAYGUI_VERSION* = "4.5-dev" ## Generated based on /home/djazz/code/nim/jazzle/csource/raygui.h:337:9
else:
  static :
    hint("Declaration of " & "RAYGUI_VERSION" &
        " already exists, not redeclaring")
when not declared(SCROLLBAR_LEFT_SIDE):
  when 0 is static:
    const
      SCROLLBAR_LEFT_SIDE* = 0 ## Generated based on /home/djazz/code/nim/jazzle/csource/raygui.h:669:9
  else:
    let SCROLLBAR_LEFT_SIDE* = 0 ## Generated based on /home/djazz/code/nim/jazzle/csource/raygui.h:669:9
else:
  static :
    hint("Declaration of " & "SCROLLBAR_LEFT_SIDE" &
        " already exists, not redeclaring")
when not declared(SCROLLBAR_RIGHT_SIDE):
  when 1 is static:
    const
      SCROLLBAR_RIGHT_SIDE* = 1 ## Generated based on /home/djazz/code/nim/jazzle/csource/raygui.h:670:9
  else:
    let SCROLLBAR_RIGHT_SIDE* = 1 ## Generated based on /home/djazz/code/nim/jazzle/csource/raygui.h:670:9
else:
  static :
    hint("Declaration of " & "SCROLLBAR_RIGHT_SIDE" &
        " already exists, not redeclaring")
when not declared(DARK_STYLE_PROPS_COUNT):
  when 23 is static:
    const
      DARK_STYLE_PROPS_COUNT* = 23 ## Generated based on /home/djazz/code/nim/jazzle/csource/style_dark.h:14:9
  else:
    let DARK_STYLE_PROPS_COUNT* = 23 ## Generated based on /home/djazz/code/nim/jazzle/csource/style_dark.h:14:9
else:
  static :
    hint("Declaration of " & "DARK_STYLE_PROPS_COUNT" &
        " already exists, not redeclaring")
when not declared(DARK_STYLE_FONT_ATLAS_COMP_SIZE):
  when 2126 is static:
    const
      DARK_STYLE_FONT_ATLAS_COMP_SIZE* = 2126 ## Generated based on /home/djazz/code/nim/jazzle/csource/style_dark.h:45:9
  else:
    let DARK_STYLE_FONT_ATLAS_COMP_SIZE* = 2126 ## Generated based on /home/djazz/code/nim/jazzle/csource/style_dark.h:45:9
else:
  static :
    hint("Declaration of " & "DARK_STYLE_FONT_ATLAS_COMP_SIZE" &
        " already exists, not redeclaring")
when not declared(GuiEnable):
  proc GuiEnable*(): void {.cdecl, importc: "GuiEnable".}
else:
  static :
    hint("Declaration of " & "GuiEnable" & " already exists, not redeclaring")
when not declared(GuiDisable):
  proc GuiDisable*(): void {.cdecl, importc: "GuiDisable".}
else:
  static :
    hint("Declaration of " & "GuiDisable" & " already exists, not redeclaring")
when not declared(GuiLock):
  proc GuiLock*(): void {.cdecl, importc: "GuiLock".}
else:
  static :
    hint("Declaration of " & "GuiLock" & " already exists, not redeclaring")
when not declared(GuiUnlock):
  proc GuiUnlock*(): void {.cdecl, importc: "GuiUnlock".}
else:
  static :
    hint("Declaration of " & "GuiUnlock" & " already exists, not redeclaring")
when not declared(GuiIsLocked):
  proc GuiIsLocked*(): bool {.cdecl, importc: "GuiIsLocked".}
else:
  static :
    hint("Declaration of " & "GuiIsLocked" & " already exists, not redeclaring")
when not declared(GuiSetAlpha):
  proc GuiSetAlpha*(alpha: cfloat): void {.cdecl, importc: "GuiSetAlpha".}
else:
  static :
    hint("Declaration of " & "GuiSetAlpha" & " already exists, not redeclaring")
when not declared(GuiSetState):
  proc GuiSetState*(state: cint): void {.cdecl, importc: "GuiSetState".}
else:
  static :
    hint("Declaration of " & "GuiSetState" & " already exists, not redeclaring")
when not declared(GuiGetState):
  proc GuiGetState*(): cint {.cdecl, importc: "GuiGetState".}
else:
  static :
    hint("Declaration of " & "GuiGetState" & " already exists, not redeclaring")
when not declared(GuiSetFont):
  proc GuiSetFont*(font: Font_536871445): void {.cdecl, importc: "GuiSetFont".}
else:
  static :
    hint("Declaration of " & "GuiSetFont" & " already exists, not redeclaring")
when not declared(GuiGetFont):
  proc GuiGetFont*(): Font_536871445 {.cdecl, importc: "GuiGetFont".}
else:
  static :
    hint("Declaration of " & "GuiGetFont" & " already exists, not redeclaring")
when not declared(GuiSetStyle):
  proc GuiSetStyle*(control: cint; property: cint; value: cint): void {.cdecl,
      importc: "GuiSetStyle".}
else:
  static :
    hint("Declaration of " & "GuiSetStyle" & " already exists, not redeclaring")
when not declared(GuiGetStyle):
  proc GuiGetStyle*(control: cint; property: cint): cint {.cdecl,
      importc: "GuiGetStyle".}
else:
  static :
    hint("Declaration of " & "GuiGetStyle" & " already exists, not redeclaring")
when not declared(GuiLoadStyle):
  proc GuiLoadStyle*(fileName: cstring): void {.cdecl, importc: "GuiLoadStyle".}
else:
  static :
    hint("Declaration of " & "GuiLoadStyle" & " already exists, not redeclaring")
when not declared(GuiLoadStyleDefault):
  proc GuiLoadStyleDefault*(): void {.cdecl, importc: "GuiLoadStyleDefault".}
else:
  static :
    hint("Declaration of " & "GuiLoadStyleDefault" &
        " already exists, not redeclaring")
when not declared(GuiEnableTooltip):
  proc GuiEnableTooltip*(): void {.cdecl, importc: "GuiEnableTooltip".}
else:
  static :
    hint("Declaration of " & "GuiEnableTooltip" &
        " already exists, not redeclaring")
when not declared(GuiDisableTooltip):
  proc GuiDisableTooltip*(): void {.cdecl, importc: "GuiDisableTooltip".}
else:
  static :
    hint("Declaration of " & "GuiDisableTooltip" &
        " already exists, not redeclaring")
when not declared(GuiSetTooltip):
  proc GuiSetTooltip*(tooltip: cstring): void {.cdecl, importc: "GuiSetTooltip".}
else:
  static :
    hint("Declaration of " & "GuiSetTooltip" &
        " already exists, not redeclaring")
when not declared(GuiIconText):
  proc GuiIconText*(iconId: cint; text: cstring): cstring {.cdecl,
      importc: "GuiIconText".}
else:
  static :
    hint("Declaration of " & "GuiIconText" & " already exists, not redeclaring")
when not declared(GuiSetIconScale):
  proc GuiSetIconScale*(scale: cint): void {.cdecl, importc: "GuiSetIconScale".}
else:
  static :
    hint("Declaration of " & "GuiSetIconScale" &
        " already exists, not redeclaring")
when not declared(GuiGetIcons):
  proc GuiGetIcons*(): ptr cuint {.cdecl, importc: "GuiGetIcons".}
else:
  static :
    hint("Declaration of " & "GuiGetIcons" & " already exists, not redeclaring")
when not declared(GuiLoadIcons):
  proc GuiLoadIcons*(fileName: cstring; loadIconsName: bool): ptr cstring {.
      cdecl, importc: "GuiLoadIcons".}
else:
  static :
    hint("Declaration of " & "GuiLoadIcons" & " already exists, not redeclaring")
when not declared(GuiDrawIcon):
  proc GuiDrawIcon*(iconId: cint; posX: cint; posY: cint; pixelSize: cint;
                    color: Color_536871447): void {.cdecl,
      importc: "GuiDrawIcon".}
else:
  static :
    hint("Declaration of " & "GuiDrawIcon" & " already exists, not redeclaring")
when not declared(GuiWindowBox):
  proc GuiWindowBox*(bounds: Rectangle_536871367; title: cstring): cint {.cdecl,
      importc: "GuiWindowBox".}
else:
  static :
    hint("Declaration of " & "GuiWindowBox" & " already exists, not redeclaring")
when not declared(GuiGroupBox):
  proc GuiGroupBox*(bounds: Rectangle_536871367; text: cstring): cint {.cdecl,
      importc: "GuiGroupBox".}
else:
  static :
    hint("Declaration of " & "GuiGroupBox" & " already exists, not redeclaring")
when not declared(GuiLine):
  proc GuiLine*(bounds: Rectangle_536871367; text: cstring): cint {.cdecl,
      importc: "GuiLine".}
else:
  static :
    hint("Declaration of " & "GuiLine" & " already exists, not redeclaring")
when not declared(GuiPanel):
  proc GuiPanel*(bounds: Rectangle_536871367; text: cstring): cint {.cdecl,
      importc: "GuiPanel".}
else:
  static :
    hint("Declaration of " & "GuiPanel" & " already exists, not redeclaring")
when not declared(GuiTabBar):
  proc GuiTabBar*(bounds: Rectangle_536871367; text: ptr cstring; count: cint;
                  active: ptr cint): cint {.cdecl, importc: "GuiTabBar".}
else:
  static :
    hint("Declaration of " & "GuiTabBar" & " already exists, not redeclaring")
when not declared(GuiScrollPanel):
  proc GuiScrollPanel*(bounds: Rectangle_536871367; text: cstring;
                       content: Rectangle_536871367; scroll: ptr Vector2_536871449;
                       view: ptr Rectangle_536871367): cint {.cdecl,
      importc: "GuiScrollPanel".}
else:
  static :
    hint("Declaration of " & "GuiScrollPanel" &
        " already exists, not redeclaring")
when not declared(GuiLabel):
  proc GuiLabel*(bounds: Rectangle_536871367; text: cstring): cint {.cdecl,
      importc: "GuiLabel".}
else:
  static :
    hint("Declaration of " & "GuiLabel" & " already exists, not redeclaring")
when not declared(GuiButton):
  proc GuiButton*(bounds: Rectangle_536871367; text: cstring): cint {.cdecl,
      importc: "GuiButton".}
else:
  static :
    hint("Declaration of " & "GuiButton" & " already exists, not redeclaring")
when not declared(GuiLabelButton):
  proc GuiLabelButton*(bounds: Rectangle_536871367; text: cstring): cint {.
      cdecl, importc: "GuiLabelButton".}
else:
  static :
    hint("Declaration of " & "GuiLabelButton" &
        " already exists, not redeclaring")
when not declared(GuiToggle):
  proc GuiToggle*(bounds: Rectangle_536871367; text: cstring; active: ptr bool): cint {.
      cdecl, importc: "GuiToggle".}
else:
  static :
    hint("Declaration of " & "GuiToggle" & " already exists, not redeclaring")
when not declared(GuiToggleGroup):
  proc GuiToggleGroup*(bounds: Rectangle_536871367; text: cstring;
                       active: ptr cint): cint {.cdecl,
      importc: "GuiToggleGroup".}
else:
  static :
    hint("Declaration of " & "GuiToggleGroup" &
        " already exists, not redeclaring")
when not declared(GuiToggleSlider):
  proc GuiToggleSlider*(bounds: Rectangle_536871367; text: cstring;
                        active: ptr cint): cint {.cdecl,
      importc: "GuiToggleSlider".}
else:
  static :
    hint("Declaration of " & "GuiToggleSlider" &
        " already exists, not redeclaring")
when not declared(GuiCheckBox):
  proc GuiCheckBox*(bounds: Rectangle_536871367; text: cstring;
                    checked: ptr bool): cint {.cdecl, importc: "GuiCheckBox".}
else:
  static :
    hint("Declaration of " & "GuiCheckBox" & " already exists, not redeclaring")
when not declared(GuiComboBox):
  proc GuiComboBox*(bounds: Rectangle_536871367; text: cstring; active: ptr cint): cint {.
      cdecl, importc: "GuiComboBox".}
else:
  static :
    hint("Declaration of " & "GuiComboBox" & " already exists, not redeclaring")
when not declared(GuiDropdownBox):
  proc GuiDropdownBox*(bounds: Rectangle_536871367; text: cstring;
                       active: ptr cint; editMode: bool): cint {.cdecl,
      importc: "GuiDropdownBox".}
else:
  static :
    hint("Declaration of " & "GuiDropdownBox" &
        " already exists, not redeclaring")
when not declared(GuiSpinner):
  proc GuiSpinner*(bounds: Rectangle_536871367; text: cstring; value: ptr cint;
                   minValue: cint; maxValue: cint; editMode: bool): cint {.
      cdecl, importc: "GuiSpinner".}
else:
  static :
    hint("Declaration of " & "GuiSpinner" & " already exists, not redeclaring")
when not declared(GuiValueBox):
  proc GuiValueBox*(bounds: Rectangle_536871367; text: cstring; value: ptr cint;
                    minValue: cint; maxValue: cint; editMode: bool): cint {.
      cdecl, importc: "GuiValueBox".}
else:
  static :
    hint("Declaration of " & "GuiValueBox" & " already exists, not redeclaring")
when not declared(GuiValueBoxFloat):
  proc GuiValueBoxFloat*(bounds: Rectangle_536871367; text: cstring;
                         textValue: cstring; value: ptr cfloat; editMode: bool): cint {.
      cdecl, importc: "GuiValueBoxFloat".}
else:
  static :
    hint("Declaration of " & "GuiValueBoxFloat" &
        " already exists, not redeclaring")
when not declared(GuiTextBox):
  proc GuiTextBox*(bounds: Rectangle_536871367; text: cstring; textSize: cint;
                   editMode: bool): cint {.cdecl, importc: "GuiTextBox".}
else:
  static :
    hint("Declaration of " & "GuiTextBox" & " already exists, not redeclaring")
when not declared(GuiSlider):
  proc GuiSlider*(bounds: Rectangle_536871367; textLeft: cstring;
                  textRight: cstring; value: ptr cfloat; minValue: cfloat;
                  maxValue: cfloat): cint {.cdecl, importc: "GuiSlider".}
else:
  static :
    hint("Declaration of " & "GuiSlider" & " already exists, not redeclaring")
when not declared(GuiSliderBar):
  proc GuiSliderBar*(bounds: Rectangle_536871367; textLeft: cstring;
                     textRight: cstring; value: ptr cfloat; minValue: cfloat;
                     maxValue: cfloat): cint {.cdecl, importc: "GuiSliderBar".}
else:
  static :
    hint("Declaration of " & "GuiSliderBar" & " already exists, not redeclaring")
when not declared(GuiProgressBar):
  proc GuiProgressBar*(bounds: Rectangle_536871367; textLeft: cstring;
                       textRight: cstring; value: ptr cfloat; minValue: cfloat;
                       maxValue: cfloat): cint {.cdecl,
      importc: "GuiProgressBar".}
else:
  static :
    hint("Declaration of " & "GuiProgressBar" &
        " already exists, not redeclaring")
when not declared(GuiStatusBar):
  proc GuiStatusBar*(bounds: Rectangle_536871367; text: cstring): cint {.cdecl,
      importc: "GuiStatusBar".}
else:
  static :
    hint("Declaration of " & "GuiStatusBar" & " already exists, not redeclaring")
when not declared(GuiDummyRec):
  proc GuiDummyRec*(bounds: Rectangle_536871367; text: cstring): cint {.cdecl,
      importc: "GuiDummyRec".}
else:
  static :
    hint("Declaration of " & "GuiDummyRec" & " already exists, not redeclaring")
when not declared(GuiGrid):
  proc GuiGrid*(bounds: Rectangle_536871367; text: cstring; spacing: cfloat;
                subdivs: cint; mouseCell: ptr Vector2_536871449): cint {.cdecl,
      importc: "GuiGrid".}
else:
  static :
    hint("Declaration of " & "GuiGrid" & " already exists, not redeclaring")
when not declared(GuiListView):
  proc GuiListView*(bounds: Rectangle_536871367; text: cstring;
                    scrollIndex: ptr cint; active: ptr cint): cint {.cdecl,
      importc: "GuiListView".}
else:
  static :
    hint("Declaration of " & "GuiListView" & " already exists, not redeclaring")
when not declared(GuiListViewEx):
  proc GuiListViewEx*(bounds: Rectangle_536871367; text: ptr cstring;
                      count: cint; scrollIndex: ptr cint; active: ptr cint;
                      focus: ptr cint): cint {.cdecl, importc: "GuiListViewEx".}
else:
  static :
    hint("Declaration of " & "GuiListViewEx" &
        " already exists, not redeclaring")
when not declared(GuiMessageBox):
  proc GuiMessageBox*(bounds: Rectangle_536871367; title: cstring;
                      message: cstring; buttons: cstring): cint {.cdecl,
      importc: "GuiMessageBox".}
else:
  static :
    hint("Declaration of " & "GuiMessageBox" &
        " already exists, not redeclaring")
when not declared(GuiTextInputBox):
  proc GuiTextInputBox*(bounds: Rectangle_536871367; title: cstring;
                        message: cstring; buttons: cstring; text: cstring;
                        textMaxSize: cint; secretViewActive: ptr bool): cint {.
      cdecl, importc: "GuiTextInputBox".}
else:
  static :
    hint("Declaration of " & "GuiTextInputBox" &
        " already exists, not redeclaring")
when not declared(GuiColorPicker):
  proc GuiColorPicker*(bounds: Rectangle_536871367; text: cstring;
                       color: ptr Color_536871447): cint {.cdecl,
      importc: "GuiColorPicker".}
else:
  static :
    hint("Declaration of " & "GuiColorPicker" &
        " already exists, not redeclaring")
when not declared(GuiColorPanel):
  proc GuiColorPanel*(bounds: Rectangle_536871367; text: cstring;
                      color: ptr Color_536871447): cint {.cdecl,
      importc: "GuiColorPanel".}
else:
  static :
    hint("Declaration of " & "GuiColorPanel" &
        " already exists, not redeclaring")
when not declared(GuiColorBarAlpha):
  proc GuiColorBarAlpha*(bounds: Rectangle_536871367; text: cstring;
                         alpha: ptr cfloat): cint {.cdecl,
      importc: "GuiColorBarAlpha".}
else:
  static :
    hint("Declaration of " & "GuiColorBarAlpha" &
        " already exists, not redeclaring")
when not declared(GuiColorBarHue):
  proc GuiColorBarHue*(bounds: Rectangle_536871367; text: cstring;
                       value: ptr cfloat): cint {.cdecl,
      importc: "GuiColorBarHue".}
else:
  static :
    hint("Declaration of " & "GuiColorBarHue" &
        " already exists, not redeclaring")
when not declared(GuiColorPickerHSV):
  proc GuiColorPickerHSV*(bounds: Rectangle_536871367; text: cstring;
                          colorHsv: ptr Vector3_536871451): cint {.cdecl,
      importc: "GuiColorPickerHSV".}
else:
  static :
    hint("Declaration of " & "GuiColorPickerHSV" &
        " already exists, not redeclaring")
when not declared(GuiColorPanelHSV):
  proc GuiColorPanelHSV*(bounds: Rectangle_536871367; text: cstring;
                         colorHsv: ptr Vector3_536871451): cint {.cdecl,
      importc: "GuiColorPanelHSV".}
else:
  static :
    hint("Declaration of " & "GuiColorPanelHSV" &
        " already exists, not redeclaring")
when not declared(darkStyleProps):
  var darkStyleProps*: array[23'i64, GuiStyleProp_536871371]
else:
  static :
    hint("Declaration of " & "darkStyleProps" &
        " already exists, not redeclaring")
when not declared(darkFontData):
  var darkFontData*: array[2126'i64, uint8]
else:
  static :
    hint("Declaration of " & "darkFontData" & " already exists, not redeclaring")
when not declared(darkFontRecs):
  var darkFontRecs*: array[189'i64, Rectangle_536871367]
else:
  static :
    hint("Declaration of " & "darkFontRecs" & " already exists, not redeclaring")
when not declared(darkFontGlyphs):
  var darkFontGlyphs*: array[189'i64, GlyphInfo_536871464]
else:
  static :
    hint("Declaration of " & "darkFontGlyphs" &
        " already exists, not redeclaring")
when not declared(GuiLoadStyleDark):
  proc GuiLoadStyleDark*(): void {.cdecl, importc: "GuiLoadStyleDark".}
else:
  static :
    hint("Declaration of " & "GuiLoadStyleDark" &
        " already exists, not redeclaring")