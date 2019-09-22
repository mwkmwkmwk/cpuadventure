#!/usr/bin/env python3

import socket

import sys

# Run with: h4x.py <host> <port>

if len(sys.argv) > 1:
    host = sys.argv[1]
else:
    host = '127.0.0.1'

if len(sys.argv) > 2:
    port = int(sys.argv[2])
else:
    port = 1234

s = socket.create_connection((host, port))
f = s.makefile()

x = y = 0
n = True

board = [[None for _ in range(8)] for _ in range(8)]

while True:
    while True:
        l = f.readline()
        if l.startswith('THERE'):
            if 'NOTHING INTERESTING' in l:
                board[y][x] = 0
            elif 'TAVERN' in l:
                board[y][x] = 1
            elif 'REDFORD' in l:
                board[y][x] = 2
            elif 'RED BULL' in l:
                board[y][x] = 3
            elif 'YELLOW DRAGON' in l:
                board[y][x] = 4
            elif 'BLUE DRAGON' in l:
                board[y][x] = 5
            elif 'CRYSTAL DRAGON' in l:
                board[y][x] = 6
            elif 'GREEN DRAGON' in l:
                board[y][x] = 7
            elif 'BEIGE DRAGON' in l:
                board[y][x] = 8
            elif 'BLACK DRAGON' in l:
                board[y][x] = 9
            elif 'GRAY DRAGON' in l:
                board[y][x] = 10
            elif 'ORANGE DRAGON' in l:
                board[y][x] = 11
            elif 'RED DRAGON' in l:
                board[y][x] = 12
            elif 'WHITE DRAGON' in l:
                board[y][x] = 13
            elif 'DRUNK DRAGON' in l:
                board[y][x] = 14
            else:
                print(x, y, l)
            break
    if n:
        if y == 7:
            if x == 7:
                break
            s.sendall(b'e')
            x += 1
            n = False
        else:
            s.sendall(b'n')
            y += 1
    else:
        if y == 0:
            if x == 7:
                break
            s.sendall(b'e')
            x += 1
            n = True
        else:
            s.sendall(b's')
            y -= 1

print(board)

class Rng:
    def __init__(self, seed):
        self.state = seed

    def get(self):
        res = self.state & 0x1f
        for _ in range(5):
            p = 0
            for i in range(15):
                if (self.state & (0x1d << 10 | 0xc << 5 | 0x11)) & 1 << i:
                    p ^= 1
            self.state >>= 1
            self.state |= p << 14
        return res

    def peek(self):
        return self.state & 0x1f

INITTAB = [
    2,
    3, 3, 3, 3, 3, 3, 3, 3, 3,
    4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14,
]

for seed in range(1, 0x8000):
    rng = Rng(seed)
    xboard = [[0 for _ in range(8)] for _ in range(8)]
    xboard[0][0] = 1
    for thing in INITTAB:
        while True:
            b = rng.get()
            a = rng.get()
            a |= b << 5
            nx = a & 7
            ny = a >> 3 & 7
            if xboard[ny][nx] == 0:
                xboard[ny][nx] = thing
                break
    if xboard == board:
        RNG = rng
        print('SEED {:04x}'.format(seed))

n = not n
while True:
    cur = board[y][x]
    if cur in [2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13]:
        print('fight')
        s.sendall(b'f')
        for l in f:
            assert l
            print(l.strip())
            if 'HEAT' in l:
                break
        done = False
        while True:
            save = RNG.state
            RNG.get()
            r_m = RNG.peek()
            if r_m & 0x10:
                print('attack')
                s.sendall(b'a')
                for l in f:
                    assert l
                    print(l.strip())
                    if 'HEAT' in l:
                        RNG.get()
                        break
                    if 'YOU KILL' in l:
                        print('kill')
                        done = True
                        break
                if done:
                    break
            else:
                print('shield')
                s.sendall(b's')
                for l in f:
                    assert l
                    print(l.strip())
                    if 'HEAT' in l:
                        break
        while True:
            l = f.readline()
            assert l
            print(l.strip())
            if l.startswith('THERE'):
                break
    if n:
        if y == 7:
            if x == 0:
                break
            s.sendall(b'w')
            x -= 1
            n = False
        else:
            s.sendall(b'n')
            y += 1
    else:
        if y == 0:
            if x == 0:
                break
            s.sendall(b'w')
            x -= 1
            n = True
        else:
            s.sendall(b's')
            y -= 1
    while True:
        l = f.readline()
        assert l
        print(l.strip())
        if l.startswith('THERE'):
            break

print('done?')
s.sendall(b'i')
while True:
    l = f.readline()
    assert l
    print(l.strip())
    if l.startswith('THERE'):
        break

for _ in range(16):
    s.sendall(b't')
    while True:
        l = f.readline()
        assert l
        print(l.strip())
        if l.startswith('THERE'):
            break
