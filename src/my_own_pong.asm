;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;D
;;; TODO:
;;; * left paddle collision is very close to being good!
;;; - need to keep testing at different heights/angles
;;; * need to make the ball score earlier and/or add a check to not collide
;;;   if we're already behind the paddle
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
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
				; this variable is also used to check which
				; player scored, 1 for p1, 0 for p2

ctrl_input_1:	.res 1
ctrl_input_2:	.res 1

paddle_1_top:	.res 1
paddle_2_top:	.res 1
paddle_speed:	.res 1

ball_x:		.res 1
ball_y:		.res 1
ball_up:	.res 1		; 1 for up, 0 for down
ball_left:	.res 1		; 1 for left, 0 for right

ball_speed_x:	.res 1
ball_frac_x:	.res 1
ball_frac_x_mx:	.res 1
ball_remndr_x:	.res 1

ball_speed_y:	.res 1
ball_frac_y:	.res 1
ball_frac_y_mx:	.res 1
ball_remndr_y:	.res 1

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
	TOP_WALL         = $07
	RIGHT_WALL       = $F4
	BOTTOM_WALL      = $E7
	LEFT_WALL        = $04

	PADDLE_1_X       = $0C
	PADDLE_2_X       = $F0
	PADDLE_START_Y   = $70
	PADDLE_WIDTH     = $04
	PADDLE_LEN       = $10

	BALL_START_X     = $80
	BALL_START_Y     = $50
	BALL_DIAMETER    = $04
	BALL_START_SPD_X = $02
	BALL_START_FRACX = $02
	BALL_START_SPD_Y = $00
	BALL_START_FRACY = $00

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
	LDA ctrl_input_1
	AND #BTN_UP
	BNE move_paddle_1_up
	LDA ctrl_input_1
	AND #BTN_DOWN
	BNE move_paddle_1_down
	JMP paddle_1_move_done

move_paddle_1_up:
	LDA paddle_1_top
	SEC
	SBC paddle_speed
	CMP #TOP_WALL
	BCC paddle_1_up_snap	; if touching or beyond top, snap into it
	STA paddle_1_top
	JMP paddle_1_move_done


paddle_1_up_snap:
	LDA #TOP_WALL
	STA paddle_1_top
	JMP paddle_1_move_done

	;; end of moving up section

move_paddle_1_down:
	LDA paddle_1_top
	CLC
	ADC paddle_speed
	STA paddle_1_top
	CLC
	ADC #PADDLE_LEN		; get bottom of paddle
	CMP #BOTTOM_WALL
	BCS paddle_1_down_snap
	JMP paddle_1_move_done

paddle_1_down_snap:
	LDA #BOTTOM_WALL
	SEC
	SBC #PADDLE_LEN
	STA paddle_1_top
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
	LDA paddle_2_top
	SEC
	SBC paddle_speed
	CMP #TOP_WALL
	BCC paddle_2_up_snap	; if touching or beyond top, snap into it
	STA paddle_2_top
	JMP paddle_2_move_done


paddle_2_up_snap:
	LDA #TOP_WALL
	STA paddle_2_top
	JMP paddle_2_move_done

	;; end of moving up section

move_paddle_2_down:
	LDA paddle_2_top
	CLC
	ADC paddle_speed
	STA paddle_2_top
	CLC
	ADC #PADDLE_LEN		; get bottom of paddle
	CMP #BOTTOM_WALL
	BCS paddle_2_down_snap
	JMP paddle_2_move_done

paddle_2_down_snap:
	LDA #BOTTOM_WALL
	SEC
	SBC #PADDLE_LEN
	STA paddle_2_top
	;; JMP paddle_2_move_done

paddle_2_move_done:
	RTS
;;; END OF MOVE_PADDLES ;;;

MOVE_BALL_UP:
	LDA ball_y
	SEC
	SBC ball_speed_y	; subtract since pos Y is down the screen
	STA ball_y

	DEC ball_frac_y
	BNE move_ball_up_done

	;; apply fractional movement
	LDA ball_frac_y_mx
	BEQ move_ball_up_done
	DEC ball_y
	STA ball_frac_y

