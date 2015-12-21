import graphics
from colors import nil
from sdl import nil
from parseutils import nil
import sequtils
from strutils import split
from tuples import staticMap
from os import nil

template asTuple(list: expr, length: int): expr =
  let
    xs = list
    length0 = len(xs)
  if length0 != length:
    raise newException(ValueError, "Expected " & $length & " items, got " & $length0)
  template getItem(i: int): expr = xs[i]
  (0 ..< length).staticMap(getItem)

proc parseInt(s: string): int =
  if parseutils.parseInt(s, result, 0) != len(s):
    raise newException(ValueError, "Cannot parse int from '" & s & "'")

proc splitInts(s: string): seq[int] =
  s.split.filterIt(it != "").map(parseInt)

let
  times = if os.paramCount() > 0: parseInt(os.paramStr(1)) else: 1

let
  (w, h) = stdin.readLine.splitInts.mapIt(it * times).asTuple(2)
  ss = newScreenSurface(w, h)

for line in stdin.lines:
  let
    (x, y, c) = line.splitInts.asTuple(3)
    rect = (x: times * x, y : times * y, width: times, height: times)
  ss.fillRect(rect, colors.Color(c))
  sdl.updateRect(ss.s, int32(rect.x), int32(rect.y), int32(rect.width), int32(rect.height))
