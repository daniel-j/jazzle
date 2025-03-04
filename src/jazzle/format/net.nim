import std/asyncdispatch
import std/asyncnet
import std/nativesockets
import std/streams
import std/strutils
import std/terminal
import std/times

export asyncdispatch

type

  UdpPacketId* {.size: 1.} = enum
    PkCsPing = 0x03
    PkScPong = 0x04
    PkCsQuery = 0x05
    PkScStatus = 0x06

  GameMode* {.size: 1.} = enum
    Singleplayer
    Coop
    Battle
    Race
    Treasure
    Capture

  CustomMode* {.size: 1.} = enum
    Off = 0
    RoastTag = 1
    LastRabbitStanding = 2
    ExtendedLRS = 3
    Pestilence = 4
    TeamBattle = 11
    Jailbreak = 12
    DeathCTF = 13
    FlagRun = 14
    TeamLRS = 15
    Domination = 16
    HeadHunters = 17

  Team* {.size: 1.} = enum
    Blue
    Red
    Green
    Yellow

  PingFlags* {.packed.} = object
    gameMode* {.bitsize: 4.}: GameMode
    private* {.bitsize: 1.}: bool
    extra* {.bitsize: 3.}: uint8

  PingResponse* = object
    address*: string
    port*: Port
    success*: bool
    ping*: int
    numberInList*: uint8
    data*: uint32
    flags*: PingFlags

  QueryFlags* {.packed.} = object
    private* {.bitsize: 1.}: bool
    plusOnly* {.bitsize: 1.}: bool
    idleServer* {.bitsize: 1.}: bool
    unused* {.bitsize: 4.}: uint8

  PlayerFlags* {.packed.} = object
    team* {.bitsize: 2.}: Team
    spectating* {.bitsize: 1.}: bool
    unused* {.bitsize: 4.}: uint8

  QueryPlayer* = object
    name*: string
    score*: uint8
    flags*: PlayerFlags

  QueryResponse* = object
    address*: string
    port*: Port
    success*: bool
    ping*: int
    numberInList*: uint8
    uptime*: uint32
    version*: string
    clientCount*: uint8
    playerCount*: uint8
    gameMode*: GameMode
    playerLimit*: uint8
    serverName*: string
    plus*: bool
    customMode*: CustomMode
    flags*: QueryFlags
    maxScore*: uint8
    teamScore*: array[Team, uint8]
    players*: seq[QueryPlayer]
    levelFile*: string

  UdpClient* = object
    socket: AsyncSocket

proc `=destroy`(self: UdpClient) =
  if not self.socket.isNil:
    self.socket.close()

const teamColorPrefix*: array[Team, string] = [
  "|||",
  "||",
  "|",
  "||||"
]

proc echoColors*(str: string) =
  let colors = [fgGreen, fgRed, fgBlue, fgYellow, fgMagenta, fgWhite, fgBlack, fgCyan]
  var colorIndex = -1
  for c in str:
    if c == '|':
      inc(colorIndex)
      if colorIndex >= colors.len: colorIndex = 0
      stdout.setForegroundColor(colors[colorIndex])
      continue
    stdout.write(c)
  stdout.resetAttributes()

proc adler16(buf: string; offset: int = 0): uint16 =
  var sum = [1, 1]
  for i in offset..<buf.len:
    sum[0] = (sum[0] + buf[i].int) mod 251
    sum[1] = (sum[1] + sum[0]) mod 251
  return (sum[1].uint16 shl 8) or sum[0].uint16

proc addChecksum(buf: string): string =
  let chksum = adler16(buf)
  result.add char chksum and 0xFf
  result.add char (chksum shr 8) and 0xff
  result &= buf

proc validateUdpPacket(buf: string): bool =
  if buf.len < 3: return false
  let checksum = buf[0].uint16 or (buf[1].uint16 shl 8)
  if adler16(buf, 2) == checksum:
    return true

proc pingParse*(buf: string): PingResponse =
  if not validateUdpPacket(buf) or PkScPong.char != buf[2]:
    echo "invalid response"
    return
  let s = newStringStream(buf)
  defer: s.close()
  s.setPosition(3)
  s.read(result.numberInList)
  s.read(result.data)
  s.read(result.flags)
  result.success = true

