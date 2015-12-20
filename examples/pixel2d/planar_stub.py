import time
import sys
import math

def line(x, y, x1, y1):
    dx = x1 - x
    dy = y1 - y
    length = int(round(math.sqrt(dx ** 2 + dy ** 2)))
    assert length > 0
    x *= length
    y *= length
    while True:
        x += dx
        y += dy
        point = (x/length, y/length)
        yield point

class Particle:
    def __init__(self, color, p0, p1):
        self.color = color
        self.points = line(*(p0 + p1))

    def move(self, mirror):
        return next(self.points)

X = 640
Y = 480
print 640, 480

P0 = (X//2, Y//2)
Z = 80
ps = [Particle(0xFFFFFF, P0, (x1, y1))
      for x1 in range(0, X, Z)
      for y1 in range(0, Y, Z)
      if (x1, y1) != P0]

while True:
    ps1 = []
    for p in ps:
        (x, y) = p.move(None)
        if 0 <= x < X and 0 <= y < Y:
            print x, y, p.color
            ps1.append(p)
        else:
            sys.stderr.write("Light has gone: (%s, %s)\n" % (x, y))
    ps = ps1
    sys.stdout.flush()
    time.sleep(0.01)
