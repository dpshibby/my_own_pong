	.include "header.asm"
	.include "constants.asm"

	.segment "CHARS"
	.incbin "pong_background.chr"
	.incbin "pong_sprites.chr"

	.segment "VECTORS"
	.addr NMI
	.addr RESET 
	.addr 0			; IRQ unused

	.segment "ZEROPAGE"
pointerLo: .res 1 		; pointer vars for 2byte addr
pointerHi: .res 1

	.segment "CODE"
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; NMI Handler routine ;;;

NMI:
	PHP
	PHA
	TXA
	PHA
	TYA
	PHA

	;; setup and do DMA from addr $0200
	LDA #$00
	STA OAMADDR
	LDA #$02
	STA OAMDMA

	;; needed?
	;; LDA #%10001000	; enable NMI, bg = pattern table 0, sprites = 1
	;; STA PPUCTRL
	;; LDA #%00011110	; turn screen on
	;; STA PPUMASK

	;; disable scrolling
	LDA #$00
	STA PPUSCROLL
	STA PPUSCROLL


	PLA
	TAY
	PLA
	TAX
	PLA
	PLP

	RTI

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
	STX PPUCTRL 		; disable NMI during startup
	STX PPUMASK		; disable rendering
	STX $4010		; diable DMC IRQ
	STX $4015		; disable APU sound

	BIT PPUSTATUS
vblankwait1:			; wait for first vblank
	BIT PPUSTATUS
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
	BNE clear_mem
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
	BIT PPUSTATUS
	BPL vblankwait2
	;; end vblankwait2

	;; jump to the main program
	JMP MAIN

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; MAIN function entry point ;;;

MAIN:
	;; load palettes
	;; create a background
	;; load sprites

	.include "default_palette.asm"

	LDX PPUSTATUS
	LDX #$3F
	STX PPUADDR
	LDX #$00
	STX PPUADDR

load_palette:
	LDA default_palette, X	; X is still #$00
	STA PPUDATA
	INX
	CPX #$20
	BNE load_palette
	;; finished loading palettes


loadbackground:
	LDA PPUSTATUS           ; read PPU status to reset the high/low latch
	LDA #$20
	STA PPUADDR             ; write high byte of $2000 address
	LDA #$00
	STA PPUADDR             ; write low byte of $2000 address

	LDA #<background
	STA pointerLo           ; put the low byte of address of background into pointer
	LDA #>background        ; #> is the same as HIGH() function in NESASM, used to get the high byte
	STA pointerHi           ; put high byte of address into pointer

	LDX #$00                ; start at pointer 0
	LDY #$00
outsideloop:

insideloop:
	LDA (pointerLo),Y       ; copy one background byte from address in pointer Y
	STA PPUDATA             ; runs 256*4 times

	INY                     ; inside loop counter
	CPY #$00
	BNE insideloop          ; run inside loop 256 times before continuing

	INC pointerHi           ; low byte went from 0 -> 256, so high byte needs to be changed now

	INX                     ; increment outside loop counter
	CPX #$04                ; needs to happen $04 times, to copy 1KB data
	BNE outsideloop
	;; initial background finished loading

	;; we turn these on after loading the initial background
	;; because it's big and causes weird glitch otherwise :)
	LDA #%10001000		; enable NMI, bg = pattern table 0, sprites = 1
	STA PPUCTRL
	LDA #%00011110		; turn screen on
	STA PPUMASK

	LDX #$00
load_sprite:
	LDA sprites, X
	STA $0200, X
	INX
	CPX #$10
	BNE load_sprite
	;; finished loading sprites

LOOP:
	JMP LOOP

sprites:
	.byte $70, $00, $00, $00
	.byte $78, $00, $00, $00
	.byte $70, $00, $00, $F8
	.byte $78, $00, $00, $F8

background:
	.byte $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01
	.byte $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01 ; row 1

	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; row 2

	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; row 3

	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; row 4

	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; row 5

	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; row 6

	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; row 7

	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; row 8

	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; row 9

	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; row 10

	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; row 11

	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; row 12

	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; row 13

	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; row 14

	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; row 15

	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; row 16

	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; row 17

	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; row 18

	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; row 19

	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; row 20

	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; row 21

	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; row 22

	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; row 23

	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; row 24

	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; row 25

	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; row 26

	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; row 27

	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; row 28

	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; row 29

	.byte $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01
	.byte $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01 ; row 30

	;; attributes are all blank to start with since we just use black and white
attributes:  ; 8 x 8 = 64 bytes
	.byte %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
	.byte %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
	.byte %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
	.byte %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
	.byte %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
	.byte %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
	.byte %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
	.byte %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
