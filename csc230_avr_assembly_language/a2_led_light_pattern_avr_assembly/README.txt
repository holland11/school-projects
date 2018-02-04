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