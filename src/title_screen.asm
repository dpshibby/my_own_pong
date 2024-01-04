	;; Title Screen constants
	PS_MSB        = $22
	PS_LSB        = $EA
	PS_SIZE       = $0C

	PLAY_MSB      = $22
	PLAY_LSB      = $CF
	PLAY_SIZE     = $04

	OPT_MSB       = $23
	OPT_LSB       = $2F
	OPT_SIZE      = $07

	BALL_SPD_MSB  = $22
	BALL_SPD_LSB  = $CF
	BALL_SPD_SIZE = $CF

	CURSOR_X  = $68

	BALL_SPD_Y_POS = $48

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; TITLE_SCREEN function subroutines ;;;

DRAW_PRESS_START:
	;; write "PRESS  START"
	LDY nmt_len
	LDA #PS_SIZE		; size
	STA nmt_buffer, Y
	INY
	LDA #PS_MSB		; addr MSB
	STA nmt_buffer, Y
	INY
	LDA #PS_LSB		; addr LSB
	STA nmt_buffer, Y
	INY
	LDA #$1F		; P
	STA nmt_buffer, Y
	INY
	LDA #$21		; R
	STA nmt_buffer, Y
	INY
	LDA #$14		; E
	STA nmt_buffer, Y
	INY
	LDA #$22		; S
	STA nmt_buffer, Y
	INY
	LDA #$22		; S
	STA nmt_buffer, Y
	INY
	LDA #$00		; space
	STA nmt_buffer, Y
	INY
	LDA #$00		; space
	STA nmt_buffer, Y
	INY
	LDA #$22		; S
	STA nmt_buffer, Y
	INY
	LDA #$23		; T
	STA nmt_buffer, Y
	INY
	LDA #$10		; A
	STA nmt_buffer, Y
	INY
	LDA #$21		; R
	STA nmt_buffer, Y
	INY
	LDA #$23		; T
	STA nmt_buffer, Y
	INY

	STY nmt_len

	RTS
;;; END OF DRAW_PRESS_START ;;;


DRAW_OPTIONS:
	;; write "PLAY"
	LDY nmt_len
	LDA #PLAY_SIZE		; size
	STA nmt_buffer, Y
	INY
	LDA #PLAY_MSB		; addr MSB
	STA nmt_buffer, Y
	INY
	LDA #PLAY_LSB		; addr LSB
	STA nmt_buffer, Y
	INY
	LDA #$1F		; P
	STA nmt_buffer, Y
	INY
	LDA #$1B		; L
	STA nmt_buffer, Y
	INY
	LDA #$10		; A
	STA nmt_buffer, Y
	INY
	LDA #$28		; Y
	STA nmt_buffer, Y
	INY

	;; write "OPTIONS"
	LDA #OPT_SIZE		; size
	STA nmt_buffer, Y
	INY
	LDA #OPT_MSB		; addr MSB
	STA nmt_buffer, Y
	INY
	LDA #OPT_LSB		; addr LSB
	STA nmt_buffer, Y
	INY
	LDA #$1E		; O
	STA nmt_buffer, Y
	INY
	LDA #$1F		; P
	STA nmt_buffer, Y
	INY
	LDA #$23		; T
	STA nmt_buffer, Y
	INY
	LDA #$18		; I
	STA nmt_buffer, Y
	INY
	LDA #$1E		; O
	STA nmt_buffer, Y
	INY
	LDA #$1D		; N
	STA nmt_buffer, Y
	INY
	LDA #$22		; S
	STA nmt_buffer, Y
	INY

	STY nmt_len

	;; erase "PRESS  START"
	LDA #PS_LSB
	LDY #PS_MSB
	LDX #PS_SIZE
	JSR STRIKEOUT

	RTS
;;; END OF DRAW_OPTIONS ;;;

DRAW_SUBMENU:
	LDY nmt_len
	LDA #$11		; B
	STA nmt_buffer, Y
	INY
	LDA #$10		; A
	STA nmt_buffer, Y
	INY
	LDA #$1B		; L
	STA nmt_buffer, Y
	INY
	LDA #$1B		; L
	STA nmt_buffer, Y
	INY
	LDA #$00		; space
	STA nmt_buffer, Y
	INY
	LDA #$22		; S
	STA nmt_buffer, Y
	INY
	LDA #$1F		; P
	STA nmt_buffer, Y
	INY
	LDA #$14		; E
	STA nmt_buffer, Y
	INY
	LDA #$14		; E
	STA nmt_buffer, Y
	INY
	LDA #$13		; L
	STA nmt_buffer, Y
	INY

	STY nmt_len

	RTS
;;; END OF DRAW_SUBMENU ;;;


	;; STRIKEOUT assumes addr in A(low) and Y(high) and len in X
STRIKEOUT:			; draw X black squares
	PHA			; LSB to stack
	TYA
	PHA			; MSB to stack
	LDY nmt_len
	TXA
	STA nmt_buffer, Y
	INY
	PLA			; MSB to A
	STA nmt_buffer, Y
	INY
	PLA			; LSB to A
	STA nmt_buffer, Y
	INY
	LDA #$00
