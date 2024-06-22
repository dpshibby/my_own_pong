;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; TODO:
;;;
;;; * The object pools method seems to be working very well at first glance!
;;;
;;; * Do some extra testing, especially on tricky angles
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

	;; Game specific constants
	NUM_PLAYERS = 2

	TOP_WALL            = $1F
	RIGHT_WALL          = $FB
	BOTTOM_WALL         = $DF
	LEFT_WALL           = $04

	PADDLE_1_X          = $1C
	PADDLE_2_X          = $E0
	PADDLE_START_Y      = $78
	PADDLE_WIDTH        = $04
	PADDLE_LEN          = $10
	PADDLE_INT_DY_MAX   = $01
	PADDLE_FRAC_DY_MAX  = $00
	PADDLE_INT_DYY_DEF  = $00
	PADDLE_FRAC_DYY_DEF = $08
	PADDLE_INT_DEC_DEF  = $00 ; deceleration
	PADDLE_FRAC_DEC_DEF = $10

	BALL_START_X        = $80
	BALL_START_Y        = $FF
	BALL_DIAMETER       = $04

	COLLIS_EJECT_INT    = $00
	COLLIS_EJECT_FRAC   = $40

	.segment "ZEROPAGE"
pointerLo:	   .res 1	; pointer vars for 2byte addr
pointerHi:	   .res 1

p1_score_MSB:	   .res 1
p1_score_LSB:	   .res 1
p2_score_MSB:	   .res 1
p2_score_LSB:	   .res 1
serving:	   .res 1	; 0 for p1, 1 for p2
				; this variable is also used to check which
				; player scored, 1 for p1, 0 for p2
game_over:	   .res 1	; 1 = p1 won, 2 = p2 won

win_score_MSB:	   .res 1
win_score_LSB:	   .res 1


ctrl_input:	   .res NUM_PLAYERS
ctrl_prev_input:   .res NUM_PLAYERS
ctrl_jp_input:	   .res NUM_PLAYERS ; jp = just pressed on this frame

paddle_int_x:	   .res NUM_PLAYERS
paddle_int_y:	   .res NUM_PLAYERS
paddle_frac_y:	   .res NUM_PLAYERS
paddle_int_dy:	   .res NUM_PLAYERS
paddle_frac_dy:	   .res NUM_PLAYERS
paddle_int_dyy:	   .res NUM_PLAYERS
paddle_frac_dyy:   .res NUM_PLAYERS

ball_int_x:        .res 1
ball_frac_x:	   .res 1
ball_int_dx:	   .res 1
ball_frac_dx:	   .res 1
ball_remndr_x:	   .res 1

ball_int_y:	   .res 1
ball_frac_y:	   .res 1
ball_int_dy:	   .res 1
ball_frac_dy:	   .res 1
ball_remndr_y:	   .res 1

cursor_y:	   .res 1
cursor_up:	   .res 1
selected_option:   .res 1
select_type:	   .res 1

frame_counter:	   .res 1
gen_counter:	   .res 1
anim_speed:	   .res 1

waiting:	   .res 1
need_nmt:	   .res 1
nmt_len:	   .res 1
soft_ppumask:	   .res 1
need_ppureg:	   .res 1

	.segment "BSS"
nmt_buffer:	.res 256
palette_buffer:	.res 32


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

	LDA #$01
	STA $0A
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

	LDA need_ppureg
	BEQ no_ppureg
	;; else update ppu registers
	LDA soft_ppumask
	STA PPUMASK

	LDA #$00
	STA need_ppureg

no_ppureg:

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

	;; NEGATE expects low (frac) byte in $00
	;; and high in $01 and returns them in the same
NEGATE:
	LDA #$00
	SEC
	SBC $00
	STA $00

	LDA #$00
	SBC $01
	STA $01
	RTS
;;; END OF NEGATE ;;;

BALL_EJECT:
	;; load in the eject amounts
	LDA #COLLIS_EJECT_FRAC
	STA $00
	LDA #COLLIS_EJECT_INT
	STA $01
	;; left or right eject?
	LDA ball_int_dx
	BMI right_eject 	; (add)
	;; else eject to left (sub)
	JSR NEGATE

right_eject:
	CLC
	LDA ball_frac_x
	ADC $00
	STA ball_frac_x
	LDA ball_int_x
	ADC $01
	STA ball_int_x

	;; if ball is not moving vertically don't eject it vertically
	LDA ball_int_dy
	ORA ball_frac_dy
	BEQ ball_eject_end

	;; reload the eject amounts in case they changed base on the previous calc
	LDA #COLLIS_EJECT_FRAC
	STA $00
	LDA #COLLIS_EJECT_INT
	STA $01

	;; This may or may not be useful when ball ends up at higher speeds
	;; for now everything seems to work okay without it
	;; LDA $03
	;; EOR ball_int_dy
	;; BMI ball_vert_eject
	;; ;; if ball and paddle are going same direction we will move
	;; ;; the paddle instead of the ball
	;; JSR PADDLE_REVERT
	;; JMP ball_eject_end


