	;; Title Screen constants
	MYOWN_MSB          = $21
	MYOWN_LSB          = $8D
	MYOWN_SIZE         = $06
	MYOWN_I            = $00

	PONG_TOP_MSB       = $21
	PONG_TOP_LSB       = $CC
	PONG_TOP_SIZE      = $08
	PONG_TOP_I         = $01

	PONG_BOT_MSB       = $21
	PONG_BOT_LSB       = $EC
	PONG_BOT_SIZE      = $08
	PONG_BOT_I         = $02

	PS_MSB             = $22
	PS_LSB             = $EA
	PS_SIZE            = $0C
	PS_I               = $03

	PLAY_MSB           = $22
	PLAY_LSB           = $CF
	PLAY_SIZE          = $04
	PLAY_I             = $04

	OPT_MSB            = $23
	OPT_LSB            = $2F
	OPT_SIZE           = $07
	OPT_I              = $05

	CURSOR_X           = $68
	CURSOR_FIRST_POS   = $B1
	CURSOR_SECOND_POS  = $C9

	;; Options menu constants
	WIN_SCORE_MSB      = $20
	WIN_SCORE_LSB      = $C5
	WIN_SCORE_SIZE     = $0C
	WIN_SCORE_I        = $06

	WIN_SCORE_NUM_MSB  = $20
	WIN_SCORE_NUM_LSB  = $D9
	WIN_SCORE_NUM_SIZE = $02

	SAMPLE_MSB         = $21
	SAMPLE_LSB         = $05
	SAMPLE_SIZE        = $06
	SAMPLE_I           = $07

	SAMPLE_NUM_MSB     = $21
	SAMPLE_NUM_LSB     = $19
	SAMPLE_NUM_SIZE    = $02

	WINNER_MSB         = $21
	WINNER_LSB         = $8C
	WINNER_SIZE        = $08
	P1_WIN_I           = $08
	P2_WIN_I           = $09

	PLAY_AG_MSB        = $22
	PLAY_AG_LSB        = $CF
	PLAY_AG_SIZE       = $0A
	PLAY_AG_I          = $0A

	QUIT_MSB           = $23
	QUIT_LSB           = $2F
	QUIT_SIZE          = $04
	QUIT_I             = $0B


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; TITLE_SCREEN function subroutines ;;;

	;; $01 == 0 for not selected,
	;; $01 == 1 for num selected,
	;; $01 == 2 for text selected
DRAW_SCORE_OPT:
	LDA $01
	CMP #$01
	BEQ @num_selected
	;; if num is not selected, can call the
	;; text portion as-is
	LDA #WIN_SCORE_I
	JSR WRITE_TXT
	LDA #$00		; num not selected
	STA $01
	JMP @draw_num

@num_selected:
	LDA #$00		; text not selected
	STA $01
	LDA #WIN_SCORE_I
	JSR WRITE_TXT
	LDA #$01
	STA $01
@draw_num:
	LDA #$02		; restore this since WRITE_TXT changes it
	STA $00
	LDA #WIN_SCORE_NUM_MSB
	STA $02
	LDA #WIN_SCORE_NUM_LSB
	STA $03
	LDA win_score_MSB
	STA $04
	LDA win_score_LSB
	STA $05
	JSR WRITE_NUMS

;; draw_score_opt_end:
	RTS
;;; END OF DRAW_SCORE_OPT

	;; $01 == 0 for not selected,
	;; $01 == 1 for num selected,
	;; $01 == 2 for text selected
DRAW_SAMPLE_OPT:
	LDA $01
	CMP #$01
	BEQ @num_selected
	;; if num is not selected, can call the
	;; text portion as-is
	LDA #SAMPLE_I
	JSR WRITE_TXT
	LDA #$00		; num not selected
	STA $01
	JMP @draw_num

@num_selected:
	LDA #$00
	STA $01
	LDA #SAMPLE_I
	JSR WRITE_TXT
	LDA #$01
	STA $01
@draw_num:
	LDA #$02		; restore this since WRITE_TXT changes it
	STA $00
	LDA #SAMPLE_NUM_MSB
	STA $02
	LDA #SAMPLE_NUM_LSB
	STA $03
	LDA #$03
	STA $04
	LDA #$00
	STA $05
	JSR WRITE_NUMS

	RTS
;;; END OF DRAW_SAMPLE_OPT

	;; WRITE_TXT expects the string index in A and will
	;; clobber A, X, Y
	;; $00 == 0 means non menu text, 2 means menu
	;; option to draw arrows at addr $01