move_ball_up_done:
	RTS
;;; END OF MOVE_BALL_UP ;;;

BALL_CEILING_COLLIS:
	LDA #TOP_WALL
	CMP ball_y
	BCC no_ceiling_collis

	LDA ball_remndr_y
	BNE consume_ceiling_remainder

	;; create_ceiling_remainder
	LDA #TOP_WALL
	SEC
	SBC ball_y
	STA ball_remndr_y
	BEQ perfect_ceiling_collis
	LDA #TOP_WALL
	STA ball_y

	JMP no_ceiling_collis

consume_ceiling_remainder:
	LDA #TOP_WALL
	CLC
	ADC ball_remndr_y
	CLC
	ADC ball_speed_y
	STA ball_y
	LDA #$00
	STA ball_remndr_y

	;; fall through

perfect_ceiling_collis:
	LDA #$00
	STA ball_up

no_ceiling_collis:
	RTS
;;; END OF BALL_CEILING_COLLIS ;;;

MOVE_BALL_DOWN:
	LDA ball_y
	CLC
	ADC ball_speed_y
	STA ball_y

	DEC ball_frac_y
	BNE move_ball_down_done

	;; apply fractional movement
	LDA ball_frac_y_mx
	BEQ move_ball_up_done
	INC ball_y
	STA ball_frac_y

move_ball_down_done:
	RTS
;;; END OF MOVE_BALL_DOWN ;;;

BALL_FLOOR_COLLIS:
	LDA ball_y
	CLC
	ADC #BALL_DIAMETER	; get to bottom of ball sprite
	CMP #BOTTOM_WALL
	BCC no_floor_collis


	TAX			; save our calculated bottom of ball in X
	LDA ball_remndr_y
	BNE consume_floor_remainder

	;; create_floor_remainder
	TXA
	SEC
	SBC #BOTTOM_WALL
	STA ball_remndr_y
	BEQ perfect_floor_collis
	LDA #BOTTOM_WALL
	SEC
	SBC #BALL_DIAMETER
	STA ball_y

	JMP no_floor_collis

consume_floor_remainder:
	LDA #BOTTOM_WALL
	SEC
	SBC ball_remndr_y
	SEC
	SBC #BALL_DIAMETER
	SEC
	SBC ball_speed_y
	STA ball_y
	LDA #$00
	STA ball_remndr_y

	;; fall through

perfect_floor_collis:
	LDA #$01
	STA ball_up

no_floor_collis:
	RTS
;;; END OF BALL_FLOOR_COLLIS ;;;


	;; This function decides which angle to reflect the pong ball
	;; after it hits a paddle, it is used by both paddles
ANGLE_SET:
	JMP (pointerLo)

paddle_angle_one_down:
	JSR SET_ANGLE_ONE
	JMP angle_down

paddle_angle_two_down:
	JSR SET_ANGLE_TWO
	JMP angle_down

paddle_angle_three_down:
	JSR SET_ANGLE_THREE
	JMP angle_down

paddle_angle_four_down:
	JSR SET_ANGLE_FOUR
	JMP angle_down

paddle_angle_five:
	JSR SET_ANGLE_FIVE
	JMP angle_set_done

paddle_angle_four_up:
	JSR SET_ANGLE_FOUR
	JMP angle_up

paddle_angle_three_up:
	JSR SET_ANGLE_THREE
	JMP angle_up

paddle_angle_two_up:
	JSR SET_ANGLE_TWO
	JMP angle_up

paddle_angle_one_up:
	JSR SET_ANGLE_ONE
	;; JMP angle_up
	;; fall through
angle_up:
	LDA #$01
	STA ball_up
	JMP angle_set_done

angle_down:
	LDA #$00
	STA ball_up

angle_set_done:
	RTS
