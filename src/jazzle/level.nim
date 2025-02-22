import std/streams
import std/strutils
import std/bitops
import pixie
import zippy
import zippy/crc
import parseini
import std/sets
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
  SecurityEnabled = 0b1111'u8

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

  EventId* {.size: sizeof(uint8).} = enum
    Event_None = 0
    Event_OneWay = 1
    Event_Hurt = 2
    Event_Vine = 3
    Event_Hook = 4
    Event_Slide = 5
    Event_H_Pole = 6
    Event_V_Pole = 7
    Event_AreaFlyOff = 8
    Event_Ricochet = 9
    Event_BeltRight = 10
    Event_BeltLeft = 11
    Event_AccBeltR = 12
    Event_AccBeltL = 13
    Event_StopEnemy = 14
    Event_WindLeft = 15
    Event_WindRight = 16
    Event_AreaEndOfLevel = 17
    Event_AreaWarpEOL = 18
    Event_AreaRevertMorph = 19
    Event_AreaFloatUp = 20
    Event_TriggerRock = 21
    Event_DimLight = 22
    Event_SetLight = 23
    Event_LimitXScroll = 24
    Event_ResetLight = 25
    Event_AreaWarpSecret = 26
    Event_Echo = 27
    Event_ActivateBoss = 28
    Event_JazzLevelStart = 29
    Event_SpazLevelStart = 30
    Event_MultiplayerLevelStart = 31
    Event_LoriLevelStart = 32
    Event_FreezerAmmo3 = 33
    Event_BouncerAmmo3 = 34
    Event_SeekerAmmo3 = 35
    Event_3WayAmmo3 = 36
    Event_ToasterAmmo3 = 37
    Event_TNTAmmo3 = 38
    Event_Gun8Ammo3 = 39
    Event_Gun9Ammo3 = 40
    Event_StillTurtleshell = 41
    Event_SwingingVine = 42
    Event_Bomb = 43
    Event_SilverCoin = 44
    Event_GoldCoin = 45
    Event_Guncrate = 46
    Event_Carrotcrate = 47
    Event_1Upcrate = 48
    Event_Gembarrel = 49
    Event_Carrotbarrel = 50
    Event_1upbarrel = 51
    Event_BombCrate = 52
    Event_FreezerAmmo15 = 53
    Event_BouncerAmmo15 = 54
    Event_SeekerAmmo15 = 55
    Event_3WayAmmo15 = 56
    Event_ToasterAmmo15 = 57
    Event_TNT_Object = 58
    Event_Airboard = 59
    Event_FrozenGreenSpring = 60
    Event_GunFastFire = 61
    Event_SpringCrate = 62
    Event_RedGem1 = 63
    Event_GreenGem1 = 64
    Event_BlueGem1 = 65
    Event_PurpleGem1 = 66
    Event_SuperRedGem = 67
    Event_Birdy = 68
    Event_GunBarrel = 69
    Event_GemCrate = 70
    Event_Jazz_Spaz = 71
    Event_CarrotEnergy1 = 72
    Event_FullEnergy = 73
    Event_FireShield = 74
    Event_WaterShield = 75
    Event_LightningShield = 76
    Event_Maxweapon = 77
    Event_Autofire = 78
    Event_FastFeet = 79
    Event_ExtraLive = 80
    Event_EndofLevelsignpost = 81
    Event_82 = 82
    Event_Savepointsignpost = 83
    Event_BonusLevelsignpost = 84
    Event_RedSpring = 85
    Event_GreenSpring = 86
    Event_BlueSpring = 87
    Event_Invincibility = 88
    Event_ExtraTime = 89
    Event_FreezeEnemies = 90
    Event_HorRedSpring = 91
    Event_HorGreenSpring = 92
    Event_HorBlueSpring = 93
    Event_MorphIntoBird = 94
    Event_SceneryTriggerCrate = 95
    Event_Flycarrot = 96
    Event_RectGemRed = 97
    Event_RectGemGreen = 98
    Event_RectGemBlue = 99
    Event_TufTurt = 100
    Event_TufBoss = 101
    Event_LabRat = 102
    Event_Dragon = 103
    Event_Lizard = 104
    Event_Bee = 105
    Event_Rapier = 106
    Event_Sparks = 107
    Event_Bat = 108
    Event_Sucker = 109
    Event_Caterpillar = 110
    Event_Cheshire1 = 111
    Event_Cheshire2 = 112
    Event_Hatter = 113
    Event_BilsyBoss = 114
    Event_Skeleton = 115
    Event_DoggyDogg = 116
    Event_NormTurtle = 117
    Event_Helmut = 118
    Event_Leaf = 119
    Event_Demon = 120
    Event_Fire = 121
    Event_Lava = 122
    Event_DragonFly = 123
    Event_Monkey = 124
    Event_FatChick = 125
    Event_Fencer = 126
    Event_Fish = 127
    Event_Moth = 128
    Event_Steam = 129
    Event_RotatingRock = 130
    Event_BlasterPowerUp = 131
    Event_BouncyPowerUp = 132
    Event_IcegunPowerUp = 133
    Event_SeekPowerUp = 134
    Event_RFPowerUp = 135
    Event_ToasterPowerUP = 136
    Event_PIN_LeftPaddle = 137
    Event_PIN_RightPaddle = 138
    Event_PIN_500Bump = 139
    Event_PIN_CarrotBump = 140
    Event_Apple = 141
    Event_Banana = 142
    Event_Cherry = 143
    Event_Orange = 144
    Event_Pear = 145
    Event_Pretzel = 146
    Event_Strawberry = 147
    Event_SteadyLight = 148
    Event_PulzeLight = 149
    Event_FlickerLight = 150
    Event_QueenBoss = 151
    Event_FloatingSucker = 152
    Event_Bridge = 153
    Event_Lemon = 154
    Event_Lime = 155
    Event_Thing = 156
    Event_Watermelon = 157
    Event_Peach = 158
    Event_Grapes = 159
    Event_Lettuce = 160
    Event_Eggplant = 161
    Event_Cucumb = 162
    Event_SoftDrink = 163
    Event_SodaPop = 164
    Event_Milk = 165
    Event_Pie = 166
    Event_Cake = 167
    Event_Donut = 168
    Event_Cupcake = 169
    Event_Chips = 170
    Event_Candy = 171
    Event_Chocbar = 172
    Event_Icecream = 173
    Event_Burger = 174
    Event_Pizza = 175
    Event_Fries = 176
    Event_ChickenLeg = 177
    Event_Sandwich = 178
    Event_Taco = 179
    Event_Weenie = 180
    Event_Ham = 181
    Event_Cheese = 182
    Event_FloatLizard = 183
    Event_StandMonkey = 184
    Event_DestructScenery = 185
    Event_DestructSceneryBOMB = 186
    Event_CollapsingScenery = 187
    Event_ButtStompScenery = 188
    Event_InvisibleGemStomp = 189
    Event_Raven = 190
    Event_TubeTurtle = 191
    Event_GemRing = 192
    Event_SmallTree = 193
    Event_AmbientSound = 194
    Event_Uterus = 195
    Event_Crab = 196
    Event_Witch = 197
    Event_RocketTurtle = 198
    Event_Bubba = 199
    Event_Devildevanboss = 200
    Event_Devan_RobotBoss = 201
    Event_Robot_RobotBoss = 202
    Event_Carrotuspole = 203
    Event_Psychpole = 204
    Event_Diamonduspole = 205
    Event_SuckerTube = 206
    Event_Text = 207
    Event_WaterLevel = 208
    Event_FruitPlatform = 209
    Event_BollPlatform = 210
    Event_GrassPlatform = 211
    Event_PinkPlatform = 212
    Event_SonicPlatform = 213
    Event_SpikePlatform = 214
    Event_SpikeBoll = 215
    Event_Generator = 216
    Event_Eva = 217
    Event_Bubbler = 218
    Event_TNTPowerup = 219
    Event_Gun8Powerup = 220
    Event_Gun9Powerup = 221
    Event_MorphFrog = 222
    Event_3DSpikeBoll = 223
    Event_Springcord = 224
    Event_Bees = 225
    Event_Copter = 226
    Event_LaserShield = 227
    Event_Stopwatch = 228
    Event_JunglePole = 229
    Event_Warp = 230
    Event_BigRock = 231
    Event_BigBox = 232
    Event_WaterBlock = 233
    Event_TriggerScenery = 234
    Event_BollyBoss = 235
    Event_Butterfly = 236
    Event_BeeBoy = 237
    Event_Snow = 238
    Event_239 = 239
    Event_WarpTarget = 240
    Event_TweedleBoss = 241
    Event_AreaId = 242
    Event_243 = 243
    Event_CTFBaseFlag = 244
    Event_NoFireZone = 245
    Event_TriggerZone = 246
    Event_XmasBilsyBoss = 247
    Event_XmasNormTurtle = 248
    Event_XmasLizard = 249
    Event_XmasFloatLizard = 250
    Event_AddonDOG = 251
    Event_AddonSparks = 252
    Event_253 = 253
    Event_254 = 254
    Event_MCE = 255

  EventType* = enum
    Normal
    Easy
    Hard
    OnlyMultiplayer

  Event* {.packed.} = object
    eventId*: EventId
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

  LevelBottomMode* = enum
    ## JJ2+ feature
    Default
    DeathPit
    SolidFloor

  TeamTriggerState* = enum
    ## JJ2+ feature
    Disabled
    BlueOff
    BlueOn

  RawTile* = uint16

  Tile* = object
    tileId*: uint16
    hflipped*: bool
    vflipped*: bool # plus only
    animated*: bool

  WordId* = uint16 # index in dictionary
  RawWord* = array[4, RawTile]
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
    helpString*: seq[string]

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

    tileCacheOverrides*: seq[OrderedSet[tuple[layer: int, x: int, y: int]]]

    # JJ2+ features
    levelBottomMode*: LevelBottomMode
    teamTriggerState*: TeamTriggerState
    teamTriggerId*: int
    serverTriggerEnabled*: bool
    serverTriggerId*: int
    overtimeTriggerEnabled*: bool
    overTimeTriggerId*: int

