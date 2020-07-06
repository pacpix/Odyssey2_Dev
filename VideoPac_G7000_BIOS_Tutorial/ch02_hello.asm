	cpu	8048
	org 400h
	include "g7000.h"

	; BIOS routines in g7000.h
	jmp selectgame				; reset
	jmp irq						; interrupt
	jmp timer					; timer
	jmp vsyncirq				; VSYNC-interrupt
	jmp start					; start main program
	jmp soundirq				; sound-interrupt

timer retr

start:
	call	gfxoff				; switch the graphics off
	mov 	r0,#vdc_char0		; start char
	mov		r3,#20h				; x-position
	mov		r2,#0Bh				; length
	mov		r1,#hellostr & 0FFh	; the string to print

loop:
	mov		a,r1				; get pointer
	movp	a,@a				; get char
	mov		r5,a				; move pointer into r5
	inc		r1					; advance pointer
	mov		r6,#col_chr_white	; color
	call	printchar			; defined in g7000.h
	djnz	r2,loop				; loop until reach end of string
	call	gfxon				; display characters

stop:
	jmp 	stop

; Addresses of Hello World characters
hellostr 	db		1Dh, 12h, 0Eh, 0Eh, 17h, 0Ch
			db		11h, 17h, 13h, 0Eh, 1Ah