;;; END OF ANGLE_SET ;;;


	;; set the x and y speeds to a y-favored setting
	;; later this will have to be made to set them
	;; based on the current speed level of the game
	;; note: the calling code is responsible for
	;; setting the direction properly
SET_ANGLE_ONE:			; 2.33y / 1.0x
	LDA #$01
	STA ball_speed_x
	LDA #$00
	STA ball_frac_x
	STA ball_frac_x_mx

	LDA #$02
	STA ball_speed_y
	LDA #$03
	STA ball_frac_y
	STA ball_frac_y_mx

	RTS

	;; same as above function but a less extreme angle
SET_ANGLE_TWO:			; 1.5y / 2.0x
	LDA #$02
	STA ball_speed_x
	LDA #$00
	STA ball_frac_x
	STA ball_frac_x_mx

	LDA #$01
	STA ball_speed_y
	LDA #$02
	STA ball_frac_y
	STA ball_frac_y_mx

	RTS

	;; now we pick angles more favored to x
SET_ANGLE_THREE:			; 1.2x / 2.2x
	LDA #$02
	STA ball_speed_x
	LDA #$05
	STA ball_frac_x
	STA ball_frac_x_mx

	LDA #$01
	STA ball_speed_y
	LDA #$05
	STA ball_frac_y
	STA ball_frac_y_mx

	RTS

	;; same as above function, slightly more x favored
SET_ANGLE_FOUR:		; 1.0y / 2.33x
	LDA #$02
	STA ball_speed_x
	LDA #$03
	STA ball_frac_x
	STA ball_frac_x_mx

	LDA #$1
	STA ball_speed_y
	LDA #$00
	STA ball_frac_y
	STA ball_frac_y_mx

	RTS

	;; same as above function but horizontal angle
SET_ANGLE_FIVE:
	LDA #$02
	STA ball_speed_x
	STA ball_frac_x
	STA ball_frac_x_mx

	LDA #$00
	STA ball_speed_y
	STA ball_frac_y
	STA ball_frac_y_mx

	RTS
;;; END OF ANGLE SET FUNCTIONS ;;;

	;; move the ball to the left based on speed
MOVE_BALL_LEFT:
	LDA ball_x
	SEC
	SBC ball_speed_x
	STA ball_x

	DEC ball_frac_x
	BNE move_ball_left_done

	;; apply fractional movement
	LDA ball_frac_x_mx
	BEQ move_ball_left_done
	DEC ball_x
	STA ball_frac_x

move_ball_left_done:
	RTS
;;; END OF MOVE_BALL_LEFT ;;;

	;; checks to see if the ball is in an appropriate position
	;; to be considered colliding with the left paddle
	;; this function expects the right side of the left paddle
	;; to be in the accumulator
LEFT_PADDLE_AREA_CHECK:
	;; first: is left side of ball reaching the paddle yet?
	CMP ball_x
	BCC left_paddle_miss

	;; second: is bottom of ball under top of paddle
	LDA ball_y
	CLC
	ADC #BALL_DIAMETER
	CMP paddle_1_top
	BEQ left_paddle_miss
	BCC left_paddle_miss

	;; third: is top of ball over bottom of paddle?
	LDA paddle_1_top
	CLC
	ADC #PADDLE_LEN
	CMP ball_y
	BEQ left_paddle_miss
	BCC left_paddle_miss

	;; seems like we did in fact collide
	LDA #$01
	JMP left_paddle_area_check_done

left_paddle_miss:
	LDA #$00
left_paddle_area_check_done:
	RTS
;;; END OF LEFT_PADDLE_AREA_CHECK ;;;

