CONST valis,	1
CONST redford,	2
CONST redbull,	3
CONST rum,	4
CONST gin,	5
CONST tequila,	6
CONST jagermeister,	7
CONST baileys,	8
CONST coca_cola,	9
CONST tonic,	10
CONST orange,	11
CONST grenadine,	12
CONST milk,	13
CONST pigwowka,	14
CONST invsz,	15

CONST dir_s,	1
CONST dir_n,	2
CONST dir_e,	4
CONST dir_w,	8

DATA cache_cur, 1
DATA cache_dir, 1
DATA valis_state, 1
DATA redford_state, 1
DATA pos,	2
DATA hp,	2
DATA monster_hp,	2
DATA cheater,	1
DATA lfsr,	3
DATA dig,	4
DATA inv,	invsz
DATA board,	64

CONST drunk, inv

start:
	CALL	init
	main_loop:
	CALL	cache
	CALL	menu
	CALL	main_cmd
	B	main_loop

menu:
	CALL	print_space_desc
	LPTR	"SELECT AN OPTION:\r\n\r\n"
	CALL	print_str
	CALL	menu_dirs
	CALL	menu_space_cmds
	CALL	menu_misc
	LPTR	"\r\nYOUR CHOICE: "
	CALL	print_str
	RET

menu_dirs:
	AND	dir_s, [cache_dir]
	BZ	menu_dirs_no_s
	LPTR	"- GO (S)OUTH\r\n"
	CALL	print_str
	menu_dirs_no_s:
	AND	dir_n, [cache_dir]
	BZ	menu_dirs_no_n
	LPTR	"- GO (N)ORTH\r\n"
	CALL	print_str
	menu_dirs_no_n:
	AND	dir_e, [cache_dir]
	BZ	menu_dirs_no_e
	LPTR	"- GO (E)AST\r\n"
	CALL	print_str
	menu_dirs_no_e:
	AND	dir_w, [cache_dir]
	BZ	menu_dirs_no_w
	LPTR	"- GO (W)EST\r\n"
	CALL	print_str
	menu_dirs_no_w:
	RET

menu_space_cmds:
	ADD	0, [cache_cur]
	BZ	menu_space_cmds_no_fight
	SUB	redford, [cache_cur]
	BC	menu_space_cmds_no_talk
	LPTR	"- (T)ALK TO "
	CALL	print_str
	CALL	print_the_monster
	CALL	print_nl
	menu_space_cmds_no_talk:
	SUB	valis, [cache_cur]
	BZ	menu_space_cmds_no_fight
	LPTR	"- (F)IGHT "
	CALL	print_str
	CALL	print_the_monster
	CALL	print_nl
	menu_space_cmds_no_fight:
	RET

menu_misc:
	LPTR	"- (D)RINK\r\n"
	CALL	print_str
	LPTR	"- SHOW (I)NVENTORY\r\n"
	CALL	print_str
	RET

cache:
	MOV	R0, [pos]
	MOV	R1, [pos+1]
	ADD	R0, LO board
	ADC	R1, MID board
	MOV	[cache_cur], DATA
	MOV	[cache_dir], 0
	MOV	R0, [pos]
	AND	R0, 7
	BZ	cache_no_w
	OR	[cache_dir], dir_w
	cache_no_w:
	SUB	7, R0
	BZ	cache_no_e
	OR	[cache_dir], dir_e
	cache_no_e:
	MOV	R0, [pos]
	MOV	R1, [pos+1]
	SHR	R1, R1
	RCR	R0, R0
	SHR	R1, R1
	RCR	R0, R0
	SHR	R1, R1
	RCR	R0, R0
	AND	R0, 7
	BZ	cache_no_s
	OR	[cache_dir], dir_s
	cache_no_s:
	SUB	7, R0
	BZ	cache_no_n
	OR	[cache_dir], dir_n
	cache_no_n:
	RET

main_cmd:
	GETC	R0
	PUTC	R0
	MOV	R1, 0
	MOV	R2, 0
	SHL	R0, R0
	RCL	R1, R1
	SHL	R0, R0
	RCL	R1, R1
	ADD	R0, LO jtab_main_cmd
	ADC	R1, MID jtab_main_cmd
	ADC	R2, HI jtab_main_cmd
	PUSH	R2
	PUSH	R1
	PUSH	R0
	RET

jtab_main_cmd:
	JMP	main_cmd_invalid
	JMP	main_cmd_invalid
	JMP	main_cmd_east
	JMP	main_cmd_invalid
	JMP	main_cmd_invalid
	JMP	main_cmd_invalid
	JMP	main_cmd_inventory
	JMP	main_cmd_invalid
	JMP	main_cmd_invalid
	JMP	main_cmd_invalid
	JMP	main_cmd_invalid
	JMP	main_cmd_invalid
	JMP	main_cmd_invalid
	JMP	main_cmd_invalid
	JMP	main_cmd_fight
	JMP	main_cmd_drink
	JMP	main_cmd_invalid
	JMP	main_cmd_invalid
	JMP	main_cmd_invalid
	JMP	main_cmd_invalid
	JMP	main_cmd_south
	JMP	main_cmd_talk
	JMP	main_cmd_west
	JMP	main_cmd_invalid
	JMP	main_cmd_invalid
	JMP	main_cmd_invalid
	JMP	main_cmd_invalid
	JMP	main_cmd_invalid
	JMP	main_cmd_invalid
	JMP	main_cmd_invalid
	JMP	main_cmd_north
	JMP	main_cmd_invalid

