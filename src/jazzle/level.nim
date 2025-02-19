import std/streams
import std/strutils
import std/bitops
import pixie
import zippy
import zippy/crc
import parseini
import ./common
import ./tileset

export common

const
  J2lVersionAGA  = 0x100'u16
  J2lVersion1_23 = 0x202'u16
  J2lVersion1_24 = 0x203'u16

  HashNoPassword = 0x00BABE'u32

  SecurityPassworded = 0xBA00BE00'u32
  SecurityMLLE = 0xBACABEEF'u32
  SecurityDisabled = 0x00000000'u32

  LayerCount* = 8
  SpriteLayerNum* = 3
  BackgroundLayerNum* = 7
  HeaderStructSize = 262
  AnimStructSize = 137

  DefaultLevelSize = (
    x: 256,
    y: 64
  )
  DefaultLayerSpeeds = [
    pow(1.5, 2),
    pow(1.5, 1),
    pow(1.5, 0),
    pow(1.5, 0),
    pow(1.5, -1),
    pow(1.5, -2),
    pow(1.5, -3),
    0
  ]

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

  RawTile* = uint16

  Tile* = object
    tileId*: uint16
    hflipped*: bool
    vflipped*: bool # plus only
    animated*: bool

  WordId* = uint16 # index in dictionary
  RawWord* = array[4, RawTile]
  WordTiles* = array[4, Tile]

  WordOverride* = object
    x*: int
    y*: int
    wordId*: WordId

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
    event*: Event

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
    tileCache*: seq[WordId]
    tileCacheOverrides*: seq[WordOverride]
    map*: seq[seq[Tile]]

  Level* = object
    title*: string
    version*: GameVersion
    hideInHomecooked*: bool
    passwordHash: uint32 # lower 3 bytes only (24-bit)
    fileSize*: uint32
    checksum*: uint32

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

    tilesetEvents*: array[4096, Event] # events for animations are stored in anims[].event
    tileTypes*: array[4096, TileType]
    isEachTileFlipped*: array[4096, bool]
    isEachTileUsed*: array[4096, uint8] # unused?

    # soundEffectPointer*: array[48, array[64, uint8]] # AGA version only
    layers*: array[LayerCount, Layer]
    events*: seq[seq[Event]]

    # unknownAGA*: array[32768, char] # only in AGA

    anims*: seq[AnimatedTile]

    dictionary*: seq[RawWord]

var jcsEvents: array[256, EventInfo]

proc maxTiles*(self: Level): int =
  if self.version == v1_23:
    1024
  else:
    4096

proc maxAnimTiles*(self: Level): int =
  if self.version == v1_23:
    128
  else:
    256

proc animOffset*(self: Level): uint16 = uint16 self.maxTiles - self.anims.len

proc calculateRealWidth*(width: uint32; tileWidth: bool): uint32 =
  if not tileWidth:
    ((width + 3) div 4) * 4
  else:
    var overflow = width mod 4
    if overflow == 0:
      width
    elif overflow == 2:
      width * 2
    else:
      width * 4

proc layerSpeed*(speed: float): int32 {.inline.} = int32 speed * 65536

proc lightLevel*(level: float): uint8 {.inline.} = uint8 level * 0.64

proc parseTile*(self: Level; rawtile: RawTile): Tile =
  if self.version != v1_24:
    result = Tile(tileId: rawtile and 1023, hflipped: (rawtile and 0x400) > 0)
  else:
    result = Tile(tileId: rawtile and 4095, hflipped: (rawtile and 0x1000) > 0)
  result.vflipped = (rawtile and 0x2000) > 0
  if result.tileId >= self.animOffset:
    result.animated = true
    result.tileId -= self.animOffset

proc rawTile*(self: Level; tile: Tile): RawTile =
  result = tile.tileId
  if tile.animated:
    result += self.animOffset
  if tile.hflipped:
    result = result or (if self.version == v1_23: 0x400 else: 0x1000)
  if tile.vflipped:
    result = result or 0x2000
  # if self.parseTile(result) != tile:
  #   echo (self.parseTile(result), tile, result, self.anims.len)
  assert self.parseTile(result) == tile

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

