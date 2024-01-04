	.include "header.asm"
	.include "constants.asm"

	.segment "CHARS"
	.incbin "pong_background.chr"
	.incbin "pong_sprites.chr"

	.segment "VECTORS"
	.addr NMI
	.addr RESET
	.addr 0		; IRQ unused

	.segment "ZEROPAGE"
pointerLo:	.res 1		; pointer vars for 2byte addr
pointerHi:	.res 1

p1_score_MSB:	.res 1
p1_score_LSB:	.res 1
p2_score_MSB:	.res 1
p2_score_LSB:	.res 1
serving:	.res 1		; 0 for p1, 1 for p2

ctrl_input_1:	.res 1
ctrl_input_2:	.res 1

paddle_1_y:	.res 1
paddle_2_y:	.res 1
paddle_speed:	.res 1

ball_x:		.res 1
ball_y:		.res 1
ball_up:	.res 1		; 1 for up, 0 for down
ball_left:	.res 1		; 1 for left, 0 for right
ball_speed:	.res 1

cursor_y:	.res 1
cursor_up:	.res 1

frame_counter:	.res 1
gen_counter:	.res 1
anim_speed:	.res 1

waiting:	.res 1
need_nmt:	.res 1
nmt_len:	.res 1

	.segment "BSS"
nmt_buffer:	.res 256
palette_buffer:	.res 32

	;; Game specific constants
	TOP_WALL     = $07
	RIGHT_WALL   = $F4
	BOTTOM_WALL  = $E7
	LEFT_WALL    = $04

	PADDLE_1_X   = $08
	PADDLE_2_X   = $F0

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

	INC frame_counter

	LDA need_nmt
	BEQ no_nmt
	;; do the nmt update thing
	LDX #$00
nmt_update_loop:
	LDY nmt_buffer, X
	BEQ nmt_update_finish
	INX
	LDA PPUSTATUS
	LDA nmt_buffer, X
	STA PPUADDR
	INX
	LDA nmt_buffer, X
	STA PPUADDR
	INX
nmt_update_data_loop:
	LDA nmt_buffer, X
	INX
	STA PPUDATA
	DEY
	BEQ nmt_update_loop
	JMP nmt_update_data_loop

nmt_update_finish:
	LDA #$00
	STA need_nmt
	STA nmt_len
no_nmt:


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
	SEI			; disable/mask interupts
	CLD			; disable decimal mode
	LDX #$40
	STA $4017		; disable APU IRQ
	LDX #$FF
	TXS			; set up stack addr
	INX
	STX PPUCTRL		; disable NMI during startup
	STX PPUMASK		; disable rendering
	STX $4010		; diable DMC IRQ
	STX $4015		; disable APU sound

	BIT PPUSTATUS
vblankwait1:			; wait for first vblank
	BIT PPUSTATUS
	BPL vblankwait1
	;; end vblankwait1

	TXA			; X and A both #$00
clear_mem:
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
	STA $0200, X		; move all data in sprite mem off screen
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
;;; MAIN function subroutines ;;;

GET_PLAYER_INPUT:
	LDA #$01
	STA CONTROLLER_1
	STA ctrl_input_1
	STA ctrl_input_2
	LDA #$00
	STA CONTROLLER_1

get_buttons:
	LDA CONTROLLER_1
	LSR A
	ROL ctrl_input_1
	LDA CONTROLLER_2
	LSR A
	ROL ctrl_input_2

	BCC get_buttons

	RTS
;;; END OF GET_PLAYER_INPUT ;;;

	;; move the paddles based on controller input
MOVE_PADDLES:
	;; start of player 1 movement
	LDA ctrl_input_1
	AND #BTN_UP
	BNE move_paddle_1_up
	LDA ctrl_input_1
	AND #BTN_DOWN
	BNE move_paddle_1_down
	JMP paddle_1_move_done

move_paddle_1_up:
	LDA paddle_1_y
	SEC
	SBC paddle_speed
	CMP #TOP_WALL
	BCC paddle_1_up_snap	; if touching or beyond top, snap into it
	STA paddle_1_y
	JMP paddle_1_move_done


paddle_1_up_snap:
	LDA #TOP_WALL
	STA paddle_1_y
	JMP paddle_1_move_done

	;; end of moving up section