ball_vert_eject:
	;; up or down eject?
	LDA ball_int_dy
	BMI down_eject		; (add)
	;; else eject upwards (sub)
	JSR NEGATE

down_eject:
	CLC
	LDA ball_frac_y
	ADC $00
	STA ball_frac_y
	LDA ball_int_y
	ADC $01
	STA ball_int_y


ball_eject_end:
	RTS
;;; END OF BALL_EJECT ;;;

	;; This function is used in tandem with BALL_EJECT
	;; This one moves the paddle slightly in the opposite direction
	;; during a collision to help find the exact moment of impact
PADDLE_REVERT:
	;; if paddle is not even moving then we leave
	LDA $03
	ORA $02
	BEQ paddle_revert_end

	;; load the eject amounts
	LDA #$40
	STA $00
	LDA #$00
	STA $01

	;; up or down eject?
	LDA $03
	BMI paddle_down_revert	; (add)
	;; else eject upwards (sub)
	JSR NEGATE

paddle_down_revert:
	CLC
	LDA $04
	ADC $00
	STA $04
	LDA $05
	ADC $01
	STA $05

paddle_revert_end:
	RTS
;;; END OF PADDLE_REVERT ;;;
	

	;; respond when the ball bonks on the flat top or bottom
	;; portion of the paddle
	;; X = paddle index
PADDLE_TOP_OR_BOT_COLLIS:
	;; if paddle and ball are going in the same direction
	;; we add a little speed to the ball and that's it
	LDA ball_int_dy
	EOR paddle_int_dy, X
	BPL ball_paddle_same_dir

	;; in this case, paddle and ball are going opposite directions,
	;; or paddle is not moving. In both cases we want to flip the ball's
	;; dy

	LDA ball_frac_dy
	STA $00
	LDA ball_int_dy
	STA $01
	JSR NEGATE
	LDA $00
	STA ball_frac_dy
	LDA $01
	STA ball_int_dy

	;; if paddle is not moving then we're done here
	LDA paddle_int_dy, X
	ORA paddle_frac_dy, X
	BEQ paddle_top_or_bot_collis_end


	;; we add little speed to the paddle speed we saved, then add that
	;; to the ball's speed
ball_paddle_same_dir:
	LDA paddle_int_dy, X
	BPL add_to_paddle_dy
	;; else sub from paddle_dy
	SEC
	LDA paddle_frac_dy, X
	SBC #$40
	STA $02
	LDA paddle_int_dy, X
	SBC #$00
	STA $03
	JMP add_paddle_dy_to_ball

	;; increase the stored paddle_dy in the positive direction
add_to_paddle_dy:
	CLC
	LDA paddle_frac_dy, X
	ADC #$40
	STA $02
	LDA paddle_int_dy, X
	ADC #$00
	STA $03

	;; fall through

add_paddle_dy_to_ball:
	CLC
	LDA ball_frac_dy
	ADC $02
	STA ball_frac_dy
	LDA ball_int_dy
	ADC $03
	STA ball_int_dy

paddle_top_or_bot_collis_end:
	RTS

	
	;; this is for 16 bit values
	;; If N1 is within range N2 return 0
	;; $00 = low byte to check
	;; $01 = high byte to check
	;; $02 = low byte of num to compare with
	;; $03 = high byte of num to compare with
	;; N1 > N2 returns 1
	;; N1 == N2 returns 0
	;; N1 < N2 returns 0
	;; So if N1 is < = N2 we return 0
	;; return value is in A
	;; thanks to the folks at codebase64.org :)
RANGE_CHECK:
	;; first convert N1 to absolute value
	;; is N1 already pos?
	LDA $01
	BPL hi_byte_check
	JSR NEGATE

	;; fall through

hi_byte_check:
	LDA $01
	CMP $03
	BCC n1_lesser_or_eq     ; hiVal1 < hiVal2 --> Val1 < Val2
	BNE n1_greater

	;; high bytes are equal so check lower
	LDA $00
	CMP $02
	BEQ n1_lesser_or_eq
	BCS n1_greater		; loVal1 > = loVal2 --> Val1 > = Val2

n1_lesser_or_eq:
	LDA #$00
	RTS
n1_greater:
	LDA #$01
	RTS
;;; END OF RANGE_CHECK ;;;


GET_PLAYER_INPUT:
	;; first store previous frame's inputs
	LDA ctrl_input
	STA ctrl_prev_input
	LDA ctrl_input + 1
	STA ctrl_prev_input + 1

	;; now get new data
	LDA #$01
	STA CONTROLLER_1
	STA ctrl_input
	STA ctrl_input + 1
	LDA #$00
	STA CONTROLLER_1

get_buttons:
	LDA CONTROLLER_1
	LSR A
	ROL ctrl_input
	LDA CONTROLLER_2
	LSR A
	ROL ctrl_input + 1

	BCC get_buttons

	;; now we find the inputs that were just pressed this frame
	LDA ctrl_prev_input
	EOR #%11111111
	AND ctrl_input
	STA ctrl_jp_input

	LDA ctrl_prev_input + 1
	EOR #%11111111
	AND ctrl_input + 1
	STA ctrl_jp_input + 1

	RTS
