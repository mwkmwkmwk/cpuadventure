This is the CPU Adventure task from the Dragon CTF 2019 Teaser.

The task is about blackbox reverse engeineering of CPU architectures.
As a player, you get a binary for a very strange processor, and access
to a server running that binary.  You have to figure out the instruction
set by statistical analysis on the binary, helped by corelation with
the running copy on server you can talk to.

If you want to solve it the intended way, do the following:

```
$ make
$ ./emu ./game.bin ./flag.txt
```

You can play the game, and you can inspect the `game.bin` file, but pretend
you cannot read the `emu` file.

To solve the task, you have to win the game without using the "(C)HEAT"
option.

The original task description from the CTF is:

```
My grandfather used to design computers back in the 60s.  While cleaning out
his attic, I found a strange machine.  Next to the machine, I found a deck of
punched cards labeled "Dragon Adventure Game".  After some time, I managed to
hook it up to modern hardware, but the game is too hard and I cannot get to
the end without cheating.  Can you help me?

I'm attaching a transcription of the punched cards used by the machine.  The
machine proudly claims to have 4 general purpose registers, 1kiB of data memory,
and 32kiB of instruction memory.
```

The author's solution is in h4x.py.  You can use it as follows:

```
$ socat tcp4-listen:1234,fork,reuseaddr exec:./emu\ game.bin\ flag.txt,pty,setsid,setpgid,ctty,stderr,rawer
$ ./h4x.py 127.0.0.1 1234
```
