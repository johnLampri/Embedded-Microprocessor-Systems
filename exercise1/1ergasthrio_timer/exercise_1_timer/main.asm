

;-------------------------------------------------------
; Created: 10/10/2021 19:14:35                         
; Author : jlamp									   
;This is a simple program that creates a delay of 20ms with a simple nested loop.	
;Programmed on microchip studio   
;--------------------------------------------------------

;;.org 0

;; .org 0x20

.org $000 
	rjmp RESET
.org $010 
	rjmp TIM1_COMPA 


 .org INT_VECTORS_SIZE  ;
  
RESET:
;we initialise the led.
    ldi r24, 0x01;
    out DDRB, r24;
	;we choose the /8 prescaler
	in  r23, TCCR1B;
	ori r23, 0x02;
	out TCCR1B, r23;
	;we set the timer value to the appropriate start value
	ldi r16, 0x9e;
	ldi r17, 0x57;
	out TCNT1H, r16;
	out TCNT1L, r17;

	;we enable the Overflow interupt
	in  r18, TIMSK;
	ori r18, 0x04;
	out TIMSK, r18;
	;enables global interrupts
	sei;
	;infinite loop
	loop:
	jmp loop;
	;interupt Handler
	TIM1_COMPA:
	;changes the led status
	in r25,PORTB;
	eor r25, r24;
	out PORTB, r25;
	;we set the interupt flag to zero
	in  r23, TIFR;
	ori r23, 16;
	out TIFR, r23;
	reti; 