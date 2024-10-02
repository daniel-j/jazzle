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
    # echo "loading ", name
    info.data = uncompress(s.readStr(info.packedSize.int), dfZlib)
    doAssert info.unpackedSize == info.data.len.uint32
    doAssert info.checksum == crc32(info.data)
    writeFile("data." & name & ".bin", info.data)

  doAssert s.atEnd()
  s.close()

  return true

proc debug*(self: Data) =

  echo "Data streams: ", self.streams.keys.toSeq()

  # TODO: Export decoded assets
  for info in self.streams.values:
    writeFile("data." & info.name & ".bin", info.data)

proc test*(filename: string) =
  var data = Data()
  if data.load(filename):
    data.debug()
