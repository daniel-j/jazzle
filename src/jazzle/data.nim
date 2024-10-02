import std/streams
import std/strutils
import std/sequtils
import std/tables
import pixie
import zippy
import zippy/crc

export tables

const DataSignature = 0xBEBAADDE'u32

type
  StreamInfo* = object
    name*: string
    offset*: uint32
    checksum*: uint32
    packedSize*, unpackedSize: uint32
    data*: string

  Data* = object
    version*: uint32
    fileSize*: uint32
    checksum*: uint32
    streams*: OrderedTable[string, StreamInfo]

proc readCStr(s: Stream, length: int): string =
  result = s.readStr(length)
  let pos = result.find('\0')
  if pos != -1: result.setLen(pos)

proc loadInfo(self: var Data; s: Stream) =
  self.streams.clear()
  while not s.atEnd():
    var info = StreamInfo()
    info.name = s.readCStr(36) # why not 32? not sure
    s.read(info.offset)
    s.read(info.checksum)
    s.read(info.packedSize)
    s.read(info.unpackedSize)
    self.streams[info.name] = info

  doAssert s.atEnd()
  s.close()

proc load*(self: var Data; filename: string): bool =
  self.reset()
  let s = newFileStream(filename)
  defer: s.close()

  doAssert s.readStr(4) == "PLIB"
  doAssert s.readUint32() == DataSignature
  s.read(self.version)

  s.read(self.fileSize)
  s.read(self.checksum)

  let infoPackedSize = s.readUint32()
  let infoUnpackedSize = s.readUint32()

  let pos = s.getPosition()
  let checksumCheck = crc32(s.readAll())
  doAssert self.fileSize == s.getPosition().uint32
  s.setPosition(pos)

  doAssert self.checksum == checksumCheck

  let data = uncompress(s.readStr(infoPackedSize.int), dfZlib)
  doAssert infoUnpackedSize == data.len.uint32

  self.loadInfo(newStringStream(data)) # needed to get the other offsets

  for name, info in self.streams.mpairs:
    info.data = uncompress(s.readStr(info.packedSize.int), dfZlib)
    doAssert info.unpackedSize == info.data.len.uint32
    doAssert info.checksum == crc32(info.data) # remove this line when parsing Plus.j2d

  doAssert s.atEnd()
  s.close()

  return true

# RGB888 to RGB555
proc get15BitColor(r, g, b: uint8): uint16 =
  return ((r.uint16 shl 7) and 0b0111110000000000) or ((g.uint16 shl 2) and 0b0000001111100000) or (b.uint16 shr 3)

