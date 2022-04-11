
/*
 * Assembler1.s
 *
 * Created: 04/11/2021 16:07:58
 *  Author: jlamp
 */ 

#define _SFR_ASM_COMPAT 1 
#define __SFR_OFFSET 0 
#define CommandL 0x60
#define CommandH 0x00

#define BCDNumberL 98
#define BCDNumberH 0x00

#define OKL 0x4C
#define OKH 0x04
#define p7segmentLedL 0x50
#define p7segmentLedH 0x04

 #include  <avr/io.h>
  
  .global InitialiseLED
  .global InitialiseTimer
  .global InitialiseCounter
  .global TIM1_COMPA
  .global ClearScreen
  .global MoveMemory
  .global InitialiseMemory
  .global Control



  
	;Subroutine used for the initialisation of the Memory registers
	InitialiseMemory: 

	ldi	XL,CommandL	; initialize X pointer
	ldi	XH,CommandH	; to Command address
	ret;
;Subroutine used for the initialisation of the leds
	InitialiseLED:
    ldi r24, 0xFF;
    out DDRA, r24;
	ldi r24, 0xFF;
    out DDRC, r24;
	ret
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

;Subroutine used for the initialisation of the ring counter
InitialiseCounter:
	;we initialise the ring counter
	ldi r20,1
	mov r3,r20
		
	ret;

;Subroutine used for the initialisation of the USART
	InitialiseRT:
;set UBRR to 64(the apropriate value for a baud rate of 9600 and a clock of 10MHz)
	ldi r16, 64
	ldi r17, 0 
	out UBRRL, r16 
	out UBRRH, r17 
	;Enable receiver and tranceiver
	ldi r16, 152 ;| (1<<TXCIE)
	out UCSRB, r16 
	ldi r16, 6
	out UCSRC,r16
	ret;

	;This interrupt is triggered every 4.1 msec to light the appropriate 7-segment LED.
	TIM1_COMPA:
	mov	ZL,r4		; initialize Z pointer
	mov	ZH,r5
	;we load the first BCD number address from the memory
	ld r18,Z+
	; the X register is prepared for the next loop
	mov	r4,ZL		
	mov	r5,ZH
	;we load the address of the 0 represantation of 7 segment LED
	ldi	ZL,p7segmentLedL	 
	ldi	ZH,p7segmentLedH
	;we get the address of the needed number represented in 7 segment LED
	add ZL,r18
	;we load the the represantation from the memory
	ld r18,Z+
	;we set the interupt flag to zero
	in  r23, TIFR;
	ori r23, 16;
	out TIFR, r23;
	;we initialise the screen output
	ldi r21, 0x00;
	out PORTA, r21;
	;we sent the output of the 7 segment LED and the ring counter
	out PORTC, r3;
	out PORTA, r18;
	;we initialise the timer value to the appropriate start value for 4.1ms delay.
	ldi r21, 0x5F;
	ldi r22, 0xD8;
	out TCNT1H, r21;
	out TCNT1L, r22;
	;we move the ring counter
	lsl r3       ; rotate the value
	breq initialise;
	reti; 
	;this block of code is used to reset the process 
	initialise :
	ldi r20,1
	mov r3,r20
	ldi	XL,BCDNumberL	; initialize X pointer
	ldi	XH,BCDNumberH	
	reti;


	;This routine is used to set to the memory the character that clears the the screen.
	 ClearScreen:
	ldi	XL,CommandL
	ldi	XH,CommandH
	ldi r16,0x0A
	ldi r17,0x0B
	;subi XL,9 ;NEW CODE
	;this loop is used to 'visit' the memory we utilise
	loopCl:
	st X+,r16
	dec r17
	cpi r17,0
	brne loopCl
	ret


	;This routine is used to move the stored data by one address.
	;Problem with the code: The first useful byte will be at the second used address.
	MoveMemory:
		ldi	XL,CommandL
		ldi	XH,CommandH
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
	;This routine is used for the  UDRE interrupt and sends the ok signal
	USART_UDRE:
	ldi	ZL,OKL		; initialize Z pointer
	ldi	ZH,OKH
puts:	
 	ld	r16,Z+				; load character from pmem		
  putc:  
 out TCNT2, r16			; replaced 
 cpi	r16,0x0A		; check if null
; breq	DisableTxc
 rjmp puts
 puts_end:
 reti

 ;This routine is used to handle the USART_RXC interrupt to read an ascii character from the RS-232.Then it handles the byte with the control routine.
;If we encounter the 0x0a ascii then it starts transmiting the message ok.
 USART_RXC: 
  gets:  
  in r18, UDR 
  in r18, UDR ; added 
  mov r18, r15 ; added 
  ;st	X+,r18	
  ;cpi	r16,$0A		; check if null
	call Control
; breq	EnableTxc
  in r17,UCSRA
  sbrs r17, RXC 
	 gets_end:			; return from subroutine
	 reti
	 rjmp gets			; store character to buffer

;Subroutine to handle the incoming data. It uses r18 as an argument.
 Control:
		 mov r18,r24
		cpi r18, 0x30
		BRSH higher
		
		cpi r18,0x0A
		breq EnableTxcCall
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
	ldi	XL,CommandL
	ldi	XH,CommandH
	ldi r16,0x30	
	sub r18,r16
	st X,r18
	call MoveMemory
	ret;

	;an intermidiate block of code to call the function ClearScreen
	ClearScreenCall:
	call ClearScreen
		ret;


	EnableTrasmitCall:
	ldi r16, (1<<RXEN) | (1<<TXEN) | (1<<RXCIE) | (1<<UDRIE)
	out UCSRB, r16 
;	ldi r16, 64
;	out UCSRA, r16 
	ret;

DisableTransmit:
	ldi r16, (1<<RXEN) | (1<<TXEN) | (1<<RXCIE) 
	out UCSRB, r16 
	reti;
	;

EnableTxcCall:
ldi	XL,CommandL	; initialize X pointer
ldi	XH,CommandH	; to Command address
inc XL
mov r4, XL
mov r5,XH
	;call EnableTxc
	ret;



