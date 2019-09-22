#include <termios.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <sys/random.h>

char flag[1024];

unsigned regs[4];
unsigned code[0x8000];
unsigned data[0x400];
unsigned pc;
unsigned sp;
bool cf;
bool zf;

unsigned op_kind[2];
unsigned op_data[2];

bool fig = false;

void init() {
        struct termios tio;
        tcgetattr(fileno(stdin), &tio);
        tio.c_lflag &= ~(ECHO|ICANON);
        tcsetattr(fileno(stdin), TCSANOW, &tio);
}

void end() {
        struct termios tio;
        tcgetattr(fileno(stdin), &tio);
        tio.c_lflag |= (ECHO|ICANON);
        tcsetattr(fileno(stdin), TCSANOW, &tio);
}

unsigned pop() {
	unsigned res = data[sp];
	sp += 1;
	sp &= 0x3ff;
	return res;
}

void push(unsigned val) {
	sp -= 1;
	sp &= 0x3ff;
	data[sp] = val;
}

void parse_op(int which, int kind) {
	op_kind[which] = kind;
	if (kind == 4 || kind == 5) {
		op_data[which] = code[pc];
		pc += 1;
		pc &= 0x7fff;
	}
}

unsigned read_op(int which) {
	unsigned kind = op_kind[which];
	if (kind < 4) {
		return regs[kind];
	} else if (kind == 4) {
		return op_data[which];
	} else if (kind == 5) {
		return data[op_data[which]];
	} else if (kind == 6) {
		unsigned addr = regs[0] | regs[1] << 5;
		return data[addr];
	} else if (kind == 7) {
		unsigned addr = regs[0] | regs[1] << 5 | regs[2] << 10;
		return code[addr];
	}
}

void write_op(int which, unsigned val) {
	unsigned kind = op_kind[which];
	if (kind < 4) {
		regs[kind] = val;
	} else if (kind == 5) {
		data[op_data[which]] = val;
	} else if (kind == 6) {
		unsigned addr = regs[0] | regs[1] << 5;
		data[addr] = val;
	} else if (kind == 7) {
		unsigned addr = regs[0] | regs[1] << 5 | regs[2] << 10;
		code[addr] = val;
	}
}

const char lettab[] = "\0AE\rYUIO\0JGHBCFD \nXZSTWV\0KMLRQNP";
const char figtab[] = "\0""12\r34\0""5 67+89\0""0\0\n,:.\0?'\0()=-/\0%";

unsigned mygetc() {
	while (1) {
		int c = getchar();
		if (c == EOF) {
			end();
			exit(1);
		}
		if (!isalpha(c))
			continue;
		c = toupper(c);
		for (int i = 0; i < 0x20; i++)
			if (lettab[i] == c)
				return i;
	}
}

void myputc(unsigned chr) {
	if (fig) {
		if (chr == 0x10)
			fig = false;
		else if (figtab[chr])
			putchar(figtab[chr]);
	} else {
		if (chr == 0x08)
			fig = true;
		else if (lettab[chr])
			putchar(lettab[chr]);
	}
}

unsigned rnd() {
	char res;
	if (getrandom(&res, 1, 0) != 1) {
		perror("getrandom");
		abort();
	}
	return res & 0x1f;
}

