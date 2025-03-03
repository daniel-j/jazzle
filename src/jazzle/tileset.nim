import std/streams
import std/strutils
import std/bitops
import zippy
import zippy/crc
import ./common

export common

const
  J2tSignature = 0xAFBEADDE'u32
  J2tVersion1_23 = 0x200'u16
  J2tVersion1_24 = 0x201'u16

  HeaderStructSize = 262

type

  StreamKind = enum
    TilesetInfo
    ImageData
    TransData
    MaskData
  StreamSize = tuple[packedSize, unpackedSize: uint32]

  TileOffsets = object
    opaque: bool
    image: int
    trans: uint32 # internal value stored in J2T
    transOffset: int
    mask: int
    flipped: int

  TileImage* = array[32*32, uint8]
  TileMask* = array[32*32, bool]

  TilePixel* = object
    color*: uint8 # palette index
    transMask*: bool # used by JCS, true when opaque
    transMaskJJ2*: bool # used by JJ2, true when opaque
    mask*: bool # true when masked/collision

  TilesetTile* = array[32*32, TilePixel]

  Tileset* = object
    title*: string
    version*: GameVersion
    fileSize*: uint32
    checksum*: uint32
    palette*: array[256, array[4, uint8]]
    tiles*: seq[TilesetTile]

    numTiles: uint32
    tileOffsets: seq[TileOffsets] # contains tile offsets
    tileImage: seq[TileImage]
    tileTransMask: seq[TileMask]
    tileTransMaskJJ2: seq[TileMask] # used by JJ2
    tileMask: seq[TileMask]


proc maxTiles*(self: Tileset): uint32 =
  if self.version == v1_23:
    1024'u32
  else:
    4096'u32

const TilesetEmptyTile = static:
  var t: TilesetTile
  t
const NoTileset* = Tileset(
  title: "Untitled",
  version: v1_24,
  tiles: @[TilesetEmptyTile]
)

proc flipMask*(tileMask: TileMask): TileMask =
  for y in 0..<32:
    for x in 0..<32:
      let srcPos = y * 32 + x
      let dstPos = y * 32 + (31 - x)
      result[dstPos] = tileMask[srcPos]

proc readMaskData(s: Stream): TileMask =
  var mask: array[128, uint8]
  s.read(mask)
  for j in 0..<128:
    for k in 0..<8:
      let pos = j * 8 + k
      result[pos] = mask[j].testBit(k)

proc writeMaskData(s: Stream; tileMask: TileMask) =
  var mask: array[128, uint8]
  for i in 0..<tileMask.len:
    let j = i div 8
    let k = i mod 8
    if tileMask[i]:
      mask[j].setBit(k)
  s.write(mask)

proc readMaskJJ2Data(s: Stream): TileMask =
  # For every tile row, read 1 byte to get number of "columns" on that row.
  # For each "column" read 1 byte skip and 1 byte width.
  # Going left to right, the skip is blank pixels and width
  # is number of pixels masked. This is a run-length encoding.
  # When processing of a column array is done, go to next row.

  for row in 0 ..< 32:
    var pos = row * 32
    let columns = s.readUint8().int
    for i in 0 ..< columns:
      let skip = s.readUint8().int
      let width = s.readUint8().int
      pos += skip
      for j in 0 ..< width:
        result[pos + j] = true
      pos += width

proc writeMaskJJ2Data(s: Stream; tileMaskJJ2: TileMask): int =
  # see comment in readMaskJJ2Data proc for format description
  # returns size of data written

  for row in 0 ..< 32:
    var columns = 0'u8
    var columnData: seq[uint8]
    var skip = 0'u8
    var width = 0'u8
    var lastMasked = false
    for i in 0 ..< 32:
      let pos = row * 32 + i
      let masked = tileMaskJJ2[pos]
      if masked:
        inc(width)
      else:
        if lastMasked != masked:
          columnData.add(skip)
          columnData.add(width)
          inc(columns)
          width = 0
          skip = 0
        inc(skip)
      lastMasked = masked
    if width > 0:
      columnData.add(skip)
      columnData.add(width)
      inc(columns)

    s.write(columns)
    if columnData.len > 0:
      s.writeData(columnData[0].addr, columnData.len)

    result += 1 + columnData.len

