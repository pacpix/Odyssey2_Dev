    cpu	8048
	org 400h
	include "g7000.h"

	; BIOS routines in g7000.h
	jmp     selectgame				    ; reset
	jmp     irq						    ; interrupt
	jmp     timer					    ; timer
	jmp     vsyncirq				    ; VSYNC-interrupt
	jmp     main					    ; start main program
	jmp     soundirq				    ; sound-interrupt

; Internal RAM variables
iram_score_start        equ     020h    ; First 8 bits of score
iram_score_end          equ     021h    ; Second 8 bits of score

; Page 1 - Initialization routines (except grid) and main loop
    align   256


; Timer not used
timer:
    ret


; Handles program flow
main:
    call    gfxoff                      ; turn off graphics while editing vdc
    call    init_grid                   ; create maze
    call    init_sprites                ; create sprites
    call    init_score
    call    game_loop                   ; main game loop


; Initializes sprite VDCs and copies onto screen
init_sprites:
    
    ; Sprite 0 Control $00-$03
    ; Sprite 1 Control $04-$07
    ; Sprite 2 Control $08-$0B
    ; Sprite 3 Control $0C-$0F

    ; Pac-Man Sprite
    mov     r0,#vdc_spr0_shape         
    mov     r1,#pacman_closed & 0ffh    
    mov     r7,#8
    call    copy_sprite
    mov     r0,#000h                    ; y position set
    movx    a,@r0
    mov     a,#130
    movx    @r0,a
    mov     r0,#001h                    ; x position set
    movx    a,@r0 
    mov     a,#75
    movx    @r0,a
    mov     r0,#002h                    ; color
    movx    a,@r0
    mov     a,#col_spr_yellow
    movx    @r0,a 

    ; Ghost Sprite 1
    mov     r0,#vdc_spr1_shape         
    mov     r1,#ghost_left & 0ffh    
    mov     r7,#8
    call    copy_sprite
    mov     r0,#004h                    ; y position set
    movx    a,@r0
    mov     a,#100
    movx    @r0,a
    mov     r0,#005h                    ; x position set
    movx    a,@r0 
    mov     a,#70
    movx    @r0,a
    mov     r0,#006h                    ; color
    movx    a,@r0
    mov     a,#col_spr_red
    movx    @r0,a 

    ; Ghost Sprite 2
    mov     r0,#vdc_spr2_shape         
    mov     r1,#ghost_right & 0ffh    
    mov     r7,#8
    call    copy_sprite
    mov     r0,#008h                    ; y position set
    movx    a,@r0
    mov     a,#100
    movx    @r0,a
    mov     r0,#009h                    ; x position set
    movx    a,@r0 
    mov     a,#80
    movx    @r0,a
    mov     r0,#00Ah                    ; color
    movx    a,@r0
    mov     a,#col_spr_blue
    movx    @r0,a 

    ; Miru Sprite
    mov     r0,#vdc_spr3_shape         
    mov     r1,#miru_right & 0ffh    
    mov     r7,#8
    call    copy_sprite
    mov     r0,#00Ch                    ; y position set
    movx    a,@r0
    mov     a,#70
    movx    @r0,a
    mov     r0,#00Dh                    ; x position set
    movx    a,@r0 
    mov     a,#75
    movx    @r0,a
    mov     r0,#00Eh                    ; color
    movx    a,@r0
    mov     a,#col_spr_green
    movx    @r0,a 

    ret

; Score functionality is modeled after gertk's Omega Race code
init_score:
		
	mov	r4,#12		            ; Quad 0 and Quad 1 y position

    ; Quad 0 is $40-4F
    mov	r3,#10		            ; Quad 0 x position
	mov	    r0,#vdc_quad0
	call	set_quad_char
	mov	    r0,#044h
	call	set_quad_char
	mov	    r0,#048h
	call	set_quad_char
	mov	    r0,#044h
	call	set_quad_char

    ; Quad 1 is $40-4F
	mov	    r3,#18		        ; Quad 1 x position
	mov	    r0,#vdc_quad1
	call	set_quad_char
	mov	    r0,#054h
	call	set_quad_char
	mov	    r0,#058h
	call	set_quad_char
	mov	    r0,#05Ch
	call	set_quad_char

    ret

