; lots of opcodes test, 'alphabetical'
; Not a program, just check output and see that it assembles.

	adc 3
	adc a
	adc b
	adc (hl)
	add 3
	add c
	add (hl)
	add hl,de
	add sp,-20
	and $80
	and c
	bit 3,c
	bit 5,(hl)
	call nz,0x2233 ; BUG: -> 0x%%%% hex number don't proc right. fix in getNum
	call c,$4488
	call $DEAD
	ccf
	cp b
	cp (hl)
	cp a
	cp 84
	cpl
	daa
	dec (hl)
	dec c
	dec hl
	dec de
	di
	ei
	nop
	nop
	halt
	nop
	nop
	inc a
	inc b
	inc (hl)
	jp hl
	jp z,0x2050
	jp nc,0x04E6
	jp 0x0BED
	jp $ed0b
	jr c,0x10
	jr n,-10
	jr $55
	ld ($1020) sp
	ld (0x2040) sp
	ldio (c),a
	ldio ($0f),a
	ldio (0xff),a
	ldio a,(c)
	ldio a,($f0)
	ldio a,(0xBF)
	ld ($1020),a
	ld (0xA0b0),a
	ld (de),a
	ld (hl+),a
	ld (hld),a
	ld a,($3040)
	ld a,(hl-)
	ld a,(bc)
	ldhl sp -10
	ldhl sp 0x20
	ldsp hl
	ld a,(hl)
	ld b,c
	ld b,b
	ld (hl),a
	ld (hl),d
	ld a,0xff
	ld c,-20
	ld de,$0DE0
	ld bc,0x0cb0
	nop
	or 0x80
	or c
	or (hl)
	pop af
	pop hl
	pop de
	push de
	push hl
	push af
	res 2,a
	res 1,(hl)
	ret
	ret nz
	ret nc
	ret c
	reti
	rl a
	rl b
	rl c
	rla
	rl (hl)
	rlc (hl)
	rlc b
	rlca
	rlc a
	rr a
	rr b
	rr (hl)
	rra
	rrc d
	rrca
	rst 0x08 ; lalala
	sbc c
	sbc a
	sbc (hl)
	sbc -10
	scf
	set 4,a
	set 0,(hl)
	set 5,e
	sla a
	sla b
	sla (hl)
	sra a
	sra c
	sra d
	srl a
	srl (hl)
	nop
	stop  ; no$ says 'currupted' stop??
	nop
	sub c
	sub e
	sub (hl)
	sub $ff
	sub 20
	swap a
	swap (hl)
	swap b
	swap c
	xor a
	xor (hl)
	xor $55
	xor 0xff
	xor 0x80
	jr -2 ; loop in place.




