; a2_template.asm
; CSC 230 - Summer 2017
; Patrick Holland
; ----- Description -----
; This program is for the ATMega2560 with LED lights plugged into pin 52,50,48,46,44,42.
; This program's default mode involves one LED being lit up at a time, changing in 1 second intervals.
; The light travels up then back down and repeats.
; Invert mode causes the 'activated' LED to be off, while the remaining 5 LED's are turned on. (Same pattern)
; There are 6 different speed settings. (0-5) 0:1s, 1:(1/2)s, 2:(1/4)s, ... , 5:(1/32)s
; There is also a pause mode which stores all of the timer counters to be restored on unpause.
; The control flow of the program is as follows:
;	main() {
;		setup(); // set up ADC for input, the interrupt timer, the stack pointer, initialize arrays
;		while (1) {
;			checkForInput)(); // check for buttons presses and handle if any are pressed.
;		}
;	}
;	interrupt() { // happens 16,000,000 / 1024 / 125 = 125 times per second 
;		timerCounter += 2^speed
;		if (timerCounter >= timerCounterMax) {
;			timerCounter -= timerCounterMax;
;			nextLights();
;		}
;	}
; 

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                        Constants and Definitions                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Special register definitions
.def XL = r26
.def XH = r27
.def YL = r28
.def YH = r29
.def ZL = r30
.def ZH = r31

; Stack pointer and SREG registers (in data space)
.equ SPH = 0x5E
.equ SPL = 0x5D
.equ SREG = 0x5F

; Initial address (16-bit) for the stack pointer
.equ STACK_INIT = 0x21FF

; Port and data direction register definitions (taken from AVR Studio; note that m2560def.inc does not give the data space address of PORTB)
.equ DDRB = 0x24
.equ PORTB = 0x25
.equ DDRL = 0x10A
.equ PORTL = 0x10B

; Definitions for the analog/digital converter (ADC) (taken from m2560def.inc)
; See the datasheet for details
.equ ADCSRA = 0x7A ; Control and Status Register
.equ ADMUX = 0x7C ; Multiplexer Register
.equ ADCL = 0x78 ; Output register (high bits)
.equ ADCH = 0x79 ; Output register (low bits)

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


; Definitions of the special register addresses for timer 0 (in data space)
.equ GTCCR = 0x43
.equ OCR0A = 0x47
.equ OCR0B = 0x48
.equ TCCR0A = 0x44
.equ TCCR0B = 0x45
.equ TCNT0  = 0x46
.equ TIFR0  = 0x35
.equ TIMSK0 = 0x6E

; Definitions of the special register addresses for timer 1 (in data space)
.equ TCCR1A = 0x80
.equ TCCR1B = 0x81
.equ TCCR1C = 0x82
.equ TCNT1H = 0x85
.equ TCNT1L = 0x84
.equ TIFR1  = 0x36
.equ TIMSK1 = 0x6F

; Definitions of the special register addresses for timer 2 (in data space)
.equ ASSR = 0xB6
.equ OCR2A = 0xB3
.equ OCR2B = 0xB4
.equ TCCR2A = 0xB0
.equ TCCR2B = 0xB1
.equ TCNT2  = 0xB2
.equ TIFR2  = 0x37
.equ TIMSK2 = 0x70

