import std/streams
import std/strutils
import std/tables
import std/bitops
import std/sets
import pixie
import zippy
import zippy/crc
import parseini
import ./common
import ./tileset

export common, tables

const
  J2lVersionAGA  = 0x100'u16
  J2lVersion1_23 = 0x202'u16
  J2lVersion1_24 = 0x203'u16
  SecurityStringPassworded = 0xBA00BE00'u32
  SecurityStringMLLE = 0xBACABEEF'u32
  SecurityStringInsecure = 0x00000000'u32
  SecurityNoPassword = 0x00BABE'u32
  LayerCount* = 8
  SpriteLayerId* = 3

type
  StreamKind = enum
    LevelInfo
    EventData
    DictData
    WordMapData

  StreamSize = tuple[packedSize, unpackedSize: uint32]

  EventType* = enum
    Normal
    Easy
    Hard
    OnlyMultiplayer

  Event* {.packed.} = object
    eventId*: uint8
    eventType* {.bitsize: 2.}: EventType
    illuminate* {.bitsize: 1.}: bool
    isActive* {.bitsize: 1}: bool
    data* {.bitsize: 20.}: uint32

  EventInfo* = object
    name*: string
    onlySingleplayer*: bool
    category*: string
    label*: string
    params*: seq[tuple[name: string, size: int]]

  Tile* = object
    tileId*: uint16
    hflipped*: bool
    vflipped*: bool # plus only
    animated*: bool

  WordId* = uint16
  WordTiles* = array[4, Tile]

  TileType*  {.size: sizeof(uint8).} = enum
    Default = 0
    Translucent = 1
    Opaque = 2
    Invisible = 3 # plus
    Caption = 4
    HeatEffect = 5 # plus
    Frozen = 6 # plus

  AnimatedTileState* = object
    currentFrame*: int

  AnimatedTile* {.packed.} = object
    frameWait*: int16
    randomWait*: int16
    pingPongWait*: int16
    pingPong*: bool
    speed*: int8
    frames*: seq[Tile]
    state*: AnimatedTileState

  LayerProperties* {.packed.} = object
    tileWidth* {.bitsize: 1.}: bool
    tileHeight* {.bitsize: 1.}: bool
    limitVisibleRegion* {.bitsize: 1.}: bool
    textureMode* {.bitsize: 1.}: bool
    parallaxStars* {.bitsize: 1.}: bool
    _ {.bitsize: 27}: uint32 # unused

  Layer* = object
    properties*: LayerProperties
    layerType*: uint8 # unused
    haveAnyTiles*: bool
    width*: uint32
    realWidth*: uint32
    height*: uint32
    zAxis*: int32 # unused
    detailLevel*: uint8 # mostly unused
    waveX*: int32 # unused
    waveY*: int32 # unused
    speedX*: int32
    speedY*: int32
    autoSpeedX*: int32
    autoSpeedY*: int32
    textureMode*: uint8
    textureParams*: array[3, uint8]
    wordMap*: seq[WordId]

  Level* = object
    title*: string
    version*: GameVersion
    hideInHomecooked*: bool
    passwordHash: uint32 # lower 3 bytes only (24-bit)
    fileSize*: uint32
    checksum*: uint32
    streamSizes*: array[StreamKind, StreamSize]

    lastHorizontalOffset*: uint16
    lastVerticalOffset*: uint16
    lastLayer*: uint8
    securityEnvelope*: uint32
    securityEnabled*: bool

    minLight*: uint8
    startLight*: uint8
    verticalSplitscreen*: bool
    isLevelMultiplayer*: bool
    levelName*: string
    tileset*: string
    bonusLevel*: string
    nextLevel*: string
    secretLevel*: string
    musicFile*: string
    helpString*: array[16, string]

    tilesetEvents*: Table[int, Event]
    tileTypes*: array[4096, TileType]
    isEachTileFlipped*: HashSet[int]
    isEachTileUsed*: Table[int, uint8] # unused?

    # soundEffectPointer*: array[48, array[64, uint8]] # AGA version only
    layers*: array[LayerCount, Layer]
    events*: seq[Event]

    # unknownAGA*: array[32768, char] # only in AGA

    animOffset*: uint16 # MAX_TILES minus AnimCount, also called StaticTiles
    animCount*: uint16
    anims*: seq[AnimatedTile]

    dictionary*: seq[WordTiles]

