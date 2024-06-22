	JSR DEBUG_STARTUP
	JSR DEBUG_RESET
	;; JSR DEBUG_GAMELOOP
	JSR SKIP_SERVE_ONCE

	;; skips the menu, puts us right into the start of the game
	;; this does a lot of the same stuff as title screen, could
	;; probably make it a shared function later to save some space
DEBUG_STARTUP:
	;; erase "PRESS  START"
	LDA #PS_LSB
	LDY #PS_MSB
	LDX #PS_SIZE
	JSR STRIKEOUT

	;; these erase "my own pong"
	LDA #$8D
	LDY #$21
	LDX #$06
	JSR STRIKEOUT

	LDA #$CC
	LDY #$21
	LDX #$08
	JSR STRIKEOUT

	LDA #$EC
	LDY #$21
	LDX #$08
	JSR STRIKEOUT

	LDA #$00
	STA nmt_buffer, Y
	INY
	STY nmt_len

	LDA #$01
	STA need_nmt

	JSR WAIT_FRAME

	;; draw a gray boundary at top of screen
	LDY nmt_len
	LDA #$20
	STA nmt_buffer, Y
	INY
	LDX #$20
	STA nmt_buffer, Y
	INY
	LDA #$60
	STA nmt_buffer, Y
	INY

	LDA #$01		; gray square
top_line_loop2:
	STA nmt_buffer, Y
	INY
	DEX
	BNE top_line_loop2

	;; draw a gray boundary at bottom of screen
	LDA #$20
	STA nmt_buffer, Y
	INY
	LDX #$20
	LDA #$23
	STA nmt_buffer, Y
	INY
	LDA #$80
	STA nmt_buffer, Y
	INY

	LDA #$01		; gray square
bot_line_loop2:
	STA nmt_buffer, Y
	INY
	DEX
	BNE bot_line_loop2

	;; LDY nmt_len
	LDA #$00
	STA nmt_buffer, Y
	INY
	STY nmt_len

	LDA #$01
	STA need_nmt

	JSR WAIT_FRAME
	JSR DRAW_SCORE
	RTS

	;; resets game field to environment wanted for testing
DEBUG_RESET:
	;; reset ball
	LDA #BALL_START_X
	LDA #$D1
	STA ball_int_x
	LDA #BALL_START_Y
	LDA #$6D
	STA ball_int_y
;;;;;; Current angles, tested ;;;;;;
;;; 7F, 7E = sharp down
;;; 7D, 7C = mostly down
;;; 7B, 7A = mild down
;;; 79, 78 = mostly forward, down
;;; 77, 76, 75 = neutral
;;; 74, 73 = mostly forward, up
;;; 72, 71 = mild up
;;; 70, 6F = mostly up
;;; 6E, 6D = sharp up
;;;;;; Current angles, tested ;;;;;;
	JSR SET_ANGLE_FOUR

	;; LDA ball_frac_dx
	;; STA $00
	;; LDA ball_int_dx
	;; STA $01
	;; JSR NEGATE
	;; LDA $00
	;; STA ball_frac_dx
	;; LDA $01
	;; STA ball_int_dx

	LDA ball_frac_dy
	STA $00
	LDA ball_int_dy
	STA $01
	JSR NEGATE
	LDA $00
	STA ball_frac_dy
	LDA $01
	STA ball_int_dy

	;; reset paddles
	LDA #PADDLE_START_Y
	LDA #$55
	STA paddle_int_y

	LDA #PADDLE_START_Y
	LDA #$34
	STA paddle_int_y + 1

	RTS

	;; run the gameplay code wanted for testing
DEBUG_GAMELOOP:
	JSR SERVE
SKIP_SERVE_ONCE:

	;; set paddle control for debug
	LDA #$04
	;; STA $1A 		; ctrl 1
	;; STA $1B		; ctrl 2

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
	BEQ @phys_loop_end
	BCC @phys_loop_end

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
	BCS @phys_loop_end

	;; then check for right side paddle collis
	LDX #$01
	JSR BALL_PADDLE_COLLISION

	;; fall through

@phys_loop_end:
	DEC $08
	BNE @phys_loop
	;; end of phys_loop

	JSR COMMON_END
	JMP SKIP_SERVE_ONCE

	
	JSR SCORE
	;; JSR COMMON_END

debug_gameloop_end:
	JMP DEBUG_GAMELOOP