proc queryParse*(buf: string): QueryResponse =
  if not validateUdpPacket(buf) or PkScStatus.char != buf[2]:
    echo "invalid response"
    return
  let s = newStringStream(buf)
  defer: s.close()
  s.setPosition(3)

  let nonplusLength = 18 + buf[16].int
  let plusLiteLength = nonplusLength + 2
  result.plus = buf.len > nonplusLength
  let extendedPlus = buf.len > plusLiteLength

  if not result.plus:
    s.read(result.numberInList)
    s.read(result.uptime)
    result.version = s.readStr(4)
    s.read(result.playerCount)
    discard s.readUint8()
    s.read(result.gameMode)
    s.read(result.playerLimit)
    result.serverName = s.readStr(s.readUint8().int)
    discard s.readUint8()
  else:
    discard s.readUint8() # always zero?
    s.read(result.uptime)
    result.version = s.readStr(4)
    s.read(result.clientCount)
    s.read(result.playerCount)
    s.read(result.gameMode)
    s.read(result.playerLimit)
    result.serverName = s.readStr(s.readUint8().int)
    s.read(result.customMode)
    if not s.atEnd():
      s.read(result.flags)
      if not s.atEnd() and extendedPlus and not result.flags.private:
        s.read(result.maxScore)
        s.read(result.teamScore)
        result.players.setLen(result.playerCount)
        for player in result.players.mitems:
          var chr: char
          while (s.read(chr); chr != '\0'):
            player.name.add(chr)
          s.read(player.score)
          s.read(player.flags)
        # jj2+ sends an extra random byte after level filename, so skip it
        result.levelFile = s.readStr(buf.len - s.getPosition() - 1)
        let randomByte = s.readUint8()
        discard randomByte

  result.success = true
  # if not s.atEnd():
  #   echo "extra data: " & s.readAll().toHex()
  # doAssert s.atEnd()


proc ping*(client: UdpClient; address: string, port: Port; numberInList: uint8 = 0; timeout: int = 1000): Future[PingResponse] {.async.} =
  let data: uint32 = 1234
  let s = newStringStream()
  s.write(uint8(PK_CS_PING))
  s.write(numberInList)
  s.write(data)
  #s.write("21  ")
  let packet = s.data
  s.close()
  let startTime = now()
  await client.socket.sendTo(address, port, addChecksum(packet))
  let res = client.socket.recvFrom(1024)
  if await res.withTimeout(timeout):
    let endTime = now()
    result = pingParse(res.read().data)
    result.ping = (endTime - startTime).inMilliseconds
    result.address = address
    result.port = port

proc query*(client: UdpClient; address: string, port: Port; counter: uint8 = 0; timeout: int = 1000): Future[QueryResponse] {.async.} =
  let packet = char(PK_CS_QUERY) & char(counter) & char(1)
  let startTime = now()
  await client.socket.sendTo(address, port, addChecksum(packet))
  let res = client.socket.recvFrom(1024)
  if await res.withTimeout(timeout):
    let endTime = now()
    result = queryParse(res.read().data)
    result.ping = (endTime - startTime).inMilliseconds
    result.address = address
    result.port = port

proc broadcastQuery*(client: UdpClient; port: Port = Port(10052); counter: uint8 = 0; timeout: int = 200): seq[QueryResponse] =
  let packet = char(PK_CS_QUERY) & char(counter) & char(1)
  client.socket.setSockOpt(OptBroadcast, true)
  waitFor client.socket.sendTo("255.255.255.255", port, addChecksum(packet))
  client.socket.setSockOpt(OptBroadcast, false)
  var fut = client.socket.recvFrom(1024)
  while waitFor fut.withTimeout(timeout):
    let res = waitFor fut
    var q = queryParse(res.data)
    q.address = res.address
    q.port = res.port
    result.add(q)
    fut = client.socket.recvFrom(1024)

proc initUdpClient*(): owned UdpClient =
  result.socket = newAsyncSocket(AF_INET, SOCK_DGRAM, IPPROTO_UDP)
  result.socket.bindAddr()

proc listserverServers*(host: string): seq[tuple[address: string, port: Port]] =
  let client = newAsyncSocket()
  defer: client.close()
  waitFor client.connect(host, Port(10057))
  var line = ""
  while (line = waitFor client.recvLine(); line != ""):
    let address = line[0 ..< line.find(" ")].split(":")
    result.add((address[0], address[1].parseUInt().Port))

proc prettyPrint*(q: QueryResponse) =
  stdout.setStyle({styleBright})
  echoColors q.serverName
  echo ""
  echo "--------------------"
  echo q.address & ":" & $q.port
  echo "[" & $q.playerCount & "/" & $q.playerLimit & "] 1." & q.version.strip() & (if q.plus: "+" else: "") & " " & (if q.customMode != Off: $q.customMode else: $q.gameMode) & " [" & q.levelFile & "] " & $q.ping & " ms"

  for player in q.players:
    stdout.setStyle({styleBright})
    if player.flags.spectating:
      styledEcho(fgBlack, player.name.replace("|", ""))
    else:
      echoColors(teamColorPrefix[player.flags.team] & player.name)
      echo ""
  echo ""