var jcsEvents: array[EventId, EventInfo]

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

proc loadJcsIni*(filename: string = "JCS.ini") =
  let jcsini = loadConfig(filename)
  for eventId in EventId:
    jcsEvents[eventId] = parseIniEvent(jcsini.getSectionValue("Events", $eventId.ord))

proc params*(event: Event): seq[int] =
  let jcsEvent = jcsEvents[event.eventId]
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

proc `params=`*(event: var Event; params: seq[int]) =
  event.data = 0
  let jcsEvent = jcsEvents[event.eventId]
  var offset = 0
  for i in 0..<min(jcsEvent.params.len, params.len):
    let p = jcsEvent.params[i]
    # let signed = p.size < 0
    let size = abs(p.size)
    let shift = 1 shl size
    let bits = uint32 params[i] and (shift - 1)
    event.data = event.data or (bits shl offset)
    offset += size

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

proc locateWordId(self: Level; wordIdCheck: WordId): OrderedSet[tuple[layer: int, x: int, y: int]] =
  for i, layer in self.layers:
    for pos, wordId in layer.tileCache:
      if wordIdCheck == wordId:
        let x = (pos * 4) mod layer.realWidth.int
        let y = (pos * 4) div layer.realWidth.int
        result.incl((i, x, y))

proc rebuildTileCache*(self: var Level; saveOverrides: bool = false) =
  var checkedWordIds: seq[WordId]
  var dictionary = newSeq[RawWord](1)
  if saveOverrides:
    self.tileCacheOverrides.reset()
  for i, layer in self.layers.mpairs:
    layer.haveAnyTiles = self.checkIfLayerHaveTiles(i)
    layer.realWidth = calculateRealWidth(layer.width, layer.properties.tileWidth)

    var tileCache: seq[WordId]
    if not layer.haveAnyTiles: continue
    # echo "reading words in layer ", i
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
          if i == SpriteLayerNum and tile.animated and x + k < layer.width.int and self.events[y][x + k].eventId != Event_None:
            hasAnimAndEvent = true
        if hasAnimAndEvent:
          let pos = dictionary.len
          dictionary.add(rawword)
          tileCache.add(pos.uint16)

          let index = tileCache.len - 1
          if saveOverrides:
            let wordId = layer.tileCache[index]
            if checkedWordIds.find(wordId) == -1:
              let locations = self.locateWordId(wordId)
              if locations.len >= 2:
                checkedWordIds.add(wordId)
                self.tileCacheOverrides.add(locations)
                tileCache[index] = wordId
            else:
              tileCache[index] = wordId

        else:
          var pos = dictionary.find(rawword)
          if pos == -1:
            pos = dictionary.len
            dictionary.add(rawword)
          tileCache.add(pos.uint16)

        x += 4

    echo "tileCache ", i, " ", (layer.tileCache.len, tileCache.len, layer.tileCache == tileCache)
    layer.tileCache = tileCache

  if not saveOverrides:
    for override in self.tileCacheOverrides:
      echo "override ", override
      var i = 0
      var wordId: WordId
      for location in override:
        let layer = self.layers[location.layer].addr
        if not layer.haveAnyTiles or location.x >= layer.realWidth.int or location.y >= layer.height.int: continue
        let index = (location.x + location.y * layer.realWidth.int) div 4
        if i == 0:
          wordId = layer.tileCache[index]
        else:
          layer.tileCache[index] = wordId
        inc(i)

  echo "dict ", (self.dictionary.len, dictionary.len, self.dictionary == dictionary)
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

