The machine has 5-bit bytes.

The character encoding used is Baudot (ITA 1).

The machine has the following registers and memories:

- `0x8000`-byte code segment (with 5-bit bytes).
- `0x400`-byte data segment (with 5-bit bytes).
- `PC`: 15-bit program counter, pointing at the current instruction in the code segment.  Starts at 0.
- `SP`: 10-bit stack pointer, pointing at the last pushed byte.  Starts at 0.  The stack grows down.
- `R0-R3`: four 5-bit general purpose registers.
- `ZF` and `CF`: two single-bit condition code flags.

The instructions are variable-size.  The first byte of the instruction selects
the opcode as follows:

- `0x00-0x17`: ALU opcodes
- `0x18`: JMP (absolute unconditional jump) — the next 3 bytes are target address, little endian.
- `0x19`: CALL (absolute subroutine call) — the next 3 bytes are target address, little endian.
- `0x1a`: branches (relative conditional jumps)
- `0x1b`: RET (single-byte) — returns from a subroutine
- `0x1c`: LOSE (single-byte) — ends the game, halts the CPU
- `0x1d`: WIN (single-byte) — prints the flag
- `0x1e-0x1f`: MISC opcodes

For subroutine calls, the addresses are stored on the stack as 15-bit little-endian numbers (ie. lowest byte of the return address is at the lowest position).

The branch instructions have the following format:

- the opcode byte (`0x1a`)
- the condition code byte
- two-byte little-endian signed distance from the end of branch instruction to the target

The condition codes are as follows:

- `0x0`: never
- `0x1`: `!ZF && !CF`
- `0x2`: `ZF && !CF`
- `0x3`: `!CF`
- `0x4`: `!ZF && CF`
- `0x5`: `!ZF`
- `0x6`: `ZF ^ CF`
- `0x7`: `!ZF || !CF`
- `0x8`: `ZF && CF`
- `0x9`: `!(ZF ^ CF)`
- `0xa`: `ZF`
- `0xb`: `ZF || !CF`
- `0xc`: `CF`
- `0xd`: `!ZF || CF`
- `0xe`: `ZF || CF`
- `0xf`: always

The ALU instructions have the following format:

- first byte:

  - bit 0: bit 2 of source type
  - bits 1-4: ALU opcode

    - `0x0`: ADD
    - `0x1`: ADC (add with carry)
    - `0x2`: SUB
    - `0x3`: SBB (subtract with borrow)
    - `0x4`: AND
    - `0x5`: OR
    - `0x6`: XOR
    - `0x7`: MOV
    - `0x8`: SHL (MOS 6502-style: `destination = source << 1`)
    - `0x9`: RCL (`destination = source << 1 | CF`)
    - `0xa`: SHR (`destination = source >> 1`)
    - `0xb`: RCR (`destination = source >> 1 | CF << 4`)

- second byte:

  - bits 0-2: destination type, one of:

    - `0`: `R0`
    - `1`: `R1`
    - `2`: `R2`
    - `3`: `R3`
    - `4`: immediate value, stored in the following byte (if used as destination, writes are ignored)
    - `5`: zero-page data cell, MOS 6502-style — the following byte contains the address of a data segment cell to be accessed (can only address the first 32 bytes)
    - `6`: data segment indirect addressing — accesses data segment at address `R1:R0` (low bits of address in R0, high bits of address in R1)
    - `7`: code segment indirect addressing — accesses code segment at address `R2:R1:R0` (low bits in R0, middle bits in R1, high bits in R2)

  - bits 3-4: bits 0-1 of source type (same enum as source type)

- (optional) destination immediate value or RAM address byte (if destination type is 4 or 5)
- (optional) source immediate value or RAM address byte (if source type is 4 or 5)

For all ALU opcodes, ZF is set iff the result is 0.  For ADD and ADC opcodes, CF is set
iff the addition generated carry.  For SUB and SBB, it is set iff subtract generated borrow.
For the shift opcodes, it is set to the value of the shifted-out bit.  For logic and MOV opcodes,
it is unchanged (but MOV still sets ZF).

There are no CMP or TEST opcodes, but comparisons/tests with immediate values can be done easily by
using the immediate value as destination — the result will be discarded in this case.

The MISC instructions have the following format:

- first byte:

  - bit 0: bit 2 of MISC opcode
  - bits 1-4: `0xf` (selects MISC opcode)

- second byte:

  - bits 0-2: argument type, same as in ALU instructions
  - bits 3-4: bits 0-1 of MISC opcode

- (optional) argument immediate value or RAM address byte (if argument type is 4 or 5)

The MISC opcodes are as follows:

- `0`: PUSH (pushes a single byte on the stack)
- `1`: POP (pushes a single byte on the stack)
- `2`: PUTC (outputs a Baudot character to screen)
- `3`: GETC (gets a Baudot character from keyboard)
- `4`: RNG (generates a true random byte to seed the PRNG)