;;; END OF GET_PLAYER_INPUT ;;;

	;; move the paddle based on controller input
	;; the paddle index to be moved is expected to be in X
MOVE_PADDLE:
	LDA paddle_frac_dyy, X
	STA $00
	LDA paddle_int_dyy, X
	STA $01

	LDA ctrl_input, X
	AND #BTN_UP
	BNE paddle_up_press
	LDA ctrl_input, X
	AND #BTN_DOWN
	BNE paddle_down_press
	;; nothing pressed? we should decel here
	LDA #PADDLE_FRAC_DEC_DEF
	STA $00
	LDA #PADDLE_INT_DEC_DEF
	STA $01

	;; are we going up or down?
	LDA paddle_int_dy, X
	BPL @decel_sub
	;; if dy is neg, we're moving up
	;; decelerate by adding dyy
	LDA paddle_frac_dy, X
	CLC
	ADC $00
	STA paddle_frac_dy, X

	LDA paddle_int_dy, X
	ADC $01
	STA paddle_int_dy, X
	JMP @decel_range_check

@decel_sub:
	SEC
	LDA paddle_frac_dy, X
	SBC $00
	STA paddle_frac_dy, X

	LDA paddle_int_dy, X
	SBC $01
	STA paddle_int_dy, X

@decel_range_check:
	LDA paddle_frac_dy, X
	STA $00
	LDA paddle_int_dy, X
	STA $01

	LDA #PADDLE_FRAC_DEC_DEF
	STA $02
	LDA #PADDLE_INT_DEC_DEF
	STA $03
	JSR RANGE_CHECK
	BNE paddle_apply_dy
	;; if dy is close to 0 then clamp it to 0
	LDA #$00
	STA paddle_frac_dy, X
	STA paddle_int_dy, X

	JMP paddle_apply_dy

paddle_up_press:
	JSR NEGATE
	JMP paddle_apply_dyy

paddle_down_press:
	;; fall through

paddle_apply_dyy:
	LDA paddle_frac_dy, X
	CLC
	ADC $00
	STA paddle_frac_dy, X

	LDA paddle_int_dy, X
	ADC $01
	STA paddle_int_dy, X

	;; check if vel has gone over max val
	LDA paddle_frac_dy, X
	STA $00
	LDA paddle_int_dy, X
	STA $01

	LDA #PADDLE_FRAC_DY_MAX
	STA $02
	LDA #PADDLE_INT_DY_MAX
	STA $03
	JSR RANGE_CHECK
	BEQ paddle_apply_dy
	;; if non zero returned then we were over max vel, must clamp
	LDA #PADDLE_INT_DY_MAX
	STA $01
	LDA #PADDLE_FRAC_DY_MAX
	STA $00
	;; was our original vel pos or neg?
	LDA paddle_int_dy, X
	BPL @store_clamped_dy
	;; if negative, negate the clamped val
	JSR NEGATE

	;; fall through

	@store_clamped_dy:
	LDA $00
	STA paddle_frac_dy, X
	LDA $01
	STA paddle_int_dy, X

	;; fall through

paddle_apply_dy:
	LDA paddle_frac_y, X
	CLC
	ADC paddle_frac_dy, X
	STA paddle_frac_y, X

	LDA paddle_int_y, X
	ADC paddle_int_dy, X
	STA paddle_int_y, X


	;; floor/ceiling check
	LDA paddle_int_dy, X
	BPL paddle_floor_check
	;; else check for ceiling collis

	LDA paddle_int_y, X
	CMP #TOP_WALL
	BCC paddle_up_snap	; if touching or beyond top, snap into it
	JMP paddle_move_done

paddle_floor_check:
	LDA paddle_int_y, X
	CLC
	ADC #PADDLE_LEN		; get bottom of paddle
	CMP #BOTTOM_WALL
	BCS paddle_down_snap
	JMP paddle_move_done

paddle_down_snap:
	LDA #BOTTOM_WALL
	SEC
	SBC #PADDLE_LEN
	STA paddle_int_y, X
	LDA #$00
	STA paddle_frac_y, X
	;; also set dy to 0 when we hit floor
	STA paddle_int_dy, X
	STA paddle_frac_dy, X
	JMP paddle_move_done

paddle_up_snap:
	LDA #TOP_WALL
	STA paddle_int_y, X
	LDA #$00
	STA paddle_frac_y, X
	;; also set dy to 0 when we hit ceiling
	STA paddle_int_dy, X
	STA paddle_frac_dy, X
	JMP paddle_move_done

paddle_move_done:
	RTS
;;; END OF MOVE_PADDLE ;;;


BALL_CEILING_COLLIS:
	LDA #TOP_WALL
	CMP ball_int_y
	BCC no_ceiling_collis

	LDA #$01
	STA $08