proc loadInfo(self: var Level, s: StringStream) =
  # data1
  s.read(self.lastHorizontalOffset)
  self.securityEnvelope = s.readUint16().uint32 shl 16
  s.read(self.lastVerticalOffset)
  self.securityEnvelope = self.securityEnvelope or s.readUint16().uint32
  let security3AndLastLayer = s.readUint8()
  self.securityEnabled = (security3AndLastLayer shr 4) == SecurityEnabled
  self.lastLayer = security3AndLastLayer and 0b1111

  s.read(self.minLight)
  s.read(self.startLight)

  var animCount: uint16
  s.read(animCount)
  self.anims.setLen(animCount.int)

  s.read(self.verticalSplitscreen)
  s.read(self.isLevelMultiplayer)

  let bufferSize = s.readUint32()
  doAssert bufferSize == s.data.len.uint32

  self.levelName = s.readCStr(32)
  self.tileset = s.readCStr(32)
  self.bonusLevel = s.readCStr(32)
  self.nextLevel = s.readCStr(32)
  self.secretLevel = s.readCStr(32)
  self.musicFile = s.readCStr(32)

  let helpStringOffset = s.getPosition()
  self.helpString.setLen(16)
  for i in 0..<16:
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

  echo "number of anims: ", self.anims.len, " of ", self.maxAnimTiles
  let expectedAfterAnim = s.getPosition() + (self.maxAnimTiles - self.anims.len) * AnimStructSize
  echo s.getPosition(), " position after anims"

  # neobeo's firetruck text strings, incompatible with JJ2+ and TSF
  s.setPosition(min(s.getPosition(), s.getPosition() - ((s.getPosition() - helpStringOffset) mod 512)) + 512)
  echo s.getPosition(), " extra help strings"

  while not s.atEnd() and self.helpString.len <= 256:
    try:
      let index = (s.getPosition() - helpStringOffset) div 512
      let str = s.readCStr(512)
      if str.len > 0:
        self.helpString.setLen(index + 1)
        self.helpString[index] = str
        echo (index, str)
    except IOError:
      discard

  s.setPosition(expectedAfterAnim)

  # remaining buffer of data1 is USUALLY just zeroes
  s.close()