int main(int argc, char **argv) {
	setvbuf(stdin, NULL, _IONBF, 0);
	setvbuf(stdout, NULL, _IONBF, 0);
	if (argc != 3) {
		printf("usage: ./emu game.bin flag.txt\n");
		return 1;
	}
	FILE *ff = fopen(argv[2], "r");
	if (!ff) {
		perror("fopen");
		return 1;
	}
	fscanf(ff, "%1023s", flag);
	fclose(ff);
	FILE *f = fopen(argv[1], "r");
	if (!f) {
		perror("fopen");
		return 1;
	}
	int i = 0;
	while (1) {
		char a[5];
		if (fread(a, 5, 1, f) != 1)
			break;
		int n = 0;
		for (int j = 0; j < 5; j++) {
			if (a[j] == '0') {
			} else if (a[j] == '1') {
				n |= 1 << (4-j);
			} else {
				printf("FUCK\n");
				return 1;
			}
		}
		code[i++] = n;
		if (i == 0x8000) {
			printf("FUCK\n");
			return 1;
		}
	}
	init();
	while (1) {
		unsigned opb[4];
		for (i = 0; i < 4; i++) {
			opb[i] = code[pc+i & 0x7fff];
		}
		//printf("%04x %02x %02x %02x %02x\n", pc, opb[0], opb[1], opb[2], opb[3]);
		if (opb[0] < 0x18) {
			// ALU
			pc += 2;
			pc &= 0x7fff;
			parse_op(0, opb[1] & 7);
			parse_op(1, (opb[1] >> 3) | (opb[0] << 2 & 4));
			unsigned a0 = read_op(0);
			unsigned a1 = read_op(1);
			unsigned res = 0;
			int subop = opb[0] >> 1;
			if (subop < 2) {
				// ADD & ADC
				if (subop == 0)
					cf = false;
				res = a0 + a1 + cf;
				cf = !!(res & 0x20);
			} else if (subop < 4) {
				// SUB & SBB
				if (subop == 2)
					cf = false;
				res = a0 - a1 - cf;
				cf = !!(res & 0x20);
			} else if (subop == 4) {
				// AND
				res = a0 & a1;
			} else if (subop == 5) {
				// OR
				res = a0 | a1;
			} else if (subop == 6) {
				// XOR
				res = a0 ^ a1;
			} else if (subop == 7) {
				// MOV
				res = a1;
			} else if (subop == 8) {
				// SHL
				res = a1 << 1;
				cf = a1 >> 4;
			} else if (subop == 9) {
				// RCL
				res = a1 << 1 | cf;
				cf = a1 >> 4;
			} else if (subop == 0xa) {
				// SHR
				res = a1 >> 1;
				cf = a1 & 1;
			} else if (subop == 0xb) {
				// RCR
				res = a1 >> 1 | cf << 4;
				cf = a1 & 1;
			}
			res &= 0x1f;
			if (subop != 7)
				zf = res == 0;
			write_op(0, res);
		} else if (opb[0] < 0x1a) {
			// CALL / JMP
			pc += 4;
			pc &= 0x7fff;
			if (opb[0] == 0x19) {
				push(pc >> 10 & 0x1f);
				push(pc >> 5 & 0x1f);
				push(pc >> 0 & 0x1f);
			}
			pc = opb[1] | opb[2] << 5 | opb[3] << 10;
		} else if (opb[0] == 0x1a) {
			// BRANCH
			pc += 4;
			unsigned fl = zf | cf << 1;
			if (opb[1] & 1 << fl) {
				int diff = opb[2] | opb[3] << 5;
				if (diff & 0x200)
					diff |= 0x7c00;
				pc += diff;
			}
			pc &= 0x7fff;
		} else if (opb[0] == 0x1b) {
			// RET
			pc = 0;
			pc |= pop();
			pc |= pop() << 5;
			pc |= pop() << 10;
		} else if (opb[0] == 0x1c) {
			// LOSE
			end();
			return 0;
		} else if (opb[0] == 0x1d) {
			// WIN
#if 0
			for (i = 0 ; i < 0x400; i++) {
				printf("%03x %02x\n", i, data[i]);
			}
#endif
			printf("%s\n", flag);
			pc += 1;
			pc &= 0x7fff;
		} else {
			// MISC single-op
			pc += 2;
			pc &= 0x7fff;
			parse_op(0, opb[1] & 7);
			int subop = (opb[1] >> 3) | (opb[0] << 2 & 4);
			if (subop == 0) {
				push(read_op(0));
			} else if (subop == 1) {
				write_op(0, pop());
			} else if (subop == 2) {
				myputc(read_op(0));
			} else if (subop == 3) {
				write_op(0, mygetc());
			} else if (subop == 4) {
				write_op(0, rnd());
			}
		}
	}
}