proc setPassword*(self: var Level; password: string) =
  self.securityEnvelope = SecurityPassworded
  self.securityEnabled = true
  self.passwordHash = crc32(password) and 0xffffff

proc removePassword*(self: var Level) =
  self.securityEnvelope = SecurityDisabled
  self.securityEnabled = false
  self.passwordHash = HashNoPassword

proc checkIfLayerHaveTiles*(self: Level; layerId: int): bool =
  if layerId == SpriteLayerNum: return true
  for row in self.layers[layerId].map:
    for tile in row:
      if tile.tileId > 0 or tile.animated:
        return true

proc rebuildMap*(self: var Level) =
  for i, layer in self.layers.mpairs:
    layer.map.setLen(layer.height)
    for row in layer.map.mitems:
      row.setLen(layer.width)
    if not layer.haveAnyTiles: continue
    for j, wordId in layer.tileCache.pairs:
      if wordId == 0: continue
      let word = self.dictionary[wordId]
      for t, rawtile in word.pairs:
        if rawtile == 0: continue
        if ((j * 4 + t) mod layer.realWidth.int) >= layer.width.int: continue
        let tile = self.parseTile(rawtile)
        let x = (j * 4 + t) mod layer.realWidth.int
        let y = (j * 4 + t) div layer.realWidth.int
        layer.map[y][x] = tile

proc rebuildTileCache*(self: var Level; saveOverrides: bool = false) =
  var dictionary = newSeq[RawWord](1)
  for i, layer in self.layers.mpairs:
    var tileCache: seq[WordId]
    layer.haveAnyTiles = self.checkIfLayerHaveTiles(i)
    layer.realWidth = calculateRealWidth(layer.width, layer.properties.tileWidth)
    if saveOverrides:
      layer.tileCacheOverrides.setLen(0)
    if not layer.haveAnyTiles: continue
    echo "reading words in layer ", i
    for y, row in layer.map:
      var x = 0
      while x < layer.realWidth.int:
        var hasAnimAndEvent = false
        var rawword: RawWord
        for k in 0..<4:
          if not layer.properties.tileWidth and x + k >= layer.width.int:
            break
          let tile = row[(x + k) mod layer.width.int].addr
          if tile.tileId == 0 and not tile.animated:
            tile.hflipped = false
            tile.vflipped = false
          rawword[k] = self.rawTile(tile[])
          if i == SpriteLayerNum and tile.animated and x + k < layer.width.int and self.events[y][x + k].eventId > 0:
            hasAnimAndEvent = true
        if hasAnimAndEvent:
          let pos = dictionary.len
          dictionary.add(rawword)
          tileCache.add(pos.uint16)
        else:
          var pos = dictionary.rfind(rawword)
          if pos == -1:
            pos = dictionary.len
            dictionary.add(rawword)
          tileCache.add(pos.uint16)

        let index = tileCache.len - 1
        if saveOverrides:
          if layer.tileCache[index] != tileCache[index]:
            layer.tileCacheOverrides.add(WordOverride(x: x, y: y, wordId: layer.tileCache[index]))
            tileCache[index] = layer.tileCache[index]
        else:
          for override in layer.tileCacheOverrides:
            if override.x == x and override.y == y:
              tileCache[index] = override.wordId

        x += 4

    echo "tileCache ", i, " ", (layer.tileCache.len, tileCache.len), layer.tileCache == tileCache
    echo layer.tileCacheOverrides
    layer.tileCache = tileCache

  echo "dict ", (self.dictionary.len, dictionary.len), self.dictionary == dictionary
  self.dictionary = dictionary

