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

	
	;; WRITE_TEXT expects the string addr in pointerLo/Hi
	;; clobber A, X, Y
	;; $00 == 0 means non menu text, 2 means menu
	;; $01 == draw arrows or not
	;; $02 = MSB of location to draw
	;; $03 = LSB of location to draw
WRITE_TEXT:
	LDY #$00
	LDX nmt_len
	LDA (pointerLo), Y	; length
	CLC
	ADC $00			; add $00 to len (can be 0 or 2)
	STA nmt_buffer, X
	LSR $00			; shift $00 right to halve it
	INY
	INX

	LDA $02			; MSB destination
	STA nmt_buffer, X
	INX
	LDA $03			; LSB destination
	SEC
	SBC $00			; move destination back by $00 (0 or 1)
	STA nmt_buffer, X
	INX

	;; if we want arrows, insert left one here
	LDA $00
	BEQ @get_txt_loop	; if not menu text, don't bother with this
	LDA $01
	CMP #$02
	BNE @no_left_arrow
	LDA #'<'
	JMP @left_char_chosen

@no_left_arrow:
	LDA #' '
@left_char_chosen:
	STA nmt_buffer, X
	INX
@get_txt_loop:
	LDA (pointerLo), Y
	BEQ @get_txt_loop_end
	;; if not 0, store a tile into nmt_buffer
	STA nmt_buffer, X
	INY
	INX
	JMP @get_txt_loop

@get_txt_loop_end:
	;; if we want arrows, insert right one here
	LDA $00
	BEQ @write_txt_end
	LDA $01
	CMP #$02
	BNE @no_right_arrow
	LDA #'>'
	JMP @right_char_chosen

@no_right_arrow:
	LDA #' '
@right_char_chosen:
	STA nmt_buffer, X
	INX

@write_txt_end:
	STX nmt_len
	RTS
;;; END OF WRITE_TXT ;;;


	;; WRITE_NUMS assumes length 2
	;; $00 == 0 for non menu, 2 for menu
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
	CMP #$01
	BNE @no_left_arrow
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
	CMP #$01
	BNE @no_right_arrow
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
	LDA #$00
	STA $00
	STA $01

	;; first draw "MY OWN"
	LDA #<my_own
	STA pointerLo
	LDA #>my_own
	STA pointerHi
	LDA #MYOWN_MSB
	STA $02
	LDA #MYOWN_LSB
	STA $03
	JSR WRITE_TEXT

	;; draw top half of pong logo
	LDA #<pong_top
	STA pointerLo
	LDA #>pong_top
	STA pointerHi
	LDA #PONG_TOP_MSB
	STA $02
	LDA #PONG_TOP_LSB
	STA $03
	JSR WRITE_TEXT

	;; now bottom half
	LDA #<pong_bot
	STA pointerLo
	LDA #>pong_bot
	STA pointerHi
	LDA #PONG_BOT_MSB
	STA $02
	LDA #PONG_BOT_LSB
	STA $03
	JSR WRITE_TEXT


	RTS
;;; END OF DRAW_MYOWNPONG ;;;


DRAW_PRESS_START:
	;; write "PRESS  START"
	LDA #$00
	STA $00
	STA $01
	LDA #<press_start
	STA pointerLo
	LDA #>press_start
	STA pointerHi
	LDA #PS_MSB
	STA $02
	LDA #PS_LSB
	STA $03
	JSR WRITE_TEXT

	RTS
;;; END OF DRAW_PRESS_START ;;;


DRAW_MENU:
	;; write "PLAY"
	LDA #$00
	STA $00
	STA $01

	LDA #<play
	STA pointerLo
	LDA #>play
	STA pointerHi
	LDA #PLAY_MSB
	STA $02
	LDA #PLAY_LSB
	STA $03
	JSR WRITE_TEXT

	;; write "OPTIONS"
	LDA #<options
	STA pointerLo
	LDA #>options
	STA pointerHi
	LDA #OPT_MSB
	STA $02
	LDA #OPT_LSB
	STA $03
	JSR WRITE_TEXT

	;; erase "PRESS  START"
	LDA #PS_LSB
	LDY #PS_MSB
	LDX #PS_SIZE
	JSR STRIKEOUT

	RTS
