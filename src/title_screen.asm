;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; TODO:
;;; * Main menu is a function
;;;  - Start Game returns then Game Loop is called
;;;  - Options menu is its own function with a loop
;;;    - Each option has a function that returns back into the Options menu loop
;;;
;;; * Actual menu is displaying now!
;;; * Basic up/down movement works!
;;; * Remember to draw the left/right arrows on entry into the options menu or
;;;   else it doesn't show up until you press down
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
	;; Title Screen constants
	MYOWN_MSB         = $21
	MYOWN_LSB         = $8D
	MYOWN_SIZE        = $06

	PONG_TOP_MSB      = $21
	PONG_TOP_LSB      = $CC
	PONG_TOP_SIZE     = $08
	
	PONG_BOT_MSB      = $21
	PONG_BOT_LSB      = $EC
	PONG_BOT_SIZE     = $08
	
	PS_MSB            = $22
	PS_LSB            = $EA
	PS_SIZE           = $0C

	PLAY_MSB          = $22
	PLAY_LSB          = $CF
	PLAY_SIZE         = $04

	OPT_MSB           = $23
	OPT_LSB           = $2F
	OPT_SIZE          = $07

	CURSOR_X          = $68
	CURSOR_FIRST_POS  = $B1
	CURSOR_SECOND_POS = $C9

	;; Options menu constants
	WIN_SCORE_TXT_MSB  = $20
	WIN_SCORE_TXT_LSB  = $C5
	WIN_SCORE_TXT_SIZE = $0C

	WIN_SCORE_NUM_MSB  = $20
	WIN_SCORE_NUM_LSB  = $D9
	WIN_SCORE_NUM_SIZE = $02

	SAMPLE_TXT_MSB     = $21
	SAMPLE_TXT_LSB     = $05
	SAMPLE_TXT_SIZE    = $06

	SAMPLE_NUM_MSB     = $21
	SAMPLE_NUM_LSB     = $19
	SAMPLE_NUM_SIZE    = $02

	;; Arrow constants
	OPT_ONE_LARROW_MSB = $20
	OPT_ONE_LARROW_LSB = $C4

	OPT_ONE_RARROW_MSB = $20
	OPT_ONE_RARROW_LSB = $D1

	OPT_ONE_NUM_LARROW_MSB = $20
	OPT_ONE_NUM_LARROW_LSB = $D8

	OPT_ONE_NUM_RARROW_MSB = $20
	OPT_ONE_NUM_RARROW_LSB = $DB

	OPT_TWO_LARROW_MSB = $21
	OPT_TWO_LARROW_LSB = $04

	OPT_TWO_RARROW_MSB = $21
	OPT_TWO_RARROW_LSB = $0B


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; TITLE_SCREEN function subroutines ;;;