main_cmd_invalid:
	LPTR	"\r\n\r\nINVALID OPTION.\r\n\r\n"
	CALL	print_str
	RET

main_cmd_south:
	AND	dir_s, [cache_dir]
	BZ	main_cmd_move_err
	SUB	[pos], 8
	SBB	[pos+1], 0
	LPTR	"\r\n\r\nYOU MOVE TO THE SOUTH.\r\n\r\n"
	CALL	print_str
	RET

main_cmd_north:
	AND	dir_n, [cache_dir]
	BZ	main_cmd_move_err
	ADD	[pos], 8
	ADC	[pos+1], 0
	LPTR	"\r\n\r\nYOU MOVE TO THE NORTH.\r\n\r\n"
	CALL	print_str
	RET

main_cmd_east:
	AND	dir_e, [cache_dir]
	BZ	main_cmd_move_err
	ADD	[pos], 1
	LPTR	"\r\n\r\nYOU MOVE TO THE EAST.\r\n\r\n"
	CALL	print_str
	RET

main_cmd_west:
	AND	dir_w, [cache_dir]
	BZ	main_cmd_move_err
	SUB	[pos], 1
	LPTR	"\r\n\r\nYOU MOVE TO THE WEST.\r\n\r\n"
	CALL	print_str
	RET

main_cmd_move_err:
	LPTR	"\r\n\r\nYOU CANNOT MOVE IN THAT DIRECTION.\r\n\r\n"
	CALL	print_str
	RET

main_cmd_inventory:
	LPTR	"\r\n\r\nYOUR INVENTORY:\r\n\r\n"
	CALL	print_str
	MOV	R0, 1
	inv_loop:
	PUSH	R0
	MOV	R1, 0
	ADD	R0, inv
	ADC	R1, 0
	ADD	0, DATA
	BZ	inv_skip
	PUSH	DATA
	LPTR	"- "
	CALL	print_str
	POP	R0
	POP	R3
	PUSH	R3
	PUSH	R0
	LPTR	stab_item
	CALL	print_from_tab
	LPTR	" ("
	CALL	print_str
	POP	R0
	MOV	R1, 0
	CALL	print_num
	LPTR	")\r\n"
	CALL	print_str
inv_skip:
	POP	R0
	ADD	R0, 1
	SUB	invsz, R0
	BNZ	inv_loop
	LPTR	"\r\n"
	CALL	print_str
	CALL	print_health
	ADD	0, [drunk]
	BZ	inv_no_drunk
	SUB	2, [drunk]
	BC	inv_very_drunk
	LPTR	"YOU ARE DRUNK.\r\n"
	CALL	print_str
	B	inv_no_drunk
inv_very_drunk:
	LPTR	"YOU ARE VERY DRUNK.\r\n"
	CALL	print_str
inv_no_drunk:
	LPTR	"\r\n"
	CALL	print_str
	RET

main_cmd_drink:
	LPTR	"\r\n\r\nCHOOSE AN ITEM TO DRINK:\r\n\r\n"
	CALL	print_str

	ADD	0, [inv+valis]
	BZ	drink_no_valis
	LPTR	"- WALIZKA (V)ALISA\r\n"
	CALL	print_str
drink_no_valis:

	ADD	0, [inv+redbull]
	BZ	drink_no_redbull
	LPTR	"- CAN OF (R)EDBULL\r\n"
	CALL	print_str
drink_no_redbull:

	ADD	0, [inv+rum]
	BZ	drink_no_rum
	LPTR	"- BOTTLE OF R(U)M\r\n"
	CALL	print_str
drink_no_rum:

	ADD	0, [inv+gin]
	BZ	drink_no_gin
	LPTR	"- BOTTLE OF (G)IN\r\n"
	CALL	print_str
drink_no_gin:

	ADD	0, [inv+tequila]
	BZ	drink_no_tequila
	LPTR	"- BOTTLE OF (T)EQUILA\r\n"
	CALL	print_str
drink_no_tequila:

	ADD	0, [inv+jagermeister]
	BZ	drink_no_jager
	LPTR	"- BOTTLE OF (J)AGERMEISTER\r\n"
	CALL	print_str
drink_no_jager:

	ADD	0, [inv+baileys]
	BZ	drink_no_baileys
	LPTR	"- BOTTLE OF (B)AILEYS\r\n"
	CALL	print_str
drink_no_baileys:

	ADD	0, [inv+coca_cola]
	BZ	drink_no_cola
	LPTR	"- BOTTLE OF (C)OCA-COLA\r\n"
	CALL	print_str
drink_no_cola:

	ADD	0, [inv+tonic]
	BZ	drink_no_tonic
	LPTR	"- BOTTLE OF TO(N)IC\r\n"
	CALL	print_str
drink_no_tonic:

	ADD	0, [inv+orange]
	BZ	drink_no_orange
	LPTR	"- CARTON OF (O)RANGE JUICE\r\n"
	CALL	print_str
drink_no_orange:

	ADD	0, [inv+grenadine]
	BZ	drink_no_grenadine
	LPTR	"- GRENADINE (S)YRUP\r\n"
	CALL	print_str
drink_no_grenadine:

	ADD	0, [inv+milk]
	BZ	drink_no_milk
	LPTR	"- CARTON OF (M)ILK\r\n"
	CALL	print_str
