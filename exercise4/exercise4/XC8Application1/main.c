/*
;main.c
;
;-------------------------------------------------------
; Created: 21/10/2021 9:10:12
; Author : Ioannis Lamprinidis
;This is a simple program that reads an ascii number from the usart,stores in the memory as a bcd represantation and then
;it is sent to a 7-segment display.
;Programmed on microchip studio
*/
#include <xc.h>
#include <avr/interrupt.h>
#include <avr/pgmspace.h> 

extern uint8_t ClearScreen(int);
extern uint8_t InitialiseLED();
extern uint8_t InitialiseTimer();
extern uint8_t InitialiseCounter();
extern uint8_t Control();
extern uint8_t TIM1_COMPA();
extern uint8_t InitialiseMemory();

const PROGMEM uint8_t data1[] = {"OK\n"};
//Subroutine used for the initialization of the USART

void InitialiseRT(){
	UBRRL = (uint8_t)(64);
	// write to higher byte
	UBRRH = (uint8_t)(0);
	UCSRB = (uint8_t)(152);
	UCSRC = (uint8_t)(6);
	
}
 	//This routine is used to enable the UDR Interrupt.

 void EnableTxc(){
	 UCSRB = (uint8_t)(184);
 };
  	//This routine is used to disable the UDR Interrupt.

 void	DisableTxc(){
	 UCSRB = (uint8_t)(152);

 }
 
 
 	//This routine is used for the  UDRE interrupt and sends the ok signal

 void USART_UDRE(){
	 int i;
	 for(i=0; i<3;i++ ){
		 ;UDR = data1[i];
		 TCNT2= data1[i];
	 }
	 DisableTxc();
 }
 //This routine is used for the  UDRE interrupt
 ISR(USART_UDRE_vect){
	 USART_UDRE();
 }
  //This routine is used to handle the USART_RXC interrupt to read an ascii character from the RS-232.Then it handles the byte with the control routine.
  //If we encounter the 0x0a ascii then it starts transmiting the message ok.
 void USART_RXC(){
	 unsigned char temp= TCNT0;
	 uint8_t temp2= UDR;
	 temp2= UDR;

	 Control(temp);
	 if(temp==0x0a){
		 EnableTxc();
	 }
	 if( UCSRA & (1<<RXC)){
		 USART_RXC();
	 }
	 
 }
   //This routine is used to handle the USART_RXC interrupt
 ISR(USART_RXC_vect)
 {
	 USART_RXC();
 }
 




int main(void){ 
	
	
	 
	
	
	PROGMEM uint8_t data2[] = {192,249,164,176,153,146,130,184,128,144,255,255};
	
	InitialiseMemory();
        ClearScreen(data1);
		ClearScreen(data2);
		InitialiseLED();
			InitialiseCounter();
			InitialiseRT();			
		 InitialiseTimer();
		 InitialiseMemory();
		sei();
	
	while(1)
    {
		
    }
}
//This interrupt is triggered every 4.1 msec to light the appropriate 7-segment LED.

ISR(TIMER1_OVF_vect)
{
	TIM1_COMPA();
}


