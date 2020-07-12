    cpu	8048
	org 400h
	include "g7000.h"

	; BIOS routines in g7000.h
	jmp     selectgame				    ; reset
	jmp     irq						    ; interrupt
	jmp     timer					    ; timer
	jmp     vsyncirq				    ; VSYNC-interrupt
	jmp     start					    ; start main program
	jmp     soundirq				    ; sound-interrupt

timer:
    ret


start:
    call    gfxoff                   ; turn off graphics while editing vdc
    call    init_sprite
    call    game_loop
    

init_sprite:
    mov     r0,#vdc_spr0_shape         ; moving sprite into useable register
    mov     r1,#ghost_sprite & 0ffh
    mov     r7,#8
    call    copy_sprite

    ; y position set
    mov     r0,#000h
    movx    a,@r0
    mov     a,#100
    movx    @r0,a

    ; x position set
    mov     r0,#001h
    movx    a,@r0 
    mov     a,#80
    movx    @r0,a

    ; color
    mov     r0,#002h
    movx    a,@r0
    mov     a,#col_spr_violet 
    movx    @r0,a 

    ret


game_loop:
    ; advance one frame
    call    gfxon
    call    waitvsync
    call    gfxoff

    mov     r1,#000h            ; select joystick 0
    call    getjoystick
    mov     a,r1 
    cpl     a 

    mov     r0,a                ; save joystick bits
    call    move_player

    jmp game_loop



move_player:
    ; call movement routines
    mov     a,r0
    anl     a,#001h
    jnz     move_up

    mov     a,r0 
    anl     a,#002h             
    jnz     move_right

    mov     a,r0
    anl     a,#004h
    jnz     move_down

    mov     a,r0
    anl     a,#008h
    jnz     move_left

    ret


move_up:
    mov     r0,#000h
    movx    a,@r0 
    add     a,#0ffh 
    movx    @r0,a

    jmp game_loop

move_down:
    mov     r0,#000h
    movx    a,@r0 
    add     a,#001h 
    movx    @r0,a

    jmp game_loop

move_left:
    mov     r0,#001h
    movx    a,@r0 
    add     a,#0ffh 
    movx    @r0,a

    jmp game_loop

move_right:
    mov     r0,#001h
    movx    a,@r0 
    add     a,#001h 
    movx    @r0,a

    jmp game_loop


copy_sprite:
    mov     a,r1 
    movp    a,@a
    movx    @r0,a 
    inc     r0
    inc     r1 
    djnz    r7,copy_sprite
    ret

pacman_closed_sprite:
 	db	00011000b
	db	0011100b
	db	01111110b
	db	11111111b
	db	00011000b
	db	0011100b
	db	01111110b
	db	00000000b  

pacman_open_sprite:
 	db	00111110b
	db	01111100b
	db	01111000b
	db	11100000b
	db	01110000b
	db	00111100b
	db	00011110b
	db	00000000b  
	
ghost_sprite:
	db	01111110b
	db	10011001b
	db	10111011b
	db	10011001b
	db	11111111b
	db	11111111b
	db	11111111b
	db	10101010b