DRAW_MYOWNPONG:
	;; write "My Own"
	LDY nmt_len
	LDA #MYOWN_SIZE		; size
	STA nmt_buffer, Y
	INY
	LDA #MYOWN_MSB		; addr MSB
	STA nmt_buffer, Y
	INY
	LDA #MYOWN_LSB		; addr LSB
	STA nmt_buffer, Y
	INY
	LDA #$1C		; M
	STA nmt_buffer, Y
	INY
	LDA #$28		; Y
	STA nmt_buffer, Y
	INY
	LDA #$00		; space
	STA nmt_buffer, Y
	INY
	LDA #$1E		; O
	STA nmt_buffer, Y
	INY
	LDA #$26		; W
	STA nmt_buffer, Y
	INY
	LDA #$1D		; N
	STA nmt_buffer, Y
	INY

	;; write "PONG" in big letters
	LDA #PONG_TOP_SIZE	; size
	STA nmt_buffer, Y
	INY
	LDA #PONG_TOP_MSB	; addr MSB
	STA nmt_buffer, Y
	INY
	LDA #PONG_TOP_LSB	; addr LSB
	STA nmt_buffer, Y
	INY
	LDA #$60
	STA nmt_buffer, Y
	INY
	LDA #$61
	STA nmt_buffer, Y
	INY
	LDA #$62
	STA nmt_buffer, Y
	INY
	LDA #$63
	STA nmt_buffer, Y
	INY
	LDA #$64
	STA nmt_buffer, Y
	INY
	LDA #$65
	STA nmt_buffer, Y
	INY
	LDA #$66
	STA nmt_buffer, Y
	INY
	LDA #$67
	STA nmt_buffer, Y
	INY

	LDA #PONG_BOT_SIZE	; size
	STA nmt_buffer, Y
	INY
	LDA #PONG_BOT_MSB	; addr MSB
	STA nmt_buffer, Y
	INY
	LDA #PONG_BOT_LSB	; addr LSB
	STA nmt_buffer, Y
	INY
	LDA #$70
	STA nmt_buffer, Y
	INY
	LDA #$71
	STA nmt_buffer, Y
	INY
	LDA #$72
	STA nmt_buffer, Y
	INY
	LDA #$73
	STA nmt_buffer, Y
	INY
	LDA #$74
	STA nmt_buffer, Y
	INY
	LDA #$75
	STA nmt_buffer, Y
	INY
	LDA #$76
	STA nmt_buffer, Y
	INY
	LDA #$77
	STA nmt_buffer, Y
	INY

	STY nmt_len
	
	RTS
;;; END OF DRAW_MYOWNPONG ;;;
	

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


DRAW_MENU:
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
;;; END OF DRAW_MENU ;;;

DRAW_OPTIONS_MENU:
	LDY nmt_len
	LDA #WIN_SCORE_TXT_SIZE
	STA nmt_buffer, Y
	INY
	LDA #WIN_SCORE_TXT_MSB	; addr MSB
	STA nmt_buffer, Y
	INY
	LDA #WIN_SCORE_TXT_LSB	; addr LSB
	STA nmt_buffer, Y
	INY
	LDA #$22		; S
	STA nmt_buffer, Y
	INY
	LDA #$12		; C
	STA nmt_buffer, Y
	INY
	LDA #$1E		; O
	STA nmt_buffer, Y
	INY
	LDA #$21		; R
	STA nmt_buffer, Y
	INY
	LDA #$14		; E
	STA nmt_buffer, Y
	INY
	LDA #$00		; space
	STA nmt_buffer, Y
	INY
	LDA #$23		; T
	STA nmt_buffer, Y
	INY
	LDA #$1E		; O
	STA nmt_buffer, Y
	INY
	LDA #$00		; space
	STA nmt_buffer, Y
	INY
	LDA #$26		; W
	STA nmt_buffer, Y
	INY
	LDA #$18		; I
	STA nmt_buffer, Y
	INY
	LDA #$1D		; N
	STA nmt_buffer, Y
	INY

	LDA #WIN_SCORE_NUM_SIZE
	STA nmt_buffer, Y
	INY
	LDA #WIN_SCORE_NUM_MSB
	STA nmt_buffer, Y
	INY
	LDA #WIN_SCORE_NUM_LSB
	STA nmt_buffer, Y
	INY
	LDA win_score_MSB
	CLC
	ADC #$40
	STA nmt_buffer, Y
	INY
	LDA win_score_LSB
	CLC
	ADC #$40
	STA nmt_buffer, Y
	INY	

	LDA #SAMPLE_TXT_SIZE
	STA nmt_buffer, Y
	INY
	LDA #SAMPLE_TXT_MSB	; addr MSB
	STA nmt_buffer, Y
	INY
	LDA #SAMPLE_TXT_LSB	; addr LSB
	STA nmt_buffer, Y
	INY
	LDA #$22		; S
	STA nmt_buffer, Y
	INY
	LDA #$10		; A
	STA nmt_buffer, Y
	INY
	LDA #$1C		; M
	STA nmt_buffer, Y
	INY
	LDA #$1F		; P
	STA nmt_buffer, Y
	INY
	LDA #$1B		; L
	STA nmt_buffer, Y
	INY
	LDA #$14		; E
	STA nmt_buffer, Y
	INY

	LDA #SAMPLE_NUM_SIZE
	STA nmt_buffer, Y
	INY
	LDA #SAMPLE_NUM_MSB
	STA nmt_buffer, Y
	INY
	LDA #SAMPLE_NUM_LSB
	STA nmt_buffer, Y
	INY
	LDA #$03
	CLC
	ADC #$40
	STA nmt_buffer, Y
	INY
	LDA #$00
	CLC
	ADC #$40
	STA nmt_buffer, Y
	INY	

	LDA #$01		; len 1
	STA nmt_buffer, Y
	INY
	LDA #OPT_ONE_LARROW_MSB
	STA nmt_buffer, Y
	INY
	LDA #OPT_ONE_LARROW_LSB
	STA nmt_buffer, Y
	INY
	LDA #$30		; left arrow
	STA nmt_buffer, Y
	INY
	
	LDA #$01		; len 1
	STA nmt_buffer, Y
	INY
	LDA #OPT_ONE_RARROW_MSB
	STA nmt_buffer, Y
	INY
	LDA #OPT_ONE_RARROW_LSB
	STA nmt_buffer, Y
	INY
	LDA #$31		; right arrow
	STA nmt_buffer, Y
	INY

	STY nmt_len

	RTS