drink_no_milk:

	LPTR	"\r\nYOUR CHOICE: "
	CALL	print_str

	GETC	R0
	PUTC	R0
	CALL	print_nl
	CALL	print_nl

	MOV	R1, 0
	MOV	R2, 0
	SHL	R0, R0
	RCL	R1, R1
	SHL	R0, R0
	RCL	R1, R1
	ADD	R0, LO jtab_drink
	ADC	R1, MID jtab_drink
	ADC	R2, HI jtab_drink
	PUSH	R2
	PUSH	R1
	PUSH	R0
	RET

jtab_drink:
	JMP	drink_invalid
	JMP	drink_invalid
	JMP	drink_invalid
	JMP	drink_invalid
	JMP	drink_invalid
	JMP	drink_rum
	JMP	drink_invalid
	JMP	drink_orange
	JMP	drink_invalid
	JMP	drink_jagermeister
	JMP	drink_gin
	JMP	drink_invalid
	JMP	drink_baileys
	JMP	drink_coca_cola
	JMP	drink_invalid
	JMP	drink_invalid
	JMP	drink_invalid
	JMP	drink_invalid
	JMP	drink_invalid
	JMP	drink_invalid
	JMP	drink_grenadine
	JMP	drink_tequila
	JMP	drink_invalid
	JMP	drink_valis
	JMP	drink_invalid
	JMP	drink_invalid
	JMP	drink_milk
	JMP	drink_invalid
	JMP	drink_redbull
	JMP	drink_invalid
	JMP	drink_tonic
	JMP	drink_invalid

drink_invalid:
	LPTR	"INVALID CHOICE.\r\n\r\n"
	CALL	print_str
	RET

drink_rum:
	ADD	0, [inv+rum]
	BZ	drink_invalid
	LPTR	"YOU DRINK A BOTTLE OF RUM.\r\n"
	CALL	print_str
	SUB	[inv+rum], 1
	JMP	drink_alcohol

drink_tequila:
	ADD	0, [inv+tequila]
	BZ	drink_invalid
	LPTR	"YOU DRINK A BOTTLE OF TEQUILA.\r\n"
	CALL	print_str
	SUB	[inv+tequila], 1
	JMP	drink_alcohol

drink_gin:
	ADD	0, [inv+gin]
	BZ	drink_invalid
	LPTR	"YOU DRINK A BOTTLE OF GIN.\r\n"
	CALL	print_str
	SUB	[inv+gin], 1
	JMP	drink_alcohol

drink_jagermeister:
	ADD	0, [inv+jagermeister]
	BZ	drink_invalid
	LPTR	"YOU DRINK A BOTTLE OF JAEGERMEISTER.\r\n"
	CALL	print_str
	SUB	[inv+jagermeister], 1
	JMP	drink_alcohol

drink_baileys:
	ADD	0, [inv+baileys]
	BZ	drink_invalid
	LPTR	"YOU DRINK A BOTTLE OF BAILEYS.\r\n"
	CALL	print_str
	SUB	[inv+baileys], 1
	JMP	drink_alcohol

drink_alcohol:
	ADD	0, [drunk]
	BNZ	drink_more
	LPTR	"YOU GET DRUNK.\r\n\r\n"
	CALL	print_str
	B	drink_end
drink_more:
	LPTR	"YOU GET EVEN MORE DRUNK.\r\n\r\n"
	CALL	print_str
drink_end:
	ADD	[drunk], 1
	RET

drink_orange:
	ADD	0, [inv+orange]
	BZ	drink_invalid
	LPTR	"YOU DRINK A CARTON OF ORANGE JUICE.\r\n\r\n"
	CALL	print_str
	SUB	[inv+orange], 1
	RET

drink_milk:
	ADD	0, [inv+milk]
	BZ	drink_invalid
	LPTR	"YOU DRINK A CARTON OF MILK.\r\n\r\n"
	CALL	print_str
	SUB	[inv+milk], 1
	RET

drink_tonic:
	ADD	0, [inv+tonic]
	BZ	drink_invalid
	LPTR	"YOU DRINK A BOTTLE OF TONIC.\r\n\r\n"
	CALL	print_str
	SUB	[inv+tonic], 1
	RET

drink_coca_cola:
	ADD	0, [inv+coca_cola]
	BZ	drink_invalid
	LPTR	"YOU DRINK A BOTTLE OF COCA-COLA.\r\n\r\n"
	CALL	print_str
	SUB	[inv+coca_cola], 1
	RET

drink_grenadine:
	ADD	0, [inv+grenadine]
	BZ	drink_invalid
	LPTR	"YOU DRINK A BOTTLE OF GRENADINE SYRUP.  EW.\r\n\r\n"
	CALL	print_str
	SUB	[inv+grenadine], 1
	RET

drink_valis:
	ADD	0, [inv+valis]
	BZ	drink_invalid
	LPTR	"YOU DRINK EVERYTHING FOUND INSIDE WALIZKA VALISA.  YOU DIE OF ALCOHOL POISONING...\r\n"
	CALL	print_str
	LOSE

drink_redbull:
	ADD	0, [inv+redbull]
	BZ	drink_invalid
	LPTR	"YOU DRINK A CAN OF REDBULL.  YOU FEEL MUCH BETTER.\r\n\r\n"
	CALL	print_str
	SUB	[inv+redbull], 1
	ADD	[hp], LO 100
	ADC	[hp+1], MID 100
	RET

