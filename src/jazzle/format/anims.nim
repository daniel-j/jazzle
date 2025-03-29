import std/os
import std/streams
import std/strutils
# import std/math
import zippy
import zippy/crc
import ./common

const
  AlibMagic = ['A', 'L', 'I', 'B']
  AlibSignature = 0x00BEBA00'u32
  AlibUnknown = 0x1808'u16

  AnimMagic = ['A', 'N', 'I', 'M']

  SampleMagicRIFF = ['R', 'I', 'F', 'F']
  SampleMagicAS = ['A', 'S', ' ', ' ']
  SampleMagicSAMP = ['S', 'A', 'M', 'P']

type
  StreamKind = enum
    AnimsInfo
    FramesInfo
    ImageData
    SampleData

  StreamSize = tuple[packedSize, unpackedSize: uint32]

  AnimLib* = object
    stream: Stream
    version*: uint16
    setCount*: int
    setAddress: seq[uint32]
    setList*: seq[AnimSet]

  AnimSet* = object
    loaded*: bool
    animList*: seq[Anim]
    imageData*: StringStream
    sampleList*: seq[Sample]

  Anim* = object
    frameRate*: int
    frameList*: seq[FrameInfo]

  AlibHeader = object
    magic*: array[4, char]
    signature*: uint32
    headerSize*: uint32
    version*: uint16
    unknown*: uint16
    fileSize*: uint32
    checksum*: uint32
    setCount*: uint32

  AnimHeader = object
    magic*: array[4, char]
    animCount*: uint8
    sampleCount*: uint8
    frameCount*: uint16
    priorSampleCount*: uint32
    streamSizes*: array[StreamKind, StreamSize]

  AnimInfo = object
    frameCount*: uint16
    frameRate*: uint16
    frameListPtr: uint32

  FrameInfo* = object
    width*: int16
    height*: int16
    coldspotX*: int16
    coldspotY*: int16
    hotspotX*: int16
    hotspotY*: int16
    gunspotX*: int16
    gunspotY*: int16
    imageAddress*: uint32
    maskAddress*: uint32

  SampleFlags* {.size: sizeof(uint16).} = enum
    NoFlags = 0
    Flag1 = 1
    Flag16bit = 2
    FlagLoop = 3
    FlagBidi = 4
    Flag5 = 5
    FlagStereo = 6

  SampleHeader = object
    totalSize*: uint32
    magicRIFF*: array[4, char]
    lengthRIFF*: uint32
    magicAS*: array[4, char]
    magicSAMP*: array[4, char]
    lengthSAMP*: uint32
    reserved1Size: uint32
    reserved1*: array[32, uint8]
    unknown1: uint16
    volume*: int16
    flags*: set[SampleFlags]
    unknown2*: uint16
    numSamples*: uint32
    loopStartEnd*: array[2, uint32]
    sampleRate*: uint32
    hasAppendix*: uint32
    reserved2: uint32

  Sample* = object
    volume*: int16
    flags*: set[SampleFlags]
    loopStartEnd*: array[2, uint32]
    sampleRate*: uint32
    numSamples*: uint32
    samples*: StringStream

proc open*(self: var AnimLib; filename: string): bool =
  if not self.stream.isNil:
    echo "alib already opened"
    return false
  self.reset()
  self.stream = newFileStream(filename)

  if self.stream.isNil:
    echo "unable to open alib"
    return false

  var alibHeader: AlibHeader
  self.stream.read(alibHeader)

  if alibHeader.magic != AlibMagic or alibHeader.signature != AlibSignature or alibHeader.unknown != AlibUnknown or alibHeader.fileSize != getFileSize(filename).uint32:
    echo "alib magic signature or filesize mismatch"
    self.stream.close()
    self.stream = nil
    return false

  self.version = alibHeader.version

  let currentPosition = self.stream.getPosition()
  let calculatedChecksum = crc32(self.stream.readAll())

  if alibHeader.fileSize != self.stream.getPosition().uint32:
    echo "alib filesize mismatch"
    self.stream.close()
    self.stream = nil
    return false

  self.stream.setPosition(currentPosition)
  if alibHeader.checksum != calculatedChecksum:
    echo "alib crc32 mismatch"
    self.stream.close()
    self.stream = nil
    return false

  self.setCount = alibHeader.setCount.int
  self.setList.setLen(self.setCount)
  self.setAddress.setLen(self.setCount)
  if self.setAddress.len > 0:
    if self.stream.readData(self.setAddress[0].addr, self.setAddress.len * sizeof(uint32)) != self.setAddress.len * sizeof(uint32):
      echo "alib header read anim offsets failed"
      self.stream.close()
      self.stream = nil
      return false

  return true