ball_ceiling_test_eject:
	LDA #TOP_WALL
	CMP ball_int_y
	BEQ perfect_ceiling_collis

	
	;; if ball is still inside wall, eject it on x and y axis then loop back
	;; for y axis we're always going to add
	CLC
	LDA ball_frac_y
	ADC #COLLIS_EJECT_FRAC
	STA ball_frac_y
	LDA ball_int_y
	ADC #COLLIS_EJECT_INT
	STA ball_int_y

	
	;; for x axis check if ball is moving pos or negative and eject
	;; in the opposite direction
	LDA ball_int_x
	BPL ball_ceiling_eject_left ; (sub)
	;; else eject right (add)
	CLC
	LDA ball_frac_x
	ADC #COLLIS_EJECT_FRAC
	STA ball_frac_x
	LDA ball_int_x
	ADC #COLLIS_EJECT_INT
	STA ball_int_x
	JMP ball_ceiling_test_eject

ball_ceiling_eject_left:
	SEC
	LDA ball_frac_x
	SBC #COLLIS_EJECT_FRAC
	STA ball_frac_x
	LDA ball_int_x
	SBC #COLLIS_EJECT_INT
	STA ball_int_x
	JMP ball_ceiling_test_eject

perfect_ceiling_collis:
	;; on collis, reverse y velocity
	LDA ball_frac_dy
	STA $00
	LDA ball_int_dy
	STA $01
	JSR NEGATE
	LDA $00
	STA ball_frac_dy
	LDA $01
	STA ball_int_dy

	;; fall through

no_ceiling_collis:
	RTS
;;; END OF BALL_CEILING_COLLIS ;;;

BALL_FLOOR_COLLIS:
	LDA ball_int_y
	CLC
	ADC #BALL_DIAMETER	; get to bottom of ball sprite
	CMP #BOTTOM_WALL
	BCC no_floor_collis


	;; if we make a collision, stop our physics ticks for this frame
	LDA #$01
	STA $08
	
ball_floor_test_eject:
	LDA ball_int_y
	CLC
	ADC #BALL_DIAMETER	; get to bottom of ball sprite
	CMP #BOTTOM_WALL
	BEQ perfect_floor_collis
	;; if ball is still inside wall, eject it on x and y axis then loop back
	;; for y axis we're always going to subtract
	SEC
	LDA ball_frac_y
	SBC #COLLIS_EJECT_FRAC
	STA ball_frac_y
	LDA ball_int_y
	SBC #COLLIS_EJECT_INT
	STA ball_int_y

	;; for x axis check if ball is moving pos or negative and eject
	;; in the opposite direction
	LDA ball_int_x
	BPL ball_floor_eject_left ; (sub)
	;; else eject right (add)
	CLC
	LDA ball_frac_x
	ADC #COLLIS_EJECT_FRAC
	STA ball_frac_x
	LDA ball_int_x
	ADC #COLLIS_EJECT_INT
	STA ball_int_x
	JMP ball_floor_test_eject

ball_floor_eject_left:
	SEC
	LDA ball_frac_x
	SBC #COLLIS_EJECT_FRAC
	STA ball_frac_x
	LDA ball_int_x
	SBC #COLLIS_EJECT_INT
	STA ball_int_x
	JMP ball_floor_test_eject
	

perfect_floor_collis:
	;; on collis, reverse y velocity
	LDA ball_frac_dy
	STA $00
	LDA ball_int_dy
	STA $01
	JSR NEGATE
	LDA $00
	STA ball_frac_dy
	LDA $01
	STA ball_int_dy

	;; fall through

no_floor_collis:
	RTS
;;; END OF BALL_FLOOR_COLLIS ;;;


	;; This function decides which angle to reflect the pong ball
	;; after it hits a paddle, it is used by both paddles
HORIZ_ANGLE_SET:
	JMP (pointerLo)

paddle_angle_four_down:
	JSR SET_ANGLE_FOUR
	JMP angle_down

paddle_angle_three_down:
	JSR SET_ANGLE_THREE
	JMP angle_down

paddle_angle_two_down:
	JSR SET_ANGLE_TWO
	JMP angle_down

paddle_angle_one_down:
	JSR SET_ANGLE_ONE
	JMP angle_down

paddle_angle_zero:		; horiztonal
	JSR SET_ANGLE_ZERO
	JMP horiz_angle_set_done

paddle_angle_one_up:
	JSR SET_ANGLE_ONE
	JMP angle_up

paddle_angle_two_up:
	JSR SET_ANGLE_TWO
	JMP angle_up

paddle_angle_three_up:
	JSR SET_ANGLE_THREE
	JMP angle_up

paddle_angle_four_up:
	JSR SET_ANGLE_FOUR
	;; JMP angle_up
	;; fall through
angle_up:
	LDA ball_frac_dy
	STA $00
	LDA ball_int_dy
	STA $01
	JSR NEGATE
	LDA $00
	STA ball_frac_dy
	LDA $01
	STA ball_int_dy

	JMP horiz_angle_set_done

angle_down:

horiz_angle_set_done:
	RTS
