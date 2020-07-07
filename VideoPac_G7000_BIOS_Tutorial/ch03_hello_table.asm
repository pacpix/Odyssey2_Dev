; This version automatically copies character data into the VDC registers
; Number of bytes to copy - 07Fh in external ram
; Pointer to first register at 07Eh
; Bytes to put in ascending registers stored in descending order at 07Dh
; Table is activated when irq_table = bit 7 of iram_irqcontrol = 03Fh in internal ram is set
; Table is copied into registers on next VSYNC interrupt

    cpu	8048
	org 400h
	include "g7000.h"

	; BIOS routines in g7000.h
	jmp     selectgame				; reset
	jmp     irq						; interrupt
	jmp     timer					; timer
	jmp     vsyncirq				; VSYNC-interrupt
	jmp     start					; start main program
	jmp     soundirq				; sound-interrupt

timer: 
    retr

start:
    call    extramenable            ; enabling external ram (outside of processor) 00ECh
    mov     r0,#07FH                ; memory location of table start into r0
    mov     a,#02Ch                 ; 4 bytes / char * 0Bh stored in accumulator
    movx    @r0,a                   ; accumulator into r0 memory address (movx since external)
    dec     r0                      ; decrement r0, moves to next byte in table
    mov     a,#vdc_char0            ; first vdc register
    movx    @r0,a                   ; accumulator into r0 memory address
    dec     r0                      ; next byte in table
    mov     r3,#20h                 ; x-position
    mov     r4,#20h                 ; y-position
    mov     r2,#0Bh                 ; length (11 bytes)
    mov     r1,#hellostr & 0FFh     ; string to print

loop:
    mov     a,r1                    ; move string pointer into accumulator
    movp    a,@a                    ; move character into accumulator
    mov     r5,a                    ; move character into r5
    inc     r1                      ; advance string pointer to next char
    mov     r6,#col_chr_green       ; green text
    call    tableprintchar          ; put characters into table 0197h
    djnz    r2,loop                 ; decrement r2 (length), loop if not 0
    call    tableend                ; activates end marker of table at 0132h

stop:
    jmp     stop

hellostr:
    db      1Dh, 12h, 0Eh, 0Eh, 17h, 0Ch
    db      11h, 17h, 13h, 0Eh, 1Ah