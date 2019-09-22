all: emu game.bin

emu: emu.c
	cc emu.c -o emu

game.bin: asm.py game.asm
	python3 asm.py game.asm game.bin

clean:
	rm -f game.bin emu