strike_loop:
	STA nmt_buffer, Y
	INY
	DEX
	BNE strike_loop

	STY nmt_len
	RTS
;;; END OF STRIKEOUT ;;;

PRESS_START_ANIM:
	LDA frame_counter
	AND anim_speed
	BNE turn_off
	;; else turn on
	JSR DRAW_PRESS_START
	JMP press_start_anim_end

turn_off:
	;; erase "PRESS  START"
	LDA #PS_LSB
	LDY #PS_MSB
	LDX #PS_SIZE
	JSR STRIKEOUT

press_start_anim_end:
	LDY nmt_len
	LDA #$00
	STA nmt_buffer, Y
	INY

	RTS
;;; END PRESS_START_ANIM ;;;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; TITLE_SCREEN entry point ;;;

TITLE_SCREEN:
	JSR GET_PLAYER_INPUT

	LDA ctrl_input_1
	AND #BTN_START
	BNE start
	JSR PRESS_START_ANIM
	LDA #$01
	STA need_nmt
	JSR WAIT_FRAME
	JMP TITLE_SCREEN

start:
	LDX #$3C
	LDA #$08
	STA anim_speed
start_loop:
	TXA
	PHA
	JSR PRESS_START_ANIM
	LDA #$01
	STA need_nmt
	JSR WAIT_FRAME
	PLA
	TAX
	DEX
	BNE start_loop

	LDA #$20
	STA anim_speed

begin_title_menu:
	;; draw Play and Options after return from routine
	JSR DRAW_OPTIONS

	;; write 0 to finish
	LDY nmt_len
	LDA #$00
	STA nmt_buffer, Y
	INY

	;; signal need to update background during NMI
	LDA #$01
	STA need_nmt

	;; now draw cursor sprite
	LDA cursor_y
	STA $0200

	LDA #$00
	STA $0201
	STA $0202
	LDA #CURSOR_X
	STA $0203
	JSR WAIT_FRAME

TITLE_MENU:
	JSR GET_PLAYER_INPUT
	LDX ctrl_input_1
	TXA
	AND #BTN_B
	BNE back_to_title
	TXA
	AND #BTN_A
	BNE option_select
	TXA
	AND #BTN_UP
	BNE move_up
	TXA
	AND #BTN_DOWN
	BNE move_down
	JMP end_title_menu

back_to_title:
	;; erase Play and Options, redraw Press Start
	LDA #PLAY_LSB
	LDY #PLAY_MSB
	LDX #PLAY_SIZE
	JSR STRIKEOUT

	LDA #OPT_LSB
	LDY #OPT_MSB
	LDX #OPT_SIZE
	JSR STRIKEOUT

	JSR DRAW_PRESS_START

	;; write 0 to finish
	LDY nmt_len
	LDA #$00
	STA nmt_buffer, Y
	INY
	STY nmt_len

	;; hide cursor
	LDA #$FF
	STA $0200
	LDA #$AF
	STA cursor_y

	;; signal need to update background during NMI
	LDA #$01
	STA need_nmt

	JSR WAIT_FRAME
	JMP TITLE_SCREEN

move_up:
	LDA #$AF
	STA cursor_y
	JMP end_title_menu

move_down:
	LDA #$C7
	STA cursor_y
	JMP end_title_menu

open_options:
	;; later on this will open the Options submenu but for now it just
	;; passes control back to the title menu (ignores button presses on
	;; Options)

	JMP end_title_menu
options_menu_loop:

option_select:
	;; open submenu or start the game depending on choice
	LDA cursor_y
	CMP #$C7
	BEQ open_options	; this is for opening the options menu but for
				; now does nothing


	;; start the game already!
	LDA #PLAY_LSB
	LDY #PLAY_MSB
	LDX #PLAY_SIZE
	JSR STRIKEOUT

	LDA #OPT_LSB
	LDY #OPT_MSB
	LDX #OPT_SIZE
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
top_line_loop:
	STA nmt_buffer, Y
	INY
	DEX
	BNE top_line_loop

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
bot_line_loop:
	STA nmt_buffer, Y
	INY
	DEX
	BNE bot_line_loop

	;; LDY nmt_len
	LDA #$00
	STA nmt_buffer, Y
	INY
	STY nmt_len

	LDA #$01
	STA need_nmt

	;; these are a bit silly but just waste a bit of time so that the
	;; A press to start the game doesn't also instantly serve the ball
	JSR WAIT_FRAME
	JSR WAIT_FRAME
	JSR WAIT_FRAME
	JSR WAIT_FRAME
	JSR WAIT_FRAME
	JMP GAME_START

end_title_menu:
	;; now draw cursor sprite
	LDA cursor_y
	STA $0200

	LDA #$00
	STA $0201
	STA $0202
	LDA #CURSOR_X
	STA $0203

	JSR WAIT_FRAME
	JMP TITLE_MENU