proc close*(self: var AnimLib) =
  if not self.stream.isNil:
    self.stream.close()

proc loadAnim*(self: var AnimLib; setNum: int): bool =
  ## Loads an animation set from the animation library
  if self.stream.isNil:
    echo "loadAnim: stream is closed"
    return false

  if setNum < 0 or setNum >= self.setCount:
    echo "loadAnim: setNum out of range"
    return false

  if self.setList[setNum].loaded:
    echo "loadAnim: set already loaded"
    return true

  var animSet = AnimSet(loaded: true)

  self.stream.setPosition(self.setAddress[setNum].int)

  var animHeader: AnimHeader
  self.stream.read(animHeader)

  if animHeader.magic != AnimMagic:
    echo "anim magic mismatch"
    return false

  var sections: array[StreamKind, StringStream]
  for kind in StreamKind.items:
    var data = self.stream.readStr(animHeader.streamSizes[kind].packedSize.int)
    data = uncompress(data, dfZlib)
    doAssert data.len.uint32 == animHeader.streamSizes[kind].unpackedSize
    sections[kind] = newStringStream(data)

  if animHeader.animCount > 0:
    var animInfo: seq[AnimInfo]
    if sections[AnimsInfo].data.len != animHeader.animCount.int * sizeof(AnimInfo):
      echo "loadAnim: animInfo length mismatch"
      return false
    animInfo.setLen(animHeader.animCount)
    if animHeader.animCount.int * sizeof(AnimInfo) != sections[AnimsInfo].readData(animInfo[0].addr, animHeader.animCount.int * sizeof(AnimInfo)):
      echo "loadAnim: animInfo readData length mismatch"
      return false

    animSet.animList.setLen(animInfo.len)
    for i, anim in animInfo:
      animSet.animList[i] = Anim(frameRate: anim.frameRate.int)
      animSet.animList[i].frameList.setLen(anim.frameCount)

  if animHeader.frameCount > 0:
    var frameInfo: seq[FrameInfo]
    if sections[FramesInfo].data.len != animHeader.frameCount.int * sizeof(FrameInfo):
      echo "loadAnim: frameInfo length mismatch"
      return false
    frameInfo.setLen(animHeader.frameCount)
    if animHeader.frameCount.int * sizeof(FrameInfo) != sections[FramesInfo].readData(frameInfo[0].addr, animHeader.frameCount.int * sizeof(FrameInfo)):
      echo "loadAnim: frameInfo readData length mismatch"
      return false

    var frameNum = 0
    for i, anim in animSet.animList.mpairs:
      anim.frameList = frameInfo[frameNum..<frameNum+anim.frameList.len]
      frameNum.inc(anim.frameList.len)

  animSet.imageData = sections[ImageData]

  if animHeader.sampleCount > 0:
    let s = sections[SampleData]
    while not s.atEnd():
      let currentPosition = s.getPosition()
      var sampleHeader: SampleHeader
      s.read(sampleHeader)
      if sampleHeader.magicRIFF != SampleMagicRIFF or sampleHeader.magicAS != SampleMagicAS or sampleHeader.magicSAMP != SampleMagicSAMP:
        echo "sample magic signatures mismatch"
        return false
      if sampleHeader.totalSize - sampleHeader.lengthRIFF != 0xc:
        echo "sample sizes mismatch"
        return false

      let is16bit = Flag16bit in sampleHeader.flags
      let isStereo = FlagStereo in sampleHeader.flags
      let sampleDataSize = sampleHeader.numSamples.int * (1 + int(is16bit)) * (1 + int(isStereo))
      if sampleHeader.hasAppendix != 0:
        echo "sample has extra data ", s.readStr(158).toHex()

      let sample = Sample(
        volume: sampleHeader.volume,
        flags: sampleHeader.flags,
        loopStartEnd: sampleHeader.loopStartEnd,
        sampleRate: sampleHeader.sampleRate,
        numSamples: sampleHeader.numSamples,
        samples: newStringStream(s.readStr(sampleDataSize))
      )
      animSet.sampleList.add(sample)

      s.setPosition(currentPosition + sampleHeader.totalSize.int)

  self.setList[setNum] = animSet

  return true