BALL_LEFT_PADDLE_COLLIS:
	LDA #PADDLE_1_X
	CLC
	ADC #PADDLE_WIDTH	; get right side of paddle
	TAX			; save right side of paddle in X

	JSR LEFT_PADDLE_AREA_CHECK
	BEQ no_left_paddle_collis

	;; create remainder
	TXA			; retrieve right side of paddle
	SEC
	SBC ball_x
	STA ball_remndr_x
	STX ball_x

	LDA ball_speed_y
	CMP ball_remndr_x
	;; if vert speed is less than remainder in x direction
	;; then we don't bother to correct, should look okay
	BCC left_paddle_correction_done
	LDA ball_up
	BEQ left_paddle_down_correction
	;; ball is going up, correct y down a bit
	LDA ball_y
	CLC
	ADC ball_remndr_x
	STA ball_y
	JMP left_paddle_correction_done

left_paddle_down_correction:
	;; ball is going down, correct y up a bit
	LDA ball_y
	SEC
	SBC ball_remndr_x
	STA ball_y

left_paddle_correction_done:
	;; now decide on angle reflection
	LDA paddle_1_top
	CLC
	ADC #PADDLE_LEN
	SEC
	SBC ball_y
	SBC #$01
	ASL
	TAX
	LDA angle_table, X
	STA pointerLo
	INX
	LDA angle_table, X
	STA pointerHi
	JSR ANGLE_SET

left_paddle_collis_done:
	LDA #$00
	STA ball_left
no_left_paddle_collis:
	RTS
;;; END OF LEFT_PADDLE_COLLIS ;;;

	;; move the ball to the right based on speed
MOVE_BALL_RIGHT:
	LDA ball_x
	CLC
	ADC ball_speed_x
	STA ball_x

	DEC ball_frac_x
	BNE move_ball_right_done

	;; apply fractional movement
	LDA ball_frac_x_mx
	BEQ move_ball_right_done
	INC ball_x
	STA ball_frac_x

move_ball_right_done:
	RTS
;;; END OF MOVE_BALL_RIGHT ;;;

	;; checks to see if the ball is in an appropriate position
	;; to be considered colliding with the right paddle
	;; this function expects the right side of the ball
	;; to be in the accumulator
RIGHT_PADDLE_AREA_CHECK:
	;; first: is right side of ball reaching the paddle yet?
	CMP #PADDLE_2_X
	BCC right_paddle_miss

	;; second: is bottom of ball under top of paddle?
	LDA ball_y
	CLC
	ADC #BALL_DIAMETER	; get bottom of ball sprite
	CMP paddle_2_top
	BEQ right_paddle_miss
	BCC right_paddle_miss

	;; third: is top of ball over bottom of paddle?
	LDA paddle_2_top
	CLC
	ADC #PADDLE_LEN
	CMP ball_y
	BEQ right_paddle_miss
	BCC right_paddle_miss

	;; seems like we did in fact collide
	LDA #$01
	JMP right_paddle_area_check_done

right_paddle_miss:
	LDA #$00
right_paddle_area_check_done:
	RTS
;;; END OF RIGHT_PADDLE_AREA_CHECK ;;;

BALL_RIGHT_PADDLE_COLLIS:
	;; first: is right side of ball reaching the paddle yet?
	INC $0100
	LDA ball_x
	CLC
	ADC #BALL_DIAMETER	; get right side
	TAX			; save right side in X
	JSR RIGHT_PADDLE_AREA_CHECK
	BEQ no_right_paddle_collis

	;; create remainder
	TXA			; retrieve right side of ball
	SEC
	SBC #PADDLE_2_X
	STA ball_remndr_x
	LDA #PADDLE_2_X
	SEC
	SBC #BALL_DIAMETER
	STA ball_x		; make ball flush with right paddle

	LDA ball_speed_y
	CMP ball_remndr_x
	BCC right_paddle_correction_done
	LDA ball_up
	BEQ right_paddle_down_correction
	;; else ball is going up, correct y down a bit
	LDA ball_y
	CLC
	ADC ball_remndr_x
	STA ball_y
	JMP right_paddle_correction_done

right_paddle_down_correction:
	;; ball is going down, correct y up a bit
	LDA ball_y
	SEC
	SBC ball_remndr_x
	STA ball_y