;;; END OF DRAW_MENU ;;;

DRAW_OPTIONS_SUBMENU:
	LDA #$00
	STA $0A
@loop:
	TAX
	LDA menu_label, X
	ORA menu_label + 1, X
	BNE @cont
	JMP @done

@cont:
	LDA menu_label, X
	STA pointerLo
	LDA menu_label + 1, X
	STA pointerHi

	LDA #$02
	STA $00

	CPX selected_option
	BNE @not_selected
	;; else this is selected
	LDA select_type
	JMP @selection_decided

@not_selected:
	LDA #$00
@selection_decided:
	STA $01

	LDA menu_label_MSB, X
	STA $02

	LDA menu_label_LSB, X
	STA $03

	JSR WRITE_TEXT
	LDX $0A
	LDY #$00
	LDA #$02
	STA $00

	LDA menu_type, X
	BEQ @menu_sprite
	;; else for now assume it's a number-based option
	LDA menu_tx, X
	STA $02
	LDA menu_ty, X
	STA $03

	LDA menu_var, X
	STA pointerLo
	LDA menu_var + 1, X
	STA pointerHi
	LDA (pointerLo), Y
	STA $06
	JSR BIN_TO_DEC
	
	JSR WRITE_NUMS
	JMP @menu_sprite_done

@menu_sprite:
	LDA menu_addr_x, X
	STA pointerLo
	LDA menu_addr_x + 1, X
	STA pointerHi
	LDA menu_tx, X
	STA (pointerLo), Y

	LDA menu_addr_y, X
	STA pointerLo
	LDA menu_addr_y + 1, X
	STA pointerHi
	LDA menu_ty, X
	STA (pointerLo), Y

	LDA #<sprite_select
	STA pointerLo
	LDA #>sprite_select
	STA pointerHi

	LDA menu_label_MSB, X
	STA $02
	LDA menu_label_LSB, X
	CLC
	ADC #$14
	STA $03

	LDA select_type
	CMP #$01
	BNE @menu_sprite_not_selected
	INC $01

	
	JSR WRITE_TEXT
	JMP @menu_sprite_done

	@menu_sprite_not_selected:
	LDA #$01
	STA $01
	JSR WRITE_TEXT
	@menu_sprite_done:

	LDA $0A
	CLC
	ADC #SIZEOF_MENU_ENTRY
	STA $0A
	JMP @loop
@done:

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

	LDA ctrl_input
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
	LDX ctrl_jp_input
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
	JSR OPTIONS_SUBMENU
	JMP TITLE_SCREEN_MENU


	;; start the game already!
game_start:
	;; get paddle sprites into position
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
top_line_loop:
	STA nmt_buffer, Y
	INY
	DEX
	BNE top_line_loop

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

OPTIONS_SUBMENU:
	JSR DRAW_OPTIONS_SUBMENU

	LDY nmt_len
	LDA #$00
	STA nmt_buffer, Y

	LDA #$01
	STA need_nmt

	;; hide cursor
	LDA #$FF
	STA cursor_y

	;; fall through to OPTIONS_SUBMENU_LOOP

OPTIONS_SUBMENU_LOOP:
	JSR GET_PLAYER_INPUT
	LDX ctrl_jp_input
	TXA
	AND #BTN_B
	BNE leave_options_submenu
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
	JSR COMMON_END
	JMP OPTIONS_SUBMENU_LOOP


leave_options_submenu:
	LDA #$00
	STA selected_option
	STA $0A

	@loop:
	TAX
	LDA menu_label, X
	ORA menu_label + 1, X
	BNE @cont
	JMP @done

@cont:
	
	LDY menu_label_MSB, X
	LDA menu_label_LSB, X
	SEC
	SBC #$01
	LDX #$17		; length of text plus num section
	JSR STRIKEOUT

	LDA $0A
	CLC
	ADC #SIZEOF_MENU_ENTRY
	STA $0A
	JMP @loop

@done:
	LDA #$FF
	STA paddle_int_y
	STA paddle_int_y + 1
	
	LDA #CURSOR_SECOND_POS
	STA cursor_y

	LDY nmt_len
	LDA #$00
	STA nmt_buffer, Y
	LDA #$01
	STA need_nmt
	JSR COMMON_END

	RTS

	;; When A is pressed, we enter the function that handles whatever
	;; setting was being selected