fight_nothing:
	LPTR	"\r\n\r\nTHERE IS NOTHING HERE TO FIGHT.\r\n\r\n"
	CALL	print_str
	RET
main_cmd_fight:
	ADD	0, [cache_cur]
	BZ	fight_nothing
	LPTR	"\r\n\r\nYOU ATTACK "
	CALL	print_str
	CALL	print_the_monster
	SUB	pigwowka, [cache_cur]
	BZ	fight_pigwowka
	LPTR	".\r\n\r\n"
	CALL	print_str
	MOV	[monster_hp], LO 100
	MOV	[monster_hp+1], MID 100
fight_loop:
	LPTR	"SELECT AN OPTION:\r\n\r\n"
	LPTR	"- (A)TTACK\r\n"
	CALL	print_str
	LPTR	"- USE (S)HIELD\r\n"
	CALL	print_str
	LPTR	"- (C)HEAT\r\n"
	CALL	print_str
	LPTR	"\r\nYOUR CHOICE: "
	CALL	print_str
	GETC	R0
	PUTC	R0
	SUB	1, R0
	BZ	fight_attack
	SUB	0x0d, R0
	BZ	fight_cheat
	SUB	0x14, R0
	BZ	fight_shield
	LPTR	"\r\n\r\nINVALID OPTION.\r\n\r\n"
	CALL	print_str
	B	fight_loop
fight_pigwowka:
	LPTR	".  HE SEEMS TO BE TOO DRUNK TO EVEN NOTICE.\r\n"
	CALL	print_str
	B	fight_item
fight_cheat:
	MOV	[hp], LO 1000
	MOV	[hp+1], MID 1000
	MOV	[cheater], 1
	LPTR	"\r\n\r\nCURRENT HEALTH: 1000%.\r\n\r\n"
	CALL	print_str
	B	fight_loop
fight_attack:
	CALL	rnd
	SUB	0x10, R0
	BA	fight_you_hit
	LPTR	"\r\n\r\nYOU ATTACK "
	CALL	print_str
	CALL	print_the_monster
	LPTR	", BUT MISS.\r\n"
	CALL	print_str
	B	fight_monster_attack
fight_you_hit:
	ADD	R0, 1
	SUB	[monster_hp], R0
	SBB	[monster_hp+1], 0
	BC	fight_you_kill
	MOV	R0, [monster_hp]
	OR	R0, [monster_hp+1]
	BZ	fight_you_kill
	LPTR	"\r\n\r\nYOU HIT "
	CALL	print_str
	CALL	print_the_monster
	LPTR	".\r\n"
	CALL	print_str
	LPTR	"ENEMY HEALTH: "
	CALL	print_str
	MOV	R0, [monster_hp]
	MOV	R1, [monster_hp+1]
	CALL	print_num
	LPTR	"%\r\n"
	CALL	print_str
fight_monster_attack:
	CALL	rnd
	SUB	0x10, R0
	BA	fight_monster_hit
	CALL	print_the_monster
	LPTR	" ATTACKS YOU, BUT MISSES.\r\n\r\n"
	CALL	print_str
	B	fight_loop
fight_monster_hit:
	ADD	R0, 1
	SUB	[hp], R0
	SBB	[hp+1], 0
	BC	fight_you_die
	MOV	R0, [hp]
	OR	R0, [hp+1]
	BZ	fight_you_die
	CALL	print_the_monster
	LPTR	" HITS YOU.\r\n"
	CALL	print_str
	CALL	print_health
	LPTR	"\r\n"
	CALL	print_str
	B	fight_loop
fight_you_die:
	CALL	print_the_monster
	LPTR	" HITS YOU.  YOU DIE...\r\n"
	CALL	print_str
	LOSE
fight_shield:
	LPTR	"\r\n\r\n"
	CALL	print_str
	CALL	print_the_monster
	CALL	rnd
	SUB	0x10, R0
	BA	fight_shield_hit
	LPTR	" ATTACKS YOU, BUT MISSES.\r\n\r\n"
	CALL	print_str
	B	fight_loop
fight_shield_hit:
	LPTR	" ATTACKS YOU, BUT BOUNCES OFF YOUR SHIELD.\r\n\r\n"
	CALL	print_str
	B	fight_loop
fight_you_kill:
	LPTR	"\r\n\r\nYOU KILL "
	CALL	print_str
	CALL	print_the_monster
	LPTR	".\r\n"
	CALL	print_str
	SUB	valis, [cache_cur]
	BNZ	fight_no_valis
	LPTR	"YOU IDIOT.  NOW NOBODY KNOWS THE FLAG.\r\n"
	CALL	print_str
fight_no_valis:
	SUB	redford, [cache_cur]
	BNZ	fight_item
	SUB	2, [redford_state]
	BNZ	fight_item
	CALL	print_nl
	B	fight_end
fight_item:
	MOV	R0, LO inv
	MOV	R1, MID inv
	ADD	R0, [cache_cur]
	ADC	R1, 0
	ADD	DATA, 1
	LPTR	"YOU ACQUIRE AN ITEM: "
	CALL	print_str
	LPTR	stab_item
	MOV	R3, [cache_cur]
	CALL	print_from_tab
	LPTR	".\r\n\r\n"
	CALL	print_str
fight_end:
	MOV	R0, [pos]
	MOV	R1, [pos+1]
	ADD	R0, LO board
	ADC	R1, MID board
	MOV	DATA, 0
	RET
	

