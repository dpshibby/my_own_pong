;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; TODO:
;;;       * make a snapping catcher for paddle movement down
;;;       * get collisions on paddles
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

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
pointerLo: 	.res 1 		; pointer vars for 2byte addr
pointerHi: 	.res 1

ctrl_input_1:	.res 1
ctrl_input_2:	.res 1

paddle_1_y:	.res 1
paddle_2_y:	.res 1
paddle_speed:	.res 1

ball_x:	   	.res 1
ball_y:	   	.res 1
ball_up:   	.res 1 		; 1 for up, 0 for down
ball_left:	.res 1 		; 1 for left, 0 for right
ball_speed:	.res 1

waiting:	.res 1

	;; Game specific constants
	TOP_WALL    = $07
	RIGHT_WALL  = $F4
	BOTTOM_WALL = $E7
	LEFT_WALL   = $04

	PADDLE_1_X  = $00
	PADDLE_2_X  = $F8

	BALL_START_X = $80
	BALL_START_Y = $50

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

	STA waiting		; A is still 0

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
load_sprite:			; for now this just loads in the paddles
	LDA sprites, X
	STA $0204, X
	INX
	CPX #$10
	BNE load_sprite
	;; finished loading sprites

	;; set initial vals for paddles
	LDA #$05
	STA paddle_speed

	LDA #$70
	STA paddle_1_y

	LDA #$70
	STA paddle_2_y

	;; set up initial vals for ball
	LDA #$01
	STA ball_speed
	STA ball_up
	STA ball_left
	
	LDA #BALL_START_X
	STA ball_x
	LDA #BALL_START_Y
	STA ball_y

	;; initial val for waiting var
	LDA #$00
	STA waiting
	

LOOP:
	;; first we're gonna read the controllers
	;; bless the guy at famicom party for this one
	LDA #$01
	STA CONTROLLER_1
	LDA #$00
	STA CONTROLLER_1

	LDA #%00000001
	STA ctrl_input_1

get_buttons_1:
	LDA CONTROLLER_1
	LSR A
	ROL ctrl_input_1
	BCC get_buttons_1

	;; controller 1 input processed

	LDA #$01
	STA CONTROLLER_2
	LDA #$00
	STA CONTROLLER_2

	LDA #%00000001
	STA ctrl_input_2

get_buttons_2:
	LDA CONTROLLER_2
	LSR A
	ROL ctrl_input_2
	BCC get_buttons_2
	
	;; controller 2 input processed

	;; move the paddles

	LDA ctrl_input_1
	AND #BTN_UP
	BNE move_paddle_1_up
	LDA ctrl_input_1
	AND #BTN_DOWN
	BNE move_paddle_1_down
	JMP paddle_1_move_done

move_paddle_1_up:
	LDA paddle_1_y
	CMP #TOP_WALL
	BCC paddle_1_up_snap	; if touching or beyond top, snap into it
	BEQ paddle_1_up_snap	; if touching or beyond top, snap into it

	LDA paddle_1_y
	SEC
	SBC paddle_speed
	STA paddle_1_y
	JMP paddle_1_move_done

paddle_1_up_snap:
	LDA #TOP_WALL
	STA paddle_1_y
	JMP paddle_1_move_done
	
move_paddle_1_down:
	LDA paddle_1_y
	CLC			; we add 16 here, 8 to get to lower block of paddle
	ADC #$10		; and 8 to get to bottom of sprite
	CMP #BOTTOM_WALL	; if touching bottom wall, don't keep moving
	BCS paddle_1_down_snap

	LDA paddle_1_y
	CLC
	ADC paddle_speed
	STA paddle_1_y
	JMP paddle_1_move_done

paddle_1_down_snap:
	LDA #BOTTOM_WALL
	SEC
	SBC #$10
	STA paddle_1_y
	;; JMP paddle_1_move_done
	
paddle_1_move_done:

	;; now for paddle 2
	LDA ctrl_input_2
	AND #BTN_UP
	BNE move_paddle_2_up
	LDA ctrl_input_2
	AND #BTN_DOWN
	BNE move_paddle_2_down
	JMP paddle_2_move_done

move_paddle_2_up:
	LDA paddle_2_y
	CMP #TOP_WALL
	BCC paddle_2_move_done	; if touching top wall, don't try to move

	LDA paddle_2_y
	SEC
	SBC paddle_speed
	STA paddle_2_y
	JMP paddle_2_move_done
	
move_paddle_2_down:
	LDA paddle_2_y
	CLC			; we add 16 here, 8 to get to lower block of paddle
	ADC #$10		; and 8 to get to bottom of sprite
	CMP #BOTTOM_WALL	; if touching bottom wall, don't keep moving
	BCS paddle_2_move_done

	LDA paddle_2_y
	CLC
	ADC paddle_speed
	STA paddle_2_y
	
paddle_2_move_done:
	
	;; move the ball

	LDA ball_left
	BEQ move_ball_right
	
move_ball_left:
	LDA ball_x
	SEC
	SBC ball_speed
	STA ball_x

	;; check if ball is hitting left side of screen
	LDA ball_x
	CMP #LEFT_WALL
	BNE horiz_movement_done
	
	LDA #$00
	STA ball_left		; switch direction to right
	JMP horiz_movement_done

	;; later this should give Player 2 a point and reset ball position
	;; but for now we'll just bounce off the walls

	;; ball left movement done

move_ball_right:
	LDA ball_x
	CLC
	ADC ball_speed
	STA ball_x

	;; check if ball is hitting right side of screen
	LDA ball_x
	CMP #RIGHT_WALL
	BCC horiz_movement_done
	
	LDA #$01
	STA ball_left		; switch direction to left
	JMP horiz_movement_done

	;; later this should give Player 1 a point and reset ball position
	;; but for now we'll just bounce off the walls

	;; ball right movement done

horiz_movement_done:

	LDA ball_up
	BEQ move_ball_down
move_ball_up:
	LDA ball_y
	SEC
	SBC ball_speed		; subtract since pos Y is down the screen
	STA ball_y

	;; check if ball is hitting top of screen
	LDA ball_y
	CMP #TOP_WALL
	BCS vert_movement_done

	LDA #$00
	STA ball_up		; switch direction to down
	JMP vert_movement_done

	;; ball up movement done

move_ball_down:
	LDA ball_y
	CLC
	ADC ball_speed
	STA ball_y

	LDA ball_y
	CLC
	ADC #08			; get to bottom of ball sprite
	CMP #BOTTOM_WALL
	BCC vert_movement_done

	LDA #$01
	STA ball_up
	JMP vert_movement_done

	;; ball down movement done

vert_movement_done:

	;; write into sprite mem that will go to PPU in VBLANK
	
	LDA ball_y
	STA $0200

	LDA #$00		; sprite 0 is plain white block
	STA $0201
	
	STA $0202		; A still == 0
	
	LDA ball_x
	STA $0203

	;; ball finished
	;; start paddles
	
	LDA paddle_1_y
	STA $0204

	LDA #$00
	STA $0205

	STA $0206

	;; don't think this is necessary because X doesn't change
	LDA #PADDLE_1_X
	STA $0207

	;; paddle 1, lower block
	LDA paddle_1_y
	CLC
	ADC #$08
	STA $0208

	LDA #$00
	STA $0209

	STA $020A

	;; don't think this is necessary because X doesn't change
	LDA #PADDLE_1_X
	STA $020B

	;; here we just spin until NMI finishes so we only do all the
	;; actions in the main loop once per frame
	INC waiting
wait_loop:
	LDA waiting
	BNE wait_loop
	
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