move_paddle_1_down:
	LDA paddle_1_y
	CLC
	ADC paddle_speed
	STA paddle_1_y
	CLC			; we add 16 here, 8 to get to lower block of
	ADC #$10		; the paddle and 8 to get to bottom of sprite
	CMP #BOTTOM_WALL	; if touching bottom wall, don't keep moving
	BCS paddle_1_down_snap
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
	SEC
	SBC paddle_speed
	CMP #TOP_WALL
	BCC paddle_2_up_snap	; if touching or beyond top, snap into it
	STA paddle_2_y
	JMP paddle_2_move_done


paddle_2_up_snap:
	LDA #TOP_WALL
	STA paddle_2_y
	JMP paddle_2_move_done

	;; end of moving up section

move_paddle_2_down:
	LDA paddle_2_y
	CLC
	ADC paddle_speed
	STA paddle_2_y
	CLC			; we add 16 here, 8 to get to lower block of
	ADC #$10		; the paddle and 8 to get to bottom of sprite
	CMP #BOTTOM_WALL	; if touching bottom wall, don't keep moving
	BCS paddle_2_down_snap
	JMP paddle_2_move_done

paddle_2_down_snap:
	LDA #BOTTOM_WALL
	SEC
	SBC #$10
	STA paddle_2_y
	;; JMP paddle_2_move_done

paddle_2_move_done:
	RTS
;;; END OF MOVE_PADDLES ;;;


	;; Draws the scoreboard at the top of the screen
DRAW_SCORE:
	LDY nmt_len
	LDA #$05
	STA nmt_buffer, Y
	INY
	LDA #$20
	STA nmt_buffer, Y
	INY
	LDA #$07
	STA nmt_buffer, Y
	INY
	LDA #$1F		; P
	STA nmt_buffer, Y
	INY
	LDA #$41		; 1
	STA nmt_buffer, Y
	INY
	LDA #$01		; space
	STA nmt_buffer, Y
	INY


	LDA p1_score_MSB
	CLC
	ADC #$40		; MSB of score
	STA nmt_buffer, Y
	INY

	LDA p1_score_LSB
	CLC
	ADC #$40		; LSB of score
	STA nmt_buffer, Y
	INY

	LDA #$05
	STA nmt_buffer, Y
	INY
	LDA #$20
	STA nmt_buffer, Y
	INY
	LDA #$14
	STA nmt_buffer, Y
	INY
	LDA #$1F		; P
	STA nmt_buffer, Y
	INY
	LDA #$42		; 2
	STA nmt_buffer, Y
	INY
	LDA #$01		; space
	STA nmt_buffer, Y
	INY

	LDA p2_score_MSB
	CLC
	ADC #$40		; MSB of score
	STA nmt_buffer, Y
	INY

	LDA p2_score_LSB
	CLC
	ADC #$40		; LSB of score
	STA nmt_buffer, Y
	INY

	LDA #$00
	STA nmt_buffer, Y
	INY
	STY nmt_len

	LDA #$01
	STA need_nmt

	RTS
;;; END OF DRAW_SCORE ;;;

	;; we wait here until NMI returns
WAIT_FRAME:
	INC waiting
wait_loop:
	LDA waiting
	BNE wait_loop
	RTS
;;; END OF WAIT_FRAME ;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; MAIN function entry point ;;;

MAIN:
	;; load palettes
	;; load title screen background
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
	LDA PPUSTATUS		; read PPU status to reset the high/low latch
	LDA #$20
	STA PPUADDR		; write high byte of $2000 address
	LDA #$00
	STA PPUADDR		; write low byte of $2000 address

	LDA #<background	; #< gets the LSB of given addr
	STA pointerLo		; put LSB of background addr into pointerLo
	LDA #>background	; #> gets the MSB of given addr
	STA pointerHi		; put MSB of background addr into pointerHi

	LDX #$00		; start at pointer 0
	LDY #$00
outsideloop:

insideloop:
	LDA (pointerLo), Y	; copy one byte from pointer, offset by Y
	STA PPUDATA		; runs 256*4 times

	INY			; inside loop counter
	CPY #$00
	BNE insideloop		; run inside loop 256 times before continuing

	INC pointerHi		; low byte wraps so increment MSB

	INX			; increment outside loop counter
	CPX #$04		; needs to happen $04 times, to copy 1KB data
	BNE outsideloop
	;; initial background finished loading



	;; we turn these on after loading the initial background
	;; because it's big and causes weird glitch otherwise :)
	LDA #%10001000		; enable NMI, bg = pattern table 0, sprites = 1
	STA PPUCTRL
	LDA #%00011110		; turn screen on
	STA PPUMASK

	;; set initial vals for paddles
	LDA #$03
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


	;; initialize values
	LDA #$00
	STA waiting
	STA need_nmt
	STA nmt_len
	STA frame_counter
	STA gen_counter
	STA p1_score_MSB
	STA p1_score_LSB
	STA p2_score_MSB
	STA p2_score_LSB
	STA serving
	LDA #$20
	STA anim_speed
	LDA #$AF
	STA cursor_y

	JMP TITLE_SCREEN
	.include "title_screen.asm"

GAME_START:
	;; draw the scoreboard here then begin the game
	JSR DRAW_SCORE
	JSR WAIT_FRAME
	JSR WAIT_FRAME
	JSR WAIT_FRAME

SERVE:
	JSR GET_PLAYER_INPUT

	;; move the paddles
	JSR MOVE_PADDLES

	;; keep the ball on the one serving
	LDA serving
	BNE p2_serve
	LDA paddle_1_y
	CLC
	ADC #$04
	STA ball_y

	LDA #PADDLE_1_X
	CLC
	ADC #$0A
	STA ball_x

	;; now check if the player pressed A to serve
	LDA ctrl_input_1
	AND #BTN_A
	BEQ serve_done
	LDA #$00
	STA ball_up
	STA ball_left

	JMP GAME

p2_serve:
	LDA paddle_2_y
	CLC
	ADC #$04
	STA ball_y

	LDA #PADDLE_2_X
	SEC
	SBC #$0A
	STA ball_x

	;; now check if the player pressed A to serve
	LDA ctrl_input_2
	AND #BTN_A
	BEQ serve_done
	LDA #$01
	STA ball_up
	STA ball_left
	JMP GAME

serve_done:
	JSR COMMON_END
	JMP SERVE

GAME:
	JSR GET_PLAYER_INPUT

	;; move the paddles
	JSR MOVE_PADDLES

	;; move the ball

	LDA ball_left
	BEQ move_ball_right

move_ball_left:
	LDA ball_x
	SEC
	SBC ball_speed
	STA ball_x

	JMP ball_horiz_movement_done

	;; ball left movement done

move_ball_right:
	LDA ball_x
	CLC
	ADC ball_speed
	STA ball_x

	;; JMP ball_horiz_movement_done

	;; ball right movement done

ball_horiz_movement_done:

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
	BEQ ball_switch
	BCS ball_vert_movement_done

ball_switch:
	LDA #$00
	STA ball_up		; switch direction to down
	JMP ball_vert_movement_done

	;; ball up movement done

move_ball_down:
	LDA ball_y
	CLC
	ADC ball_speed
	STA ball_y

	LDA ball_y
	CLC
	ADC #$08		; get to bottom of ball sprite
	CMP #BOTTOM_WALL
	BCC ball_vert_movement_done

	LDA #$01
	STA ball_up
	JMP ball_vert_movement_done

	;; ball down movement done

ball_vert_movement_done:

	;; check if someone scores
	LDA ball_x
	CMP #LEFT_WALL
	BCC player_2_score
	BEQ player_2_score

	CLC
	ADC #$08		; get right side of ball
	CMP #RIGHT_WALL
	BCC score_check_done
player_1_score:
	INC p1_score_LSB
	LDA p1_score_LSB
	CMP #$0A
	BNE p2_serve_setup
	INC p1_score_MSB
	LDA #$00
	STA p1_score_LSB

p2_serve_setup:
	LDA #$01
	STA serving
	JSR DRAW_SCORE
	JMP SERVE

player_2_score:
	INC p2_score_LSB
	LDA p2_score_LSB
	CMP #$0A
	BNE p1_serve
	INC p2_score_MSB
	LDA #$00
	STA p2_score_LSB

p1_serve:
	LDA #$00
	STA serving
	JSR DRAW_SCORE
	JMP SERVE

score_check_done:


	;; check collisions on paddles
	;; paddle 1:
	LDA ball_x
	SEC
	SBC #$08
	CMP #PADDLE_1_X
	BCS paddle_1_collision_done

	LDA ball_y
	CLC
	ADC #$08
	CMP paddle_1_y
	BEQ paddle_1_collision_done
	BCC paddle_1_collision_done

	;; here we take ball_y and subtract 16 from it and compare it to
	;; the paddle_1_y, this is the same as comparing ball_y to
	;; the bottom portion of the paddle since we don't actually
	;; use a variable to keep that value
	LDA ball_y
	SEC
	SBC #$10
	CMP paddle_1_y
	BCS paddle_1_collision_done

	LDA #$00
	STA ball_left

