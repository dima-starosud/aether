import graphics
from colors import nil
from sdl import nil
from parseutils import nil
import sequtils
from strutils import nil

proc parseInt(s: string): int =
  if parseutils.parseInt(s, result, 0) != len(s):
    raise newException(ValueError, "Cannot parse int from '" & s & "'.")

proc splitInts(s: string): seq[int] =
  strutils.split(s).filterIt(it != "").map(parseInt)

let
  nums = splitInts(system.readLine(system.stdin))
  ss = newScreenSurface(nums[0], nums[1])

for line in system.lines(system.stdin):
  let
    data = splitInts(line)
    x = data[0]
    y = data[1]
    c = colors.Color(data[2])
  ss[x, y] = c
  #sdl.updateRect(ss.s, int32(x), int32(y), 1, 1) ???
  sdl.updateRect(ss.s, 0, 0, 0, 0)