;;; END OF DRAW_OPTIONS_MENU ;;;


	;; STRIKEOUT assumes addr in A(LSB) and Y(MSB) and len in X
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
	JSR DRAW_MYOWNPONG
	JSR DRAW_PRESS_START

	;; write 0 to finish
	LDY nmt_len
	LDA #$00
	STA nmt_buffer, Y
	STY nmt_len

	;; signal need to update background during NMI
	LDA #$01
	STA need_nmt

	;; hide cursor
	LDA #$FF
	STA $0200
	LDA #CURSOR_FIRST_POS
	STA cursor_y

	LDA #$00
	STA frame_counter

	;; fall through into TITLE_SCREEN_LOOP

TITLE_SCREEN_LOOP:
	JSR GET_PLAYER_INPUT

	LDA ctrl_input_1
	AND #BTN_START
	BNE start
	JSR PRESS_START_ANIM
	LDA #$01
	STA need_nmt
	JSR WAIT_FRAME
	JMP TITLE_SCREEN_LOOP

	;; this loop makes Press Start flash faster when start is pressed
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

	;; after animation completes, fall through into TITLE_SCREEN_MENU

TITLE_SCREEN_MENU:
	;; draw Play Game and Options
	JSR DRAW_MENU

	;; write 0 to finish
	LDY nmt_len
	LDA #$00
	STA nmt_buffer, Y

	;; signal need to update background during NMI
	LDA #$01
	STA need_nmt


	;; fall through to TITLE_SCREEN_MENU_LOOP

TITLE_SCREEN_MENU_LOOP:
	JSR GET_PLAYER_INPUT
	LDX ctrl_jp_input_1
	TXA
	AND #BTN_B
	BNE back_to_title
	TXA
	AND #BTN_A
	BNE menu_select
	TXA
	AND #BTN_UP
	BNE move_up
	TXA
	AND #BTN_DOWN
	BNE move_down
	
title_screen_menu_loop_end:
	;; now draw cursor sprite
	LDA cursor_y
	STA $0200

	LDA #$00
	STA $0201
	STA $0202
	LDA #CURSOR_X
	STA $0203

	JSR WAIT_FRAME
	JMP TITLE_SCREEN_MENU_LOOP

back_to_title:
	;; erase Play and Options
	LDA #PLAY_LSB
	LDY #PLAY_MSB
	LDX #PLAY_SIZE
	JSR STRIKEOUT

	LDA #OPT_LSB
	LDY #OPT_MSB
	LDX #OPT_SIZE
	JSR STRIKEOUT

	JMP TITLE_SCREEN

move_up:
	LDA #CURSOR_FIRST_POS
	STA cursor_y
	JMP title_screen_menu_loop_end

