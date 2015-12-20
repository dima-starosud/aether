import graphics
from colors import nil
from sdl import nil
from parseutils import nil
import sequtils
from strutils import split
from tuples import staticMap

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
    raise newException(ValueError, "Cannot parse int from '" & s & "'.")

proc splitInts(s: string): seq[int] =
  s.split.filterIt(it != "").map(parseInt)

let
  (w, h) = stdin.readLine.splitInts.asTuple(2)
  ss = newScreenSurface(w, h)

for line in stdin.lines:
  let
    (x, y, c) = line.splitInts.asTuple(3)
  ss[x, y] = colors.Color(c)
  sdl.updateRect(ss.s, 0, 0, 0, 0)
