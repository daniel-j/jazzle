import std/streams
import std/strutils
import std/bitops
import pixie
import zippy

type

  TilesetVersion* {.size: sizeof(uint16).} = enum
    v1_23 = 0x200
    v1_24 = 0x201

  StreamKind = enum
    TilesetInfo
    ImageData
    AlphaData
    MaskData
  StreamSize = tuple[packedSize, unpackedSize: uint32]

  TileOffsets* = object
    opaque*: bool
    image*: int
    trans*: uint32
    transOffset*: int
    mask*: int
    flipped*: int

  TileImage* = array[1024, uint8]
  TileMask* = array[1024, bool]

  Tileset* = object
    title*: string
    version*: TilesetVersion
    fileSize*: uint32
    checksum*: uint32
    streamSizes*: array[StreamKind, StreamSize]
    palette*: array[256, array[4, uint8]]
    numTiles*: uint32
    tileOffsets*: seq[TileOffsets] # contains tile offsets
    tileImage*: seq[TileImage]
    tileTransMask*: seq[TileMask]
    tileTransMaskJJ2*: seq[TileMask] # used by JJ2
    tileMask*: seq[TileMask]

proc maxTiles*(self: Tileset): uint32 =
  if self.version == v1_23:
    1024'u32
  else:
    4096'u32

proc readMaskData(s: Stream): TileMask =
  var mask: array[128, uint8]
  s.read(mask)
  for j in 0..<128:
    for k in 0..<8:
      let pos = j * 8 + k
      result[pos] = mask[j].testBit(k)

proc loadInfo(self: var Tileset, s: Stream) =
  # data1
  s.read(self.palette)
  self.numTiles = s.readUint32()
  let unusedNum = self.maxTiles - self.numTiles

  self.tileOffsets = newSeq[TileOffsets](self.maxTiles)

  for i in 0..<self.numTiles:
    self.tileOffsets[i].opaque = s.readBool()
  s.setPosition(s.getPosition() + (unusedNum + self.maxTiles).int)

  for i in 0..<self.numTiles:
    self.tileOffsets[i].image = int s.readUint32() div 1024
  s.setPosition(s.getPosition() + (unusedNum + self.maxTiles).int * 4)

  for i in 0..<self.numTiles:
    self.tileOffsets[i].trans = s.readUint32()
  s.setPosition(s.getPosition() + (unusedNum + self.maxTiles).int * 4)

  for i in 0..<self.numTiles:
    self.tileOffsets[i].mask = int s.readUint32() div 128

  for i in 0..<self.maxTiles:
    self.tileOffsets[i].flipped = int s.readUint32() div 128
  s.setPosition(s.getPosition() + (self.maxTiles).int * 4)

  doAssert s.atEnd()
  s.close()

proc loadImageData(self: var Tileset, si: Stream, sa: Stream, sm: Stream) =
  let imageDataLength = self.streamSizes[ImageData].unpackedSize
  let maskDataLength = self.streamSizes[MaskData].unpackedSize
  self.tileImage.setLen(imageDataLength div 1024)
  self.tileMask.setLen(maskDataLength div 128)

  # data3 extraction
  var transCounter = 0
  var transMaskOffset = newSeq[uint32](self.maxTiles)
  self.tileTransMask.setLen(0)
  while not sa.atEnd():
    transMaskOffset[transCounter] = sa.getPosition().uint32
    # first 128 bytes contain regular transparency mask
    self.tileTransMask.add(sa.readMaskData())
    # but jj2 uses a special format that follows it
    self.tileTransMaskJJ2.setLen(transCounter + 1)
    for row in 0 ..< 32:
      var pos = row * 32
      let runlength1 = sa.readUint8().int
      for i in 0 ..< runlength1:
        pos += sa.readUint8().int
        let runlength2 = pos + sa.readUint8().int
        while pos < runlength2:
          self.tileTransMaskJJ2[transCounter][pos] = true
          inc(pos)
    # check that they are equal
    doAssert self.tileTransMask[transCounter] == self.tileTransMaskJJ2[transCounter]
    inc(transCounter)

  transMaskOffset.setLen(transCounter)
  self.tileTransMask.setLen(transCounter)
  self.tileTransMaskJJ2.setLen(transCounter)

  # use array offsets instead of buffer addresses
  for i in 0..<self.tileOffsets.len:
    for j in 0..<transMaskOffset.len:
      if self.tileOffsets[i].trans == transMaskOffset[j]:
        self.tileOffsets[i].transOffset = j
        break

  var im = newImage(max(self.tileImage.len, max(self.tileTransMask.len, self.tileMask.len)) * 32, 32 * 4)

  # data2
  for i in 0..<self.tileImage.len:
    si.read(self.tileImage[i])
    for j in 0..<1024:
      let color = self.tileImage[i][j]
      im[i * 32 + j mod 32, j div 32] = ColorRGBA(
        r: self.palette[color][0],
        g: self.palette[color][1],
        b: self.palette[color][2],
        a: if color > 0: 255 else: 0
      )

  doAssert si.atEnd()
  si.close()

  # data3
  for i in 0..<self.tileTransMask.len:
    for j in 0..<1024:
      let color = if self.tileTransMask[i][j]: 100'u8 else: 255'u8
      im[i * 32 + j mod 32, 1 * 32 + (j div 32)] = ColorRGB(
        r: color,
        g: color,
        b: color
      )
      let color2 = if self.tileTransMaskJJ2[i][j]: 100'u8 else: 255'u8
      im[i * 32 + j mod 32, 2 * 32 + (j div 32)] = ColorRGB(
        r: color2,
        g: color2,
        b: color2
      )

  doAssert sa.atEnd()
  sa.close()

  # data4
  for i in 0..<self.tileMask.len:
    self.tileMask[i] = sm.readMaskData()
    for j in 0..<1024:
      let color = if self.tileMask[i][j]: 50'u8 else: 255'u8
      im[i * 32 + j mod 32, 3 * 32 + (j div 32)] = ColorRGB(
        r: color,
        g: color,
        b: color
      )

  doAssert sm.atEnd()
  sm.close()

  # DEBUG
  im.writeFile("uniquetiles.png")