main_cmd_talk:
	SUB	valis, [cache_cur]
	BZ	talk_valis
	SUB	redford, [cache_cur]
	BZ	talk_redford
	LPTR	"\r\n\r\nYOU TALK TO YOURSELF.  YOU'RE NOT VERY INTERESTING.\r\n\r\n"
	CALL	print_str
	RET

talk_redford:
	LPTR	"\r\n\r\nYOU APPROACH REDFORD.\r\n\r\n"
	CALL	print_str
	MOV	R0, [redford_state]
	SHL	R0, R0
	RCL	R1, 0
	SHL	R0, R0
	RCL	R1, R1
	MOV	R2, 0
	ADD	R0, LO jtab_talk_redford
	ADC	R1, MID jtab_talk_redford
	ADC	R2, HI jtab_talk_redford
	PUSH	R2
	PUSH	R1
	PUSH	R0
	RET

talk_valis:
	LPTR	"\r\n\r\nYOU ENTER THE TAVERN AND APPROACH VALIS.\r\n\r\n"
	CALL	print_str
	MOV	R0, [valis_state]
	SHL	R0, R0
	RCL	R1, 0
	SHL	R0, R0
	RCL	R1, R1
	MOV	R2, 0
	ADD	R0, LO jtab_talk_valis
	ADC	R1, MID jtab_talk_valis
	ADC	R2, HI jtab_talk_valis
	PUSH	R2
	PUSH	R1
	PUSH	R0
	RET

jtab_talk_valis:
	JMP	valis_redbull
	JMP	valis_powerstrip
	JMP	valis_redbull
	JMP	valis_redbull
	JMP	valis_gin_tonic
	JMP	valis_redbull
	JMP	valis_jagermeister
	JMP	valis_redbull
	JMP	valis_redbull
	JMP	valis_tequila_sunrise
	JMP	valis_redbull
	JMP	valis_cuba_libre
	JMP	valis_redbull
	JMP	valis_win

valis_redbull:
	LPTR	"- HEY, I WAS WONDERING IF YOU COULD HELP ME FIND THE FLAG?\r\n"
	CALL	print_str
	LPTR	"- THE FLAG?  MAYBE, BUT FIRST, I NEED A REDBULL.\r\n"
	CALL	print_str
	ADD	0, [inv+redbull]
	BZ	valis_no_redbull
	SUB	[inv+redbull], 1
	ADD	[valis_state], 1
	LPTR	"\r\nYOU GIVE VALIS A REDBULL.  VALIS DRINKS IT IN ONE GO.\r\n\r\n"
	CALL	print_str
	RET
valis_no_redbull:
	LPTR	"- I... I DON'T HAVE A REDBULL.\r\n"
	CALL	print_str
	LPTR	"- WELL THEN, MAKE YOURSELF USEFUL AND FIND ONE.\r\n"
	CALL	print_str
	CALL	print_nl
	RET

valis_powerstrip:
	ADD	0, [inv+redford]
	BZ	valis_no_powerstrip
	LPTR	"YOU GIVE VALIS A POWER STRIP.  VALIS CONNECTS HIS LAPTOP.\r\n"
	CALL	print_str
	CALL	print_nl
	SUB	[inv+redford], 1
	ADD	[valis_state], 1
	RET
valis_no_powerstrip:
	LPTR	"- SO, CAN I GET THE FLAG NOW?\r\n"
	CALL	print_str
	LPTR	"- FLAG?  I CANNOT GIVE YOU ANY FLAGS WITHOUT POWER FOR MY LAPTOP.  GO FIND REDFORD AND GET A POWER STRIP FROM HIM.\r\n"
	CALL	print_str
	CALL	print_nl
	MOV	[redford_state], 1
	RET

valis_gin_tonic:
	LPTR	"- HEY, I WAS WONDERING IF YOU COULD HELP ME FIND THE FLAG?\r\n"
	CALL	print_str
	LPTR	"- THE FLAG?  MAYBE, BUT FIRST, I NEED A GIN AND TONIC.\r\n"
	CALL	print_str
	ADD	0, [inv+gin]
	BZ	valis_no_gin_tonic
	ADD	0, [inv+tonic]
	BZ	valis_no_gin_tonic
	SUB	[inv+gin], 1
	SUB	[inv+tonic], 1
	ADD	[valis_state], 1
	LPTR	"\r\nYOU GIVE VALIS A GIN AND TONIC.  VALIS DRINKS IT IN ONE GO.\r\n\r\n"
	CALL	print_str
	RET
valis_no_gin_tonic:
	LPTR	"- I... I DON'T HAVE THE INGREDIENTS FOR GIN AND TONIC.\r\n"
	CALL	print_str
	LPTR	"- WELL THEN, MAKE YOURSELF USEFUL AND FIND THEM.\r\n"
	CALL	print_str
	CALL	print_nl
	RET

valis_tequila_sunrise:
	LPTR	"- HEY, I WAS WONDERING IF YOU COULD HELP ME FIND THE FLAG?\r\n"
	CALL	print_str
	LPTR	"- THE FLAG?  MAYBE, BUT FIRST, I NEED A TEQUILA SUNRISE.\r\n"
	CALL	print_str
	ADD	0, [inv+tequila]
	BZ	valis_no_tequila_sunrise
	ADD	0, [inv+orange]
	BZ	valis_no_tequila_sunrise
	ADD	0, [inv+grenadine]
	BZ	valis_no_tequila_sunrise
	SUB	[inv+tequila], 1
	SUB	[inv+orange], 1
	SUB	[inv+grenadine], 1
	ADD	[valis_state], 1
	LPTR	"\r\nYOU GIVE VALIS A TEQUILA SUNRISE.  VALIS DRINKS IT IN ONE GO.\r\n\r\n"
	CALL	print_str
	RET
