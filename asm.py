import sys


ranges = []

class Chunk:
    def __init__(self, thing, which):
        self.thing = thing
        self.which = which

    def resolve(self):
        if isinstance(self.thing, int):
            t = self.thing
        else:
            t = self.thing.resolve()
        return t >> (self.which * 5) & 0x1f

class Ref:
    def __init__(self, lbl, off):
        self.lbl = lbl
        self.off = off

    def resolve(self):
        return labels[self.lbl] + self.off

class StringRef:
    def __init__(self, s):
        self.s = s
        strs.add(s)

    def resolve(self):
        return strpool[self.s]
        

out = []
labels = {}
dptr = 0
rels = []
strs = set()

JUMPS = {
    'JMP': 0x18,
    'CALL': 0x19,
}

BRANCH = {
    'BNZ': 0x05,
    'BZ': 0x0a,
    'BA': 0x01,
    'BC': 0x0c,
    'B': 0x0f,
}

SINGLE = {
    'RET': 0x1b,
    'LOSE': 0x1c,
    'WIN': 0x1d,
}

ALU = {
    'ADD': 0,
    'ADC': 1,
    'SUB': 2,
    'SBB': 3,
    'AND': 4,
    'OR': 5,
    'XOR': 6,
    'MOV': 7,
    'SHL': 8,
    'RCL': 9,
    'SHR': 10,
    'RCR': 11,
}

ONEARG = {
    'PUSH': 0,
    'POP': 1,
    'PUTC': 2,
    'GETC': 3,
    'RND': 4,
}

ARGS = {
    'R0': 0,
    'R1': 1,
    'R2': 2,
    'R3': 3,
    'DATA': 6,
    'CODE': 7,
}

LET = {
    'A': 0x01,
    'E': 0x02,
    'Y': 0x04,
    'U': 0x05,
    'I': 0x06,
    'O': 0x07,
    'J': 0x09,
    'G': 0x0a,
    'H': 0x0b,
    'B': 0x0c,
    'C': 0x0d,
    'F': 0x0e,
    'D': 0x0f,
    ' ': 0x10,
    'X': 0x12,
    'Z': 0x13,
    'S': 0x14,
    'T': 0x15,
    'W': 0x16,
    'V': 0x17,
    'K': 0x19,
    'M': 0x1a,
    'L': 0x1b,
    'R': 0x1c,
    'Q': 0x1d,
    'N': 0x1e,
    'P': 0x1f,
}

FIG = {
    '1': 0x01,
    '2': 0x02,
    '3': 0x04,
    '4': 0x05,
    '5': 0x07,
    '6': 0x09,
    '7': 0x0a,
    '+': 0x0b,
    '8': 0x0c,
    '9': 0x0d,
    '0': 0x0f,
    ',': 0x12,
    ':': 0x13,
    '.': 0x14,
    '?': 0x16,
    '\'': 0x17,
    '(': 0x19,
    ')': 0x1a,
    '=': 0x1b,
    '-': 0x1c,
    '/': 0x1d,
    '%': 0x1f,
}

def do_const(val):
    if val[0].isdigit():
        return int(val, 0)
    if '"' in val:
        if val[0] != '"' or val[-1] != '"':
            raise ValueError(val)
        bs = False
        fig = False
        s = []
        for c in val[1:-1]:
            if bs:
                if c == 'n':
                    s.append(0x11)
                elif c == 'r':
                    s.append(3)
                else:
                    raise ValueError(c)
                bs = False
            elif c == ' ':
                s.append(0x08 if fig else 0x10)
            elif c in LET:
                if fig:
                    s.append(0x10)
                    fig = False
                s.append(LET[c])
            elif c in FIG:
                if not fig:
                    s.append(0x08)
                    fig = True
                s.append(FIG[c])
            elif c == '\\':
                bs = True
            else:
                raise ValueError(c)
        if fig:
            s.append(0x10)
            fig = False
        s.append(0)
        return StringRef(bytes(s))
    if '+' in val:
        l, _, n = val.partition('+')
        if n[0].isdigit():
            n = int(n, 0)
        else:
            n = labels[n]
        if l in labels:
            return labels[l] + n
        return Ref(l, n)
    if val in labels:
        return labels[val]
    return Ref(val, 0)