var jcsEvents: array[256, EventInfo]

proc maxTiles*(self: Level): uint32 =
  if self.version == v1_23:
    1024'u32
  else:
    4096'u32

proc maxAnimTiles*(self: Level): uint16 =
  if self.version == v1_23:
    128'u16
  else:
    256'u16

proc parseTile*(self: Level; rawtile: uint16): Tile =
  if self.version != v1_24:
    result = Tile(tileId: rawtile and 1023, hflipped: (rawtile and 0x400) > 0)
  else:
    result = Tile(tileId: rawtile and 4095, hflipped: (rawtile and 0x1000) > 0)
  result.vflipped = (rawtile and 0x2000) > 0
  if result.tileId >= self.animOffset:
    result.animated = true
    result.tileId -= self.animOffset

proc updateAnims*(self: var Level; t: float64): bool =
  ## Updates animation frames and returns true if any change occured
  for i, anim in self.anims.mpairs:
    if anim.speed == 0 or anim.frames.len == 0: continue
    let prevFrame = anim.state.currentFrame

    let runningLength = anim.frames.len + anim.frameWait + anim.pingPong.ord * (anim.frames.len + anim.pingPongWait)

    let runningFrame = int floor((t mod (runningLength / anim.speed)) * anim.speed.float)
    # let runningFrame = int(t * anim.speed.float) mod runningLength

    anim.state.currentFrame = min(runningFrame, anim.frames.len - 1)
    if anim.pingPong and runningFrame >= anim.frames.len + anim.pingPongWait:
      if runningFrame < anim.frames.len*2 + anim.pingPongWait:
        anim.state.currentFrame = max(0, anim.frames.len * 2 + anim.pingPongWait - 1 - runningFrame)
      else:
        anim.state.currentFrame = 0
    if prevFrame != anim.state.currentFrame:
      result = true

proc calculateAnimTile*(self: Level; animId: uint16; hflipped: bool = false; vflipped: bool = false; counter: int = 0): Tile =
  if counter > 10: return # limit 10 recursions
  let anim = self.anims[animId]
  if anim.frames.len == 0: return
  result = anim.frames[anim.state.currentFrame]
  if result.animated:
    result = self.calculateAnimTile(result.tileId, bool result.hflipped.ord xor hflipped.ord, bool result.vflipped.ord xor vflipped.ord, counter + 1)

  result.hflipped = bool result.hflipped.ord xor hflipped.ord
  result.vflipped = bool result.vflipped.ord xor vflipped.ord