const NewLevel* = static:
  var level = Level(
    title: "Untitled",
    version: v1_24,
    passwordHash: HashNoPassword,
    lastLayer: SpriteLayerNum,
    securityEnvelope: SecurityDisabled,
    minLight: lightLevel(100),
    startLight: lightLevel(100),
    dictionary: newSeq[RawWord](1)
  )
  level.levelName = level.title

  level.layers[BackgroundLayerNum].properties.tileWidth = true
  level.layers[BackgroundLayerNum].properties.tileHeight = true

  for i, layer in level.layers.mpairs:
    layer.zAxis = int32 i * 100 - 300
    if i != BackgroundLayerNum:
      layer.width = ceil(DefaultLevelSize.x.float * DefaultLayerSpeeds[i]).uint32
      layer.height = ceil(DefaultLevelSize.y.float * DefaultLayerSpeeds[i]).uint32
    else:
      layer.width = 8
      layer.height = 8
    if i == SpriteLayerNum:
      layer.speedX = layerSpeed(1)
      layer.speedY = layerSpeed(1)
      layer.haveAnyTiles = true
      level.events.setLen(layer.height)
      for row in level.events.mitems:
        row.setLen(layer.width)
    else:
      layer.speedX = layerSpeed(DefaultLayerSpeeds[i])
      layer.speedY = layerSpeed(DefaultLayerSpeeds[i])

    layer.map.setLen(layer.height)
    for row in layer.map.mitems:
      row.setLen(layer.width)

    layer.realWidth = calculateRealWidth(layer.width, layer.properties.tileWidth)

    if layer.haveAnyTiles:
      layer.tileCache = newSeq[WordId](layer.realWidth * layer.height div 4)

  # level.anims.add(AnimatedTile(frames: @[Tile(tileId: 100)]))

  # level.layers[SpriteLayerNum].map[63][200] = Tile(tileId: 0, animated: true)
  # level.events[63][200].eventId = 160
  # level.layers[SpriteLayerNum].map[63][204] = Tile(tileId: 0, animated: true)
  # level.events[63][204].eventId = 170
  # level.layers[SpriteLayerNum].map[63][208] = Tile(tileId: 0, animated: true)

  # level.layers[SpriteLayerNum].map[63][180] = Tile(tileId: 100)
  # level.layers[SpriteLayerNum].map[63][184] = Tile(tileId: 100)

  level.rebuildTileCache()

  level

proc loadInfo(self: var Level, s: Stream) =
  # data1
  s.read(self.lastHorizontalOffset)
  self.securityEnvelope = s.readUint16().uint32 shl 16
  s.read(self.lastVerticalOffset)
  self.securityEnvelope = self.securityEnvelope or s.readUint16().uint32
  let security3AndLastLayer = s.readUint8()
  self.securityEnabled = (security3AndLastLayer shr 4) != 0
  self.lastLayer = security3AndLastLayer and 0b1111

  s.read(self.minLight)
  s.read(self.startLight)

  var animCount: uint16
  s.read(animCount)
  self.anims.setLen(animCount.int)

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

  var staticTiles: uint16
  s.read(staticTiles)

  doAssert staticTiles == self.maxTiles.uint16 - animCount
  doAssert staticTiles == self.animOffset

  for i in 0..<staticTiles.int:
    s.read(self.tilesetEvents[i])
  for i in 0..<self.anims.len:
    s.read(self.anims[i].event)

  for i in 0..<self.maxTiles:
    self.isEachTileFlipped[i] = s.readBool()

  for i in 0..<self.maxTiles:
    let val = s.readUint8()
    self.tileTypes[i] = case val:
      of 1: Translucent
      of 4: Caption
      else: Default

  for i in 0..<self.maxTiles:
    s.read(self.isEachTileUsed[i]) # unused?

  # if self.version == v_AGA:
  #   s.read(self.unknownAGA)

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