proc writeInfo(s: StringStream; level: var Level) =
  s.write(level.lastHorizontalOffset)
  s.write(uint16 level.securityEnvelope shr 16)
  s.write(level.lastVerticalOffset)
  s.write(uint16 level.securityEnvelope and 0xffff)
  s.write(uint8 ((if level.securityEnabled: SecurityEnabled else: 0) shl 4) or (level.lastLayer and 0b1111))

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

  let helpStringOffset = s.getPosition()
  if level.helpString.len < 16:
    level.helpString.setLen(16)
  for i in 0..<16:
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

  # for i in 0..<(level.maxAnimTiles - level.anims.len):
  #   for j in 0..<AnimStructSize:
  #     s.write(uint8 0)

  echo "number of anims: ", level.anims.len, " of ", level.maxAnimTiles
  let expectedAfterAnim = s.getPosition() + (level.maxAnimTiles - level.anims.len) * AnimStructSize
  echo s.getPosition(), " after anims"

  # neobeo's firetruck text strings, incompatible with JJ2+ and TSF
  let extraTextStringsPos = min(s.getPosition(), s.getPosition() - ((s.getPosition() - helpStringOffset) mod 512)) + 512
  s.writeCStr("", extraTextStringsPos - s.getPosition())
  echo s.getPosition(), " extra help strings"

  let index = ((s.getPosition() - helpStringOffset) div 512)
  for i in index..<level.helpString.len:
    echo "writing string ", i
    s.writeCStr(level.helpString[i], 512)

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

  if self.layers[SpriteLayerNum].width >= 4 and self.layers[SpriteLayerNum].height >= 2:
    let bottomRightEvent = self.events[self.layers[SpriteLayerNum].height - 1][self.layers[SpriteLayerNum].width - 1].addr
    if bottomRightEvent.eventId == Event_MCE:
      self.levelBottomMode = DeathPit
      bottomRightEvent[].reset()
    elif bottomRightEvent.eventId == Event_OneWay:
      self.levelBottomMode = SolidFloor
      bottomRightEvent[].reset()
    else:
      self.levelBottomMode = Default

    let teamTrigEvent = self.events[self.layers[SpriteLayerNum].height - 1][0].addr
    let serverTrigEvent = self.events[self.layers[SpriteLayerNum].height - 1][1].addr
    let overtimeTrigEvent = self.events[self.layers[SpriteLayerNum].height - 1][2].addr
    if teamTrigEvent.eventId == Event_TriggerZone:
      let params = teamTrigEvent[].params()
      self.teamTriggerState = if params[1] == 0: BlueOff else: BlueOn
      self.teamTriggerId = params[0]
      teamTrigEvent[].reset()
    else:
      self.teamTriggerState = Disabled

    if serverTrigEvent.eventId == Event_TriggerZone:
      let params = serverTrigEvent[].params()
      self.serverTriggerEnabled = true
      self.serverTriggerId = params[0]
      serverTrigEvent[].reset()
    else:
      self.serverTriggerEnabled = false

    if overtimeTrigEvent.eventId == Event_TriggerZone:
      let params = overtimeTrigEvent[].params()
      self.overtimeTriggerEnabled = true
      self.overtimeTriggerId = params[0]
      overtimeTrigEvent[].reset()
    else:
      self.overtimeTriggerEnabled = false