proc loadInfo(self: var Level, s: Stream) =
  # data1
  s.read(self.lastHorizontalOffset)
  self.securityEnvelope = s.readUint16().uint32 shl 16
  s.read(self.lastVerticalOffset)
  self.securityEnvelope = self.securityEnvelope or s.readUint16().uint32
  let security3AndLastLayer = s.readUint8()
  self.securityEnabled = (security3AndLastLayer shr 4) != 0
  self.lastLayer = security3AndLastLayer and 0b1111

  case self.securityEnvelope:
  of SecurityStringPassworded: echo "level passworded"
  of SecurityStringMLLE: echo "MLLE only level"
  of SecurityStringInsecure: echo "level unprotected"
  else: echo "unknown security"
  # echo self.securityEnabled, " ", (security3AndLastLayer shr 4)

  s.read(self.minLight)
  s.read(self.startLight)
  s.read(self.animCount)
  s.read(self.verticalSplitscreen)
  s.read(self.isLevelMultiplayer)

  let bufferSize = s.readUint32()
  doAssert bufferSize == StringStream(s).data.len.uint32

  self.levelName = s.readCStr(32)
  self.tileset = s.readCStr(32)
  self.bonusLevel = s.readCStr(32)
  self.nextLevel = s.readCStr(32)
  self.secretLevel = s.readCStr(32)
  self.musicFile = s.readCStr(32)
  for i in 0..<self.helpString.len:
    self.helpString[i] = s.readCStr(512)

  # if self.version == v_AGA:
  #   s.read(self.soundEffectPointer)

  for layer in self.layers.mitems: s.read(layer.properties)
  for layer in self.layers.mitems: s.read(layer.layerType) # unused
  for layer in self.layers.mitems: s.read(layer.haveAnyTiles)
  for layer in self.layers.mitems: s.read(layer.width)
  for layer in self.layers.mitems: s.read(layer.realWidth)
  for layer in self.layers.mitems: s.read(layer.height)
  for layer in self.layers.mitems: s.read(layer.zAxis) # unused
  for layer in self.layers.mitems: s.read(layer.detailLevel) # mostly unused
  for layer in self.layers.mitems: s.read(layer.waveX) # unused
  for layer in self.layers.mitems: s.read(layer.waveY) # unused
  for layer in self.layers.mitems: s.read(layer.speedX)
  for layer in self.layers.mitems: s.read(layer.speedY)
  for layer in self.layers.mitems: s.read(layer.autoSpeedX)
  for layer in self.layers.mitems: s.read(layer.autoSpeedY)
  for layer in self.layers.mitems: s.read(layer.textureMode)
  for layer in self.layers.mitems: s.read(layer.textureParams)

  s.read(self.animOffset)

  doAssert self.animOffset == self.maxTiles - self.animCount

  var event = Event()
  self.tilesetEvents.clear()
  for i in 0..<self.maxTiles.int:
    s.read(event)
    if event.eventId > 0:
      self.tilesetEvents[i] = event

  self.isEachTileFlipped.clear()
  for i in 0..<self.maxTiles.int:
    if s.readBool():
      self.isEachTileFlipped.incl(i)

  for i in 0..<self.maxTiles.int:
    let val = s.readUint8()
    self.tileTypes[i] = case val:
      of 1: Translucent
      of 4: Caption
      else: Default

  for i in 0..<self.maxTiles.int:
    let val = s.readUint8()
    if val != 0:
      self.isEachTileUsed[i] = val # unused?

  # if self.version == v_AGA:
  #   s.read(self.unknownAGA)

  self.anims.setLen(self.animCount.int)
  for i, anim in self.anims.mpairs:
    s.read(anim.frameWait)
    s.read(anim.randomWait)
    s.read(anim.pingPongWait)
    s.read(anim.pingPong)
    s.read(anim.speed)
    let frameCount = s.readUint8().int
    anim.frames.setLen(frameCount)
    var rawframes: array[64, uint16]
    s.read(rawframes)
    for f, frame in anim.frames:
      anim.frames[f] = self.parseTile(rawframes[f])

  # remaining buffer of data1 is just zeroes
  s.close()


proc loadEvents(self: var Level; s: Stream) =
  self.events.setLen(self.streamSizes[EventData].unpackedSize div 4)
  for event in self.events.mitems:
    s.read(event)
  doAssert s.atEnd()
  s.close()

proc loadDictionary(self: var Level; s: Stream) =
  self.dictionary.setLen(self.streamSizes[DictData].unpackedSize.int div 8)
  var rawword: array[4, uint16]
  for word in self.dictionary.mitems:
    s.read(rawword)
    for t, rawtile in rawword.pairs:
      word[t] = self.parseTile(rawtile)
  doAssert s.atEnd()
  s.close()

proc loadWordMap(self: var Level; s: Stream)=
  for i in 0..<8:
    if not self.layers[i].haveAnyTiles:
      continue
    self.layers[i].wordMap.setLen(((self.layers[i].realWidth+3) div 4) * self.layers[i].height)
    for j in 0..<self.layers[i].wordMap.len:
      s.read(self.layers[i].wordMap[j])
  doAssert s.atEnd()
  s.close()