; Non-Template defs
.def index = r16 ; which light pattern is current (patterns stored in two arrays indexed into by this)
.def inverted = r17 ; 0: normal mode, 1: inverted
.def direction = r18 ; which direction we are heading in the array (0:down, 1:up)
.def t2counter = r19 ; interrupt counter compared with (t2max<<speed)
.def speed = r20 ; 0-5 (0:1s, 1:(1/2)s, 2:(1/4)s, ... , 5:(1/32)s)
.def button_pressed = r21 ; 0:not pressed, 1:pressed
.def paused = r24 ; 0:not paused, 1:paused
.equ t2overflow = 124
.equ t2max = 125
.equ PRESCALER = 0b0000_0111 ; _0111:1024, _0110:256, _0101:128, _0100:56
.equ ARRAY_SIZE = 6
; 16,000,000 / 124(+1)[t2overflow+1] / 1024[prescaler] = 125[t2max] ATMega2560

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
	sts SPH, r16
	ldi r16, low(STACK_INIT)
	sts SPL, r16

	ldi r22, 0xff
	sts DDRL,r22
	sts DDRB,r22
	
	; Set up Timer2 for interrupts
	ldi r21, t2overflow
	sts OCR2A, r21
	lds r21, TCCR2B
	ori r21, PRESCALER
	sts TCCR2B, r21 
	lds r21, TIMSK2 ; enable t2 output compare A interrupt
	ori r21, 0b0000_0010
	sts TIMSK2, r21
	ldi r21, 0b0000_0010
	sts TCCR2A, r21 ; enable CTC mode
	sei ; enable interrupt sreg flag
	
	clr index
	clr direction
	clr inverted
	clr speed
	clr button_pressed
	clr paused
	clr t2counter

	; Set up the ADC
	; Set up ADCSRA (ADEN = 1, ADPS2:ADPS0 = 111 for divisor of 128)
	ldi	r22, 0x87
	sts	ADCSRA, r22
	
	; Set up ADMUX (MUX4:MUX0 = 00000, ADLAR = 0, REFS1:REFS0 = 1)
	ldi	r22, 0x40
	sts	ADMUX, r22
	
	call init_arrays
	
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
button_left: ; if already inverted, do nothing
	cpi inverted,1
	breq after_button_press
	call invert ; else invert
	rjmp after_button_press
button_right: ; if already not inverted, do nothing
	cpi inverted,0
	breq after_button_press
	call invert ; else invert the invert :)
	rjmp after_button_press
button_up:
	;rjmp after_button_press ; debugging
	cpi speed,5
	breq after_button_press
	inc speed
	rjmp after_button_press
button_down:
	cpi speed,0
	breq after_button_press
	dec speed
	rjmp after_button_press
; ----------------------------------------- ;

; ***************************************** ;
;	      Function to toggle pause		    ;
;		   (no params) (no return)          ;
toggle_pause:
	push r22
	push XL
	push XH
	
	ldi XL, low(paused_counter)
	ldi XH, high(paused_counter)
	cpi paused,0
	breq store_counter
	rjmp restore_counter
	
toggle_pause_done:
	ldi r22, 1
	eor paused, r22
	pop XH
	pop XL
	pop r22
	ret
	
store_counter:
	lds r22, TCNT2
	st X, r22
	rjmp toggle_pause_done
	
restore_counter:
	ld r22, X
	sts TCNT2, r22
	rjmp toggle_pause_done

; ***************************************** ;
;	   Function to invert LED patterns		;
;		  (no params) (no return)           ;
invert:
	push r22
	push r23
	push r24
	push r25
	ldi YL, low(ARRAY_B)
	ldi YH, high(ARRAY_B)
	ldi ZL, low(ARRAY_L)
	ldi ZH, high(ARRAY_L)
	ldi r22, 1
	eor inverted, r22 ; toggle inverted variable
	clr r22
	ser r23 ; 0xff toggles all bits, but could toggle only relevent bits with more accurate bit masks for PORTB and PORTL

invert_loop:
	cpi r22, ARRAY_SIZE
	breq invert_done
	inc r22
	ld r24, Z
	ld r25, Y
	eor r24,r23
	eor r25,r23
	st Z+,r24
	st Y+,r25
	rjmp invert_loop
	
invert_done:
	call set_lights
	pop r25
	pop r24
	pop r23
	pop r22
	ret
	
