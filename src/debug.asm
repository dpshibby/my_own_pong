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

	;; draw a gray boundary at top of screen
	LDY nmt_len
	LDA #$20
	STA nmt_buffer, Y
	INY
	TAX
	STA nmt_buffer, Y
	INY
	LDA #$00
	STA nmt_buffer, Y
	INY

	LDA #$01		; gray square
top_line_loop2:
	STA nmt_buffer, Y
	INY
	DEX
	BNE top_line_loop2

	LDA #$00
	STA nmt_buffer, Y
	INY
	STY nmt_len

	LDA #$01
	STA need_nmt

	JSR WAIT_FRAME

	;; draw a gray boundary at bottom of screen
	LDY nmt_len
	LDA #$20
	STA nmt_buffer, Y
	INY
	TAX
	LDA #$23
	STA nmt_buffer, Y
	INY
	LDA #$A0
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
	LDA #$E8
	STA ball_x
	LDA #BALL_START_Y
	;; LDA #$60
	LDA #$8D
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
	STA ball_y
	LDA #$01
	STA ball_up
	LDA #$00
	STA ball_left
	LDA #$01
	STA ball_speed_x
	LDA #$02
	STA ball_speed_y

	;; reset paddles
	LDA #PADDLE_START_Y
	STA paddle_1_top

	LDA #PADDLE_START_Y
	STA paddle_2_top

	RTS

	;; run the gameplay code wanted for testing
DEBUG_GAMELOOP:
	JSR SERVE
SKIP_SERVE_ONCE:
	JSR PLAY
	JSR SCORE
	;; JSR COMMON_END

debug_gameloop_end:
	JMP DEBUG_GAMELOOP
