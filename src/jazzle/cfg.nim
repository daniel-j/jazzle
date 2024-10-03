import std/streams

type

  InputDevice {.size: sizeof(uint32).} = enum
    Keyboard1
    Keyboard2
    Joystick1
    Joystick2
    Joystick3
    Joystick4

  PlayerInput* = object
    inputDevice*: InputDevice
    unknown1: uint32 # input order device?? only updates when player has entered game in MP.
    unknown2: uint32 # always zero ??

  InputKey* = uint32

  InputMap* {.packed.} = object
    up*: array[2, InputKey]
    down*: array[2, InputKey]
    left*: array[2, InputKey]
    right*: array[2, InputKey]
    fire*: array[2, InputKey]
    select*: array[2, InputKey]
    jump*: array[2, InputKey]
    run*: array[2, InputKey]

  SoundSettings* = object
    effectVolume*: uint32 # 128 is highest
    musicVolume*: uint32 # 128 is highest
    outputModeDirectSound*: bool
    stereoMode* {.align: 4, bitsize: 1.}: bool
    sound16Bit* {.bitsize: 1.}: bool
    interpolationEnabled* {.bitsize: 1.}: bool
    sampleRate* {.align: 4.}: uint32 # 48000 seems to be the highest (tested with plus)

  Cfg* {.packed.} = object
    versionStr*: array[4, char]
    playerInput: array[4, PlayerInput]
    controls*: array[InputDevice, InputMap]
    sound*: SoundSettings

proc load*(self: var Cfg; filename: string): bool =
  self.reset()
  let s = newFileStream(filename)
  defer: s.close()

  s.read(self)

  doAssert s.atEnd()
  s.close()

  return true

proc save*(self: Cfg; filename: string): bool =
  let s = newFileStream(filename, fmWrite)
  defer: s.close()

  s.write(self)
  s.flush()
  s.close()

  return true

proc debug*(self: var Cfg) =
  for info in self.playerInput: echo info
  for device, inputs in self.controls: echo device, ": ", inputs
  echo self.sound

proc test*(filename: string) =
  var cfg = Cfg()
  if cfg.load(filename):
    cfg.debug()
    # echo cfg.save(filename)