move_down:
	LDA #CURSOR_SECOND_POS
	STA cursor_y
	JMP title_screen_menu_loop_end

menu_select:
	;; open options menu or start the game depending on choice

	;; first we erase the screen
	LDA #PLAY_LSB
	LDY #PLAY_MSB
	LDX #PLAY_SIZE
	JSR STRIKEOUT

	LDA #OPT_LSB
	LDY #OPT_MSB
	LDX #OPT_SIZE
	JSR STRIKEOUT

	;; these erase "my own pong"
	LDA #MYOWN_LSB
	LDY #MYOWN_MSB
	LDX #MYOWN_SIZE
	JSR STRIKEOUT

	LDA #PONG_TOP_LSB
	LDY #PONG_TOP_MSB
	LDX #PONG_TOP_SIZE
	JSR STRIKEOUT

	LDA #PONG_BOT_LSB
	LDY #PONG_BOT_MSB
	LDX #PONG_BOT_SIZE
	JSR STRIKEOUT

	LDY nmt_len
	LDA #$00
	STA nmt_buffer, Y
	STY nmt_len

	LDA #$01
	STA need_nmt

	JSR WAIT_FRAME
	
	;; then act based on option selected
	LDA cursor_y
	CMP #CURSOR_SECOND_POS
	BNE game_start
	JSR OPTIONS_MENU
	JMP TITLE_SCREEN_MENU


	;; start the game already!
game_start:
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

	;; draw a gray boundary at bottom of screen
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

	STY nmt_len

	JMP GAME_INIT

OPTIONS_MENU:
	JSR DRAW_OPTIONS_MENU
	
	;; INC $0100
	LDA #$00
	STA nmt_buffer, Y

	LDA #$01
	STA need_nmt

	;; hide cursor
	LDA #$FF
	STA $0200
	LDA #CURSOR_FIRST_POS
	STA cursor_y

	JSR WAIT_FRAME

	;; fall through to OPTIONS_MENU_LOOP

OPTIONS_MENU_LOOP:
	JSR GET_PLAYER_INPUT
	LDX ctrl_jp_input_1
	TXA
	AND #BTN_B
	BNE leave_options_menu
	TXA
	AND #BTN_A
	BNE modify_setting
	TXA
	AND #BTN_UP
	BNE move_option_up
	TXA
	AND #BTN_DOWN
	BNE move_option_down
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Here we'll check for moving up/down to select an option and left/right
;;; to adjust options
;;; 
;;; For now we just loop
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	JSR WAIT_FRAME
	JMP OPTIONS_MENU_LOOP


leave_options_menu:
;;;;;;;;;;;;;;;;;; ERASE MENU OPTIONS BEFORE LEAVING ;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; NOTE:
;;; Unless you press B in 1 frame and release then going back ends up
;;; accidentally taking you all the way to the Title Screen because
;;; the Title Menu you're supposed to go back to also checks for a B
;;; press to go back to Title Screen
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	RTS
	
	;; When A is pressed, we enter the function that handles whatever
	;; setting was being selected
modify_setting:
	LDA selected_option
	BEQ select_option_1		; option one
	;; check for other options here, for now just loop back
	JMP OPTIONS_MENU_LOOP

select_option_1:
	JSR OPTION_SCORE_TO_WIN
	JMP OPTIONS_MENU_LOOP
	
move_option_up:
	LDA selected_option
	BEQ move_option_end
	DEC selected_option
	JMP move_option_apply
	
move_option_down:
	LDA selected_option
	CMP #$01 		; current num of options - 1, use a CONST later
	BEQ move_option_end
	INC selected_option
	JMP move_option_apply

move_option_end:
	
	JSR WAIT_FRAME
	JMP OPTIONS_MENU_LOOP

move_option_apply:
	LDA #$01
	STA need_nmt

	LDA selected_option
	BNE hover_option_1
	;; else option == 0
	LDA #$00
	PHA
	PHA
	LDA #$31
	PHA
	LDA #$30
	PHA
	JMP option_arrow_update

