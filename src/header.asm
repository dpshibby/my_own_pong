	.segment "HEADER"
	.byte "NES"		; these two lines make up the
	.byte $1A		; iNES header
	.byte $02		; 2 PRG-ROM banks
	.byte $01		; 1 CHR-ROM bank
	.byte %00000001		; vertical mirroring, no saves, no mem mapping
	.byte %00000000		; no special flags
	.byte $00		; no PRG-RAM
	.byte $00		; NTSC format
