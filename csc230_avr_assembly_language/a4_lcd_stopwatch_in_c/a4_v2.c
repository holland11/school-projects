/* lab08_show_adc_result.c
   CSC 230 - Summer 2017
   
   This program demonstrates how to poll the ADC with C code.
   The main loop polls the ADC and displays the result on the LCD
   screen in hex.

   B. Bird - 07/12/2017
*/
/*
CSC 230 Assignment 4 Summer 2017
Patrick Holland
-------------
Built off the lab08_show_adc_result.c file as shown above.
Also imported and modified code from other lab files (timer2_setup() for example)

To reduce button related issues, I read 100 button registers then find which button registered
most frequently to determine which button handler to call.
Buttons are working flawlessly after this was added.

Prescalar 256, output compare at 249 for 250 interrupts per second. 
25 interrupts = (1/10)s. 
*/


#include "CSC230.h"
#include <stdio.h>
#include <stdlib.h>

#define  ADC_BTN_RIGHT 0x032
#define  ADC_BTN_UP 0x0C3
#define  ADC_BTN_DOWN 0x17C
#define  ADC_BTN_LEFT 0x22B
#define  ADC_BTN_SELECT 0x316

#define T2MAX 25
#define OC_NUM 249 // output compare
// prescale 256, OCA 249 (250) = 250 interrupts per second. 25 interrupts = 1/10 of a second

int paused = 1;
int t2counter = 0;
int show_lap = 0;
int time[5]; // { (1/10)s, low_s, high_s, low_m, high_m }
int lap_start[5];
int lap_end[5];
int lap_end_displayed[5]; 
// when left button is pressed, lap_start goes to 00:00.0, but still need to print the old lap start time

//A short is 16 bits wide, so the entire ADC result can be stored
//in an unsigned short.
unsigned short poll_adc(){
	// function pasted from lab example
	unsigned short adc_result = 0; //16 bits
	
	ADCSRA |= 0x40;
	while((ADCSRA & 0x40) == 0x40); //Busy-wait
	
	unsigned short result_low = ADCL;
	unsigned short result_high = ADCH;
	
	adc_result = (result_high<<8)|result_low;
	return adc_result;
}

void increment_time() {
	time[0]++;
	if (time[0] >= 10) {
		time[0] = 0;
		time[1]++;
		if (time[1] >= 10) {
			time[1] = 0;
			time[2]++;
			if (time[2] >= 6) {
				time[2] = 0;
				time[3]++;
				if (time[3] >= 10) {
					time[3] = 0;
					time[4]++;
					if (time[4] >= 10) {
						time[4] = 0;
					}
				}
			}
		}
	}
}

void print_time() {
	lcd_xy(0,0);
	char str[20];
	sprintf(str, "Time: %d%d:%d%d.%d   ", time[4], time[3], 
		time[2], time[1], time[0]);
	lcd_puts(str);
	lcd_xy(0,1);
	if (show_lap) {
		sprintf(str, "%d%d:%d%d.%d  %d%d:%d%d.%d", lap_start[4], lap_start[3],
			lap_start[2], lap_start[1], lap_start[0], lap_end_displayed[4], lap_end_displayed[3],
			lap_end_displayed[2], lap_end_displayed[1], lap_end_displayed[0]);
		lcd_puts(str);
	}
	else {
		sprintf(str, "                ");
		lcd_puts(str);
	}
}

ISR(TIMER2_COMPA_vect){
	if (paused == 0) {
		t2counter++;
		if (t2counter >= T2MAX) {
			t2counter = 0;
			increment_time();
			print_time();
		}
	}
}

void timer2_setup(){
	//You can also enable output compare mode or use other
	//timers (as you would do in assembly).
	TIMSK2 = 0x02; // output compare A
	OCR2A = OC_NUM; // output compare 
	TCNT2 = 0x00; // clear internal counter
	TCCR2A = 0x02; // CTC mode
	TCCR2B = 0x06; //Prescaler of 256
}

void data_init() {
	int i;
	for (i = 0; i < 5; i++) {
		time[i] = 0;
		lap_start[i] = 0;
		lap_end[i] = 0;
		lap_end_displayed[i] = 0;
	}
}

void select_button() {
	paused = 1 - paused;
}

void left_button() {
	int i;
	for (i = 0; i < 5; i++) {
		lap_end[i] = 0;
		time[i] = 0;
	}
	paused = 1;
	print_time();
}

void down_button() {
	int i;
	show_lap = 0;
	for (i = 0; i < 5; i++) {
		lap_start[i] = 0;
		lap_end[i] = 0;
		lap_end_displayed[i] = 0;
	}
	if (paused) {
		print_time();
	}
}

void up_button() {
	int i;
	show_lap = 1;
	for (i = 0; i < 5; i++) {
		lap_start[i] = lap_end[i];
		lap_end[i] = time[i];
		lap_end_displayed[i] = time[i];
	}
	if (paused) {
		print_time();
	}
}

void right_button() {
	return;
}

int most_freq(int button_pushes[], int button_count) {
	int i;
	int count[6];
	int result = 0;
	int most = 0;
	for (i = 0; i < 6; i++) {
		count[i] = 0;
	}
	for (i = 0; i < button_count; i++) {
		count[button_pushes[i]]++;
		if (count[button_pushes[i]] > most) {
			most = count[button_pushes[i]];
			result = button_pushes[i];
		}
	}
	return result;
}

int main(){
	
	//ADC Set up
	ADCSRA = 0x87;
	ADMUX = 0x40;

	data_init();
	lcd_init();
	timer2_setup();
	int button_pressed = 0;
	int button_count = 0;
	int button_pushes[100]; // read adc 100 times before deciding which button was pushed 
	// (find which button registered most frequently during that span)

	sei();
	print_time();

	while(1){
		unsigned short adc_result = poll_adc();
		if (adc_result > ADC_BTN_SELECT) {
			button_pushes[button_count++] = 0;
		}
		else if (adc_result > ADC_BTN_LEFT) {
			button_pushes[button_count++] = 1;
		}
		else if (adc_result > ADC_BTN_DOWN) {
			button_pushes[button_count++] = 2;
		}
		else if (adc_result > ADC_BTN_UP) {
			button_pushes[button_count++] = 3;
		}
		else if (adc_result > ADC_BTN_RIGHT) {
			button_pushes[button_count++] = 4;
		}
		else {
			button_pushes[button_count++] = 5;
		}
		if (button_count >= 100) {
			int pressed = most_freq(button_pushes, button_count);
			button_count = 0;
			if (pressed == 0) {
				button_pressed = 0;
			}
			else if (button_pressed == 0) {
				button_pressed = 1;
				switch (pressed) {
					case 1:
						select_button();
						break;
					case 2:
						left_button();
						break;
					case 3:
						down_button();
						break;
					case 4:
						up_button();
						break;
					case 5:
						right_button();
						break;
					default:
						break;
				}
			}

		}
	}
	
	return 0;
	
}