;;; END OF HORIZ_ANGLE_SET ;;;


	;; in this set of functions we set the ball to the
	;; appropriate angle after it hits a paddle
	;; same as above function but horizontal angle
	;; note: the calling code is responsible for
	;; setting the direction properly
	;; NB: the numbers are done using 8.8 fixed point
	;; All of the numbers are divided by 4 for 4-tick
	;; physics calculations
SET_ANGLE_ZERO:			; 0.0y / 2.5x
	LDA #$00
	STA ball_int_dy
	STA ball_frac_dy

	LDA #$00
	STA ball_int_dx
	LDA #$94
	STA ball_frac_dx

	RTS

	;; same as above function, next most x-favored angle
SET_ANGLE_ONE:			; 0.7y / 2.4x
	LDA #$00
	STA ball_int_dy
	LDA #$2D
	STA ball_frac_dy

	LDA #$00
	STA ball_int_dx
	LDA #$99
	STA ball_frac_dx

	RTS

	;; same as above, slightly more vertical
SET_ANGLE_TWO:			; 1.2y / 2.2x
	LDA #$00
	STA ball_int_dy
	LDA #$4D
	STA ball_frac_dy

	LDA #$00
	STA ball_int_dx
	LDA #$8D
	STA ball_frac_dx

	RTS

	;; same as above but even more vertical
SET_ANGLE_THREE:		; 1.81y / 1.73x
	LDA #$00
	STA ball_int_dy
	LDA #$74
	STA ball_frac_dy

	LDA #$00
	STA ball_int_dx
	LDA #$6F
	STA ball_frac_dx

	RTS

SET_ANGLE_FOUR:			; 2.25y / 1.10x
	LDA #$00
	STA ball_int_dy
	LDA #$90
	STA ball_frac_dy

	LDA #$00
	STA ball_int_dx
	LDA #$46
	STA ball_frac_dx

	RTS

;;; END OF ANGLE SET FUNCTIONS ;;;

MOVE_BALL:
	;; X portion
	CLC
	LDA ball_frac_x
	ADC ball_frac_dx
	STA ball_frac_x

	LDA ball_int_x
	ADC ball_int_dx
	STA ball_int_x

	;; Y portion
	CLC
	LDA ball_frac_y
	ADC ball_frac_dy
	STA ball_frac_y

	LDA ball_int_y
	ADC ball_int_dy
	STA ball_int_y

	RTS
;;; END OF MOVE_BALL ;;;

	;; X = paddle index
BALL_PADDLE_COLLISION_CHECK:
	;; right side of ball vs left side of paddle
	LDA ball_int_x
	CLC
	ADC #BALL_DIAMETER
	CMP paddle_int_x, X
	BCC paddle_miss

	;; right side of paddle vs left side of ball
	LDA paddle_int_x, X
	CLC
	ADC #PADDLE_WIDTH
	CMP ball_int_x
	BCC paddle_miss

	;; bottom of ball vs top of paddle
	LDA ball_int_y
	CLC
	ADC #BALL_DIAMETER
	CMP paddle_int_y, X
	BCC paddle_miss

	;; bottom of paddle vs top of ball
	LDA paddle_int_y, X
	CLC
	ADC #PADDLE_LEN
	CMP ball_int_y
	BCC paddle_miss

	;; seems like we did collide if we made it here
	LDA #$01
	RTS

paddle_miss:
	LDA #$00
	RTS
;;; END OF BALL_PADDLE_COLLISION_CHECK ;;;

	;; X = paddle index
BALL_PADDLE_COLLISION:
	JSR BALL_PADDLE_COLLISION_CHECK
	BEQ no_paddle_collis

	;; add these values to memory to use within function
	LDA paddle_int_dy, X
	STA $03
	LDA paddle_frac_dy, X
	STA $02

	LDA paddle_int_y, X
	STA $05
	LDA paddle_frac_y, X
	STA $04

	;; collision definitely happened
	;; we're going to cut short the physics calcs after this
	;; so we have at least 1 frame of the ball touching the
	;; paddle
	LDA #$01
	STA $08
	;; are we going to count it as vertical or horizontal?
paddle_test_eject:
	;; horiz checks
	;; we check if the ball is hitting the side of both paddles here
	;; because it ends up being simpler than checking which paddle
	;; we're at and they're mutually exclusive so we shouldn't
	;; get any false positives
	LDA ball_int_x
	CLC
	ADC #BALL_DIAMETER
	CMP paddle_int_x, X
	BEQ paddle_horiz_collis
	
	LDA paddle_int_x, X
	CLC
	ADC #PADDLE_WIDTH
	CMP ball_int_x
	BEQ paddle_horiz_collis
	
	;; vertical checks
	LDA paddle_int_y, X
	CLC
	ADC #PADDLE_LEN
	CMP ball_int_y
	BEQ paddle_top_or_bot_collis
	LDA paddle_int_y, X
	SEC
	SBC #BALL_DIAMETER
	CMP ball_int_x, X
	BEQ paddle_top_or_bot_collis

	;; if none of above conditions are met, we readjust the ball
	;; then loop back up to try again
	JSR BALL_EJECT

	;; if BALL_EJECT changes paddle then we should
	;; reflect the change here
	;; LDA $05
	;; STA paddle_2_int_y
	;; LDA $04
	;; STA paddle_2_frac_y
	
	;; else no hit, do another loop
	JMP paddle_test_eject

	;; if we get a top/bot collis we just reflect Y velocity and carry on
