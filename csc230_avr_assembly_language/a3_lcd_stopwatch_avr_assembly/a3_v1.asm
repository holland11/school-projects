; a2_template.asm
; CSC 230 - Summer 2017
; Patrick Holland
; ----- Description -----
; This program is for the ATMega2560 with an LCD shield.
; This is using my Assignment 2 submission as a template for testing the LCD functions.
; What I call milliseconds in this code are actually centiseconds.
; 
; This program utilizes the LCD screen and interrupts to simulate a stopwatch (aka a timer).
; The buttons can be used to pause / reset the timer and there is also the capability to 
; time 'laps'.
; 

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                        Constants and Definitions                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


; Initial address (16-bit) for the stack pointer
.equ STACK_INIT = 0x21FF

; Definitions for button values from the ADC
; Some boards may use the values in option B
; The code below used less than comparisons so option A should work for both
; Option A (v 1.1)
;.equ ADC_BTN_RIGHT = 0x032
;.equ ADC_BTN_UP = 0x0FA
;.equ ADC_BTN_DOWN = 0x1C2
;.equ ADC_BTN_LEFT = 0x28A
;.equ ADC_BTN_SELECT = 0x352
; Option B (v 1.0)
.equ ADC_BTN_RIGHT = 0x032
.equ ADC_BTN_UP = 0x0C3
.equ ADC_BTN_DOWN = 0x17C
.equ ADC_BTN_LEFT = 0x22B
.equ ADC_BTN_SELECT = 0x316

.include "m2560def.inc"
.include "lcd_function_defs.inc"

.equ SPH_DATASPACE = 0x5E
.equ SPL_DATASPACE = 0x5D

; Non-Template defs
.def t2counter = r16 ; 
.def button_pressed = r17 ; 0:not pressed, 1:pressed
.def show_lap = r18
.def paused = r19
.equ T2OC = 249
.equ T2MAX = 25 ; 250 int/s = 25 int per 10th of second
.equ PRESCALER = 0b0000_0110 ; _0111:1024, _0110:256, _0101:128, _0100:56
; 16,000,000 / 256[prescaler] / (249+1)[t2oc+1] = 250 interrupts per second
; 250/s = 2.5 / centisecond
; count to 2 half the time and to 3 half the time = perfect deciseconds = perfect seconds = perfect minutes = perfect hours
; could count to 25 instead for perfect deciseconds, but no centiseconds

.cseg
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                          Reset/Interrupt Vectors                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.org 0x0000 ; RESET vector
	jmp main_begin
	
; Add interrupt handlers for timer interrupts here. See Section 14 (page 101) of the datasheet for addresses.
.org 0x001a ; timer2 overflow
	jmp timer2
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                               Main Program                                  ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; According to the datasheet, the last interrupt vector has address 0x0070, so the first
; "unreserved" location is 0x0074
.org 0x0074
main_begin:

	; Initialize the stack
	ldi r16, high(STACK_INIT)
	sts SPH_DATASPACE, r16
	ldi r16, low(STACK_INIT)
	sts SPL_DATASPACE, r16
	
	clr button_pressed
	clr t2counter
	clr show_lap
	call clr_timer
	ldi paused, 1

	; Set up the ADC
	; Set up ADCSRA (ADEN = 1, ADPS2:ADPS0 = 111 for divisor of 128)
	ldi	r22, 0x87
	sts	ADCSRA, r22
	
	; Set up ADMUX (MUX4:MUX0 = 00000, ADLAR = 0, REFS1:REFS0 = 1)
	ldi	r22, 0x40
	sts	ADMUX, r22
	
	call lcd_init
	call clr_lcd
	
	; Set up Timer2 for interrupts
	ldi r21, T2OC
	sts OCR2A, r21
	lds r21, TCCR2B
	ori r21, PRESCALER
	sts TCCR2B, r21 
	lds r21, TIMSK2 ; enable t2 output compare A interrupt
	ori r21, 0b0000_0010
	sts TIMSK2, r21
	ldi r21, 0b0000_0010
	sts TCCR2A, r21 ; enable CTC mode
	sei
	
	call print_time
	
; ***************************************** ;
;	   Infinite loop polling for input      ;
poll_input:
	lds r22,ADCSRA
	ori r22,0x40
	sts ADCSRA,r22

