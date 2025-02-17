import std/streams

type
  GameVersion* = enum
    v_AGA
    v1_23
    v1_24

const DataFileCopyright* =
  "                      Jazz Jackrabbit 2 Data File\r\n" &
  "\r\n" &
  "         Retail distribution of this data is prohibited without\r\n" &
  "             written permission from Epic MegaGames, Inc.\r\n" &
  "\r\n" &
  "\x1a"

static: doAssert DataFileCopyright.len == 180

proc readCStr*(s: Stream, length: int): string =
  result = s.readStr(length)
  let pos = result.find('\0')
  if pos != -1: result.setLen(pos)

proc writeCStr*(s: Stream; str: string; len: int) =
  if str.len <= len:
    s.write(str)
    let diff = len - str.len
    for i in 0 ..< diff:
      s.write('\0')
  else:
    s.write(str[0 ..< len])