paddle_top_or_bot_collis:
	JSR PADDLE_TOP_OR_BOT_COLLIS
	JMP no_paddle_collis

paddle_horiz_collis:
	;; first save our paddle index on the stack
	TXA
	PHA
	
	LDA paddle_int_y, X
	CLC
	ADC #PADDLE_LEN
	SEC
	SBC ball_int_y
	;; if ball hits riiight on the bottom of the paddle then
	;; this actually ends up underflowing and breaks, so we just
	;; manually manipulate so it takes the desired angle
	BNE paddle_normal_collis
	LDA #$01

	;; fall through

paddle_normal_collis:
	SEC
	SBC #$01
	ASL
	TAX
	LDA horiz_angle_table, X
	STA pointerLo
	INX
	LDA horiz_angle_table, X
	STA pointerHi
	JSR HORIZ_ANGLE_SET

	;; quick check if this is left or right paddle
	PLA			; get index back from stack
	TAX
	BEQ no_paddle_collis
	;; if it's right paddle we need to reflect new horiz
	;; speed
	LDA ball_frac_dx
	STA $00
	LDA ball_int_dx
	STA $01
	JSR NEGATE
	LDA $00
	STA ball_frac_dx
	LDA $01
	STA ball_int_dx

	;; fall through

no_paddle_collis:
	RTS
;;; END OF BALL_PADDLE_COLLISION

	;; Draws the scoreboard at the top of the screen
DRAW_SCORE:
	LDY nmt_len
	LDA #$05
	STA nmt_buffer, Y
	INY
	LDA #$20
	STA nmt_buffer, Y
	INY
	LDA #$47
	STA nmt_buffer, Y
	INY
	LDA #$1F		; P
	STA nmt_buffer, Y
	INY
	LDA #$41		; 1
	STA nmt_buffer, Y
	INY
	LDA #$00		; space
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
	LDA #$54
	STA nmt_buffer, Y
	INY
	LDA #$1F		; P
	STA nmt_buffer, Y
	INY
	LDA #$42		; 2
	STA nmt_buffer, Y
	INY
	LDA #$00		; space
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

	STY nmt_len

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

	;; NB: This reads all the default bg tiles written at the bottom of
	;; this file, but also the nametable data!
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
	LDA #PADDLE_1_X
	STA paddle_int_x
	LDA #PADDLE_2_X
	STA paddle_int_x + 1
	
	LDA #PADDLE_FRAC_DYY_DEF
	STA paddle_frac_dyy
	STA paddle_frac_dyy + 1

	LDA #PADDLE_INT_DYY_DEF
	STA paddle_int_dyy
	STA paddle_int_dyy + 1

	LDA #PADDLE_START_Y
	STA paddle_int_y
	STA paddle_int_y + 1


	;; set up initial vals for ball
	JSR SET_ANGLE_ZERO

	LDA #BALL_START_X
	STA ball_int_x
	LDA #BALL_START_Y
	STA ball_int_y


	;; initialize values
	LDA #$00
	STA waiting
	STA need_nmt
	STA nmt_len
	STA frame_counter
	STA gen_counter
	STA paddle_frac_y
	STA paddle_frac_dy
	STA paddle_int_dyy
	STA paddle_frac_y + 1
	STA paddle_frac_dy + 1
	STA paddle_int_dyy + 1
	STA ball_frac_x
	STA ball_remndr_x
	STA ball_int_dy
	STA ball_frac_y
	STA ball_frac_dy
	STA ball_remndr_y
	STA p1_score_MSB
	STA p1_score_LSB
	STA p2_score_MSB
	STA p2_score_LSB
	STA game_over
	STA win_score_MSB
	STA serving
	STA soft_ppumask
	STA need_ppureg
	STA selected_option
	LDA #$02
	STA select_type

	LDA #$20
	STA anim_speed
	LDA #CURSOR_FIRST_POS
	STA cursor_y

	LDA #$05
	STA win_score_LSB

	;; uncomment for quick start/debug mode
	;; .include "debug.asm"

	JMP TITLE_SCREEN
	.include "title_screen.asm"

GAME_INIT:
	;; draw the scoreboard here then begin the game
	JSR DRAW_SCORE

	LDY nmt_len
	LDA #$00
	STA nmt_buffer, Y

	LDA #$01
	STA need_nmt

	JSR COMMON_END

GAME_LOOP:
	JSR SERVE
	JSR PLAY
	JSR SCORE
	JSR GAME_END_CHECK
	JMP GAME_LOOP

SERVE:
	JSR GET_PLAYER_INPUT

	LDA #$04
	STA $08