check_buttons_loop:
	lds r22,ADCSRA
	andi r22,0x40 	; check if Analog to Digital converter is done
	brne check_buttons_loop ; keep checking if not
	
	; analyze ADC 16-bit(10-bit) number to see if / what button was pressed
	ldi r22,low(ADC_BTN_SELECT)
	ldi r23,high(ADC_BTN_SELECT)
	lds XL,ADCL
	lds XH,ADCH
	cp XL,r22
	cpc XH,r23
	brsh no_button
	
	cpi button_pressed,1 ; don't record multiple button presses during 1 button press
	breq poll_input
	ldi button_pressed,1 
	
	ldi r22,low(ADC_BTN_LEFT)
	ldi r23,high(ADC_BTN_LEFT)
	cp XL,r22
	cpc XH,r23
	brsh button_select
	
	ldi r22,low(ADC_BTN_DOWN)
	ldi r23,high(ADC_BTN_DOWN)
	cp XL,r22
	cpc XH,r23
	brsh button_left
	
	ldi r22,low(ADC_BTN_UP)
	ldi r23,high(ADC_BTN_UP)
	cp XL,r22
	cpc XH,r23
	brsh button_down
	
	ldi r22,low(ADC_BTN_RIGHT)
	ldi r23,high(ADC_BTN_RIGHT)
	cp XL,r22
	cpc XH,r23
	brsh button_up
	rjmp button_right
	
after_button_press:
	rjmp poll_input
; ----------------------------------------- ;

; ***************************************** ;
;		      Button handlers               ;
no_button:
	ldi button_pressed,0
	rjmp poll_input

button_select:
	call toggle_pause
	rjmp after_button_press
button_left:
	ldi paused, 1
	call clr_timer
	call print_time
	rjmp after_button_press
button_right:
	rjmp after_button_press
button_up:
	call store_laps
	ldi show_lap, 1
	cpi paused, 0 ; if paused, we still want to print the new lap times, but print won't get called so we must call it here
	breq after_button_press
	call print_time
	rjmp after_button_press
button_down:
	ldi show_lap, 0
	call clr_laps
	rjmp after_button_press
; ----------------------------------------- ;

; ***************************************** ;
;	      Function to toggle pause		    ;
;		   (no params) (no return)          ;
toggle_pause:
	push r20
	push XL
	push XH
	
	ldi XL, low(paused_counter)
	ldi XH, high(paused_counter)
	cpi paused,0
	breq store_counter
	rjmp restore_counter
	
toggle_pause_done:
	ldi r20, 1
	eor paused, r20
	pop XH
	pop XL
	pop r20
	ret
	
store_counter:
	lds r20, TCNT2
	st X, r20
	rjmp toggle_pause_done
	
restore_counter:
	ld r20, X
	sts TCNT2, r20
	rjmp toggle_pause_done
; ----------------------------------------- ;
	
; ***************************************** ;
;		  Timer2 Interrupt Handler          ;
timer2:
	push r20
	lds r20, SREG
	push r20
	
	cpi paused, 1
	breq timer2_paused
	inc t2counter
	cpi t2counter, T2MAX
	brlo timer2_done
	clr t2counter ; t2counter hit its max
	call inc_ms_high
	call print_time
	rjmp timer2_done
	
timer2_done:
	pop r20
	sts SREG, r20
	pop r20
	reti
	
timer2_paused:
	rjmp timer2_done
	
; ----------------------------------------- ;

; ***************************************** ;
;		  Increment Time Functions          ;
; Simple set of functions simulating counting by milliseconds:
;	ms_high >= 9: set to 0 and increment s_low
; 	s_low >= 9: set to 0 and increment s_high
;	s_high >= 6: set to 0 and increment m_low
;	etc.
;	
;	Storing stopwatch number this way so that it is easy to print by char.
; --------- ;
inc_ms_high:
	push r20
	
	lds r20, ms_high
	cpi r20, 9
	brsh inc_ms_high_carry
	inc r20
	sts ms_high, r20
	rjmp inc_ms_high_done
	
inc_ms_high_carry:
	clr r20
	sts ms_high, r20
	call inc_s_low
	rjmp inc_ms_high_done
	
inc_ms_high_done:
	pop r20
	ret
; --------- ;
; --------- ;
inc_s_low:
	push r20
	
	lds r20, s_low
	cpi r20, 9
	brsh inc_s_low_carry
	inc r20
	sts s_low, r20
	rjmp inc_s_low_done
	