modify_setting:
	JSR MODIFY_SETTING
	JMP OPTIONS_SUBMENU_LOOP

select_option_1:
	JSR OPTION_SCORE_TO_WIN
	JMP OPTIONS_SUBMENU

move_option_up:
	LDA selected_option
	BEQ OPTIONS_MENU_END	; if option already 0, don't move
	SEC
	SBC #SIZEOF_MENU_ENTRY
	STA selected_option
	JMP move_option_apply

move_option_down:
	LDA selected_option
	CMP #SIZEOF_MENU_ENTRY * NUM_MENU_ENTRIES - SIZEOF_MENU_ENTRY
	BEQ OPTIONS_MENU_END
	CLC
	ADC #SIZEOF_MENU_ENTRY
	STA selected_option
	;; JMP move_option_apply
	;; fall through

move_option_apply:

	JSR DRAW_OPTIONS_SUBMENU
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
	JSR DRAW_OPTIONS_SUBMENU
	LDY nmt_len
	LDA #$00
	STA nmt_buffer, Y
	LDA #$01
	STA need_nmt

OPTION_SCORE_TO_WIN_LOOP:
	JSR GET_PLAYER_INPUT
	LDX ctrl_jp_input
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
	JSR DRAW_OPTIONS_SUBMENU
	LDY nmt_len
	LDA #$00
	STA nmt_buffer, Y
	LDA #$01
	STA need_nmt
OPTION_SCORE_TO_WIN_END:
	JSR WAIT_FRAME
	JMP OPTION_SCORE_TO_WIN_LOOP

;;; END OF OPTION_SCORE_TO_WIN_LOOP ;;;


	
	.segment "RODATA"
.LINECONT +
menu_entries:
	menu_entry win_score_str, $20, $C5, %00000001, $20, $D9, paddle_int_x, paddle_int_y, \
	win_score, $03, $63

	menu_entry p1_look, $21, $25, %00000000, $CF, $44, paddle_int_x, paddle_int_y, \
	paddle_palette, $00, $03

	menu_entry p2_look, $21, $85, %00000000, $CF, $5C, paddle_int_x+1, paddle_int_y+1, \
	paddle_palette+1, $00, $03

	.addr $0000

	.segment "CODE"
MODIFY_SETTING:
	LDA #$01
	STA select_type

	;; fall through

MODIFY_SETTING_LOOP:
	JSR GET_PLAYER_INPUT
	LDX ctrl_jp_input
	TXA
	AND #BTN_B
	BNE back_to_menu
	TXA
	AND #BTN_RIGHT
	BNE increase_option
	TXA
	AND #BTN_LEFT
	BNE decrease_option

	;; fall through
	
modify_setting_loop_end:
	JSR DRAW_OPTIONS_SUBMENU
	LDA #$01
	STA need_nmt
	LDY nmt_len
	LDA #$00
	JSR COMMON_END
	JMP MODIFY_SETTING_LOOP

back_to_menu:
	LDA #$02
	STA select_type
	JSR DRAW_OPTIONS_SUBMENU
	LDA #$01
	STA need_nmt
	LDY nmt_len
	LDA #$00
	STA nmt_buffer, Y
	RTS

increase_option:
	LDX selected_option
	LDY #$00
	LDA menu_var, X
	STA pointerLo
	LDA menu_var + 1, X
	STA pointerHi

	LDA menu_var_max, X
	CMP (pointerLo), Y
	BEQ modify_setting_loop_end
	LDA #$01
	CLC
	ADC (pointerLo), Y
	STA (pointerLo), Y
	JMP modify_setting_loop_end

decrease_option:
	LDX selected_option
	LDY #$00
	LDA menu_var, X
	STA pointerLo
	LDA menu_var + 1, X
	STA pointerHi

	LDA menu_var_min, X
	CMP (pointerLo), Y
	BEQ modify_setting_loop_end
	LDA #$FF
	CLC
	ADC (pointerLo), Y
	STA (pointerLo), Y
	JMP modify_setting_loop_end	

;;; END OF MODIFY_SETTING ;;;