@phys_loop:
	;; move the paddles
	LDX #$00
	JSR MOVE_PADDLE
	INX
	JSR MOVE_PADDLE

	DEC $08
	BNE @phys_loop
	;; end of phys_loop

	;; keep the ball on the one serving
	LDA serving
	BNE p2_serve
	LDA paddle_int_y
	CLC
	ADC #$06		; keep ball at middle of paddle
	STA ball_int_y

	LDA paddle_int_x
	CLC
	ADC #$0A		; 10 pixels from paddle 1
	STA ball_int_x

	;; now check if the player pressed A to serve
	;; if A not pressed, move on
	LDA ctrl_jp_input
	AND #BTN_A
	BEQ serve_done

	;; new A press detected, serve ball
	RTS

p2_serve:
	LDA paddle_int_y + 1
	CLC
	ADC #$06		; keep ball at middle of paddle
	STA ball_int_y

	LDA paddle_int_x + 1
	SEC
	SBC #$0A		; 10 pixels from paddle 2
	STA ball_int_x

	;; now check if the player pressed A to serve
	;; if A not pressed, move on
	LDA ctrl_jp_input + 1
	AND #BTN_A
	BEQ serve_done

	;; new A press detected, serve ball
	RTS

serve_done:
	JSR COMMON_END
	JMP SERVE

PLAY:
	JSR GET_PLAYER_INPUT

	LDA #$04
	STA $08
@phys_loop:
	;; move the paddles
	LDX #$00
	JSR MOVE_PADDLE
	INX
	JSR MOVE_PADDLE

	;; move the ball
	JSR MOVE_BALL
	;; check if ball is hitting top of screen or bottom
	LDA ball_int_dy
	BPL @ball_floor_check
	JSR BALL_CEILING_COLLIS
	JMP @ball_floor_ceiling_done

@ball_floor_check:
	JSR BALL_FLOOR_COLLIS

@ball_floor_ceiling_done:

	LDA ball_int_dx
	BPL @right_side_checks
	;; else check left paddle and left score zone
	;; check if p2 scores by ball going off left side
	LDA ball_int_x
	CMP #LEFT_WALL
	BEQ player_2_score
	BCC player_2_score

	;; then check for left side paddle collis
	LDX #$00
	JSR BALL_PADDLE_COLLISION
	JMP @phys_loop_end

	@right_side_checks:
	;; check if p1 scores by ball going off right side
	LDA ball_int_x
	CLC
	ADC #BALL_DIAMETER	; get right side of ball
	CMP #RIGHT_WALL
	BCS player_1_score

	;; then check for right side paddle collis
	LDX #$01
	JSR BALL_PADDLE_COLLISION

	;; fall through

@phys_loop_end:
	DEC $08
	BNE @phys_loop
	;; end of phys_loop

	JSR COMMON_END
	JMP PLAY

	;; these scoring labels are the exit point of the PLAY function
player_1_score:
	LDA #$01
	STA serving
	RTS

player_2_score:
	LDA #$00
	STA serving
	RTS

SCORE:
	;; who scored?
	LDA serving
	BEQ p2_scored

	;; else p1 scored
	INC p1_score_LSB
	LDA p1_score_LSB
	CMP #$0A
	BNE @game_end_test
	INC p1_score_MSB
	LDA #$00
	STA p1_score_LSB

@game_end_test:
	;; now check if game has ended
	LDA p1_score_MSB
	CMP win_score_MSB
	BNE score_end
	;; MSB is same, now try LSB
	LDA p1_score_LSB
	CMP win_score_LSB
	BNE score_end
	;; if both are the same, set game over val
	LDA #$01
	STA game_over
	JMP score_end

p2_scored:
	INC p2_score_LSB
	LDA p2_score_LSB
	CMP #$0A
	BNE @game_end_test
	INC p2_score_MSB
	LDA #$00
	STA p2_score_LSB

@game_end_test:
	;; now check if game has ended
	LDA p2_score_MSB
	CMP win_score_MSB
	BNE score_end
	;; MSB is same, now try LSB
	LDA p2_score_LSB
	CMP win_score_LSB
	BNE score_end
	;; if both are the same, set game over val
	LDA #$01
	STA game_over
	;; fall through

score_end:
	JSR DRAW_SCORE

	LDA #$00
	STA nmt_buffer, Y
	STY nmt_len

	LDA #$01
	STA need_nmt

	JSR SET_ANGLE_ZERO

	;; if P1 scored then we want to reverse the ball's vel for
	;; P2 to serve
	LDA serving
	BEQ @no_negate
	
	LDA ball_frac_dx
	STA $00
	LDA ball_int_dx
	STA $01
	JSR NEGATE
	LDA $00
	STA ball_frac_dx
	LDA $01
	STA ball_int_dx

@no_negate:


	JSR COMMON_END
	RTS
;;; END OF SCORE ;;;

GAME_END_CHECK:
	LDA game_over
	BEQ game_not_over	; branch if game is still going
	;; else display win message
	LDA #$00
	STA $00
	STA $01
	LDA serving
	BEQ p2_wins
	;; else p1 wins
	LDA #P1_WIN_I
	JMP display_game_over

game_not_over:
	RTS

