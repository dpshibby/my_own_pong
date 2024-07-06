	.segment "RODATA"
default_palette:
	.byte $1F, $00, $20, $20 ; bg palettes
	.byte $1F, $00, $20, $20
	.byte $1F, $20, $20, $20
	.byte $1F, $20, $20, $20

	.byte $1F, $00, $10, $20 ; sprite palettes
	.byte $1F, $20, $20, $2A
	.byte $1F, $20, $20, $11
	.byte $1F, $20, $20, $24

	;; these are all the same for now while I experiment :)
	.segment "CODE"