valis_no_tequila_sunrise:
	LPTR	"- I... I DON'T HAVE THE INGREDIENTS FOR TEQUILA SUNRISE.\r\n"
	CALL	print_str
	LPTR	"- WELL THEN, MAKE YOURSELF USEFUL AND FIND THEM.\r\n"
	CALL	print_str
	CALL	print_nl
	RET

valis_jagermeister:
	LPTR	"- HEY, I WAS WONDERING IF YOU COULD HELP ME FIND THE FLAG?\r\n"
	CALL	print_str
	LPTR	"- THE FLAG?  MAYBE, BUT FIRST, I NEED A JAEGERMEISTER WITH REDBULL.\r\n"
	CALL	print_str
	ADD	0, [inv+jagermeister]
	BZ	valis_no_jagermeister
	ADD	0, [inv+redbull]
	BZ	valis_no_jagermeister
	SUB	[inv+jagermeister], 1
	SUB	[inv+redbull], 1
	ADD	[valis_state], 1
	LPTR	"\r\nYOU GIVE VALIS A JAEGERMEISTER WITH REDBULL.  VALIS DRINKS IT IN ONE GO.\r\n\r\n"
	CALL	print_str
	RET
valis_no_jagermeister:
	LPTR	"- I... I DON'T HAVE THE INGREDIENTS FOR JAEGERMEISTER WITH REDBULL.\r\n"
	CALL	print_str
	LPTR	"- WELL THEN, MAKE YOURSELF USEFUL AND FIND THEM.\r\n"
	CALL	print_str
	CALL	print_nl
	RET

valis_cuba_libre:
	LPTR	"- HEY, I WAS WONDERING IF YOU COULD HELP ME FIND THE FLAG?\r\n"
	CALL	print_str
	LPTR	"- THE FLAG?  MAYBE, BUT FIRST, I NEED A CUBA LIBRE.\r\n"
	CALL	print_str
	ADD	0, [inv+rum]
	BZ	valis_no_cuba_libre
	ADD	0, [inv+coca_cola]
	BZ	valis_no_cuba_libre
	SUB	[inv+rum], 1
	SUB	[inv+coca_cola], 1
	ADD	[valis_state], 1
	LPTR	"\r\nYOU GIVE VALIS A CUBA LIBRE.  VALIS DRINKS IT IN ONE GO.\r\n\r\n"
	CALL	print_str
	RET
valis_no_cuba_libre:
	LPTR	"- I... I DON'T HAVE THE INGREDIENTS FOR CUBA LIBRE.\r\n"
	CALL	print_str
	LPTR	"- WELL THEN, MAKE YOURSELF USEFUL AND FIND THEM.\r\n"
	CALL	print_str
	CALL	print_nl
	RET

valis_win:
	LPTR	"- FLA... THE FLAG... I'VE DONE EVERYTHING... PLEASE...\r\n"
	CALL	print_str
	ADD	0, [cheater]
	BNZ	valis_cheater
	CALL	print_str
	LPTR	"- EH.  FINE.  HERE IT IS: "
	CALL	print_str
	WIN
	CALL	print_nl
	CALL	print_nl
	RET

valis_cheater:
	LPTR	"- YES.  BUT YOU CHEATED.  YOU WILL NEVER GET THE FLAG NOW.\r\n\r\n"
	CALL	print_str
	RET

jtab_talk_redford:
	JMP	redford_hi
	JMP	redford_powerstrip
	JMP	redford_hi

redford_hi:
	LPTR	"- HI.  HOW'S IT GOING?\r\n\r\n"
	CALL	print_str
	LPTR	"REDFORD RANTS ABOUT UNTESTED CTF TASKS.\r\n"
	CALL	print_str
	CALL	print_nl
	RET

redford_powerstrip:
	LPTR	"- HI.  DO YOU HAVE A POWERSTRIP?\r\n"
	CALL	print_str
	LPTR	"- SURE.\r\n"
	CALL	print_str
	LPTR	"- OK, CAN I GET IT?  VALIS REALLY NEEDS IT.\r\n"
	CALL	print_str
	LPTR	"- ONLY IF I GET SOMETHING IN RETURN.  BAILEYS WITH MILK WOULD BE GOOD.\r\n"
	CALL	print_str
	ADD	0, [inv+baileys]
	BZ	redford_no_baileys
	ADD	0, [inv+milk]
	BZ	redford_no_baileys
	CALL	print_nl
	
	LPTR	"YOU MIX REDFORD A BAILEYS WITH MILK.  REDFORD HAPPILY GIVES YOU HIS POWER STRIP.\r\n"
	CALL	print_str
	SUB	[inv+baileys], 1
	SUB	[inv+milk], 1
	ADD	[inv+redford], 1
	MOV	[redford_state], 2
redford_no_baileys:
	CALL	print_nl
	RET


rnd:
	MOV	R0, [lfsr]
	CALL	lfsr_rot
	CALL	lfsr_rot
	CALL	lfsr_rot
	CALL	lfsr_rot
	CALL	lfsr_rot
	RET

