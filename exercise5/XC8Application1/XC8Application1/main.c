/*
 * main.c
 * Created: 11/12/2021 5:14:22 PM
 *  Author: jlamp
 */ 

#include <xc.h>
#include <avr/interrupt.h>
#include <avr/pgmspace.h>
#include <math.h>

//saves the message OK in the flash position 0x116
const PROGMEM uint8_t data1[] = {"OK\n"};
	
//saves the 7 segment representation in the flash position 0x10A
const 	PROGMEM uint8_t BCDTo7segmentLED[] = {192,249,164,176,153,146,130,184,128,144,255,255};
	//This space is used to store the ascii numbers.
	uint8_t StoredBCD[9]={1,1,1,1,1,1,1,1,1};
			//This byte is used as the counter.
	uint8_t counter=1;

	//Function used for the initialization of the LEDs.
void InitialiseLED(){
	DDRA= 0xFF;
	DDRC=0xFF;
}

	//Function used for the initialization of the timer1.
void InitialiseTimer(){
	TCCR1B=TCCR1B || 0x01;
	TCNT1H=0x5F;
	TCNT1L=0xD8;
	TIMSK=0x04;
}

//This Function is used to set to the memory the character that clears the the screen.

void ClearScreen(){
	int i=0;
	for(int i=0;i<9;i++){
		StoredBCD[i]=0x0A;
	}
}
//This function is used to move up the stored data by one address.
void MoveMemory(){
	int i;
	for(int i=8;i>=1;i--){
		StoredBCD[i]=StoredBCD[i-1];
}
}
//Function that reads an ascii number, finds the corresponding number and stores it to memory 

void SaveToMemory(uint8_t data){
	StoredBCD[0]=data-'0';
		MoveMemory();
}

	//Subroutine to handle the incoming data.


void Control(uint8_t  ascii){
	if(ascii<=0x39 && ascii>=0x30){
		SaveToMemory(ascii);
	}else if(ascii==0x43 ||ascii == 0x4E ){
		ClearScreen();
	}else{
		return;
	}
}


//This interrupt is triggered every 4.1 msec to light the appropriate 7-segment LED.
void TIM1_COMPA(){
	int temp=(log10(counter)/log10(2))+1;//with this calculation we get the position of of the number in the stored memory
	//to be printed.
	uint8_t BCDout=StoredBCD[temp];
	BCDout=BCDTo7segmentLED[BCDout];

	TIFR=TIFR||0x0F;
	PORTA=0x00;
	PORTC=counter;
	PORTA=BCDout;
	
	TCNT1H=0x5F;
	TCNT1L=0xD8;
	
	if(counter!= 128){
		counter=counter*2;
	}else{
		counter=1;
	}
}

//Function used for the initialization of the USART

void InitialiseRT(){
	UBRRL = (uint8_t)(64);
	// write to higher byte
	UBRRH = (uint8_t)(0);
	UCSRB = (uint8_t)(152);
	UCSRC = (uint8_t)(6);
	
}
//This function is used to enable the UDR Interrupt.

void EnableTxc(){
	UCSRB = (uint8_t)(184);
}
//This function is used to disable the UDR Interrupt.

void	DisableTxc(){
	UCSRB = (uint8_t)(152);

}


//This function is used for the  UDRE interrupt and sends the ok signal

void USART_UDRE(){
	int i;
	for(i=0; i<3;i++ ){
		UDR = data1[i];
		TCNT2= data1[i];
	}
	DisableTxc();
}
//This function is used for the  UDRE interrupt
ISR(USART_UDRE_vect){
	USART_UDRE();
}
//This function is used to handle the USART_RXC interrupt to read an ascii character from the RS-232.Then it handles the byte with the control routine.
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
//This function is used to handle the USART_RXC interrupt
ISR(USART_RXC_vect)
{
	USART_RXC();
}





int main(void){
	

	ClearScreen();
	InitialiseLED();
	InitialiseRT();
	InitialiseTimer();
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