proc writeInfo(s: Stream; level: var Level) =
  s.write(level.lastHorizontalOffset)
  s.write(uint16 level.securityEnvelope shr 16)
  s.write(level.lastVerticalOffset)
  s.write(uint16 level.securityEnvelope and 0xffff)
  s.write(uint8 (level.securityEnabled.uint8 shl 4) or (level.lastLayer and 0b1111))

  s.write(level.minLight)
  s.write(level.startLight)
  s.write(uint16 level.anims.len)
  s.write(level.verticalSplitscreen)
  s.write(level.isLevelMultiplayer)

  s.write(uint32 0xffffffff) # bufferSize, gets filled in later

  s.writeCStr(level.levelName, 32)
  s.writeCStr(level.tileset, 32)
  s.writeCStr(level.bonusLevel, 32)
  s.writeCStr(level.nextLevel, 32)
  s.writeCStr(level.secretLevel, 32)
  s.writeCStr(level.musicFile, 32)
  for i in 0..<level.helpString.len:
    s.writeCStr(level.helpString[i], 512)

  for layer in level.layers.items: s.write(layer.properties)
  for layer in level.layers.items: s.write(layer.layerType) # unused
  for layer in level.layers.items: s.write(layer.haveAnyTiles)
  for layer in level.layers.items: s.write(layer.width)
  for layer in level.layers.mitems:
    layer.realWidth = calculateRealWidth(layer.width, layer.properties.tileWidth)
    s.write(layer.realWidth)
  for layer in level.layers.items: s.write(layer.height)
  for layer in level.layers.items: s.write(layer.zAxis) # unused
  for layer in level.layers.items: s.write(layer.detailLevel) # mostly unused
  for layer in level.layers.items: s.write(layer.waveX) # unused
  for layer in level.layers.items: s.write(layer.waveY) # unused
  for layer in level.layers.items: s.write(layer.speedX)
  for layer in level.layers.items: s.write(layer.speedY)
  for layer in level.layers.items: s.write(layer.autoSpeedX)
  for layer in level.layers.items: s.write(layer.autoSpeedY)
  for layer in level.layers.items: s.write(layer.textureMode)
  for layer in level.layers.items: s.write(layer.textureParams)

  s.write(uint16 level.animOffset)

  for i in 0..<level.maxTiles:
    s.write(level.tilesetEvents[i])

  for i in 0..<level.maxTiles:
    s.write(level.isEachTileFlipped[i])

  for i in 0..<level.maxTiles:
    s.write(level.tileTypes[i].uint8)

  for i in 0..<level.maxTiles:
    s.write(level.isEachTileUsed[i]) # unused?

  for i, anim in level.anims.pairs:
    s.write(anim.frameWait)
    s.write(anim.randomWait)
    s.write(anim.pingPongWait)
    s.write(anim.pingPong)
    s.write(anim.speed)
    s.write(uint8 anim.frames.len)
    var rawframes: array[64, uint16]
    for f, frame in anim.frames:
      rawframes[f] = level.rawTile(frame)
    s.write(rawframes)

  for i in 0..<(level.maxAnimTiles - level.anims.len):
    for j in 0..<AnimStructSize:
      s.write(uint8 0)

  let bufferSize = s.getPosition().uint32
  s.setPosition(15)
  s.write(bufferSize)

proc loadEvents(self: var Level; s: StringStream) =
  self.events.setLen(self.layers[SpriteLayerNum].height)
  for row in self.events.mitems:
    row.setLen(self.layers[SpriteLayerNum].width)
    for event in row.mitems:
      s.read(event)
  doAssert s.atEnd()
  s.close()

proc loadDictionary(self: var Level; s: StringStream) =
  self.dictionary.setLen(s.data.len div sizeof(RawWord))
  for word in self.dictionary.mitems:
    s.read(word)
  doAssert s.atEnd()
  s.close()

proc writeDictData(s: Stream; level: Level) =
  for word in level.dictionary:
    for tile in word:
      s.write(tile)

proc loadWordMap(self: var Level; s: Stream)=
  for i in 0..<LayerCount:
    if not self.layers[i].haveAnyTiles:
      self.layers[i].tileCache.setLen(0)
      continue
    self.layers[i].tileCache.setLen(((self.layers[i].realWidth+3) div 4) * self.layers[i].height)
    for j in 0..<self.layers[i].tileCache.len:
      s.read(self.layers[i].tileCache[j])
  doAssert s.atEnd()
  s.close()

