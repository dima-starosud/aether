import graphics
import colors
from sdl import nil
from os import nil

import sequtils
import strutils
import tuples
import sets
import tables
import times


template asTuple(list: expr, length: int): expr =
  let
    xs = list
    length0 = len(xs)
  if length0 != length:
    raise newException(ValueError, "Expected " & $length & " items, got " & $length0)
  template getItem(i: int): expr = xs[i]
  (0 ..< length).staticMap(getItem)


let
  zoom = if os.paramCount() > 0: parseInt(os.paramStr(1)) else: 1
  (w, h) = stdin.readLine.split.mapIt(parseInt(it) * zoom).asTuple(2)
  ss = newScreenSurface(w, h)


proc fillRect(x: int, y: int, c: Color) =
  let rect = (x: zoom * x, y: zoom * y, width: zoom, height: zoom)
  ss.fillRect(rect, c)
  sdl.updateRect(ss.s, int32(rect.x), int32(rect.y), int32(rect.width), int32(rect.height))


proc newSet[A](): ref HashSet[A] =
  new(result)
  result[] = initSet[A]()


type
  Pos = (int, int)

let
  bg = newTable[Pos, Color]()

var
  fg1 = newSet[Pos]()
  fg2 = newSet[Pos]()


for line in stdin.lines:
  let
    params = line.split.asTuple(4)
    kind = params[0]
    (x, y, c0) = params.get(1..3).map(parseInt)
    p = (x, y)
    c = colors.Color(c0)
  fillRect(x, y, c)
  case kind:
    of "permanent":
      bg[p] = c
    of "temporary":
      fg1[].excl(p)
      fg2[].incl(p)
    else:
      raise newException(ValueError, "Unexpected message kind " & kind)