proc debug(self: Tileset, filename: string = "tileset.png") =
  var im = newImage(320 * 6, ((self.maxTiles.int + 9) div 10) * 32)

  for i in 1..<self.maxTiles.int:
    for j in 0..<1024:
      let x = (i mod 10) * 32 + (j mod 32)
      let y = (i div 10) * 32 + (j div 32)

      if i < self.numTiles.int:
        let opaque = if self.tileOffsets[i].opaque: 150'u8 else: 255'u8
        im[x + 0 * 320, y] = ColorRGB(
          r: opaque,
          g: opaque,
          b: opaque
        )

        var tileId = self.tileOffsets[i].image
        let color = self.tileImage[tileId][j]
        if tileId > 0:
          im[x + 1 * 320, y] = ColorRGBA(
            r: self.palette[color][0],
            g: self.palette[color][1],
            b: self.palette[color][2],
            a: if color > 0: 255 else: 0
          )

        tileId = self.tileOffsets[i].transOffset
        if tileId > 0:
          let trans1 = if self.tileTransMask[tileId][j]: 100'u8 else: 255'u8
          im[x + 2 * 320, y] = ColorRGB(
            r: trans1,
            g: trans1,
            b: trans1
          )
          let trans2 = if self.tileTransMaskJJ2[tileId][j]: 100'u8 else: 255'u8
          im[x + 3 * 320, y] = ColorRGB(
            r: trans2,
            g: trans2,
            b: trans2
          )

        tileId = self.tileOffsets[i].mask
        if tileId > 0:
          let mask = if self.tileMask[tileId][j]: 50'u8 else: 255'u8
          im[x + 4 * 320, y] = ColorRGB(
            r: mask,
            g: mask,
            b: mask
          )

      var tileId = self.tileOffsets[i].flipped
      if tileId > 0:
        let flipped = if self.tileMask[tileId][j]: 50'u8 else: 255'u8
        im[x + 5 * 320, y] = ColorRGB(
          r: flipped,
          g: flipped,
          b: flipped
        )

  im.writeFile(filename)

proc test(filename: string) =
  var tileset = Tileset()
  let s = newFileStream(filename)
  defer: s.close()

  let copyright = s.readStr(180)
  discard copyright
  let magic = s.readStr(4)
  doAssert magic == "TILE"
  let signature = s.readUint32()
  doAssert signature == 0xAFBEADDE'u32
  tileset.title = s.readStr(32).strip(leading=false)
  let versionNum = s.readUint16()
  tileset.version = if versionNum <= 0x200: v1_23 else: v1_24
  tileset.fileSize = s.readUint32()
  tileset.checksum = s.readUint32()

  for kind in StreamKind.items:
    tileset.streamSizes[kind].packedSize = s.readUint32()
    tileset.streamSizes[kind].unpackedSize = s.readUint32()

  var sections: array[StreamKind, Stream]
  for kind in StreamKind.items:
    sections[kind] = newStringStream(uncompress(s.readStr(tileset.streamSizes[kind].packedSize.int), dfZlib))

  doAssert s.atEnd()
  s.close()

  tileset.loadInfo(sections[TilesetInfo])
  tileset.loadImageData(sections[ImageData], sections[AlphaData], sections[MaskData])

  tileset.debug("tileset.png")

test("TubeNite.j2t")
