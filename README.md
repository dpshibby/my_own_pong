# My Own Pong
Hello this is a little repository for my pong implementation for
NES written in 6502 assembly.

I've gone through a few NES tutorials and wanted to try to make a small
game from scratch. The plan is to start with basic pong and maybe make some
improvements from there.

## Compiling
This project uses the ca65 assembler.
For now use:

`ca65 src/my_own_pong.asm`

`ld65 src/my_own_pong.o -C nes.cfg -o my_pong.nes`

More instructions will be written later, maybe a Makefile