WRITE_TXT:
	ASL
	TAX
	LDA string_table, X
	STA pointerLo
	LDA string_table + 1, X
	STA pointerHi

	LDY #$00
	LDX nmt_len
	LDA (pointerLo), Y	; length
	CLC
	ADC $00			; add $00 to len (can be 0 or 2)
	STA nmt_buffer, X
	LSR $00			; shift $00 right to halve it
	INY
	INX

	LDA (pointerLo), Y	; MSB destination
	STA nmt_buffer, X
	INY
	INX
	LDA (pointerLo), Y	; LSB destination
	SEC
	SBC $00			; move destination back by $00 (0 or 1)
	STA nmt_buffer, X
	INY
	INX

	;; if we want arrows, insert left one here
	LDA $00
	BEQ get_txt_loop	; if not menu text, don't bother with this
	LDA $01
	BEQ @no_left_arrow
	LDA #'<'
	JMP @left_char_chosen

@no_left_arrow:
	LDA #' '
@left_char_chosen:
	STA nmt_buffer, X
	INX
get_txt_loop:
	LDA (pointerLo), Y
	BEQ get_txt_loop_end
	;; if not 0, store a tile into nmt_buffer
	STA nmt_buffer, X
	INY
	INX
	JMP get_txt_loop

get_txt_loop_end:
	;; if we want arrows, insert right one here
	LDA $00
	BEQ write_txt_end
	LDA $01
	BEQ @no_right_arrow
	LDA #'>'
	JMP @right_char_chosen

@no_right_arrow:
	LDA #' '
@right_char_chosen:
	STA nmt_buffer, X
	INX

write_txt_end:
	STX nmt_len
	RTS
;;; END OF WRITE_TXT ;;;

	;; WRITE_NUMS assumes length 2
	;; $00 == 0 for non menu 2 for menu
	;; option to draw arrows in $01
	;; gets addr MSB from $02 and LSB from $03
	;; gets actual num MSB from $04 and LSB from $05
	;; clobbers A, X, Y
WRITE_NUMS:
	LDX nmt_len
	LDA #$02		; length default
	CLC
	ADC $00			; add what's in $00
	STA nmt_buffer, X
	LSR $00
	INX
	LDA $02			; get MSB where to print
	STA nmt_buffer, X
	INX

	LDA $03			; get LSB where to print
	SEC
	SBC $00			; move back by what's in $00
	STA nmt_buffer, X
	INX

	;; if we want left arrow, put it now
	LDA $01
	BEQ @no_left_arrow
	LDA #'<'
	JMP @no_left_arrow_done

@no_left_arrow:
	LDA #' '
@no_left_arrow_done:
	STA nmt_buffer, X
	INX

	;; now write MSB of number
	LDA $04
	CLC
	ADC #$40		; num to tile offset
	STA nmt_buffer, X
	INX
	LDA $05
	CLC
	ADC #$40		; num to tile offset
	STA nmt_buffer, X
	INX

	;; now if we want right arrow, add it
	LDA $01
	BEQ @no_right_arrow
	LDA #'>'
	JMP @no_right_arrow_done

@no_right_arrow:
	LDA #' '
@no_right_arrow_done:
	STA nmt_buffer, X
	INX

write_nums_end:
	STX nmt_len
	RTS
;;; END WRITE_NUMS ;;;

DRAW_MYOWNPONG:
	;; first draw "MY OWN"
	LDA #MYOWN_I 		; index
	JSR WRITE_TXT

	;; draw top half of pong logo
	LDA #PONG_TOP_I
	JSR WRITE_TXT

	;; now bottom half
	LDA #PONG_BOT_I
	JSR WRITE_TXT


	RTS
;;; END OF DRAW_MYOWNPONG ;;;


DRAW_PRESS_START:
	;; write "PRESS  START"
	LDA #PS_I
	JSR WRITE_TXT

	RTS
;;; END OF DRAW_PRESS_START ;;;


DRAW_MENU:
	;; write "PLAY"
	LDA #PLAY_I
	JSR WRITE_TXT

	;; write "OPTIONS"
	LDA #OPT_I
	JSR WRITE_TXT

	;; erase "PRESS  START"
	LDA #PS_LSB
	LDY #PS_MSB
	LDX #PS_SIZE
	JSR STRIKEOUT

	RTS
;;; END OF DRAW_MENU ;;;

DRAW_OPTIONS_MENU:
	;; first option, score to win
	LDA #$02		; these are all menu text so put a 2 here
	STA $00
	LDX #$00
	CPX selected_option
	BNE @not_selected
	;; else option selected is 0
	LDA select_type
	JMP store_first

@not_selected:
	LDA #$00

store_first:
	STA $01
	TXA
	PHA
	JSR DRAW_SCORE_OPT
	PLA
	TAX

	;; second option, the sample option
	LDA #$02		; these are all menu text so put a 2 here
	STA $00
	INX
	LDA selected_option
	CPX selected_option
	BNE @not_selected
	;; else option selected is 1
	LDA select_type
	JMP store_second

@not_selected:
	LDA #$00

