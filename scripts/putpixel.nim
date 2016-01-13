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


type
  Pos = (int, int)


proc fillRect(p: Pos, c: Color) =
  let
    (x, y) = p
    rect = (x: zoom * x, y: zoom * y, width: zoom, height: zoom)
  ss.fillRect(rect, c)
  sdl.updateRect(ss.s, int32(rect.x), int32(rect.y), int32(rect.width), int32(rect.height))


let
  refresh_timeout = 0.025 # 25 millis; 40 ~fps
  bg = newTable[Pos, Color]()

var
  fgw = initSet[Pos]()
  fgr = initSet[Pos]()
  last_refresh = epochTime()


for line in stdin.lines:
  let
    params = line.split.asTuple(4)
    kind = params[0]
    (x, y, c0) = params.get(1..3).map(parseInt)
    p = (x, y)
    c = colors.Color(c0)
  fillRect(p, c)
  case kind:
    of "permanent":
      bg[p] = c
    of "temporary":
      fgw.incl(p)
      fgr.excl(p)
    else:
      raise newException(ValueError, "Unexpected message kind " & kind)
  let
    now = epochTime()
  if now > last_refresh + refresh_timeout:
    last_refresh = now
    for p in fgr:
      fillRect(p, bg.getOrDefault(p))
    fgr = fgw
    fgw = initSet[Pos]()
