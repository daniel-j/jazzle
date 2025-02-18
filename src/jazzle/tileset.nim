import std/streams
import std/strutils
import std/bitops
import pixie
import zippy
import zippy/crc
import ./common

export common

const
  J2tSignature = 0xAFBEADDE'u32
  J2tVersion1_23 = 0x200'u16
  J2tVersion1_24 = 0x201'u16


type

  StreamKind = enum
    TilesetInfo
    ImageData
    TransData
    MaskData
  StreamSize = tuple[packedSize, unpackedSize: uint32]

  TileOffsets* = object
    opaque*: bool
    image*: int
    trans*: uint32 # internal value stored in J2T
    transOffset*: int
    mask*: int
    flipped*: int

  TileImage* = array[1024, uint8]
  TileMask* = array[1024, bool]

  Tileset* = object
    title*: string
    version*: GameVersion
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

proc readInfo(self: var Tileset, s: Stream) =
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


proc readImageData(self: var Tileset, si: Stream, sa: Stream, sm: Stream) =
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
    self.tileTransMaskJJ2[transCounter] = sa.readMaskJJ2Data()

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

proc writeImageData(s: Stream; tileset: Tileset) =
  for i in 0..<tileset.tileImage.len:
    s.write(tileset.tileImage[i])

proc writeTransMaskData(s: Stream; tileset: var Tileset) =
  ## Writes transparent mask data to stream
  ## This also updates the trans tile offsets in Tileset

  var offsets = newSeq[uint32](tileset.tileTransMask.len)
  var offset = 0'u32
  for i in 0..<tileset.tileTransMask.len:
    offsets[i] = offset
    s.writeMaskData(tileset.tileTransMask[i])
    offset += uint32 128 + s.writeMaskJJ2Data(tileset.tileTransMaskJJ2[i])

  for i in 0..<tileset.numTiles:
    tileset.tileOffsets[i].trans = offsets[tileset.tileOffsets[i].transOffset]

proc writeMaskData(s: Stream; tileset: Tileset) =
  for i in 0..<tileset.tileMask.len:
    s.writeMaskData(tileset.tileMask[i])

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

  var compressedLength: uint32 = 0
  for kind in StreamKind.items:
    tileset.streamSizes[kind].packedSize = s.readUint32()
    tileset.streamSizes[kind].unpackedSize = s.readUint32()
    compressedLength += tileset.streamSizes[kind].packedSize

  if compressedLength + 262 != tileset.fileSize:
    echo "filesize doesn't match!"
    return false

  let compressedData = newStringStream(s.readStr(compressedLength.int))
  defer: compressedData.close()

  let checksum = crc32(compressedData.data)

  if checksum != tileset.checksum:
    echo "checksums doesn't match!"
    return false

  var sections: array[StreamKind, Stream]
  for kind in StreamKind.items:
    let data = uncompress(compressedData.readStr(tileset.streamSizes[kind].packedSize.int), dfZlib)
    sections[kind] = newStringStream(data)

  doAssert compressedData.atEnd()

  # There may be extra data after last stream
  # doAssert s.atEnd()
  s.close()

  tileset.readInfo(sections[TilesetInfo])
  tileset.readImageData(sections[ImageData], sections[TransData], sections[MaskData])

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

  # needs to be after TransData, since that updates trans mask tile offsets
  let tileInfoStream = newStringStream("")
  tileInfoStream.writeInfo(tileset)
  streams[TilesetInfo] = tileInfoStream.data
  tileInfoStream.close()

  var compressedData = ""
  for kind in StreamKind.items:
    tileset.streamSizes[kind].unpackedSize = streams[kind].len.uint32
    streams[kind] = compress(streams[kind], DefaultCompression, dfZlib)
    tileset.streamSizes[kind].packedSize = streams[kind].len.uint32
    compressedData &= streams[kind]
    streams[kind] = ""

  tileset.fileSize = compressedData.len.uint32 + 262
  tileset.checksum = crc32(compressedData)

  s.write(tileset.fileSize)
  s.write(tileset.checksum)

  for kind in StreamKind.items:
    s.write(tileset.streamSizes[kind].packedSize)
    s.write(tileset.streamSizes[kind].unpackedSize)

  s.write(compressedData)

proc save*(tileset: var Tileset; filename: string) =
  let s = newFileStream(filename, fmWrite)
  defer: s.close()
  tileset.save(s)

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
    tileset.save("tileset_saved.j2t")