hover_option_1:
	LDA #$31
	PHA
	LDA #$30
	PHA
	LDA #$00
	PHA
	PHA

option_arrow_update:
	;; Option 1 left and right arrow
	
	LDY nmt_len
	LDA #$01		; len 1
	STA nmt_buffer, Y
	INY
	LDA #OPT_ONE_LARROW_MSB
	STA nmt_buffer, Y
	INY
	LDA #OPT_ONE_LARROW_LSB
	STA nmt_buffer, Y
	INY
	PLA			; get tile number from stack
	STA nmt_buffer, Y
	INY
	
	LDA #$01		; len 1
	STA nmt_buffer, Y
	INY
	LDA #OPT_ONE_RARROW_MSB
	STA nmt_buffer, Y
	INY
	LDA #OPT_ONE_RARROW_LSB
	STA nmt_buffer, Y
	INY
	PLA			; get tile number from stack
	STA nmt_buffer, Y
	INY

	;; Option 2 left and right arrow

	LDA #$01 		; len 1
	STA nmt_buffer, Y
	INY
	LDA #OPT_TWO_LARROW_MSB
	STA nmt_buffer, Y
	INY
	LDA #OPT_TWO_LARROW_LSB
	STA nmt_buffer, Y
	INY
	PLA			; get tile number from stack
	STA nmt_buffer, Y
	INY

	LDA #$01 		; len 1
	STA nmt_buffer, Y
	INY
	LDA #OPT_TWO_RARROW_MSB
	STA nmt_buffer, Y
	INY
	LDA #OPT_TWO_RARROW_LSB
	STA nmt_buffer, Y
	INY
	PLA			; get tile number from stack
	STA nmt_buffer, Y
	INY

	
	LDA #$00
	STA nmt_buffer, Y
	STY nmt_len

	JMP move_option_end	

;;; END OF OPTIONS_MENU ;;;

	;; Enter this function when the first option is chosen with A
OPTION_SCORE_TO_WIN:
	;; erase arrows around the option text
	LDY nmt_len
	LDA #$01		; len 1
	STA nmt_buffer, Y
	INY
	LDA #OPT_ONE_LARROW_MSB
	STA nmt_buffer, Y
	INY
	LDA #OPT_ONE_LARROW_LSB
	STA nmt_buffer, Y
	INY
	LDA #$00
	STA nmt_buffer, Y
	INY
	
	LDA #$01		; len 1
	STA nmt_buffer, Y
	INY
	LDA #OPT_ONE_RARROW_MSB
	STA nmt_buffer, Y
	INY
	LDA #OPT_ONE_RARROW_LSB
	STA nmt_buffer, Y
	INY
	LDA #$00
	STA nmt_buffer, Y
	INY
	
	;; draw the arrows around the numbers instead
	LDA #$01		; len 1
	STA nmt_buffer, Y
	INY
	LDA #OPT_ONE_NUM_LARROW_MSB
	STA nmt_buffer, Y
	INY
	LDA #OPT_ONE_NUM_LARROW_LSB
	STA nmt_buffer, Y
	INY
	LDA #$30
	STA nmt_buffer, Y
	INY
	
	LDA #$01		; len 1
	STA nmt_buffer, Y
	INY
	LDA #OPT_ONE_NUM_RARROW_MSB
	STA nmt_buffer, Y
	INY
	LDA #OPT_ONE_NUM_RARROW_LSB
	STA nmt_buffer, Y
	INY
	LDA #$31
	STA nmt_buffer, Y
	INY

	LDA #$00
	STA nmt_buffer, Y
	STY nmt_len
	LDA #$01
	STA need_nmt

	INC $0100

	JSR WAIT_FRAME

OPTION_SCORE_TO_WIN_LOOP:

	JSR WAIT_FRAME
	JMP OPTION_SCORE_TO_WIN_LOOP

;;; END OF OPTION_SCORE_TO_WIN_LOOP ;;;