proc writeWordMapData(s: Stream; level: Level) =
  for i in 0..<LayerCount:
    if not level.layers[i].haveAnyTiles:
      continue
    for j in 0..<level.layers[i].tileCache.len:
      s.write(level.layers[i].tileCache[j])

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

  if self.passwordHash != HashNoPassword:
    var hash = crc32(password) and 0xffffff
    if self.passwordHash != hash:
      echo "invalid password"
      echo (self.passwordHash.toHex(), hash.toHex(), password)
      return false

  s.read(self.hideInHomecooked)

  self.title = s.readCStr(32)
  let versionNum = s.readUint16()
  self.version = if versionNum == 0x100: v_AGA elif versionNum <= 0x202: v1_23 else: v1_24
  self.fileSize = s.readUint32()
  self.checksum = s.readUint32()
  echo "version: ", self.version

  var streamSizes: array[StreamKind, StreamSize]
  var compressedLength: uint32 = 0
  for kind in StreamKind.items:
    streamSizes[kind].packedSize = s.readUint32()
    streamSizes[kind].unpackedSize = s.readUint32()
    compressedLength += streamSizes[kind].packedSize

  if compressedLength + HeaderStructSize != self.fileSize:
    echo "filesize doesn't match!"
    return false

  let compressedData = newStringStream(s.readStr(compressedLength.int))
  defer: compressedData.close()

  let checksum = crc32(compressedData.data)

  if checksum != self.checksum:
    echo "checksums doesn't match!"
    return false

  var sections: array[StreamKind, StringStream]
  for kind in StreamKind.items:
    var data = compressedData.readStr(streamSizes[kind].packedSize.int)
    data = uncompress(data, dfZlib)
    doAssert data.len.uint32 == streamSizes[kind].unpackedSize
    sections[kind] = newStringStream(data)

  doAssert compressedData.atEnd()

  # TODO: Parse MLLE data here
  # doAssert s.atEnd()
  s.close()

  self.loadInfo(sections[LevelInfo])

  case self.securityEnvelope:
  of SecurityPassworded: echo "level passworded"
  of SecurityMLLE: echo "MLLE only level"
  of SecurityDisabled: echo "level unprotected"
  else: echo "unknown security envelope: " & self.securityEnvelope.toHex(); return false

  self.loadEvents(sections[EventData])
  self.loadDictionary(sections[DictData])
  self.loadWordMap(sections[WordMapData])

  self.rebuildMap()
  self.rebuildTileCache(true)

  return true

proc load*(self: var Level; filename: string; password: string = ""): bool =
  self.reset()
  let s = newFileStream(filename)
  defer: s.close()
  self.load(s, password)