lfsr_rot:
	MOV	R1, [lfsr]
	MOV	R2, [lfsr+1]
	MOV	R3, [lfsr+2]
	AND	R1, 0x11
	AND	R2, 0xc
	AND	R3, 0x1d
	XOR	R1, R2
	XOR	R1, R3
	SHR	R2, R1
	XOR	R1, R2
	SHR	R2, R2
	XOR	R1, R2
	SHR	R2, R2
	XOR	R1, R2
	SHR	R2, R2
	XOR	R1, R2
	SHR	R1, R1
	RCR	[lfsr+2], [lfsr+2]
	RCR	[lfsr+1], [lfsr+1]
	RCR	[lfsr+0], [lfsr+0]
	RET

init:
	MOV	[pos], 0
	MOV	[cheater], 0
	MOV	[valis_state], 0
	MOV	[redford_state], 0
	MOV	[hp], LO 100
	MOV	[hp+1], MID 100
	MOV	[drunk], 0
	init_rnd:
	RND	[lfsr]
	RND	[lfsr+1]
	RND	[lfsr+2]
	MOV	R0, [lfsr]
	OR	R0, [lfsr+1]
	OR	R0, [lfsr+2]
	BZ	init_rnd
	MOV	R0, LO inv
	MOV	R1, MID inv
	MOV	R2, invsz
	init_inv_loop:
	MOV	DATA, 0
	ADD	R0, 1
	ADC	R1, 0
	SUB	R2, 1
	BNZ	init_inv_loop

	MOV	R0, LO board
	MOV	R1, MID board
	MOV	R2, 0
	MOV	R3, 2
clear_board_loop:
	MOV	DATA, 0
	ADD	R0, 1
	ADC	R1, 0
	SUB	R2, 1
	SBB	R3, 0
	BNZ	clear_board_loop
	ADD	0, R2
	BNZ	clear_board_loop

	MOV	R0, LO board
	MOV	R1, MID board
	MOV	DATA, valis

	LPTR	init_board_tab
init_board_loop:
	MOV	R3, CODE
	ADD	0, R3
	BZ	init_end
	ADD	R0, 1
	ADC	R1, 0
	ADC	R2, 0
	PUSH	R0
	PUSH	R1
	PUSH	R2
	PUSH	R3
init_board_rnd_loop:
	CALL	rnd
	PUSH	R0
	CALL	rnd
	POP	R1
	AND	R1, 1
	ADD	R0, LO board
	ADC	R1, MID board
	ADD	0, DATA
	BNZ	init_board_rnd_loop
	POP	DATA
	POP	R2
	POP 	R1
	POP	R0
	B	init_board_loop
init_end:
	RET

# BL:AH:AL string
print_str:
	SUB	0, CODE
	BZ	printstr_ret
	PUTC	CODE
	ADD	R0, 1
	ADC	R1, 0
	ADC	R2, 0
	B	print_str
	printstr_ret:
	RET

print_nl:
	PUTC	0x03
	PUTC	0x11
	RET

print_the_monster:
	LPTR	stab_the_monster
	MOV	R3, [cache_cur]
	JMP	print_from_tab

print_space_desc:
	LPTR	stab_space_desc
	MOV	R3, [cache_cur]
	JMP	print_from_tab

print_from_tab:
	PUSH	R2
	PUSH	R1
	MOV	R1, R3
	SHL	R2, R3
	RCL	R3, 0
	ADD	R2, R1
	ADC	R3, 0
	POP	R1
	ADD	R0, R2
	ADC	R1, R3
	POP	R2
	ADC	R2, 0
	PUSH	CODE
	ADD	R0, 1
	ADC	R1, 0
	ADC	R2, 0
	PUSH	CODE
	ADD	R0, 1
	ADC	R1, 0
	ADC	R2, 0
	MOV	R2, CODE
	POP	R1
	POP	R0
	JMP	print_str

print_health:
	LPTR	"CURRENT HEALTH: "
	CALL	print_str
	MOV	R0, [hp]
	MOV	R1, [hp+1]
	CALL	print_num
	LPTR	"%\r\n"
	CALL	print_str
	RET

print_num:
	MOV	[dig], 0
	MOV	[dig+1], 0
	MOV	[dig+2], 0
	MOV	[dig+3], 0

print_num_loop_3:
	SUB	MID 1000, R1
	BC	print_num_loop_3_yes
	BA	print_num_loop_2
	SUB	LO 1000, R0
	BA	print_num_loop_2
print_num_loop_3_yes:
	SUB	R0, LO 1000
	SBB	R1, MID 1000
	ADD	[dig+3], 1
	B	print_num_loop_3

print_num_loop_2:
	SUB	MID 100, R1
	BC	print_num_loop_2_yes
	BA	print_num_loop_1
	SUB	LO 100, R0
	BA	print_num_loop_1
print_num_loop_2_yes:
	SUB	R0, LO 100
	SBB	R1, MID 100
	ADD	[dig+2], 1
	B	print_num_loop_2

print_num_loop_1:
	SUB	MID 10, R1
	BC	print_num_loop_1_yes
	BA	print_num_loop_0
	SUB	LO 10, R0
	BA	print_num_loop_0
print_num_loop_1_yes:
	SUB	R0, LO 10
	SBB	R1, MID 10
	ADD	[dig+1], 1
	B	print_num_loop_1

print_num_loop_0:
	MOV	[dig], R0

	PUTC	0x08
	SUB	0, [dig+3]
	BNZ	print_num_3
	SUB	0, [dig+2]
	BNZ	print_num_2
	SUB	0, [dig+1]
	BNZ	print_num_1
	B	print_num_0
