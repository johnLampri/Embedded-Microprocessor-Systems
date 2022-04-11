;
; exercise 2.asm
;
;-------------------------------------------------------
; Created: 21/10/2021 9:10:12                       
; Author : jlamp									   
;This is a simple program that reads a BCD from memory and uses as output a 7-sgment display.	
;Programmed on microchip studio   
;--------------------------------------------------------
.org $000 
	rjmp RESET
.org $010 
	rjmp TIM1_COMPA 


 .org INT_VECTORS_SIZE  ;
  
RESET:

;initialise stack pointer

	ldi R16,Low(RAMEND) ; Point to the end of SRAM, LSB address
	out SPL,R16
	ldi R16,High(RAMEND) ; Point to the end of SRAM, MSB address
    out SPH,R16 

	;we initialise the leds.

    ldi r24, 0xFF;
    out DDRA, r24;
	ldi r24, 0xFF;
    out DDRC, r24;
	;a prescaler is not needed so we use the base clock for the timer
	in  r23, TCCR1B;
	ori r23, 0x01;
	out TCCR1B, r23;
	;we initialise the timer value to the appropriate start value for 4.1ms delay.
	ldi r21, 0x5F;
	ldi r22, 0xD8;
	out TCNT1H, r21;
	out TCNT1L, r22;

	;we enable the Overflow interupt
	in  r18, TIMSK;
	ori r18, 0x04;
	out TIMSK, r18;
	;enables global interrupts
	sei;
	;we initialise the ring counter
	ldi r20,1
	; initialize X pointer
	ldi	XL,LOW(2*BCDNumber)	
	ldi	XH,HIGH(2*BCDNumber)		
	;infinite loop
	loop:
	jmp loop;
	;interupt Handler

	TIM1_COMPA:

	mov	ZL,XL		; initialize Z pointer
	mov	ZH,XH
	;we load the first BCD number address from the memory
	lpm r18,Z+
	; the X register is prepared for the next loop
	mov	XL,ZL		
	mov	XH,ZH
	;we load the address of the 0 represantation of 7 segment LED
	ldi	ZL,LOW(2*p7segmentLed)		 
	ldi	ZH,HIGH(2*p7segmentLed)
	;we get the address of the needed number represented in 7 segment LED
	add ZL,r18
	;we load the the represantation from the memory
	lpm r18,Z+

	;we set the interupt flag to zero
	in  r23, TIFR;
	ori r23, 16;
	out TIFR, r23;
	;we initialise the screen output
	ldi r21, 0x00;
	out PORTA, r21;
	;we sent the output of the 7 segment LED and the ring counter

	out PORTC, r20;
	out PORTA, r18;
	;we initialise the timer value to the appropriate start value for 4.1ms delay.
	ldi r21, 0x5F;
	ldi r22, 0xD8;
	out TCNT1H, r21;
	out TCNT1L, r22;
	;we move the ring counter
	rol r20       ; rotate the value
	breq initialise;
	reti; 
	;this block of code is used to reset the process 
	initialise :
	 ldi r20,1
	ldi	XL,LOW(2*BCDNumber)		; initialize X pointer
	ldi	XH,HIGH(2*BCDNumber)		
	reti;
;initialise the flash memory
BCDNumber: .db   9,7,8,5,6,0,3,4
p7segmentLed:	.db	63,5,91,79,102,109,125,71,127,111		