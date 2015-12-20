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
    point = None
    just_reflected = False
    while True:
        mirror = MIRRORS.get(point)
        if mirror and not just_reflected:
            x, y = x/length, y/length
            dx, dy = mirror(dx, dy)
            length = int(round(math.sqrt(dx ** 2 + dy ** 2)))
            assert length > 0
            x *= length
            y *= length
        just_reflected = bool(mirror)
        x += dx
        y += dy
        point = (x/length, y/length)
        yield point

class Particle:
    def __init__(self, color, p0, p1):
        self.color = color
        self.points = line(*(p0 + p1))

    def move(self):
        return next(self.points)

X = 640
Y = 480

P0 = (X//2, Y//2)
Z = 80
ps = [Particle(0xFFFFFF, P0, (x1, y1))
      for x1 in range(0, X, Z)
      for y1 in range(0, Y, Z)
      if (x1, y1) != P0]

#ps = [Particle(0xFFFFFF, P0, (X//4, Y//3))]

def vertical(dx, dy):
    return (-dx, dy)

def horizontal(dx, dy):
    return (dx, -dy)

MIRRORS = dict(
    [((x, y), vertical) for x in [Z, X - Z] for y in range(Y)] +
    [((x, y), horizontal) for x in range(X) for y in [Z, Y - Z]])

if __name__ == "__main__":
    print 640, 480
    while True:
        ps1 = []
        for p in ps:
            (x, y) = p.move()
            if 0 <= x < X and 0 <= y < Y:
                print x, y, p.color
                ps1.append(p)
            else:
                sys.stderr.write("Light has gone: (%s, %s)\n" % (x, y))
        ps = ps1
        sys.stdout.flush()
        time.sleep(0.01)