print_num_3:
	MOV	R0, [dig+3]
	CALL	print_digit
print_num_2:
	MOV	R0, [dig+2]
	CALL	print_digit
print_num_1:
	MOV	R0, [dig+1]
	CALL	print_digit
print_num_0:
	MOV	R0, [dig+0]
	CALL	print_digit
	PUTC	0x10
	RET

print_digit:
	MOV	R1, 0
	MOV	R2, 0
	ADD	R0, LO digits
	ADC	R1, MID digits
	ADC	R2, HI digits
	PUTC	CODE
	RET

stab_item:
	PTR	0
	PTR	"WALIZKA VALISA"
	PTR	"POWER STRIP"
	PTR	"CAN OF REDBULL"
	PTR	"BOTTLE OF RUM"
	PTR	"BOTTLE OF GIN"
	PTR	"BOTTLE OF TEQUILA"
	PTR	"BOTTLE OF JAEGERMEISTER"
	PTR	"BOTTLE OF BAILEYS"
	PTR	"BOTTLE OF COCA-COLA"
	PTR	"BOTTLE OF TONIC"
	PTR	"CARTON OF ORANGE JUICE"
	PTR	"GRENADINE SYRUP"
	PTR	"CARTON OF MILK"
	PTR	"EMPTY BOTTLE OF SOPLICA PIGWOWA"

stab_the_monster:
	PTR	0
	PTR	"VALIS"
	PTR	"REDFORD"
	PTR	"THE RED BULL"
	PTR	"THE YELLOW DRAGON"
	PTR	"THE BLUE DRAGON"
	PTR	"THE CRYSTAL DRAGON"
	PTR	"THE GREEN DRAGON"
	PTR	"THE BEIGE DRAGON"
	PTR	"THE BLACK DRAGON"
	PTR	"THE GRAY DRAGON"
	PTR	"THE ORANGE DRAGON"
	PTR	"THE RED DRAGON"
	PTR	"THE WHITE DRAGON"
	PTR	"THE DRUNK DRAGON"

stab_space_desc:
	PTR	"THERE IS NOTHING INTERESTING HERE.\r\n\r\n"
	PTR	"THERE IS A TAVERN HERE.  INSIDE THE TAVERN, YOU SEE VALIS.\r\n\r\n"
	PTR	"THERE IS REDFORD HERE.  HE APPEARS TO BE BUSY HACKING.\r\n\r\n"
	PTR	"THERE IS A RED BULL HERE.  IT APPEARS TO BE GUARDING SOME SORT OF A METAL OBJECT.\r\n\r\n"
	PTR	"THERE IS A YELLOW DRAGON HERE.  SHE APPEARS TO BE GUARDING SOME KIND OF A BOTTLE.\r\n\r\n"
	PTR	"THERE IS A BLUE DRAGON HERE.  THEY APPEAR TO BE GUARDING SOME KIND OF A BOTTLE.\r\n\r\n"
	PTR	"THERE IS A CRYSTAL DRAGON HERE.  HE APPEARS TO BE GUARDING SOME KIND OF A BOTTLE.\r\n\r\n"
	PTR	"THERE IS A GREEN DRAGON HERE.  SHE APPEARS TO BE GUARDING SOME KIND OF A BOTTLE.\r\n\r\n"
	PTR	"THERE IS A BEIGE DRAGON HERE.  HE APPEARS TO BE GUARDING SOME KIND OF A BOTTLE.\r\n\r\n"
	PTR	"THERE IS A BLACK DRAGON HERE.  SHE APPEARS TO BE GUARDING SOME KIND OF A BOTTLE.\r\n\r\n"
	PTR	"THERE IS A GRAY DRAGON HERE.  HE APPEARS TO BE GUARDING SOME KIND OF A BOTTLE.\r\n\r\n"
	PTR	"THERE IS AN ORANGE DRAGON HERE.  SHE APPEARS TO BE GUARDING SOME KIND OF A CARTONE.\r\n\r\n"
	PTR	"THERE IS A RED DRAGON HERE.  HE APPEARS TO BE GUARDING SOME KIND OF A BOTTLE.\r\n\r\n"
	PTR	"THERE IS A WHITE DRAGON HERE.  SHE APPEARS TO BE GUARDING SOME KIND OF A CARTON.\r\n\r\n"
	PTR	"THERE IS A DRUNK DRAGON HERE.  HE APPEARS TO BE GUARDING SOME KIND OF A BOTTLE.\r\n\r\n"

init_board_tab:
	BYTE	redford
	BYTE	redbull
	BYTE	redbull
	BYTE	redbull
	BYTE	redbull
	BYTE	redbull
	BYTE	redbull
	BYTE	redbull
	BYTE	redbull
	BYTE	redbull
	BYTE	rum
	BYTE	gin
	BYTE	tequila
	BYTE	jagermeister
	BYTE	baileys
	BYTE	coca_cola
	BYTE	tonic
	BYTE	orange
	BYTE	grenadine
	BYTE	milk
	BYTE	pigwowka
	BYTE	0

digits:
	BYTE	0x0f
	BYTE	0x01
	BYTE	0x02
	BYTE	0x04
	BYTE	0x05
	BYTE	0x07
	BYTE	0x09
	BYTE	0x0a
	BYTE	0x0c
	BYTE	0x0d
