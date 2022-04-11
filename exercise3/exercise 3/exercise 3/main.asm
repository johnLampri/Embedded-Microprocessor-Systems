;
; exercise 3.asm
;
;-------------------------------------------------------
; Created: 21/10/2021 9:10:12                       
; Author : jlamp									   
;This is a simple program that reads an ascii number from the usart,stores in the memory as a bcd represantation and then
;it is sent to a 7-segment display.	
;Programmed on microchip studio   
;--------------------------------------------------------

;global variables r20 ring counter, X pointer for memory location, Zpointer for flash memory location

.dseg
.org	SRAM_START 
Command: .byte 2
BCDNumber:	.byte	9	
.cseg
.org $000 
	rjmp RESET
.org $010 
	rjmp TIM1_COMPA 
	 .org $016 
rjmp USART_RXC
;.org	$01A
.org $018
rjmp USART_UDRE
 .org INT_VECTORS_SIZE  ;
 RESET:
 main:
 InitialiseStack:
;initialise stack pointer

	ldi R16,Low(RAMEND) ; Point to the end of SRAM, LSB address
	out SPL,R16
	ldi R16,High(RAMEND) ; Point to the end of SRAM, MSB address
    out SPH,R16 
	;initialisation
	call ClearScreen;
	call InitialiseLED;
	call InitialiseCounter;
	call InitialiseRT;
	call InitialiseTimer;
	call InitialiseMemory;
	  sei;
	  	;infinite loop
	loop:
	 in r17, UCSRA 
	 sbrs r17, UDRE 
	 jmp loop;
	;check for transmission
	ldi r16,(1 << TXC) | ( 1<< UDRE)
	out UCSRA, r16 
	 jmp loop;
;	----------------------------------------------------------------------------------------------
	;Subroutine used for the initialisation of the Memory registers
InitialiseMemory: 
	
	ldi	XL,LOW(Command)		; initialize X pointer
	ldi	XH,HIGH(Command)	; to Command address
	ldi	ZL,LOW(2*Ok)		; initialize Z pointer
	ldi	ZH,HIGH(2*Ok)	
	ret;
	


;	--------------------------------------------------------------------------------------------
	;Subroutine used for the initialisation of the leds
InitialiseLED:
    ldi r24, 0xFF;
    out DDRA, r24;
	ldi r24, 0xFF;
    out DDRC, r24;
	ret
	;-----------------------------------------------------------------------------------------------
	;Subroutine used for the initialisation of the timer1
InitialiseTimer:
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
	ret;
	;enables global interrupts
	;-----------------------------------------------------------------------------------------------
		;Subroutine used for the initialisation of the ring counter

InitialiseCounter:
	
	ldi r20,1
	
	ret;
	;-----------------------------------------------------------------------------------------------
	;Subroutine used for the initialisation of the USART
InitialiseRT:
;set UBRR to 64(the apropriate value for a baud rate of 9600 and a clock of 10MHz)
	ldi r16, 64
	ldi r17, 0 
	out UBRRL, r16 
	out UBRRH, r17 
	;Enable receiver and tranceiver
	ldi r16, (1<<RXEN) | (1<<TXEN) | (1<<RXCIE) 
	out UCSRB, r16 
	ldi r16, (3<<UCSZ0)
	out UCSRC,r16
	ret;
	;-----------------------------------------------------------------------------------------------
	;This interrupt is triggered every 4.1 msec to light the appropriate 7-segment LED.

TIM1_COMPA:
	mov	ZL,XL		; initialize Z pointer
	mov	ZH,XH
	;we load the first BCD number address from the memory
	ld r18,Z+
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
	ldi	XL,LOW(BCDNumber)		; initialize X pointer
	ldi	XH,HIGH(BCDNumber)		
	reti;
	;-----------------------------------------------------------------------------------------------	


	;This routine is used to set to the memory the character that clears the the screen.
 ClearScreen:
	ldi	XL,LOW(Command)	
	ldi	XH,HIGH(Command)
	ldi r16,0x0A
	ldi r17,0x0B
	;this loop is used to 'visit' the memory we utilise
	loopCl:
	st X+,r16
	dec r17
	cpi r17,0
	brne loopCl
	ret
;	-----------------------------------------------------------------------------------------------
	;This routine is used to move the stored data by one address.
	;Problem with the code: The first useful byte will be at the second used address.
	MoveMemory:
		ldi	XL,LOW(Command)	
		ldi	XH,HIGH(Command)	
		mov r16,XL
		dec r16
		ldi r17,8
		add XL,r17
		AccessLoop:
		ld r17,X+
		st X, r17
		SUBI XL,2
		cp XL, r16
		brne AccessLoop
	ret;
;-----------------------------------------------------------------------------------------------
; This routine is used for the  UDRE interrupt and sends the ok signal

 USART_UDRE:
	ldi	ZL,LOW(2*Ok)		; initialize Z pointer
	ldi	ZH,HIGH(2*Ok)
puts:	
 	lpm	r16,Z+				; load character from pmem		
  putc:  
 out TCNT2, r16 ; replaced 
 cpi	r16,0x0A		; check if null
 breq	DisableTransmit
 rjmp puts
 puts_end:
 reti
 
; -----------------------------------------------------------------------------------------------
;This routine is used to handle the USART_RXC interrupt to read an ascii character from the RS-232.Then it handles the byte with the control routine.
;If we encounter the 0x0a ascii then it starts transmiting the message ok.
USART_RXC: 
  gets:  
  in r18, UDR 
  in r18, UDR ; added 
  mov r18, r15 ; added 
	call Control
  in r17,UCSRA 
  sbrs r17, RXC 
	 gets_end:			; return from subroutine
	 reti
	 rjmp gets			; store character to buffer

	
	;-----------------------------------------------------------------------------------------------
	;Subroutine to handle the incoming data. It uses r18 as an argument.
	Control:
		cpi r18, 0x30
		BRSH higher
		
		cpi r18,0x0A
		breq EnableTrasmitCall
		ret
	higher:
		cpi r18, 0x39
		BRLO SaveToMemory
		cpi r18,0x43
		breq ClearScreenCall
		cpi r18,0x4E
		breq ClearScreenCall
		ret;

;Routine that reads an ascii number, finds the corresponding number and stores it to memory 
SaveToMemory:
	ldi	XL,LOW(Command)	
	ldi	XH,HIGH(Command)
	ldi r16,0x30	
	sub r18,r16
	st X,r18
	call MoveMemory
	ret;
	;an intermidiate block of code to call the function ClearScreen
ClearScreenCall:
	call ClearScreen
		ret;
		;
EnableTrasmitCall:
ldi	XL,LOW(Command)		; initialize X pointer
ldi	XH,HIGH(Command)	; to Command address
inc XL
	call EnableTransmit
	ret;
;------------------------------------------------------------------
	;This routine is used to enable the UDR Interrupt.
EnableTransmit:
	ldi r16, (1<<RXEN) | (1<<TXEN) | (1<<RXCIE) | (1<<UDRIE)
	out UCSRB, r16 

	ret;
		;This routine is used to disable the UDR Interrupt.

DisableTransmit:
	ldi r16, (1<<RXEN) | (1<<TXEN) | (1<<RXCIE) 
	out UCSRB, r16 
	reti;
	;


;initialise the flash memory

p7segmentLed:	.db	192,249,164,176,153,146,130,184,128,144,255,255
OK:				.db 79,75,13,10