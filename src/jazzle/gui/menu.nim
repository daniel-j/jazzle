import raylib, raygui

type
  Menu*[T] = object
    text*: string
    id*: T
    uID: int
    width*: int
    items*: seq[Menu[T]]

# Button control, returns true when clicked
proc focusedGuiRect(bounds: Rectangle): bool =
  var state = guiGetState()
  if (state != Disabled) and not guiIsLocked():
    let mousePoint = getMousePosition()
    # Check button state
    if checkCollisionPointRec(mousePoint, bounds):
      if isMouseButtonDown(Left):
        state = Pressed
      else:
        state = Focused

  return state != Normal

proc showMenu*[T](menu: var Menu[T]; h: int): T =
  let align = guiGetStyle(Button, TextAlignment)
  statusBar(Rectangle(x: 0, y: 0, width: getRenderWidth().float32, height: h.float32), "")
  guiSetStyle(Button, TextAlignment, Left)
  var isClosed = false
  var isFocused = false
  var isOpen = -1
  for m in 0..<menu.items.len:
    let item = menu.items[m].addr
    if item.uID != 0:
      isOpen = m

  var woffset = 0
  for m in 0..<menu.items.len:
    let item = menu.items[m].addr
    let firstItemWidth = measureText(item.text, 10) + 20
    var rect = Rectangle(x: float32 woffset, y: 0, width: float32 firstItemWidth, height: float32 h)
    woffset += rect.width.int
    # first item in menu is the top level button string
    # tell the system we're focused on something
    if focusedGuiRect(rect):
      isFocused = true
    # put the Menu title button up 
    if button(rect, item.text):
      # if we hit the button, we toggle the menu on/off
      item.uID = int (not (item.uID.bool))
      # set is closed if the top menu is switched off.
      if item.uID == 0:
        isClosed = true

    # if it's open
    if item.uID != 0:
      rect.width = item.width.float32
      # check if it's the one we had last time 
      if (m != isOpen) and (isOpen != -1):
        menu.items[isOpen].uID = 0

      # add the other entries
      for q in 0..<item.items.len:
        # step down 1 slot
        rect.y += rect.height
        # set if we're focused
        if focusedGuiRect(rect):
          isFocused = true
        # handle button press
        if button(rect, item.items[q].text):
          item.uID = 0
          isClosed = true
          result = item.items[q].id

  # if we're not focused and left click, close the menu
  if isMouseButtonPressed(Left) and not isFocused:
    isClosed = true

  # turn everything off
  if isClosed:
    for m in menu.items.mitems:
      m.uID = 0

  # restore alignment
  guiSetStyle(Button, TextAlignment, align)


type
  MainMenuValues* = enum
    MenuNone
    MenuFileNew
    MenuFileOpen
    MenuFileSave
    MenuLevelProperties

  MainMenu* = Menu[MainMenuValues]

var mainMenu* = MainMenu(items: @[
  MainMenu(
    text: "_File",
    width: 100,
    items: @[
      MainMenu(text: "#08# New", id: MenuFileNew),
      MainMenu(text: "#01# Open", id: MenuFileOpen),
      MainMenu(text: "#02# Save", id: MenuFileSave)
    ]
  ),
  MainMenu(
    text: "_Edit",
    width: 200,
    items: @[
      MainMenu(text: "#59# Level properties", id: MenuLevelProperties)
    ]
  )
])