; Moves quad char positions into VDC
set_quad_char:
	; Set Y Position
    mov	    a,r4
	movx	@r0,a	
    ; Set X Position	
	inc	    r0
	mov	    a,r3
	movx	@r0,a
    ; Set character
    mov     a,#00h
    movp    a,@a 
    call    printchar
    movx    @r0,a
    
    ret  

; Page 2
    align 256
; Loop that runs for every game frame
game_loop:
    
    ; Activate collision check for pac-man sprite on next frame
    mov     r0,#vdc_collision
    mov     a,#vdc_coll_spr0
    movx    @r0,a 

    ; Advance one frame
    call    gfxon
    call    waitvsync            
    call    gfxoff

    ; Check collision and move sprite back if collided
    call    pacman_grid_col_check
    ; Read joystick and move
    call    move_player

    jmp game_loop


; Calls movement routines for player
move_player:

    ; Get joystick 0 movement
    mov     r1,#000h                    ; select joystick 0
    call    getjoystick
    mov     a,r1 
    cpl     a 
    mov     r1,a                        ; save joystick bits

    ; Store initial X and Y values
    mov     r0,#000h                    ; y position 
    movx    a,@r0
    mov     r2,a
    mov     r0,#001h                    ; x position  
    movx    a,@r0
    mov     r3,a  

    ; Joystick bits in BIOS 0 = Up, 1 = Right, 2 = Down, 3 = Left, 4 = Fire
    ; "stored movement" AND with BIOS value to determine which bit set
    mov     a,r1
    anl     a,#001h
    jnz     move_up

    mov     a,r1 
    anl     a,#002h             
    jnz     move_right

    mov     a,r1
    anl     a,#004h
    jnz     move_down

    mov     a,r1
    anl     a,#008h
    jnz     move_left

    ret


; Move player sprite up
move_up:

    ; Move sprite
    mov     r1,#000h
    movx    a,@r1
    add     a,#0ffh
    movx    @r1,a

    jmp     game_loop


; Move player sprite down
move_down:

    ; Move sprite
    mov     r1,#000h
    movx    a,@r1 
    add     a,#001h 
    movx    @r1,a

    jmp     game_loop


; Move player sprite left
move_left:

    ; Move sprite
    mov     r1,#001h
    movx    a,@r1 
    add     a,#0ffh 
    movx    @r1,a

    jmp     game_loop


; Move player sprite right
move_right:

    ; Move sprite
    mov     r1,#001h
    movx    a,@r1 
    add     a,#001h 
    movx    @r1,a

    jmp     game_loop


; Checks if pac-man is colliding with grid
; If collision, move back to pre-movement position
pacman_grid_col_check: 

    ; Check for collision of player with grid
    ; Bit 5 is horizontal, bit 4 is vertical
    mov     r0,#iram_collision
    mov     a,@r0
    anl     a,#00110000b
    jnz     pacman_col_grid

    ret

; Moves pac-man back if collide with grid     
pacman_col_grid:

    mov     r0,#000h
    mov     a,r2 
    movx    @r0,a  
    mov     r0,#001h
    mov     a,r3    
    movx    @r0,a

    jmp     game_loop    


; ***NEW PAGE***
; Need sprites and copy sprite that accesses them on same page
    align   256