proc writeEvents(self: var Level): string =
  if self.layers[SpriteLayerNum].width >= 4 and self.layers[SpriteLayerNum].height >= 2:
    let bottomRightEvent = self.events[self.layers[SpriteLayerNum].height - 1][self.layers[SpriteLayerNum].width - 1].addr
    if bottomRightEvent.eventId in [Event_None, Event_OneWay, Event_MCE]:
      case self.levelBottomMode:
      of DeathPit: bottomRightEvent[] = Event(eventId: Event_MCE)
      of SolidFloor: bottomRightEvent[] = Event(eventId: Event_OneWay)
      else: discard

    let teamTrigEvent = self.events[self.layers[SpriteLayerNum].height - 1][0].addr
    let serverTrigEvent = self.events[self.layers[SpriteLayerNum].height - 1][1].addr
    let overtimeTrigEvent = self.events[self.layers[SpriteLayerNum].height - 1][2].addr
    if self.teamTriggerState != Disabled and teamTrigEvent.eventId in [Event_None, Event_TriggerZone]:
      teamTrigEvent[] = Event(eventId: Event_TriggerZone)
      teamTrigEvent[].params = @[self.teamTriggerId, if self.teamTriggerState == BlueOff: 0 else: 1]

    if self.serverTriggerEnabled and serverTrigEvent.eventId in [Event_None, Event_TriggerZone]:
      serverTrigEvent[] = Event(eventId: Event_TriggerZone)
      serverTrigEvent[].params = @[self.serverTriggerId]

    if self.overtimeTriggerEnabled and overtimeTrigEvent.eventId in [Event_None, Event_TriggerZone]:
      overtimeTrigEvent[] = Event(eventId: Event_TriggerZone)
      overtimeTrigEvent[].params = @[self.overtimeTriggerId]

  result = newString(self.layers[SpriteLayerNum].width.int * self.layers[SpriteLayerNum].height.int * sizeof(Event))
  var eventOffset = 0
  for row in self.events:
    if row.len > 0:
      copyMem(result[eventOffset].addr, row[0].addr, row.len * sizeof(Event))
    eventOffset += self.layers[SpriteLayerNum].width.int * sizeof(Event)

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
  for i, layer in self.layers.mpairs:
    if not layer.haveAnyTiles:
      layer.tileCache.setLen(0)
      continue
    layer.tileCache.setLen(((layer.realWidth+3) div 4) * layer.height)
    for wordId in layer.tileCache.mitems:
      s.read(wordId)
  doAssert s.atEnd()
  s.close()