right_paddle_correction_done:
	;; now decide on angle reflection
	LDA paddle_2_top
	CLC
	ADC #PADDLE_LEN
	SEC
	SBC ball_y
	;; if ball hits riiight on the bottom of the paddle then
	;; this actually ends up underflowing and breaks, so we just
	;; manually manipulate so it takes the desired angle
	BCS right_paddle_normal_collis
	LDA #$01

right_paddle_normal_collis:
	SEC
	SBC #$01
	ASL
	TAX
	LDA angle_table, X
	STA pointerLo
	INX
	LDA angle_table, X
	STA pointerHi
right_paddle_set_angle:
	JSR ANGLE_SET

right_paddle_collis_done:
	LDA #$01
	STA ball_left
no_right_paddle_collis:
	RTS
;;; END OF RIGHT_PADDLE_COLLIS ;;;

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

	LDA #PADDLE_START_Y
	STA paddle_1_top

	LDA #PADDLE_START_Y
	STA paddle_2_top

	;; set up initial vals for ball
	LDA #BALL_START_SPD_X
	STA ball_speed_x
	LDA #BALL_START_FRACX
	STA ball_frac_x
	STA ball_frac_x_mx

	LDA #$00
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
	STA ball_frac_x
	STA ball_remndr_x
	STA ball_speed_y
	STA ball_frac_y
	STA ball_remndr_y
	STA p1_score_MSB
	STA p1_score_LSB
	STA p2_score_MSB
	STA p2_score_LSB
	STA serving
	LDA #$20
	STA anim_speed
	LDA #CURSOR_FIRST_POS
	STA cursor_y

	;; uncomment for quick start/debug mode
	;; .include "debug.asm"

	JMP TITLE_SCREEN
	.include "title_screen.asm"

GAME_START:
	;; draw the scoreboard here then begin the game
	JSR DRAW_SCORE
	JSR WAIT_FRAME
	JSR WAIT_FRAME
	JSR WAIT_FRAME

GAME_LOOP:
	JSR SERVE
	JSR PLAY
	JSR SCORE
	JMP GAME_LOOP

SERVE:
	JSR GET_PLAYER_INPUT

	;; move the paddles
	JSR MOVE_PADDLES

	;; keep the ball on the one serving
	LDA serving
	BNE p2_serve
	LDA paddle_1_top
	CLC
	ADC #$06		; keep ball at middle of paddle
	STA ball_y

	LDA #PADDLE_1_X
	CLC
	ADC #$0A		; 10 pixels from paddle 1
	STA ball_x

	;; now check if the player pressed A to serve
	LDA ctrl_input_1
	AND #BTN_A
	BEQ serve_done
	LDA #$00
	STA ball_up
	STA ball_left

	RTS

p2_serve:
	LDA paddle_2_top
	CLC
	ADC #$06		; keep ball at middle of paddle
	STA ball_y

	LDA #PADDLE_2_X
	SEC
	SBC #$0A		; 10 pixels from paddle 2
	STA ball_x

	;; now check if the player pressed A to serve
	LDA ctrl_input_2
	AND #BTN_A
	BEQ serve_done
	LDA #$01
	STA ball_up
	STA ball_left
	RTS

serve_done:
	JSR COMMON_END
	JMP SERVE

PLAY:
	JSR GET_PLAYER_INPUT

	;; move the paddles
	JSR MOVE_PADDLES

	;; move the ball

	LDA ball_up
	BEQ ball_down

	JSR MOVE_BALL_UP

	;; check if ball is hitting top of screen
	JSR BALL_CEILING_COLLIS
	JMP ball_vert_move_done
	;; ball up movement done

ball_down:
	JSR MOVE_BALL_DOWN

	;; check if ball is hitting bottom of screen
	JSR BALL_FLOOR_COLLIS
	;; ball down movement done

ball_vert_move_done:

	LDA ball_left
	BEQ ball_right

	JSR MOVE_BALL_LEFT

	;; check if p2 scores by ball going off left side
	LDA ball_x
	CMP #LEFT_WALL
	BEQ player_2_score
	BCC player_2_score

	;; then check for left side paddle collis
	JSR BALL_LEFT_PADDLE_COLLIS

	JMP ball_horiz_move_done
	;; ball left movement done

	;; these scoring labels are the exit point of the PLAY function