; Initialize grid at start of game
; Note: bit 7 = bottom of grid
init_grid:

    ; Set color of maze 
    mov     r0,#vdc_color
    mov     a,#col_grd_yellow
    movx    @r0,a

    ; Create vertical lines on both edges
    mov     r0,#vdc_gridv0
    mov     a,#11111111b
    movx    @r0,a
    mov     r0,#vdc_gridv9
    mov     a,#11111111b
    movx    @r0,a

    ; Bottom border
    ; Grid "i" bits refers to 9th row
    mov     r0,#vdc_gridi0
    mov     a,#00000001b
    movx    @r0,a
    mov     r0,#vdc_gridi1
    mov     a,#00000001b
    movx    @r0,a
    mov     r0,#vdc_gridi2
    mov     a,#00000001b
    movx    @r0,a
    mov     r0,#vdc_gridi3
    mov     a,#00000001b
    movx    @r0,a
    mov     r0,#vdc_gridi4
    mov     a,#00000001b
    movx    @r0,a
    mov     r0,#vdc_gridi5
    mov     a,#00000001b
    movx    @r0,a
    mov     r0,#vdc_gridi6
    mov     a,#00000001b
    movx    @r0,a
    mov     r0,#vdc_gridi7
    mov     a,#00000001b
    movx    @r0,a
    mov     r0,#vdc_gridi8
    mov     a,#00000001b
    movx    @r0,a

    ; Set horizontal lines
    mov     r0,#vdc_gridh0
    mov     a,#00000001b
    movx    @r0,a
    mov     r0,#vdc_gridh1
    mov     a,#10110011b
    movx    @r0,a
    mov     r0,#vdc_gridh2
    mov     a,#00000001b
    movx    @r0,a
    mov     r0,#vdc_gridh3
    mov     a,#11011111b
    movx    @r0,a
    mov     r0,#vdc_gridh4
    mov     a,#10010001b
    movx    @r0,a
    mov     r0,#vdc_gridh5
    mov     a,#11011111b
    movx    @r0,a
    mov     r0,#vdc_gridh6
    mov     a,#00000001b
    movx    @r0,a
    mov     r0,#vdc_gridh7
    mov     a,#10110011b
    movx    @r0,a
    mov     r0,#vdc_gridh8
    mov     a,#00000001b
    movx    @r0,a

    ; Set vertical lines
    mov     r0,#vdc_gridv1
    mov     a,#01101110b
    movx    @r0,a
    mov     r0,#vdc_gridv2
    mov     a,#01101110b
    movx    @r0,a
    mov     r0,#vdc_gridv3
    mov     a,#00001010b
    movx    @r0,a
    mov     r0,#vdc_gridv4
    mov     a,#10100010b
    movx    @r0,a
    mov     r0,#vdc_gridv5
    mov     a,#10100010b
    movx    @r0,a
    mov     r0,#vdc_gridv6
    mov     a,#00001010b
    movx    @r0,a
    mov     r0,#vdc_gridv7
    mov     a,#01101110b
    movx    @r0,a
    mov     r0,#vdc_gridv8
    mov     a,#01101110b
    movx    @r0,a

    ret

; Copies sprite data into VDC
copy_sprite:
    mov     a,r1 
    movp    a,@a
    movx    @r0,a 
    inc     r0
    inc     r1 
    djnz    r7,copy_sprite

    ret

; All sprites designed with assumption that will be flipped on Y-axis
ghost_left:
	db	01111110b
	db	10011001b
	db	10111011b
	db	10011001b
	db	11111111b
	db	11111111b
    db	11111111b
	db	10101010b

ghost_right:
	db	01111110b
	db	10011001b
	db	11011101b
	db	10011001b
	db	11111111b
	db	11111111b
    db	11111111b
	db	01010101b

; right bow
miru_left:
	db	00100000b
    db  01011100b
    db  00111110b
    db  01110101b
    db  01111111b
    db  00111110b
    db  00011100b
    db  00000000b

;  left bow
miru_right:
	db	00000100b
    db  00111010b
    db  01111100b
    db  10101110b
    db  11111110b
    db  01111100b
    db  00111000b
    db  00000000b

; left bow
miru_up:
	db	00000100b
    db  00111010b
    db  01010100b
    db  11111110b
    db  11111110b
    db  01111100b
    db  00111000b
    db  00000000b

; right bow
miru_down:
	db	00100000b
    db  01011100b
    db  00111110b
    db  01111111b
    db  01101011b
    db  00111110b
    db  00011100b
    db  00000000b

pacman_closed:
 	db	00011000b
	db	00111100b
	db	01111110b
	db	11111111b
	db	01111110b
	db	00111100b
    db	00011000b
	db	00000000b  

pacman_left:
 	db	00111110b
	db	01111100b
	db	01111000b
	db	11100000b
	db	01110000b
	db	00111100b
	db	00011110b
	db	00000000b

pacman_right:
 	db	01111100b
	db	00111110b
	db	00011110b
	db	00000111b
	db	00001110b
	db	00111100b
	db	01111000b
	db	00000000b 

pacman_up:
 	db	11000011b
	db	11000011b
	db	11100111b
	db	11100111b
	db	01111110b
	db	01111110b
	db	00111100b
	db	00000000b

pacman_down:
    db  00111100b
    db  01111110b
    db  01111110b
    db  11100111b
    db  11100111b
    db  11000011b
    db  11000011b
	db	00000000b