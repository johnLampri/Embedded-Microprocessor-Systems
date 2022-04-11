;
; exercise1_loop.asm
;-------------------------------------------------------
; Created: 10/10/2021 19:14:35                         
; Author : jlamp									   
;This is a simple program that creates a delay of 20ms with a simple nested loop.	
;Programmed on microchip studio   
;--------------------------------------------------------






.dseg

.cseg
.org 0
;starts the program
 rjmp start

 .org 0x20
start:
   
   ldi r24, 0x01; we initialise the Led and it's initial status is 'high' 
      out DDRB, r24;
	  out PORTB, r24;

	 
   wait: 
   			ldi r16, 250 ;initialise the outer loop counter

	delay: 
				ldi r17, 200; initialise the inner loop counter

			extra_steps: 
				dec r17; decrease the counter by 1 for each loop
				nop;
				brne extra_steps;
		dec r16;
		brne delay;
		in r25,PORTB;gets the value of the PortB 
		eor r25, r24;changes the LED FROM 0 to 1 and vice versa
		out PORTB, r25;
		jmp wait;starts all over again