paddle_1_collision_done:

	;; paddle 2:
	LDA ball_x
	CLC
	ADC #$08
	CMP #PADDLE_2_X
	BEQ paddle_2_collision_done
	BCC paddle_2_collision_done

	LDA ball_y
	CLC
	ADC #$08
	CMP paddle_2_y
	BEQ paddle_2_collision_done
	BCC paddle_2_collision_done

	;; here we take ball_y and subtract 16 from it and compare it to
	;; the paddle_2_y, this is the same as comparing ball_y to
	;; the bottom portion of the paddle since we don't actually
	;; use a variable to keep that value
	LDA ball_y
	SEC
	SBC #$10
	CMP paddle_2_y
	BCS paddle_2_collision_done

	LDA #$01
	STA ball_left

paddle_2_collision_done:

	JSR COMMON_END
	JMP GAME

	;; Handle all the sprite drawing for each frame
	;; then burn cycles until next frame
COMMON_END:

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
	;; paddle 1 done

	LDA paddle_2_y
	STA $020C

	LDA #$00
	STA $020D

	STA $020E

	;; don't think this is necessary because X doesn't change
	LDA #PADDLE_2_X
	STA $020F

	;; paddle 2, lower block
	LDA paddle_2_y
	CLC
	ADC #$08
	STA $0210

	LDA #$00
	STA $0211

	STA $0212

	;; don't think this is necessary because X doesn't change
	LDA #PADDLE_2_X
	STA $0213

	;; here we just spin until NMI finishes so we only do all the
	;; actions in the main loop once per frame
	JSR WAIT_FRAME
	RTS
;;; END OF DRAW_SCORE ;;;

sprites:
	.byte $70, $00, $00, $00
	.byte $78, $00, $00, $00
	.byte $70, $00, $00, $F8
	.byte $78, $00, $00, $F8

background:
	;; row 1
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

	;; row 2
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

	;; row 3
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

	;; row 4
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

	;; row 5
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

	;; row 6
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

	;; row 7
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

	;; row 8
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

	;; row 9
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

	;; row 10
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

	;; row 11
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

	;; row 12
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

	;; row 13
	;; write MY OWN on this line ;;;;;;;
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$1C,$28,$00
	.byte $1E,$26,$1D,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

	;; row 14
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

	;; row 15
	;; rows 15 and 16 have the Pong logo for title screen
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$60,$61,$62,$63
	.byte $64,$65,$66,$67,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

	;; row 16
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$70,$71,$72,$73
	.byte $74,$75,$76,$77,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

	;; row 17
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

	;; row 18
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

	;; row 19
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

	;; row 20
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

	;; row 21
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

	;; row 22
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

	;; row 23
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

	;; row 24
	;; this row says "Press	 Start
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$1F,$21,$14,$22,$22,$00
	.byte $00,$22,$23,$10,$21,$23,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

	;; row 25
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

	;; row 26
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

	;; row 27
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

	;; row 28
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

	;; row 29
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

	;; row 30
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

attributes:  ; 8 x 8 = 64 bytes
	.byte %00000101, %00000101, %00000101, %00000101
	.byte %00000101, %00000101, %00000101, %00000101

	.byte %00000000, %00000000, %00000000, %00000000
	.byte %00000000, %00000000, %00000000, %00000000

	.byte %00000000, %00000000, %00000000, %00000000
	.byte %00000000, %00000000, %00000000, %00000000

	.byte %00000000, %00000000, %00000000, %00000000
	.byte %00000000, %00000000, %00000000, %00000000

	.byte %00000000, %00000000, %00000000, %00000000
	.byte %00000000, %00000000, %00000000, %00000000

	.byte %00000000, %00000000, %00000000, %00000000
	.byte %00000000, %00000000, %00000000, %00000000

	.byte %00000000, %00000000, %00000000, %00000000
	.byte %00000000, %00000000, %00000000, %00000000

	;; bottom row attributes
	.byte %00000101, %00000101, %00000101, %00000101
	.byte %00000101, %00000101, %00000101, %00000101