proc writeWordMapData(s: Stream; level: Level) =
  for layer in level.layers:
    if not layer.haveAnyTiles:
      continue
    for wordId in layer.tileCache:
      s.write(wordId)

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

  echo "reading sizes: ", streamSizes

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
  echo "version: ", self.version

  var streams: array[StreamKind, string]

  let levelInfoStream = newStringStream("")
  levelInfoStream.writeInfo(self)
  streams[LevelInfo] = levelInfoStream.data
  levelInfoStream.close()

  streams[EventData] = self.writeEvents()

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

  echo "writing sizes: ", streamSizes

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
      if event.eventId == Event_None: continue
      var paramTable = newSeq[tuple[name: string, value: int]](jcsEvents[event.eventId].params.len)
      let params = event.params()
      for j, param in jcsEvents[event.eventId].params:
        paramTable[j] = (name: param.name, value: params[j])
      if event.eventId == Event_Generator:
        let genEventId = cast[EventId](params[0])
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
  newLevel.teamTriggerState = BlueOff
  newLevel.teamTriggerId = 1
  newLevel.serverTriggerEnabled = true
  newLevel.serverTriggerId = 2
  newLevel.overtimeTriggerEnabled = true
  newLevel.overtimeTriggerId = 3
  newLevel.levelBottomMode = DeathPit
  newLevel.save("level_new.j2l")

  echo "loading created new level"
  var level = Level()
  doAssert level.load("level_new.j2l", "heya")
  level.save("level_new_saved.j2l")

  doAssert readFile("level_new.j2l") == readFile("level_new_saved.j2l")

  echo "loading official level"
  level = Level()
  if level.load("Tube2.j2l", "heya"):
    echo "saving level"
    level.rebuildTileCache()
    level.save("level_saved.j2l")
    level.debug()
