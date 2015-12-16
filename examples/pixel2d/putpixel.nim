import graphics
from colors import nil
from sdl import nil
from parseutils import nil
import sequtils
from strutils import split

proc parseInt(s: string): int =
  if parseutils.parseInt(s, result, 0) != len(s):
    raise newException(ValueError, "Cannot parse int from '" & s & "'.")

proc splitInts(s: string): seq[int] =
  s.split.filterIt(it != "").map(parseInt)

let
  nums = stdin.readLine.splitInts
  ss = newScreenSurface(nums[0], nums[1])

for line in stdin.lines:
  let
    data = line.splitInts
    x = data[0]
    y = data[1]
    c = colors.Color(data[2])
  ss[x, y] = c
  sdl.updateRect(ss.s, 0, 0, 0, 0)