proc parseIniEvent(value: string): EventInfo =
  let values = value.strip().split('|')
  for i, val in values:
    case i:
    of 0: result.name = val.strip()
    of 1: result.onlySingleplayer = val == "-"
    of 2: result.category = val.strip()
    of 3: result.label = val.strip()
    of 4: result.label = (result.label & "\n" & val).strip()
    else:
      let params = val.split(":")
      result.params.add((params[0].strip(), parseInt(params[1].strip())))

proc loadJcsIni(filename: string) =
  let jcsini = loadConfig("JCS.ini")
  for i in 0..<jcsEvents.len:
    jcsEvents[i] = parseIniEvent(jcsini.getSectionValue("Events", $i))

proc parseEventParams*(event: Event): seq[int] =
  let jcsEvent = jcsEvents[event.eventId.int]
  var offset = 0
  result.setLen(jcsEvent.params.len)
  for i in 0..<jcsEvent.params.len:
    let signed = jcsEvent.params[i].size < 0
    let size = abs(jcsEvent.params[i].size)
    let shift = 1 shl size
    result[i] = (event.data.int shr offset) and (shift - 1)
    if signed and result[i].testBit(size - 1):
      result[i] =  result[i] - shift
    offset += size


proc load*(self: var Level; s: Stream; password: string = ""): bool =
  self.reset()

  let copyright = s.readStr(180)
  doAssert copyright == DataFileCopyright
  let magic = s.readStr(4)
  doAssert magic == "LEVL"
  self.passwordHash = (s.readUint8().uint32 shl 16) or (s.readUint8().uint32 shl 8) or s.readUint8().uint32
  # doAssert s.readData(self.passwordHash.addr, 3) == 3
  # bigEndian32(self.passwordHash.addr, self.passwordHash.addr)

  if self.passwordHash != SecurityNoPassword:
    var hash = crc32(password) and 0xffffff
    if self.passwordHash != hash:
      echo "invalid password"
      echo (self.passwordHash.toHex(), hash.toHex())
      return false

  s.read(self.hideInHomecooked)

  self.title = s.readCStr(32)
  let versionNum = s.readUint16()
  self.version = if versionNum == 0x100: v_AGA elif versionNum <= 0x202: v1_23 else: v1_24
  self.fileSize = s.readUint32()
  self.checksum = s.readUint32()
  var compressedLength: uint32 = 0
  for kind in StreamKind.items:
    self.streamSizes[kind].packedSize = s.readUint32()
    self.streamSizes[kind].unpackedSize = s.readUint32()
    compressedLength += self.streamSizes[kind].packedSize

  let compressedData = newStringStream(s.readStr(compressedLength.int))
  defer: compressedData.close()

  let checksum = crc32(compressedData.data)

  if checksum != self.checksum:
    echo "checksums doesn't match!"
    return false

  var sections: array[StreamKind, Stream]
  for kind in StreamKind.items:
    var data = compressedData.readStr(self.streamSizes[kind].packedSize.int)
    data = uncompress(data, dfZlib)
    doAssert data.len.uint32 == self.streamSizes[kind].unpackedSize
    sections[kind] = newStringStream(data)

  doAssert compressedData.atEnd()

  # TODO: Parse MLLE data here
  # doAssert s.atEnd()
  s.close()

  self.loadInfo(sections[LevelInfo])
  self.loadEvents(sections[EventData])
  self.loadDictionary(sections[DictData])
  self.loadWordMap(sections[WordMapData])

  return true

proc load*(self: var Level; filename: string; password: string = ""): bool =
  self.reset()
  let s = newFileStream(filename)
  defer: s.close()
  self.load(s)