# proc lerp(a: float, b: float, f: float): float =
#   return (a * (1.0 - f)) + (b * f)

# proc resampleAudio(samples: var seq[int16]; fromSampleRate: int; toSampleRate: int): seq[int16] =
#   let ratio = toSampleRate / fromSampleRate
#   let newLength = int samples.len.float * ratio
#   result.setLen(newLength)
#   for i, samp in result.mpairs:
#     let indexA = floor(i.float / ratio)
#     let indexB = ceil((i + 1).float / ratio)
#     if indexB.int >= samples.len:
#       break
#     let distance = indexB - indexA
#     let position = ((i.float / ratio) - indexA) / distance
#     samp = int16 lerp(samples[indexA.int].float, samples[indexB.int].float, position)

proc toWav*(sample: Sample): string =
  let s = newStringStream()
  var targetSampleRate = sample.sampleRate.int

  var is16bit = Flag16bit in sample.flags
  var bytesPerSample = 1 + int(is16bit)
  let isStereo = FlagStereo in sample.flags
  let channels = 1 + int(isStereo)

  var samples16bit: seq[int16]
  samples16bit.setLen(sample.samples.data.len div bytesPerSample)

  for i, samp in samples16bit.mpairs:
    if is16bit:
      sample.samples.read(samp)
    else:
      samp = sample.samples.readUint8().int16 shl 8

  is16bit = true
  bytesPerSample = 1 + int(is16bit)

  s.write("RIFF")
  s.write(36 + sample.samples.data.len.uint32)
  s.write("WAVE")

  s.write("fmt ")
  s.write(16'u32)
  s.write(1'u16) # Audio format = PCM
  s.write(uint16 channels)
  s.write(uint32 targetSampleRate)
  s.write(uint32 targetSampleRate * bytesPerSample * channels) # BytesPerSec
  s.write(uint16 bytesPerSample * channels) # BytesPerBloc
  s.write(uint16 bytesPerSample * 8) # BitsPerSample

  s.write("data")
  s.write(uint32 samples16bit.len * bytesPerSample)

  for samp in samples16bit:
    s.write(samp)

  return s.data

when not defined(emscripten):
  import std/strformat
  import std/osproc

  proc test*() =
    echo "loading Anims.j2a"
    var animLib = AnimLib()
    doAssert animLib.open("Anims.j2a")
    echo "alib sets: ", animLib.setList.len
    for i in 0..<animLib.setCount:
      doAssert animLib.loadAnim(i)
      for j in 0..<animLib.setList[i].animList.len:
        let anim = animLib.setList[i].animList[j].addr
        # echo (i, j, anim[].frameList.len, anim[].frameRate)
      for j in 0..<animLib.setList[i].sampleList.len:
        let sample = animLib.setList[i].sampleList[j].addr
        # echo sample[]
        let wavData = sample[].toWav()
        let filename = &"sample_{i}_{j}.wav"
        let filenameOut = &"sample_{i}_{j}_resampled.wav"
        writeFile(filename, wavData)
        # resample to high quality wav!
        assert 0 == execCmd(&"sox {filename} -b 16 {filenameOut} gain -2 rate -q 44100")