player_1_score:
	LDA #$01
	STA serving
	RTS

player_2_score:
	LDA #$00
	STA serving
	RTS

ball_right:
	JSR MOVE_BALL_RIGHT

	;; check if p1 scores by ball going off right side
	LDA ball_x
	CLC
	ADC #BALL_DIAMETER	; get right side of ball
	CMP #RIGHT_WALL
;;; ;;;;; CHECK HERE ;;;;;;;;;;;;;;;;;;;
	BCS player_1_score

	;; then check for right side paddle collis
	JSR BALL_RIGHT_PADDLE_COLLIS

	;; ball right movement done

ball_horiz_move_done:

	JSR COMMON_END
	JMP PLAY

SCORE:
	;; who scored?
	LDA serving
	BEQ p2_scored

	;; else p1 scored
	INC p1_score_LSB
	LDA p1_score_LSB
	CMP #$0A
	BNE score_end
	INC p1_score_MSB
	LDA #$00
	STA p1_score_LSB
	JMP score_end

p2_scored:
	INC p2_score_LSB
	LDA p2_score_LSB
	CMP #$0A
	BNE score_end
	INC p2_score_MSB
	LDA #$00
	STA p2_score_LSB

score_end:
	JSR DRAW_SCORE
	JSR COMMON_END
	RTS


	;; Handle all the sprite drawing for each frame
	;; then burn cycles until next frame
COMMON_END:

	;; write into sprite mem that will go to PPU in VBLANK

	LDA ball_y
	STA $0200

	LDA #$00		; sprite 0 is the ball
	STA $0201

	STA $0202		; A still == 0

	LDA ball_x
	STA $0203

	;; ball finished
	;; start paddles

	LDA paddle_1_top
	STA $0204

	LDA #$01
	STA $0205

	LDA #$00
	STA $0206

	;; don't think this is necessary because X doesn't change
	LDA #PADDLE_1_X
	STA $0207

	;; paddle 1, lower block
	LDA paddle_1_top
	CLC
	ADC #$08
	STA $0208

	LDA #$01
	STA $0209

	LDA #$00
	STA $020A

	;; don't think this is necessary because X doesn't change
	LDA #PADDLE_1_X
	STA $020B
	;; paddle 1 done

	LDA paddle_2_top
	STA $020C

	LDA #$01
	STA $020D

	LDA #$00
	STA $020E

	;; don't think this is necessary because X doesn't change
	LDA #PADDLE_2_X
	STA $020F

	;; paddle 2, lower block
	LDA paddle_2_top
	CLC
	ADC #$08
	STA $0210

	LDA #$01
	STA $0211

	LDA #$00
	STA $0212

	;; don't think this is necessary because X doesn't change
	LDA #PADDLE_2_X
	STA $0213

	;; here we just spin until NMI finishes so we only do all the
	;; actions in the main loop once per frame
	JSR WAIT_FRAME
	RTS
;;; END OF COMMON_END ;;;

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

angle_table:
	.word paddle_angle_one_down
	.word paddle_angle_one_down
	.word paddle_angle_two_down
	.word paddle_angle_two_down
	.word paddle_angle_three_down
	.word paddle_angle_three_down
	.word paddle_angle_four_down
	.word paddle_angle_four_down
	.word paddle_angle_five
	.word paddle_angle_five
	.word paddle_angle_five
	.word paddle_angle_four_up
	.word paddle_angle_four_up
	.word paddle_angle_three_up
	.word paddle_angle_three_up
	.word paddle_angle_two_up
	.word paddle_angle_two_up
	.word paddle_angle_one_up
	.word paddle_angle_one_up
	.word paddle_angle_one_up ; need an extra entry here for when the ball
				  ; hits on top of the paddle
	;; .word $0000