inc_s_low_carry:
	clr r20
	sts s_low, r20
	call inc_s_high
	rjmp inc_s_low_done
	
inc_s_low_done:
	pop r20
	ret
; --------- ;
; --------- ;
inc_s_high:
	push r20
	
	lds r20, s_high
	cpi r20, 5
	brsh inc_s_high_carry
	inc r20
	sts s_high, r20
	rjmp inc_s_high_done
	
inc_s_high_carry:
	clr r20
	sts s_high, r20
	call inc_m_low
	rjmp inc_s_high_done
	
inc_s_high_done:
	pop r20
	ret
; --------- ;
; --------- ;
inc_m_low:
	push r20
	
	lds r20, m_low
	cpi r20, 9
	brsh inc_m_low_carry
	inc r20
	sts m_low, r20
	rjmp inc_m_low_done
	
inc_m_low_carry:
	clr r20
	sts m_low, r20
	call inc_m_high
	rjmp inc_m_low_done
	
inc_m_low_done:
	pop r20
	ret
; --------- ;
; --------- ;
inc_m_high:
	push r20
	
	lds r20, m_high
	cpi r20, 9
	brsh inc_m_high_carry
	inc r20
	sts m_high, r20
	rjmp inc_m_high_done
	
inc_m_high_carry: ; caps at 99:59:9 (m:s:1/10s)
	clr r20
	sts m_high, r20
	rjmp inc_m_high_done
	
inc_m_high_done:
	pop r20
	ret
; --------- ;
; ----------------------------------------- ;

; ***************************************** ;
;	          Clear LCD Screen              ;
clr_lcd:
	push r20
	
	ldi r20, 0
	push r20
	push r20
	call lcd_gotoxy
	pop r20
	pop r20
	
	call print_clr_line
	
	ldi r20, 1
	push r20
	ldi r20, 0
	push r20
	call lcd_gotoxy
	pop r20
	pop r20
	
	call print_clr_line
	
clr_lcd_done:
	pop r20
	ret
	
;; lcd_gotoxy must be set to column 0 of any row [assume there are 16 columns]
print_clr_line:
	push r20
	push r21
	clr r21
	ldi r20, ' '
	push r20
	
print_clr_line_loop:
	cpi r21, 16
	brsh print_clr_line_done
	inc r21
	call lcd_putchar
	rjmp print_clr_line_loop

print_clr_line_done:
	pop r20
	pop r21
	pop r20
	ret

; ----------------------------------------- ;

; ***************************************** ;
;	  	    Print Time Function             ;
print_time:
	push r20
	push r21
	
	ldi r21, '0'
	
	ldi r20, 0
	push r20
	ldi r20, 0
	push r20
	call lcd_gotoxy
	pop r20
	pop r20
	
	ldi r20, 'T'
	push r20
	call lcd_putchar
	pop r20
	
	ldi r20, 'i'
	push r20
	call lcd_putchar
	pop r20
	
	ldi r20, 'm'
	push r20
	call lcd_putchar
	pop r20
	
	ldi r20, 'e'
	push r20
	call lcd_putchar
	pop r20
	
	ldi r20, ':'
	push r20
	call lcd_putchar
	pop r20
	
	lds r20, m_high
	add r20, r21
	push r20
	call lcd_putchar
	pop r20
	
	lds r20, m_low
	add r20, r21
	push r20
	call lcd_putchar
	pop r20
	
	ldi r20, ':'
	push r20
	call lcd_putchar
	pop r20
	
	lds r20, s_high
	add r20, r21
	push r20
	call lcd_putchar
	pop r20
	
	lds r20, s_low
	add r20, r21
	push r20
	call lcd_putchar
	pop r20
	
	ldi r20, ':'
	push r20
	call lcd_putchar
	pop r20
	
	lds r20, ms_high
	add r20, r21
	push r20
	call lcd_putchar
	pop r20
	
	ldi r20, 1
	push r20
	ldi r20, 0
	push r20
	call lcd_gotoxy
	pop r20
	pop r20
	
	cpi show_lap, 1
	breq print_laps
	
	call print_clr_line
	rjmp print_time_done
	
print_time_done:
	pop r21
	pop r20
	ret
	
