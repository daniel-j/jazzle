import std/streams
import std/strutils
import pixie
import zippy

type

  StreamInfo = object
    packedSize, unpackedSize: uint32
    name: string
    offset: uint32
    unknown: string

  Data* = object
    version*: uint32
    streamInfo*: seq[StreamInfo]
    streamData*: seq[string]

proc readCStr(s: Stream, length: int): string =
  result = s.readStr(length)
  let pos = result.find('\0')
  if pos != -1: result.setLen(pos)

proc loadInfo(self: var Data; s: Stream) =
  self.streamInfo.setLen(0)
  while not s.atEnd():
    var info = StreamInfo()
    info.name = s.readCStr(36)
    info.offset = s.readUint32()
    info.unknown = s.readStr(4).toHex()
    info.packedSize = s.readUint32()
    info.unpackedSize = s.readUint32()
    self.streamInfo.add(info)

  doAssert s.atEnd()
  s.close()

proc debug*(self: Data) =

  #[var im2 = newImage(self.widthTitle.int, self.heightTitle.int)
  for y in 0..<self.heightTitle.int:
    for x in 0..<self.widthTitle.int:
      #let index2 = self.imageData[EpisodeData2][y * self.widthTitle.int + x].uint8
      #im2[x, y] = ColorRGB(
      #  r: index2,
      #  g: index2,
      #  b: index2
      #)
  im2.writeFile("episode2.png")]#
  discard

proc load*(self: var Data; filename: string): bool =
  self.reset()
  let s = newFileStream(filename)
  defer: s.close()

  doAssert s.readStr(4) == "PLIB"
  doAssert s.readUint32() == 0xBEBAADDE'u32
  self.version = s.readUint32()

  let fileSize = s.readUint32()
  let checksum = s.readUint32()

  echo self

  let infoPackedSize = s.readUint32()
  let infoUnpackedSize = s.readUint32()
  let data = uncompress(s.readStr(infoPackedSize.int), dfZlib)
  doAssert infoUnpackedSize == data.len.uint32
  #writeFile("data.info.bin", data)
  self.loadInfo(newStringStream(data)) # needed to get the other offsets

  self.streamData.setLen(self.streamInfo.len)

  for i, info in self.streamInfo:
    echo "loading ", info
    self.streamData[i] = uncompress(s.readStr(info.packedSize.int), dfZlib)
    doAssert info.unpackedSize == self.streamData[i].len.uint32
    writeFile("data." & info.name & ".bin", self.streamData[i])

  doAssert s.atEnd()
  s.close()

  return true


proc test*(filename: string) =

  var data = Data()
  if data.load(filename):
    data.debug()