proc debug*(self: Data) =

  echo "Data streams: ", self.streams.keys.toSeq()

  let menuPalette = self.streams["Menu.Palette"].data

  # TODO: Tiles.*, Balls.Dump, Order.ShadeLUT and Order.Colors streams are unknown
  for info in self.streams.values:
    echo "exporting ", info.name, " ", info.data.len
    case info.name:
    of "Menu.Palette", "Credits.Palette", "Order.Palette", "ogLogo.Palette", "Std.Palette":
      let size = 16
      var im = newImage(size, size)
      for i in 1..<256:
        let x = i mod size
        let y = i div size
        im[x, y] = ColorRGB(
          r: info.data[i * 4 + 0].uint8,
          g: info.data[i * 4 + 1].uint8,
          b: info.data[i * 4 + 2].uint8
        )
      im.writeFile("data." & info.name & ".png")
    of "Shield.Plasma":
      let size = 128
      var im = newImage(size, size)
      for i, value in info.data.pairs:
        let x = i mod size
        let y = i div size
        im[x, y] = ColorRGB(
          r: value.uint8,
          g: value.uint8,
          b: value.uint8
        )
      im.writeFile("data." & info.name & ".png")
    of "Menu.Texture.128x128", "Menu.Texture.32x32", "Menu.Texture.16x16":
      let size = if info.name == "Menu.Texture.128x128": 128 elif info.name == "Menu.Texture.32x32": 32 else: 16
      var im = newImage(size, size)
      for i, index in info.data.pairs:
        if index.uint8 == 0: continue
        let x = i mod size
        let y = i div size
        im[x, y] = ColorRGB(
          r: menuPalette[index.int * 4 + 0].uint8,
          g: menuPalette[index.int * 4 + 1].uint8,
          b: menuPalette[index.int * 4 + 2].uint8
        )
      im.writeFile("data." & info.name & ".png")
    of "Picture.Continue", "Picture.Credits", "Picture.CreditsEaster", "Picture.EasterTit",
       "Picture.Loading", "Picture.OrderTexture128x128", "Picture.Thanks", "Picture.Title",
       "Picture.Title-XMas", "Order.Newspaper":
      let s = newStringStream(info.data)
      defer: s.close()
      let paletteOffset = if info.name == "Order.Newspaper": -208 else: 0
      let transparent = info.name == "Order.Newspaper"
      let width = s.readUint32().int
      let height = s.readUint32().int
      let depth = s.readUint32().int
      let palette = s.readStr(1024)
      doAssert depth == 8
      var im = newImage(width, height)
      for y in 0..<height:
        for x in 0..<width:
          let index = max(0, s.readUint8().int + paletteOffset)
          if index == 0 and transparent: continue
          im[x, y] = ColorRGB(
            r: palette[index.int * 4 + 0].uint8,
            g: palette[index.int * 4 + 1].uint8,
            b: palette[index.int * 4 + 2].uint8
          )
      im.writeFile("data." & info.name & ".png")
    of "Menu.ColorLUT", "ogLogo.ColorLUT":
      let width = 256
      let height = 512
      let palette = if info.name == "Menu.ColorLUT": menuPalette else: self.streams["ogLogo.Palette"].data
      var im = newImage(width, height)
      for i in 0..<width*height:
        let x = i mod width
        let y = i div width
        let index = info.data[get15BitColor(x.uint8, clamp(y, 0, 255).uint8, clamp(y - 256, 0, 255).uint8)].int
        im[x, y] = ColorRGB(
          r: palette[index * 4].uint8,
          g: palette[index * 4 + 1].uint8,
          b: palette[index * 4 + 2].uint8
        )
      im.writeFile("data." & info.name & ".png")
    of "Order.ShadeLUT":
      let width = 16
      let height = 256
      var im = newImage(width, height)
      for i in 0..<width*height:
        let x = i mod width
        let y = i div width
        let value = info.data[i].int
        im[x, y] = ColorRGB(
          r: value.uint8,
          g: value.uint8,
          b: value.uint8
        )
      im.writeFile("data." & info.name & ".png")
    of "SoundFXList.Ending", "SoundFXList.Intro", "SoundFXList.Logo", "SoundFXList.P2":
      let s = newStringStream(info.data)
      defer: s.close()
      var output = ""
      while not s.atEnd():
        output &= $s.readUint32() & "\n"
      writeFile("data." & info.name & ".txt", output)
    of "TextureBG.1", "TextureBG.2", "TextureBG.3", "TextureBG.4", "TextureBG.5",
       "TextureBG.6", "TextureBG.7", "TextureBG.8", "TextureBG.9", "TextureBG.10",
       "TextureBG.11", "TextureBG.12", "TextureBG.13", "TextureBG.14", "TextureBG.15":
      let size = 256
      var im = newImage(size, size)
      for i, value in info.data.pairs:
        let x = i mod size
        let y = i div size
        im[x, y] = ColorRGB(
          r: value.uint8,
          g: value.uint8,
          b: value.uint8
        )
      im.writeFile("data." & info.name & ".png")
    of "ogLogo.Balls":
      let s = newStringStream(info.data)
      defer: s.close()
      var i = 0
      var output = ""
      while not s.atEnd():
        let unknown1 = s.readUint32()
        let unknown2 = s.readStr(32) # all zeroes
        let unknown3 = s.readInt16()
        let unknown4 = s.readInt16()
        output &= $unknown1 & " " & $unknown3 & " " & $unknown4 & "\n"
        inc(i)
      writeFile("data." & info.name & ".txt", output)
    else:
      writeFile("data." & info.name & ".bin", info.data)

proc test*(filename: string) =
  var data = Data()
  if data.load(filename):
    data.debug()