proc debug*(self: Level) =

  var ef = open("events.txt", fmWrite)

  for i, event in self.events.pairs:
    if event.eventId == 0: continue
    let x = i mod self.layers[3].width.int
    let y = i div self.layers[3].width.int
    var paramTable = newSeq[tuple[name: string, value: int]](jcsEvents[event.eventId].params.len)
    let params = parseEventParams(event)
    for j, param in jcsEvents[event.eventId].params:
      paramTable[j] = (name: param.name, value: params[j])
    if event.eventId == 216:
      let genEventId = params[0]
      ef.writeLine $genEventId, ": " & jcsEvents[genEventId].name, "* (" & $(x+1) & ", " & $(y+1) & ") " & $paramTable & " " & $event & " 0b" & cast[uint32](event).BiggestInt.toBin(32)
    else:
      ef.writeLine $event.eventId & ": " & jcsEvents[event.eventId].name & " (" & $(x+1) & ", " & $(y+1) & ") " & $paramTable & " " & $event & " 0b" & cast[uint32](event).BiggestInt.toBin(32)

  echo "saving"
  ef.close()

  echo "loading tileset"
  var tileset = Tileset()
  doAssert tileset.load(self.tileset)

  if self.animCount.int > 0:
    var highestFrame = 0
    for anim in self.anims:
      if anim.frames.len > highestFrame:
        highestFrame = anim.frames.len
    if highestFrame > 0:
      echo "drawing anims"
      var ima = newImage(32 * highestFrame.int,  32 * self.animCount.int)
      for i, anim in self.anims:
        for j, frame in anim.frames:
          if frame.tileId == 0 or frame.tileId >= self.animOffset: continue
          let tileOffset = tileset.tileOffsets[frame.tileId].image
          let tilesetTile = tileset.tileImage[tileOffset]
          for k in 0..<1024:
            let x = j * 32 + (k mod 32)
            let y = i * 32 + (k div 32)
            let index = tilesetTile[k]
            if index == 0: continue
            let color = tileset.palette[index]
            ima[x, y] = ColorRGB(
              r: color[0],
              g: color[1],
              b: color[2]
            )

      echo "saving"
      ima.writeFile("anims.png")

  echo "drawing dictionary"
  let dictColumns = 16
  var im = newImage(4*32*dictColumns,  32 * ((self.dictionary.len - 1) div dictColumns + 1))
  for i, word in self.dictionary.pairs:
    for j, tile in word:
      if tile.tileId == 0 or tile.tileId >= self.animOffset: continue
      let tileOffset = tileset.tileOffsets[tile.tileId].image
      let tilesetTile = tileset.tileImage[tileOffset]
      for k in 0..<1024:
        let x = (j + (i mod dictColumns) * 4) * 32 + (k mod 32)
        let y = (i div dictColumns) * 32 + (k div 32)
        let index = tilesetTile[k]
        if index == 0: continue
        let color = tileset.palette[index]
        # if color == 0: continue
        im[x, y] = ColorRGB(
          r: color[0],
          g: color[1],
          b: color[2]
        )
  echo "saving"
  im.writeFile("dictionary.png")

  for i, layer in self.layers.pairs:
    if not layer.haveAnyTiles: continue
    echo "drawing layer " & $i
    var im2 = newImage(32 * (layer.width.int),  int 32 * layer.height.int)
    for j, wordId in layer.wordMap.pairs:
      if wordId == 0: continue
      let word = self.dictionary[wordId]
      for t, tile in word.pairs:
        if tile.tileId == 0: continue
        if ((j * 4 + t) mod layer.realWidth.int) >= layer.width.int: continue
        let tileId = if not tile.animated:
          tile.tileId
        else:
          self.calculateAnimTile(tile.tileId).tileId
        let tileOffset = tileset.tileOffsets[tileId].image
        let tilesetTile = tileset.tileImage[tileOffset]
        for k in 0..<1024:
          let x = ((j * 4 + t) mod layer.realWidth.int) * 32 + (k mod 32)
          let y = ((j * 4 + t) div layer.realWidth.int) * 32 + (k div 32)
          let index = tilesetTile[k]
          if index == 0: continue
          let color = tileset.palette[index]
          im2[x, y] = ColorRGB(
            r: color[0],
            g: color[1],
            b: color[2]
          )
    echo "saving"
    im2.writeFile("layer-" & $i & ".png")


proc test*(filename: string) =
  echo "loading events"
  loadJcsIni("JCS.ini")

  var level = Level()
  if level.load(filename, "heya"):
    level.debug()
