	.include "constants.asm"
	.include "header.asm"

	
	.segment "VECTORS"
	.addr NMI
	.addr RESET 
	.addr IRQ

	.segment "CODE"
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; RESET Handler routine ;;;

RESET:
	SEI 			; disable/mask interupts
	CLD 			; disable decimal mode
	LDX #$40
	STA $4017 		; disable APU IRQ
	LDX #$FF
	TXS 			; set up stack addr
	INX
	STX $2000 		; disable NMI during startup
	STX $2001		; disable rendering
	STX $4010		; diable DMC IRQ
	STX $4015		; disable APU sound

	BIT $2002
vblankwait1:			; wait for first vblank
	BIT $2002
	BPL vblankwait1
	;; end vblankwait1

clear_mem:	
	TXA			; X and A both #$00
	STA $0000, X
	STA $0100, X
	STA $0200, X
	STA $0300, X
	STA $0400, X
	STA $0500, X
	STA $0600, X
	STA $0700, X
	INX
	BNE clearmem
	;; end clear_mem

	LDA #$FF
clear_oam:
	STA $0200, X		; moves all garbage data in sprite mem off screen
	INX
	INX
	INX
	INX
	BNE clear_oam
	;; end clear_oam

vblankwait2:			; wait for second vblank
	BIT $2002
	BPL vblankwait2
	;; end vblankwait2

	;; initialization is complete, now we enable NMI and
	;; jump to the main program
	LDA #%10010000		; enable NMI, bg = pattern table 0, sprites = 1
	STA PPUCTRL
	LDA #%00011110		; turn screen on
	STA PPUMASK
	JMP MAIN

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; MAIN function entry point ;;;

MAIN:	
	;; load palettes
	;; create a background
	;; load sprites
	;; write them to OAM mem

	.include "default_palette.asm"

