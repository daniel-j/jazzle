import std/streams
import std/strutils
import pixie
import zippy
import ./data

type

  StreamKind = enum
    EpisodeData1
    EpisodeData2
    EpisodeData3

  StreamSize = tuple[packedSize, unpackedSize: uint32]

  Episode* = object
    position*: uint32
    isRegistered*: uint32
    title*: string
    level*: string
    width*: uint32
    height*: uint32
    widthTitle*: uint32
    heightTitle*: uint32
    imageData*: array[StreamKind, string]

proc readCStr(s: Stream, length: int): string =
  result = s.readStr(length)
  let pos = result.find('\0')
  if pos != -1: result.setLen(pos)


proc load*(self: var Episode; filename: string; password: string = ""): bool =
  self.reset()
  let s = newFileStream(filename)
  defer: s.close()

  let sizeHeader = s.readUint32()
  s.read(self.position)
  s.read(self.isRegistered)
  discard s.readUint32() # unknown
  self.title = s.readCStr(128)
  self.level = s.readCStr(32)
  s.read(self.width)
  s.read(self.height)
  discard s.readUint32() # unknown
  discard s.readUint32() # unknown
  s.read(self.widthTitle)
  s.read(self.heightTitle)
  discard s.readUint32() # unknown
  discard s.readUint32() # unknown

  doAssert sizeHeader + 4 == s.getPosition().uint32

  echo self

  var streamSizes: array[StreamKind, StreamSize]

  streamSizes[EpisodeData1].unpackedSize = self.width * self.height
  streamSizes[EpisodeData2].unpackedSize = self.widthTitle * self.heightTitle
  streamSizes[EpisodeData3].unpackedSize = self.widthTitle * self.heightTitle

  for kind in StreamKind.items:
    streamSizes[kind].packedSize = s.readUint32()
    self.imageData[kind] = uncompress(s.readStr(streamSizes[kind].packedSize.int), dfZlib)
    doAssert streamSizes[kind].unpackedSize == self.imageData[kind].len.uint32

  doAssert s.atEnd()
  s.close()

  return true


proc debug*(self: Episode; palette: string) =
  var im1 = newImage(self.width.int, self.height.int)
  for y in 0..<self.height.int:
    for x in 0..<self.width.int:
      let index = self.imageData[EpisodeData1][y * self.width.int + x].uint8
      im1[x, y] = ColorRGB(
        r: palette[index.int * 4 + 0].uint8,
        g: palette[index.int * 4 + 1].uint8,
        b: palette[index.int * 4 + 2].uint8
      )

  im1.writeFile("episode1.png")

  var im2 = newImage(self.widthTitle.int, self.heightTitle.int)
  var im3 = newImage(self.widthTitle.int, self.heightTitle.int)
  for y in 0..<self.heightTitle.int:
    for x in 0..<self.widthTitle.int:
      let index2 = self.imageData[EpisodeData2][y * self.widthTitle.int + x].uint8
      if index2 > 0:
        im2[x, y] = ColorRGB(
          r: palette[index2.int * 4 + 0].uint8,
          g: palette[index2.int * 4 + 1].uint8,
          b: palette[index2.int * 4 + 2].uint8
        )
      let index3 = self.imageData[EpisodeData3][y * self.widthTitle.int + x].uint8
      if index3 > 0:
        im3[x, y] = ColorRGB(
          r: palette[index3.int * 4 + 0].uint8,
          g: palette[index3.int * 4 + 1].uint8,
          b: palette[index3.int * 4 + 2].uint8
        )

  im2.writeFile("episode2.png")
  im3.writeFile("episode3.png")

proc test*(filename: string) =

  var data = Data()
  if data.load("Data.j2d"):
    var episode = Episode()
    if episode.load(filename):
      episode.debug(data.streams["Menu.Palette"].data)