store_second:
	STA $01
	TXA
	PHA
	JSR DRAW_SAMPLE_OPT
	PLA
	TAX

	;; next option here
	;; LDA #$02		; these are all menu text so put a 2 here
	;; STA $00
	;; INX

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
	STA $0214
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
	JSR DRAW_MYOWNPONG
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
	STA $0214

	LDA #$00
	STA $0215
	STA $0216
	LDA #CURSOR_X
	STA $0217

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

	;; hide cursor
	LDA #$FF
	STA cursor_y

	JMP GAME_INIT

OPTIONS_MENU:
	JSR DRAW_OPTIONS_MENU

	LDY nmt_len
	LDA #$00
	STA nmt_buffer, Y

	LDA #$01
	STA need_nmt

	;; hide cursor
	LDA #$FF
	STA $0214

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

	;; fall through
OPTIONS_MENU_END:
	JSR WAIT_FRAME
	JMP OPTIONS_MENU_LOOP


leave_options_menu:
	LDA #$00
	STA $00
	STA $00
	LDA #$00
	STA selected_option
	;; erase option 1
	LDX #$17		; length of text plus num section
	LDY #WIN_SCORE_MSB
	LDA #WIN_SCORE_LSB
	SEC
	SBC #$01
	JSR STRIKEOUT

	;; erase option 1
	LDX #$17		; length of text plus num section
	LDY #SAMPLE_MSB
	LDA #SAMPLE_LSB
	SEC
	SBC #$01
	JSR STRIKEOUT

	LDY nmt_len
	LDA #$00
	STA nmt_buffer, Y
	LDA #$01
	STA need_nmt
	JSR WAIT_FRAME

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
	JMP OPTIONS_MENU

move_option_up:
	LDA selected_option
	BEQ OPTIONS_MENU_END	; if option already 0, don't move
	DEC selected_option
	JMP move_option_apply

move_option_down:
	LDA selected_option
	CMP #$01		; current num of options - 1, use a CONST later
	BEQ OPTIONS_MENU_END
	INC selected_option
	;; JMP move_option_apply
	;; fall through

move_option_apply:

	JSR DRAW_OPTIONS_MENU
	LDA #$01
	STA need_nmt
	JMP OPTIONS_MENU_END

;;; END OF OPTIONS_MENU ;;;

	;; This function can probably be re-written to be much more general
	;; maybe by figuring out how to access the associated variables with
	;; each menu option
	;; Enter this function when the first option is chosen with A
OPTION_SCORE_TO_WIN:
	LDA #$01
	STA select_type
	JSR DRAW_OPTIONS_MENU
	LDY nmt_len
	LDA #$00
	STA nmt_buffer, Y
	LDA #$01
	STA need_nmt

OPTION_SCORE_TO_WIN_LOOP:
	JSR GET_PLAYER_INPUT
	LDX ctrl_jp_input_1
	TXA
	AND #BTN_RIGHT
	BNE @inc_setting
	TXA
	AND #BTN_LEFT
	BNE @dec_setting
	TXA
	AND #BTN_B
	BNE @leave_menu
	JMP OPTION_SCORE_TO_WIN_END

@inc_setting:
	INC win_score_LSB
	LDA win_score_LSB
	CMP #$0A		; did LSB hit 10?
	BNE @change_setting_end
	;; if so, also inc MSB
	INC win_score_MSB
	LDA #$00
	STA win_score_LSB
	LDA win_score_MSB
	CMP #$0A
	BNE @change_setting_end
	LDA #$09
	STA win_score_LSB
	STA win_score_MSB
	JMP @change_setting_end

@dec_setting:
	DEC win_score_LSB
	LDA win_score_MSB
	CMP #$00
	BNE @no_three_check      ; if not 0, do normal dec
	;; if MSB is 0, don't let LSB go below 3
	LDA win_score_LSB
	CMP #$02		; lower than 3?
	BNE @change_setting_end
	;; if lower than 3, set back to 3
	LDA #$03
	STA win_score_LSB
	JMP @change_setting_end

@no_three_check:
	LDA win_score_LSB
	CMP #$FF		; wrapped to -1?
	BNE @change_setting_end
	;; if it did wrap, also dec MSB
	DEC win_score_MSB
	LDA #$09
	STA win_score_LSB
	JMP @change_setting_end

@leave_menu:
	LDA #$02
	STA select_type
	RTS

@change_setting_end:
	JSR DRAW_OPTIONS_MENU
	LDY nmt_len
	LDA #$00
	STA nmt_buffer, Y
	LDA #$01
	STA need_nmt
OPTION_SCORE_TO_WIN_END:
	JSR WAIT_FRAME
	JMP OPTION_SCORE_TO_WIN_LOOP

;;; END OF OPTION_SCORE_TO_WIN_LOOP ;;;
