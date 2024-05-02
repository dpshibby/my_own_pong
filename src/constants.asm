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
	.charmap ' ', $01
	
	.segment "RODATA"
string_table:
	.word my_own
	.word pong_top
	.word pong_bot
	.word press_start
	.word play
	.word options
	.word win_score
my_own:
	.byte MYOWN_SIZE, MYOWN_MSB, MYOWN_LSB, "MY OWN", 0
pong_top:
	.byte PONG_TOP_SIZE, PONG_TOP_MSB, PONG_TOP_LSB
	.byte $60, $61, $62, $63, $64, $65, $66, $67, 0
pong_bot:
	.byte PONG_BOT_SIZE, PONG_BOT_MSB, PONG_BOT_LSB
	.byte $70, $71, $72, $73, $74, $75, $76, $77, 0
press_start:
	.byte PS_SIZE, PS_MSB, PS_LSB, "PRESS  START", 0
play:
	.byte PLAY_SIZE, PLAY_MSB, PLAY_LSB, "PLAY", 0
options:
	.byte OPT_SIZE, OPT_MSB, OPT_LSB, "OPTIONS", 0
win_score:
	.byte WIN_SCORE_SIZE, WIN_SCORE_MSB, WIN_SCORE_LSB, "<SCORE TO WIN>", 0