; ***************************************** ;
;		  Timer2 Interrupt Handler          ;
timer2:
	push r22
	lds r22, SREG
	push r22
	
	cpi paused, 1
	breq timer2_done
	call inc_counter
	cpi t2counter, t2max
	brlo timer2_done
	call next_index
	call set_lights
	ldi r22, t2max
	sub t2counter, r22
	
timer2_done:
	pop r22
	sts SREG, r22
	pop r22
	reti
	
;helper function to increment t2counter by 2^speed
inc_counter:
	push r22
	push r23
	clr r22 ; loop counter
	ldi r23, 1 ; increment amount
	
inc_counter_loop:
	cp r22, speed
	breq inc_counter_done
	inc r22
	lsl r23
	rjmp inc_counter_loop

inc_counter_done:
	add t2counter, r23
	pop r23
	pop r22
	ret
	
; ----------------------------------------- ;

; ***************************************** ;
; 		Function to inc or dec index        ;
;		   (no params) (no return)          ;
next_index:
	push r22
	cpi index, (ARRAY_SIZE - 1)
	breq toggle_direction
	cpi index, 0
	breq toggle_direction
next_index2:
	cpi direction, 0
	breq next_index_down
next_index_up:
	inc index
	rjmp next_index_done
next_index_down:
	dec index
next_index_done:
	pop r22
	ret
	
toggle_direction:
	ldi r22, 1
	eor direction, r22
	rjmp next_index2
; ----------------------------------------- ;
	
; ***************************************** ;
;  Function to set the current LED pattern  ;
; 		   (no params) (no return)          ;
set_lights:
	push ZL
	push ZH
	push r0
	push r22
	
	clr r0
	ldi ZL, low(ARRAY_B)
	ldi ZH, high(ARRAY_B)
	add ZL, index
	adc ZH, r0
	ld r22, Z
	sts PORTB, r22
	
	ldi ZL, low(ARRAY_L)
	ldi ZH, high(ARRAY_L)
	add ZL, index
	adc ZH, r0
	ld r22, Z
	sts PORTL, r22
	
	pop r22
	pop r0
	pop ZH
	pop ZL
	ret
; ----------------------------------------- ;

; ***************************************** ;
; 	    Function to initialize arrays	    ;
;		   (no params) (no return)			;
init_arrays:
	push ZL
	push ZH
	push XL
	push XH
	
	ldi ZL, low(ARRAY_B_INIT<<1)
	ldi ZH, high(ARRAY_B_INIT<<1)
	ldi XL, low(ARRAY_B)
	ldi XH, high(ARRAY_B)
	call init_array
	ldi ZL, low(ARRAY_L_INIT<<1)
	ldi ZH, high(ARRAY_L_INIT<<1)
	ldi XL, low(ARRAY_L)
	ldi XH, high(ARRAY_L)
	call init_array
	
	pop XH
	pop XL
	pop ZH
	pop ZL
	ret
; ----------------------------------------- ;

; ***************************************** ;
;	  Function to initialize one array		;
;	  X = array in DM | Z = array in PM     ;
;				(no return)                 ;
init_array:
	push r22
	push r23
	clr r22
	
init_array_loop:
	cpi r22, ARRAY_SIZE
	breq init_array_done
	inc r22
	lpm r23,Z+
	st X+,r23
	rjmp init_array_loop
	
init_array_done:
	pop r23
	pop r22
	ret
; ----------------------------------------- ;
stop:
	rjmp stop
	
; ***************************************** ;
;	  Array's stored in program memory      ;
ARRAY_B_INIT:
	.db 0b0000_0010,0b0000_1000,0,0,0,0
ARRAY_L_INIT:
	.db 0,0,0b0000_0010,0b0000_1000,0b0010_0000,0b1000_0000
; ----------------------------------------- ;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                               Data Section                                  ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.dseg
.org 0x200
; Put variables and data arrays here...
ARRAY_B:	.byte 6
ARRAY_L:	.byte 6
paused_counter: .byte 1