/*
 * Joseph_Noonan_and_Matthew_Levis_Lab2_sourcecode.c
 *
 * Created: 1/14/2020 12:03:09 PM
 * Author : Joseph Noonan and Matthew Levis
 */ 

/*
This code will cause a TekBot connected to the AVR board to
move forward and when it touches an obstacle, it will reverse
and turn away from the obstacle and resume forward motion.

PORT MAP
Port B, Pin 4 -> Output -> Right Motor Enable
Port B, Pin 5 -> Output -> Right Motor Direction
Port B, Pin 7 -> Output -> Left Motor Enable
Port B, Pin 6 -> Output -> Left Motor Direction
Port D, Pin 1 -> Input -> Left Whisker
Port D, Pin 0 -> Input -> Right Whisker
*/

#define F_CPU 16000000
#include <avr/io.h>
#include <util/delay.h>
#include <stdio.h>

int main(void)
{
	DDRB = 0b11110000;
	PORTB = 0b11110000;
	DDRD  = 0b00000000;
	PORTD = 0b11111111;

	while (1) // loop forever
	{
		PORTB = 0b01100000;			//Tekbot move forward
		
		// If both whiskers hit or left whisker hit
		if ((PIND == 0b11111100) || (PIND == 0b11111101)) {
			PORTB = 0b00000000;     // move backward
			_delay_ms(1000);        // wait for 500 ms
			PORTB = 0b01000000;     // turn right
			_delay_ms(1000);        // wait for 1 s
		}
		
		// If right whisker is hit
		else if (PIND == 0b11111110) {
			PORTB = 0b00000000;     // move backward
			_delay_ms(1000);        // wait for 500 ms
			PORTB = 0b00100000;     // turn left
			_delay_ms(1000);        // wait for 1 s
		}
	}
}