def parse_alu_arg(arg):
    if arg in ARGS:
        return ARGS[arg], None
    kind = 4
    if arg[0] == '[' and arg[-1] == ']':
        kind = 5
        arg = arg[1:-1]
    which = None
    if arg.startswith('LO '):
        arg = arg[3:]
        which = 0
    elif arg.startswith('MID '):
        arg = arg[4:]
        which = 1
    elif arg.startswith('HI '):
        arg = arg[3:]
        which = 2
    data = do_const(arg)
    if which is not None:
        if isinstance(data, Ref):
            data = Chunk(data, which)
        else:
            data = data >> (which * 5) & 0x1f
    return kind, data
    

with open(sys.argv[1]) as f:
    for l in f:
        l = l.strip()
        if not l:
            continue
        if l[0] == '#':
            continue
        if l[-1] == ':':
            l = l[:-1]
            if l in labels:
                raise ValueError(l)
            labels[l] = len(out)
            continue
        args = []
        for i, c in enumerate(l):
            if c.isspace():
                op = l[:i]
                q = False
                apos = i
                while i < len(l):
                    c = l[i]
                    if c == '"':
                        q = not q
                    elif c == ',' and not q:
                        args.append(l[apos:i].strip())
                        apos = i + 1
                    i += 1
                if apos != len(l):
                    args.append(l[apos:].strip())
                break
        else:
            op = l
        if op == 'DATA':
            name, num = args
            num = do_const(num)
            if name in labels:
                raise ValueError(name)
            labels[name] = dptr
            dptr += num
            if dptr > 0x400:
                raise ValueError(dptr)
        elif op == 'CONST':
            name, num = args
            num = do_const(num)
            if name in labels:
                raise ValueError(name)
            labels[name] = num
        elif op == 'PTR':
            arg, = args
            arg = do_const(arg)
            out.append(Chunk(arg, 0))
            out.append(Chunk(arg, 1))
            out.append(Chunk(arg, 2))
        elif op == 'BYTE':
            arg, = args
            arg = do_const(arg)
            out.append(arg)
        elif op == 'LPTR':
            arg, = args
            arg = do_const(arg)
            out.append(0x0f)
            out.append(0x00)
            out.append(Chunk(arg, 0))
            out.append(0x0f)
            out.append(0x01)
            out.append(Chunk(arg, 1))
            out.append(0x0f)
            out.append(0x02)
            out.append(Chunk(arg, 2))
        elif op in JUMPS:
            arg, = args
            arg = do_const(arg)
            out.append(JUMPS[op])
            out.append(Chunk(arg, 0))
            out.append(Chunk(arg, 1))
            out.append(Chunk(arg, 2))
        elif op in BRANCH:
            arg, = args
            end = len(out) + 4
            out.append(0x1a)
            out.append(BRANCH[op])
            out.append(Chunk(Ref(arg, -end), 0))
            out.append(Chunk(Ref(arg, -end), 1))
            ranges.append((arg, -end))
        elif op in SINGLE:
            out.append(SINGLE[op])
            if args:
                raise ValueError(op, args)
        elif op in ALU:
            op = ALU[op]
            a0, a1 = args
            a0k, a0d = parse_alu_arg(a0)
            a1k, a1d = parse_alu_arg(a1)
            op = op << 6 | a1k << 3 | a0k
            out.append(op >> 5 & 0x1f)
            out.append(op >> 0 & 0x1f)
            if a0d is not None:
                out.append(a0d)
            if a1d is not None:
                out.append(a1d)
        elif op in ONEARG:
            op = ONEARG[op]
            a0, = args
            a0k, a0d = parse_alu_arg(a0)
            op = 0xf << 6 | op << 3 | a0k
            out.append(op >> 5 & 0x1f)
            out.append(op >> 0 & 0x1f)
            if a0d is not None:
                out.append(a0d)
        else:
            print('FUCK', op, args)


strpool = {}

for s in sorted(strs):
    strpool[s] = len(out)
    for x in s:
        out.append(x)

for a, b in ranges:
    diff = labels[a] + b
    if diff not in range(-0x200, 0x200):
        print('FUCK', a, b)
        raise ValueError

with open(sys.argv[2], 'w') as f:
    for x in out:
        if not isinstance(x, int):
            x = x.resolve()
        if x not in range(0x20):
            raise ValueError(x)
        f.write(f'{x:05b}')