p2_wins:
	LDA #P2_WIN_I
	JMP display_game_over

display_game_over:
	JSR WRITE_TXT
	;; load options for replay/quit
	LDA #PLAY_AG_I
	JSR WRITE_TXT

	LDA #QUIT_I
	JSR WRITE_TXT

	LDY nmt_len
	LDA #$00
	STA nmt_buffer, Y
	LDA #$01
	STA need_nmt

	LDA #CURSOR_FIRST_POS
	STA cursor_y

GAME_END_CHECK_LOOP:
	JSR GET_PLAYER_INPUT
	LDX ctrl_jp_input
	TXA
	AND #BTN_A
	BNE game_end_select
	TXA
	AND #BTN_UP
	BNE move_up_ge
	TXA
	AND #BTN_DOWN
	BNE move_down_ge



GAME_END_CHECK_LOOP_END:
	JSR COMMON_END
	JMP GAME_END_CHECK_LOOP

move_up_ge:
	LDA #CURSOR_FIRST_POS
	STA cursor_y
	JMP GAME_END_CHECK_LOOP_END

move_down_ge:
	LDA #CURSOR_SECOND_POS
	STA cursor_y
	JMP GAME_END_CHECK_LOOP_END

game_end_select:
	LDA cursor_y
	CMP #CURSOR_SECOND_POS
	BNE reset_game
	;; else we go back to the title screen
	;; fall through

	;; at some point this should send us back to the title
	;; screen while keeping our settings but for now this
	;; is good enough
back_to_start:
	JMP RESET

reset_game:
	;; set up initial for paddles etc again
	LDA #PADDLE_START_Y
	STA paddle_int_y

	LDA #PADDLE_START_Y
	STA paddle_int_y + 1

	;; JSR SET_ANGLE_ZERO

	LDA #$00
	STA p1_score_LSB
	STA p1_score_MSB
	STA p2_score_LSB
	STA p2_score_MSB

	STA game_over


	LDA #WINNER_LSB
	LDY #WINNER_MSB
	LDX #WINNER_SIZE
	JSR STRIKEOUT

	LDA #PLAY_AG_LSB
	LDY #PLAY_AG_MSB
	LDX #PLAY_AG_SIZE
	JSR STRIKEOUT

	LDA #QUIT_LSB
	LDY #QUIT_MSB
	LDX #QUIT_SIZE
	JSR STRIKEOUT


	JSR DRAW_SCORE
	LDA #$00
	STA nmt_buffer, Y
	LDA #$01
	STA need_nmt

	;; hide cursor before game
	LDA #$FF
	STA cursor_y

	JSR COMMON_END

	;; go back to SERVE
	RTS


	;; Handle all the sprite drawing for each frame
	;; then burn cycles until next frame
COMMON_END:

	;; write into sprite mem that will go to PPU in VBLANK

	LDA ball_int_y
	STA $0200

	LDA #$00		; sprite 0 is the ball
	STA $0201

	STA $0202		; A still == 0

	LDA ball_int_x
	STA $0203

	;; ball finished
	;; start paddles

	LDA paddle_int_y
	STA $0204

	LDA #$01
	STA $0205

	LDA #$00
	STA $0206

	;; don't think this is necessary because X doesn't change
	LDA paddle_int_x
	STA $0207

	;; paddle 1, lower block
	LDA paddle_int_y
	CLC
	ADC #$08
	STA $0208

	LDA #$01
	STA $0209

	LDA #$00
	STA $020A

	;; don't think this is necessary because X doesn't change
	LDA paddle_int_x
	STA $020B
	;; paddle 1 done

	LDA paddle_int_y + 1
	STA $020C

	LDA #$01
	STA $020D

	LDA #$00
	STA $020E

	;; don't think this is necessary because X doesn't change
	LDA paddle_int_x + 1
	STA $020F

	;; paddle 2, lower block
	LDA paddle_int_y + 1
	CLC
	ADC #$08
	STA $0210

	LDA #$01
	STA $0211

	LDA #$00
	STA $0212

	;; don't think this is necessary because X doesn't change
	LDA paddle_int_x + 1
	STA $0213

	LDA cursor_y
	STA $0214

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
	.byte %01010000, %01010000, %01010000, %01010000
	.byte %01010000, %01010000, %01010000, %01010000

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

horiz_angle_table:
	.word paddle_angle_four_down
	.word paddle_angle_four_down
	.word paddle_angle_three_down
	.word paddle_angle_three_down
	.word paddle_angle_two_down
	.word paddle_angle_two_down
	.word paddle_angle_one_down
	.word paddle_angle_one_down
	.word paddle_angle_zero
	.word paddle_angle_zero
	.word paddle_angle_zero
	.word paddle_angle_one_up
	.word paddle_angle_one_up
	.word paddle_angle_two_up
	.word paddle_angle_two_up
	.word paddle_angle_three_up
	.word paddle_angle_three_up
	.word paddle_angle_four_up
	.word paddle_angle_four_up
	.word paddle_angle_four_up ; need an extra entry here for when the ball
				   ; hits on top of the paddle
