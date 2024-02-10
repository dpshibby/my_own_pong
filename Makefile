GAME=my_own_pong
ASSEMBLER=ca65
LINKER=ld65
INC_FILES=$(addprefix src/, constants.asm debug.asm default_palette.asm header.asm title_screen.asm)
#INC_FILES=constants.asm debug.asm default_palette.asm header.asm title_screen.asm
CHR_FILES=$(addprefix src/, pong_background.chr pong_sprites.chr)

all: $(GAME).nes

$(GAME).nes: $(GAME).o nes.cfg
	$(LINKER) -o $(GAME).nes -C nes.cfg $(GAME).o

$(GAME).o: src/$(GAME).asm $(INC_FILES) $(CHR_FILES)
	$(ASSEMBLER) src/$(GAME).asm -o $(GAME).o

clean:
	rm -f $(GAME).o
