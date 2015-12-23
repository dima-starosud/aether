import time
import sys
import math
import itertools

def line(x, y, x1, y1, reflect = True):
    dx = x1 - x
    dy = y1 - y
    length = int(round(math.sqrt(dx ** 2 + dy ** 2)))
    assert length > 0
    x *= length
    y *= length
    point = None
    just_reflected = False
    while True:
        mirror = reflect and MIRRORS.get(point)
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

def vertical(dx, dy):
    return (-dx, dy)

def horizontal(dx, dy):
    return (dx, -dy)

MAX = 10 ** 6

def createMirror(dx, dy):
    assert dx != 0 and dy != 0
    s = 1 if dx * dy > 0 else -1
    kx = s * dx ** 2
    ky = s * dy ** 2
    def mirror(dx, dy):
        dx, dy = dy * kx, dx * ky
        n = max(abs(dx), abs(dy)) // MAX
        if n < 1:
            n = 1
        return dx // n, dy // n
    return mirror

def createMirrorPoints(x0, y0, x1, y1):
    dx = x1 - x0
    dy = y1 - y0
    if dx == 0:
        m = vertical
    elif dy == 0:
        m = horizontal
    else:
        m = createMirror(dx, dy)
    p0 = (x0, y0)
    p1 = (x1, y1)
    return ((p, m) for p in itertools.chain([p0, p1], itertools.takewhile(lambda p: p != p1, line(x0, y0, x1, y1, reflect = False))))

################################################################################################################################################

X = 640
Y = 480

P0 = (X//2, Y//2)
Z = Y // 3
ps = [Particle(0xFFFFFF, P0, (x1, y1))
      for x1 in range(0, X, Z)
      for y1 in range(0, Y, Z)
      if (x1, y1) != P0]

P1 = (21    , Y/2  )
P2 = (X - 22, Y/2  )
P3 = (X/2   , 21    )
P4 = (X/2   , Y - 22)

MIRRORS = {}
PS = [P1 + P4, P4 + P2, P2 + P3, P3 + P1]
for args in PS:
    MIRRORS.update(createMirrorPoints(*args))

for x, y in MIRRORS.keys():
    MIRRORS[(x, y - 1)] = MIRRORS[(x, y)]
    MIRRORS[(x, y + 1)] = MIRRORS[(x, y)]

if __name__ == "__main__":
    print X, Y
    for x, y in MIRRORS:
        print "permanent", x, y, 0xFF0000
    while True:
        ps1 = []
        for p in ps:
            (x, y) = p.move()
            if 0 <= x < X and 0 <= y < Y:
                print "temporary", x, y, p.color
                ps1.append(p)
            else:
                sys.stderr.write("Light has gone: (%s, %s)\n" % (x, y))
        ps = ps1
        sys.stdout.flush()
        time.sleep(0.0)