proc save*(self: var Level; s: Stream) =
  s.write(DataFileCopyright)
  s.write("LEVL")
  s.write(uint8 (self.passwordHash shr 16) and 0xff)
  s.write(uint8 (self.passwordHash shr 8) and 0xff)
  s.write(uint8 self.passwordHash and 0xff)
  s.write(uint8 self.hideInHomecooked)
  s.writeCStr(self.title, 32)
  s.write(if self.version == v_AGA: J2lVersionAGA elif self.version == v1_23: J2lVersion1_23 else: J2lVersion1_24)

  var streams: array[StreamKind, string]

  let levelInfoStream = newStringStream("")
  levelInfoStream.writeInfo(self)
  streams[LevelInfo] = levelInfoStream.data
  levelInfoStream.close()

  streams[EventData] = newString(self.layers[SpriteLayerNum].width.int * self.layers[SpriteLayerNum].height.int * sizeof(Event))
  var eventOffset = 0
  for row in self.events:
    if row.len > 0:
      copyMem(streams[EventData][eventOffset].addr, row[0].addr, row.len * sizeof(Event))
    eventOffset += self.layers[SpriteLayerNum].width.int * sizeof(Event)

  let dictDataStream = newStringStream("")
  dictDataStream.writeDictData(self)
  streams[DictData] = dictDataStream.data
  dictDataStream.close()

  let wordMapStream = newStringStream("")
  wordMapStream.writeWordMapData(self)
  streams[WordMapData] = wordMapStream.data
  wordMapStream.close()

  var streamSizes: array[StreamKind, StreamSize]
  var compressedData = ""
  for kind in StreamKind.items:
    streamSizes[kind].unpackedSize = streams[kind].len.uint32
    streams[kind] = compress(streams[kind], DefaultCompression, dfZlib)
    streamSizes[kind].packedSize = streams[kind].len.uint32
    compressedData &= streams[kind]
    streams[kind] = ""

  self.fileSize = compressedData.len.uint32 + HeaderStructSize
  self.checksum = crc32(compressedData)

  s.write(self.fileSize)
  s.write(self.checksum)

  for kind in StreamKind.items:
    s.write(streamSizes[kind].packedSize)
    s.write(streamSizes[kind].unpackedSize)

  s.write(compressedData)

proc save*(self: var Level; filename: string) =
  let s = newFileStream(filename, fmWrite)
  defer: s.close()
  self.save(s)

proc debug*(self: Level) =

  var ef = open("events.txt", fmWrite)

  for y, row in self.events.pairs:
    for x, event in row:
      if event.eventId == 0: continue
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

  if self.anims.len > 0:
    var highestFrame = 0
    for anim in self.anims:
      if anim.frames.len > highestFrame:
        highestFrame = anim.frames.len
    if highestFrame > 0:
      echo "drawing anims"
      var ima = newImage(32 * highestFrame.int,  32 * self.anims.len)
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
    for j, rawtile in word:
      if rawtile == 0: continue
      let tile = self.parseTile(rawtile)
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
    for j, wordId in layer.tileCache:
      if wordId == 0: continue
      let word = self.dictionary[wordId]
      for t, rawtile in word.pairs:
        if rawtile == 0: continue
        let tile = self.parseTile(rawtile)
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
    echo "saving 1"
    im2.writeFile("layer-" & $i & "-tilecache.png")

    im2 = newImage(32 * (layer.width.int),  int 32 * layer.height.int)
    for y, row in layer.map:
      for x, tile in row:
        let tileId = if not tile.animated:
          tile.tileId
        else:
          self.calculateAnimTile(tile.tileId).tileId
        let tileOffset = tileset.tileOffsets[tileId].image
        let tilesetTile = tileset.tileImage[tileOffset]
        for k in 0..<1024:
          let px = x * 32 + (k mod 32)
          let py = y * 32 + (k div 32)
          let index = tilesetTile[k]
          if index == 0: continue
          let color = tileset.palette[index]
          im2[px, py] = ColorRGB(
            r: color[0],
            g: color[1],
            b: color[2]
          )
    echo "saving 2"
    im2.writeFile("layer-" & $i & "-map.png")



proc test*() =
  echo "loading events"
  loadJcsIni("JCS.ini")

  echo "loading JCS new level"
  var jcsNewLevel = Level()
  doAssert jcsNewLevel.load("Untitled.j2l")
  jcsNewLevel.save("level_untitled_saved.j2l")

  echo "creating new level"
  var newLevel = NewLevel
  newLevel.setPassword("heya")
  newLevel.save("level_new.j2l")

  echo "loading created new level"
  var level = Level()
  doAssert level.load("level_new.j2l", "heya")
  level.save("level_new_saved.j2l")

  doAssert readFile("level_new.j2l") == readFile("level_new_saved.j2l")

  echo "loading official level"
  level = Level()
  if level.load("ReworderEx2.j2l", "heya"):
    echo "saving level"
    level.rebuildTileCache()
    level.save("level_saved.j2l")
    level.debug()
