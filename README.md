# My Own Pong
Hello this is a little repository for my pong implementation for
NES written in 6502 assembly.

I've gone through a few NES tutorials and wanted to try to make a small
game from scratch. The plan is to start with basic pong and maybe make some
improvements from there.

## Version 1.0
This is the first playable version.This is basically as simple as it
gets while it is still recognizeable as Pong.

* There is a title screen and basic menu

* Collisions are pretty good now

* The scoreboard works properly up to 99 points on either

* The vertical and horizontal speed of the ball is the same so it always
travels in basic diagonal lines

* The Options menu currently does nothing

So yay it works but of course there is much to do to make it smoother, prettier,
and of course more fun.

## Compiling
This project uses the ca65 assembler.
For now use:

`ca65 src/my_own_pong.asm`

`ld65 src/my_own_pong.o -C nes.cfg -o my_pong.nes`

More instructions will be written later, maybe a Makefile