proc readInfo(self: var Tileset, s: StringStream) =
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

  for i in 0..<self.maxTiles:
    self.tileOffsets[i].mask = int s.readUint32() div 128

  for i in 0..<self.maxTiles:
    self.tileOffsets[i].flipped = int s.readUint32() div 128

  doAssert s.atEnd()
  s.close()

proc writeInfo(s: Stream; tileset: Tileset) =
  # data1
  s.write(tileset.palette)
  s.write(tileset.numTiles)

  let maxTiles = tileset.maxTiles
  for i in 0 ..< maxTiles * 2:
    if i < tileset.numTiles:
      s.write(tileset.tileOffsets[i].opaque)
    else:
      s.write(false)

  for i in 0 ..< maxTiles * 2:
    if i < tileset.numTiles:
      s.write(uint32 tileset.tileOffsets[i].image * 1024)
    else:
      s.write(0'u32)

  for i in 0 ..< maxTiles * 2:
    if i < tileset.numTiles:
      s.write(uint32 tileset.tileOffsets[i].trans)
    else:
      s.write(0'u32)

  for i in 0 ..< maxTiles:
    s.write(uint32 tileset.tileOffsets[i].mask * 128)

  for i in 0 ..< maxTiles:
    s.write(uint32 tileset.tileOffsets[i].flipped * 128)

proc readImageData(self: var Tileset, s: StringStream) =
  # data2 image data
  self.tileImage.setLen(s.data.len div 1024)

  for i in 0..<self.tileImage.len:
    s.read(self.tileImage[i])

  doAssert s.atEnd()
  s.close()

  # var im = newImage(self.tileImage.len * 32, 32)
  # for i in 0..<self.tileImage.len:
  #   for j in 0..<1024:
  #     let color = self.tileImage[i][j]
  #     im[i * 32 + j mod 32, j div 32] = ColorRGBA(
  #       r: self.palette[color][0],
  #       g: self.palette[color][1],
  #       b: self.palette[color][2],
  #       a: if color > 0: 255 else: 0
  #     )
  # im.writeFile("tileset_data2.png")

proc writeImageData(s: Stream; tileset: Tileset) =
  for i in 0..<tileset.tileImage.len:
    s.write(tileset.tileImage[i])

proc readTransMask(self: var Tileset; s: StringStream) =
  # data3 transparency mask
  var transCounter = 0
  var transMaskOffset = newSeq[uint32](self.maxTiles)
  self.tileTransMask.setLen(0)
  self.tileTransMaskJJ2.setLen(0)

  while not s.atEnd():
    transMaskOffset[transCounter] = s.getPosition().uint32
    # first 128 bytes contain regular transparency mask
    self.tileTransMask.add(s.readMaskData())
    # but jj2 uses a special format that follows it
    self.tileTransMaskJJ2.setLen(transCounter + 1)
    self.tileTransMaskJJ2[transCounter] = s.readMaskJJ2Data()

    # check that they are equal
    # doAssert self.tileTransMask[transCounter] == self.tileTransMaskJJ2[transCounter]
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

  doAssert s.atEnd()
  s.close()

  # var im = newImage(self.tileTransMask.len * 32, 32 * 2)
  # for i in 0..<self.tileTransMask.len:
  #   for j in 0..<1024:
  #     let color = if self.tileTransMask[i][j]: 100'u8 else: 255'u8
  #     im[i * 32 + j mod 32, 0 * 32 + (j div 32)] = ColorRGB(
  #       r: color,
  #       g: color,
  #       b: color
  #     )
  #     let color2 = if self.tileTransMaskJJ2[i][j]: 100'u8 else: 255'u8
  #     im[i * 32 + j mod 32, 1 * 32 + (j div 32)] = ColorRGB(
  #       r: color2,
  #       g: color2,
  #       b: color2
  #     )
  # im.writeFile("tileset_data3.png")

proc writeTransMaskData(s: Stream; tileset: var Tileset) =
  ## Writes transparent mask data to stream
  ## This also updates the trans tile offsets

  var offsets = newSeq[uint32](tileset.tileTransMask.len)
  var offset = 0'u32
  for i in 0..<tileset.tileTransMask.len:
    offsets[i] = offset
    s.writeMaskData(tileset.tileTransMask[i])
    offset += uint32 128 + s.writeMaskJJ2Data(tileset.tileTransMaskJJ2[i])

  for i in 0..<tileset.numTiles:
    tileset.tileOffsets[i].trans = offsets[tileset.tileOffsets[i].transOffset]

proc readMaskData(self: var Tileset; s: StringStream) =
  # data4 collision mask
  self.tileMask.setLen(s.data.len div 128)

  for i in 0..<self.tileMask.len:
    self.tileMask[i] = s.readMaskData()

  doAssert s.atEnd()
  s.close()

  # var im = newImage(self.tileMask.len * 32, 32)
  # for i in 0..<self.tileMask.len:
  #   for j in 0..<1024:
  #     let color = if self.tileMask[i][j]: 50'u8 else: 255'u8
  #     im[i * 32 + (j mod 32), j div 32] = ColorRGB(
  #       r: color,
  #       g: color,
  #       b: color
  #     )
  # im.writeFile("tileset_data4.png")

proc writeMaskData(s: Stream; tileset: Tileset) =
  for i in 0..<tileset.tileMask.len:
    s.writeMaskData(tileset.tileMask[i])

proc cleanup*(self: var Tileset) =
  self.tileOffsets.reset()
  self.tileImage.reset()
  self.tileTransMask.reset()
  self.tileTransMaskJJ2.reset()
  self.tileMask.reset()

proc updateToTiles(self: var Tileset) =
  # uses tileOffsets, tileImage, tileMask... to write self.tiles
  self.tiles = newSeq[TilesetTile](self.numTiles)
  for i, tile in self.tiles.mpairs:
    if i == 0: continue # first tile is always empty
    let offsets = self.tileOffsets[i]
    let tileImage = self.tileImage[offsets.image]
    let transMask = self.tileTransMask[offsets.transOffset]
    let transMaskJJ2 = self.tileTransMaskJJ2[offsets.transOffset]
    let tileMask = self.tileMask[offsets.mask]
    # let tileMaskFlipped = self.tileMask[offsets.flipped]
    for j in 0..<32*32:
      tile[j].color = tileImage[j]
      tile[j].transMask = transMask[j]
      tile[j].transMaskJJ2 = transMaskJJ2[j]
      tile[j].mask = tileMask[j]

proc updateFromTiles(self: var Tileset) =
  # uses self.tiles to write tileOffsets, tileImage, tileMask...
  self.numTiles = max(1, self.tiles.len).uint32
  self.tileOffsets = newSeq[TileOffsets](self.maxTiles)
  self.tileImage = newSeq[TileImage](1)
  self.tileMask = newSeq[TileMask](1)
  self.tileTransMask = newSeq[TileMask](1)
  self.tileTransMaskJJ2 = newSeq[TileMask](1)
  for i, tile in self.tiles:
    if i == 0: continue
    let offsets = self.tileOffsets[i].addr
    var tileImage: TileImage
    var transMask: TileMask
    var transMaskJJ2: TileMask
    var tileMask: TileMask

    offsets.opaque = true

    for j, pixel in tile:
      tileImage[j] = pixel.color
      transMask[j] = pixel.transMask
      transMaskJJ2[j] = pixel.transMaskJJ2
      tileMask[j] = pixel.mask

      # TODO: check if this should use transMask or transMaskJJ2
      if not pixel.transMask:
        offsets.opaque = false

    var flippedMask = flipMask(tileMask)

    offsets.image = self.tileImage.find(tileImage)
    if offsets.image == -1:
      offsets.image = self.tileImage.len
      self.tileImage.add(tileImage)

    offsets.transOffset = self.tileTransMask.find(transMask)
    if offsets.transOffset == -1:
      offsets.transOffset = self.tileTransMask.len
      self.tileTransMask.add(transMask)
      self.tileTransMaskJJ2.add(transMaskJJ2)

    offsets.mask = self.tileMask.find(tileMask)
    if offsets.mask == -1:
      offsets.mask = self.tileMask.len
      self.tileMask.add(tileMask)

    offsets.flipped = self.tileMask.find(flippedMask)
    if offsets.flipped == -1:
      offsets.flipped = self.tileMask.len
      self.tileMask.add(flippedMask)

proc load*(tileset: var Tileset; s: Stream): bool =
  tileset.reset()

  let copyright = s.readStr(180)
  discard copyright
  let magic = s.readStr(4)
  doAssert magic == "TILE"
  let signature = s.readUint32()
  doAssert signature == J2tSignature
  tileset.title = s.readStr(32).strip(leading=false, chars={'\0'})
  let versionNum = s.readUint16()
  tileset.version = if versionNum <= J2tVersion1_23: v1_23 else: v1_24
  tileset.fileSize = s.readUint32()
  tileset.checksum = s.readUint32()

  var streamSizes: array[StreamKind, StreamSize]
  var compressedLength: uint32 = 0
  for kind in StreamKind.items:
    streamSizes[kind].packedSize = s.readUint32()
    streamSizes[kind].unpackedSize = s.readUint32()
    compressedLength += streamSizes[kind].packedSize

  echo streamSizes

  doAssert s.getPosition() == HeaderStructSize

  if compressedLength + HeaderStructSize != tileset.fileSize:
    echo "filesize doesn't match!"
    return false

  let compressedData = newStringStream(s.readStr(compressedLength.int))
  defer: compressedData.close()

  let checksum = crc32(compressedData.data)

  if checksum != tileset.checksum:
    echo "checksums doesn't match!"
    return false

  var sections: array[StreamKind, StringStream]
  for kind in StreamKind.items:
    let data = uncompress(compressedData.readStr(streamSizes[kind].packedSize.int), dfZlib)
    sections[kind] = newStringStream(data)

  doAssert compressedData.atEnd()

  # There may be extra data after last stream
  # doAssert s.atEnd()
  s.close()

  tileset.readInfo(sections[TilesetInfo])
  tileset.readImageData(sections[ImageData])
  tileset.readTransMask(sections[TransData])
  tileset.readMaskData(sections[MaskData])

  tileset.updateToTiles()

  return true

proc load*(tileset: var Tileset; filename: string): bool =
  tileset.reset()
  let s = newFileStream(filename)
  defer: s.close()
  return tileset.load(s)

proc save*(tileset: var Tileset; s: Stream) =
  s.write(DataFileCopyright)
  s.write("TILE")
  s.write(J2tSignature)
  s.writeCStr(tileset.title, 32)
  s.write(if tileset.version == v1_23: J2tVersion1_23 else: J2tVersion1_24)

  tileset.updateFromTiles()

  var streams: array[StreamKind, string]

  let imageDataStream = newStringStream("")
  imageDataStream.writeImageData(tileset)
  streams[ImageData] = imageDataStream.data
  imageDataStream.close()

  let transDataStream = newStringStream("")
  transDataStream.writeTransMaskData(tileset)
  streams[TransData] = transDataStream.data
  transDataStream.close()

  let maskDataStream = newStringStream("")
  maskDataStream.writeMaskData(tileset)
  streams[MaskData] = maskDataStream.data
  maskDataStream.close()

  # needs to be after the other streams, since they update the tile offsets
  let tileInfoStream = newStringStream("")
  tileInfoStream.writeInfo(tileset)
  streams[TilesetInfo] = tileInfoStream.data
  tileInfoStream.close()

  var streamSizes: array[StreamKind, StreamSize]
  var compressedData = ""
  for kind in StreamKind.items:
    streamSizes[kind].unpackedSize = streams[kind].len.uint32
    streams[kind] = compress(streams[kind], DefaultCompression, dfZlib)
    streamSizes[kind].packedSize = streams[kind].len.uint32
    compressedData &= streams[kind]
    streams[kind] = ""

  echo streamSizes

  tileset.fileSize = compressedData.len.uint32 + HeaderStructSize
  tileset.checksum = crc32(compressedData)

  s.write(tileset.fileSize)
  s.write(tileset.checksum)

  for kind in StreamKind.items:
    s.write(streamSizes[kind].packedSize)
    s.write(streamSizes[kind].unpackedSize)

  s.write(compressedData)

proc save*(tileset: var Tileset; filename: string) =
  let s = newFileStream(filename, fmWrite)
  defer: s.close()
  tileset.save(s)

when not defined(emscripten):
  import pixie

  proc debug*(self: Tileset) =
    echo "drawing tileset buffers"

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

    echo "saving"
    im.writeFile("tileset.png")

  proc test*(filename: string) =
    var tileset = Tileset()
    if tileset.load(filename):
      tileset.debug()
      tileset.cleanup()
      tileset.save("tileset_saved.j2t")
      if tileset.load("tileset_saved.j2t"):
        tileset.cleanup()
        tileset.save("tileset_saved_twice.j2t")
