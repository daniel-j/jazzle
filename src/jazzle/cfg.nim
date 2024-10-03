import std/streams
import std/strutils

type

  PlayerControls* {.packed.} = object
    keyUp*: uint32
    keyUpAlt*: uint32
    keyDown*: uint32
    keyDownAlt*: uint32
    keyLeft*: uint32
    keyLeftAlt*: uint32
    keyRight*: uint32
    keyRightAlt*: uint32
    keyFire*: uint32
    keyFireAlt*: uint32
    keySelect*: uint32
    keySelectAlt*: uint32
    keyJump*: uint32
    keyJumpAlt*: uint32
    keyRun*: uint32
    keyRunAlt*: uint32

  Cfg* {.packed.} = object
    versionStr*: array[4, char]
    unknown1: array[12, uint32]
    playerControls*: array[6, PlayerControls]
    unknown2: array[4, uint32]
    soundSampleRate*: uint32

proc load*(self: var Cfg; filename: string): bool =
  self.reset()
  let s = newFileStream(filename)
  defer: s.close()

  s.read(self)

  doAssert s.atEnd()
  s.close()

  return true


proc debug*(self: Cfg) =
  echo self

proc test*(filename: string) =
  var cfg = Cfg()
  if cfg.load(filename):
    cfg.debug()
