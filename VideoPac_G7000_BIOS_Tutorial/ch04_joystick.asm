; All VDC access is done using table routines

    cpu	8048
    
; internal ram vars
iram_xl		    equ	020h		; bit 0-7 of x position
iram_xh		    equ	021h		; bit 8 of y position
iram_y		    equ	022h		; y position
iram_colctrl	equ	023h		; color/control
iram_shape	    equ	024h		; last shape
    
	org 400h
	include "g7000.h"


	; BIOS routines in g7000.h
	jmp     selectgame				; reset
	jmp     irq						; interrupt
	jmp     timer					; timer
	jmp     vsyncirq				; VSYNC-interrupt
	jmp     loop					; start main program
	jmp     soundirq				; sound-interrupt

timer: 
    retr

loop:
    call    waitvsync               ; execute only once per frame
    mov     r1,#0                   ; joystick 0
    call    getjoystick             ; get offsets

    ; test if fire
    mov     r1,#iram_colctrl
    mov     a,#col_spr_white | spr_double
    jf0     firepressed
    mov     a,#col_spr_white

firepressed:
    mov     @r1,a                   ; store color/control
    call    decodejoystick          ; get direction from offsets
    call    extramenable            ; enable extram
    mov     r0,#07Fh                ; start of table

    ; test if joystick is in neutral position
    mov     a,r2                    ; x-offset
    jnz     shapetest               ; left/right
    mov     a,r3                    ; y-offset
    jnz     shapetest               ; up/down
    mov     r1,#8                   ; shape: neutral

shapetest:
    ; tests if the shape has changed since last frame
    mov     a,r1                    ; need to free-up r1 for pointer
    mov     r7,a                    ; move r1 value into r7
    mov     r1,#iram_shape          ; move internal ram sprite into r1
    mov     a,@r1                   ; store pointer to r1 in accumulator
    xrl     a,r7                    ; exclusive or stored in accumulator
    jz      setpos                  ; jump to setpos if accumulator is 0

    ; change iram_shape value
    mov     a,r7                    ; shape number
    mov     @r1,a                   ; move into r1 pointer

    ; init table to copy sprite data (in external ram)
    mov     a,#8                    ; copy 8 bytes
    movx    @r0,a 
    dec     r0 
    mov     a,#vdc_spr0_shape
    movx    @r0,a
    dec     r0

    ; copy sprite data
    mov     a,r7                    ; copy 8 bytes
    rl      a
    rl      a
    rl      a                       ; shifts left 1 position 3 times 3*rl = a*8
    add     a,#spritedata & 0FFh
    mov     r1,a                    ; start of shape
    mov     r7,#8                   ; allocate 8 bytes

copyspriteloop:
    mov     a,r1
    movp    a,@a                    ; get byte
    movx    @r0,a                   ; store in extram
    dec     r0 
    inc     r1
    djnz    r7,copyspriteloop

; adjusting sprite positions in iram
setpos:
    mov     r1,#iram_y              ; y position
    mov     a,@r1                   ; get position
    add     a,r3                    ; add offset
    mov     @r1,a                   ; store y position

    ; x is 9 bit add with carry
    ; expand r2 to 9 bit also
    mov     r1,#iram_xl             ; low byte
    mov     a,@r1                   ; get position
    add     a,r2                    ; add offset, set carry if needed
    mov     @r1,a                   ; store lowbyte of x
    mov     r1,#iram_xh             ; high byte
    mov     a,@r1                   ; get position
    addc    a,#0                    ; add the carry
    mov     r7,a                    ; we need this later
    mov     a,r2                    ; get offset
    rr      a                       ; reuse bit 1 of offset as bit 8
    add     a,r7                    ; add result from above to bit 8 of offset
    anl     a,#001h                 ; only need 1 bit
    mov     @r1,a                   ; store as high bit

    ; prepare table for sprite positions
    mov     a,#3                    ; copy 3 bytes
    movx    @r0,a
    dec     r0 
    mov     a,#vdc_spr0_ctrl
    movx    @r0,a
    dec     r0 

    ; set sprite positions from iram using table
    mov     r1,#iram_y              ; y position
    mov     a,@r1 
    movx    @r0,a                   ; move into external ram
    dec     r0

    ; x position recombine xh and xl and split into 8-1/0
    mov     r1,#iram_xh 
    mov     a,@r1
    rrc     a                       ; highest bit of sprite_x into carry
    mov     r1,#iram_xl             ; low byte of x position
    mov     a,@r1                   
    rrc     a                       ; lowest bit into carry, highest bit into r7
    movx    @r0,a 
    dec     r0 
    mov     a,#0
    rlc     a 
    mov     r7,a 
    mov     r1,#iram_colctrl 
    mov     a,@r1 
    orl     a,r7                    ; put together    
    movx    @r0,a                   ; move into sprite control 2
    dec     r0
    call    tableend
    jmp     loop

spritedata:
	db	00000000b
	db	00110000b
	db	01100000b
	db	11111111b
	db	11111111b
	db	01100000b
	db	00110000b
	db	00000000b

	db	11111000b
	db	11100000b
	db	11110000b
	db	10111000b
	db	10011100b
	db	00001110b
	db	00000111b
	db	00000010b

	db	00011000b
	db	00111100b
	db	01111110b
	db	01011010b
	db	00011000b
	db	00011000b
	db	00011000b
	db	00011000b

	db	00011111b
	db	00000111b
	db	00001111b
	db	00011101b
	db	00111001b
	db	01110000b
	db	11100000b
	db	01000000b

	db	00000000b
	db	00001100b
	db	00000110b
	db	11111111b
	db	11111111b
	db	00000110b
	db	00001100b
	db	00000000b

	db	01000000b
	db	11100000b
	db	01110000b
	db	00111001b
	db	00011101b
	db	00001111b
	db	00000111b
	db	00011111b

	db	00011000b
	db	00011000b
	db	00011000b
	db	00011000b
	db	01011010b
	db	01111110b
	db	00111100b
	db	00011000b

	db	00000010b
	db	00000111b
	db	00001110b
	db	10011100b
	db	10111000b
	db	11110000b
	db	11100000b
	db	11111000b

	db	00000000b
	db	00000000b
	db	00000000b
	db	00011000b
	db	00011000b
	db	00000000b
	db	00000000b
	db	00000000b

	end