print_laps:
	push r20
	ldi XL, low(lap_start)
	ldi XH, high(lap_start)
	call print_lap
	ldi r20, ' '
	push r20
	call lcd_putchar
	call lcd_putchar
	pop r20
	ldi XL, low(lap_end)
	ldi XH, high(lap_end)
	call print_lap
	pop r20
	rjmp print_time_done
; ----------------------------------------- ;

; ***************************************** ;
;		        Print lap                   ;
;	XH:XL must be set to lap array address  ;
;	 lcd_gotoxy must also be set already    ;
print_lap:
	push r20
	push r21
	
	ldi r21, '0'
	
	ld r20, X+
	add r20, r21
	push r20
	call lcd_putchar
	pop r20
	
	ld r20, X+
	add r20, r21
	push r20
	call lcd_putchar
	pop r20
	
	ldi r20, ':'
	push r20
	call lcd_putchar
	pop r20
	
	ld r20, X+
	add r20, r21
	push r20
	call lcd_putchar
	pop r20
	
	ld r20, X+
	add r20, r21
	push r20
	call lcd_putchar
	pop r20
	
	ldi r20, ':'
	push r20
	call lcd_putchar
	pop r20
	
	ld r20, X
	add r20, r21
	push r20
	call lcd_putchar
	pop r20
	
	pop r21
	pop r20
	ret
	
; ----------------------------------------- ;

; ***************************************** ;
;		       Store Laps                   ;
; Set lap_start to lap_end, set lap_end to  ;
; 			  current_time                  ;
;  Function assumes that m_high -> ms_high  ;
;         are stored sequentially           ;
store_laps:
	push r20
	
	ldi XL, low(curr_lap_start) ; overwrite lap_start values with lap_end values
	ldi XH, high(curr_lap_start)
	ldi YL, low(lap_start)
	ldi YH, high(lap_start)
	
	ld r20, X+
	st Y+, r20
	ld r20, X+
	st Y+, r20
	ld r20, X+
	st Y+, r20
	ld r20, X+
	st Y+, r20
	ld r20, X+
	st Y+, r20
	
	ldi YL, low(lap_end) ; overwrite lap_end values with main time values
	ldi YH, high(lap_end)
	ldi XL, low(m_high)
	ldi XH, high(m_high)
	
	ld r20, X+
	st Y+, r20
	ld r20, X+
	st Y+, r20
	ld r20, X+
	st Y+, r20
	ld r20, X+
	st Y+, r20
	ld r20, X+
	st Y+, r20
	
	ldi YL, low(curr_lap_start) ; keep backup of lap_end for when
	ldi YH, high(curr_lap_start); timer is cleared but we still want
	ldi XL, low(lap_end)        ; to display the same laps AND be able
	ldi XH, high(lap_end)       ; to have the next lap start at 0:00:0 again
	
	ld r20, X+
	st Y+, r20
	ld r20, X+
	st Y+, r20
	ld r20, X+
	st Y+, r20
	ld r20, X+
	st Y+, r20
	ld r20, X+
	st Y+, r20
	
	pop r20
	ret
; ----------------------------------------- ;

; ***************************************** ;
;		  Clear Timer and Laps              ;
clr_timer: ; clear timer, leaving displayed laps alone, but setting curr_lap_start to 00:00:0
	push r20
	push XL
	push XH
	
	ldi r20, 0
	sts m_high, r20
	sts m_low, r20
	sts s_high, r20
	sts s_low, r20
	sts ms_high, r20
	
	ldi XL, low(curr_lap_start)
	ldi XH, high(curr_lap_start)
	st X+, r20
	st X+, r20
	st X+, r20
	st X+, r20
	st X, r20

clr_timer_done:
	pop XH
	pop XL
	pop r20
	ret
	
clr_laps:
	push r20
	
	ldi r20, 0
	ldi XL, low(curr_lap_start)
	ldi XH, high(curr_lap_start)
	st X+, r20
	st X+, r20
	st X+, r20
	st X+, r20
	st X, r20

clr_laps_done:
	pop r20
	ret

; ----------------------------------------- ;


stop:
	rjmp stop

.include "lcd_function_code.asm"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                               Data Section                                  ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.dseg
m_high: .byte 1
m_low: .byte 1
s_high: .byte 1
s_low: .byte 1
ms_high: .byte 1
lap_start: .byte 5
lap_end: .byte 5
curr_lap_start: .byte 5
paused_counter: .byte 1