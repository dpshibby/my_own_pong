	PPUCTRL      = $2000
	PPUMASK      = $2001
	PPUSTATUS    = $2002
	PPUSCROLL    = $2005
	PPUADDR      = $2006
	PPUDATA      = $2007

	OAMADDR      = $2003
	OAMDMA       = $4014

	CONTROLLER_1 = $4016
	CONTROLLER_2 = $4017
	
	BTN_RIGHT    = %00000001
	BTN_LEFT     = %00000010
	BTN_DOWN     = %00000100
	BTN_UP       = %00001000
	BTN_START    = %00010000
	BTN_SELECT   = %00100000
	BTN_B        = %01000000
	BTN_A        = %10000000

	;; These aren't exactly constants but good enough
	.charmap 'A', $10
	.charmap 'B', $11
	.charmap 'C', $12
	.charmap 'D', $13
	.charmap 'E', $14
	.charmap 'F', $15
	.charmap 'G', $16
	.charmap 'H', $17
	.charmap 'I', $18
	.charmap 'J', $19
	.Charmap 'K', $1A
	.charmap 'L', $1B
	.charmap 'M', $1C
	.charmap 'N', $1D
	.charmap 'O', $1E
	.charmap 'P', $1F
	.charmap 'Q', $20
	.charmap 'R', $21
	.charmap 'S', $22
	.charmap 'T', $23
	.charmap 'U', $24
	.charmap 'V', $25
	.charmap 'W', $26
	.charmap 'X', $27
	.charmap 'Y', $28
	.charmap 'Z', $29
	.charmap '<', $30
	.charmap '>', $31
	.charmap ' ', $03
	.charmap '0', $40
	.charmap '1', $41
	.charmap '2', $42
	.charmap '3', $43
	.charmap '4', $44
	.charmap '5', $45
	.charmap '6', $46
	.charmap '7', $47
	.charmap '8', $48
	.charmap '9', $49
	
	.segment "RODATA"
string_table:
	;; title screen entries
	.word my_own
	.word pong_top
	.word pong_bot
	.word press_start
	.word play
	.word options
	
	;; option submenu entries
	.word win_score

	;; entries for end of game/replay
	.word p1_win
	.word p2_win
	.word play_again
	.word quit

	;; label: text associated with the entry
	;; l_MSB, l_LSB: nametable addr to write the label
	;; type: is the menu entry going to modify a number, text, or sprite?
	;; t_x, t_y: x and y to display the sprite
	;; NB: if it not a sprite type then these will be nametable addr of num
	;; t_addr_x, t_addr_y: address of sprite data so it can be set according to t_x/t_y
	;; var_1, var_2: variables that can be modified with this menu entry
	;; NB: if the menu type is number then var_1 and var_2 will be what is displayed
	.macro menu_entry label, l_MSB, l_LSB, type, t_x, t_y, t_addr_x, t_addr_y, var, var_min, var_max
	.addr label
	.byte l_MSB, l_LSB, type, t_x, t_y
	.addr t_addr_x, t_addr_y
	.addr var
	.byte var_min, var_max
	.endmacro

	SIZEOF_MENU_ENTRY = 15
	NUM_MENU_ENTRIES  = 3
	menu_label         := menu_entries + 0
	menu_label_MSB     := menu_entries + 2
	menu_label_LSB     := menu_entries + 3
	menu_type          := menu_entries + 4
	menu_tx            := menu_entries + 5
	menu_ty            := menu_entries + 6
	menu_addr_x        := menu_entries + 7
	menu_addr_y        := menu_entries + 9
	menu_var           := menu_entries + 11
	menu_var_min       := menu_entries + 13
	menu_var_max       := menu_entries + 14

	.macro plaintext_entry entry_name, msb, lsb
	.addr entry_name
	.byte msb, lsb
	.endmacro

	SIZEOF_PLAINTEXT_ENTRY = 4
	pt_entry_name    := menu_entries + 0
	pt_entry_MSB     := menu_entries + 2
	pt_entry_LSB     := menu_entries + 3

	.macro string_entry str
	.byte .strlen(str), str, $00
	.endmacro

plaintext:
	plaintext_entry my_own, MYOWN_MSB, MYOWN_LSB
	.byte PONG_TOP_SIZE
	.addr pong_top
	.byte PONG_TOP_MSB, PONG_TOP_LSB
	.byte PONG_BOT_SIZE
	.addr pong_bot
	.byte PONG_BOT_MSB, PONG_BOT_LSB
	plaintext_entry press_start, PS_MSB, PS_LSB

my_own:
	string_entry "MY OWN"

pong_top:
	.byte $08, $60, $61, $62, $63, $64, $65, $66, $67, 0
pong_bot:
	.byte $08, $70, $71, $72, $73, $74, $75, $76, $77, 0
press_start:
	string_entry "PRESS  START"
play:
	string_entry "PLAY"
options:
	string_entry "OPTIONS"
win_score_str:
	string_entry "SCORE TO WIN"
p1_look:
	string_entry "P1 LOOK"
p2_look:
	string_entry "P2 LOOK"
sprite_select:
	string_entry "  "
p1_win:
	string_entry "P1  WINS"
p2_win:
	string_entry "P2  WINS"
play_again:
	string_entry "PLAY AGAIN"
quit:
	string_entry "QUIT"



