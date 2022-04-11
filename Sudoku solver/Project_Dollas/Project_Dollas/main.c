/*
 * main.c
 *
 * Created: 11/30/2021 12:31:04 PM
 *  Author: George Piperakis 2018030012
 *  Author2: Lamprinidhs Ioannis 2018030075
 *	Milestone 1 Project of Semester
 *	Embedded Microprossecor Systems
 */ 

#include <xc.h>
#include <avr/interrupt.h>
#include <avr/pgmspace.h>
#include <math.h>
#define UNASSIGNED 0
#define N 9
/*
*Finds an empty cell
*/
uint8_t FindEmptyLocation(uint8_t table[N][N],uint8_t* row,uint8_t* col);
/*
*This function checks if it is ok to assign here a specific number.
*/
uint8_t isOk(uint8_t table[N][N],uint8_t row,uint8_t col,uint8_t num);
void printTable(uint8_t table[N][N]);
//#include <avr/iom16.h>
//#include <avr/io.h>

uint8_t table[9][9];			//sudoku table
uint8_t led_counter = 0;	//counter for 
char command[6];			//command we get 
uint8_t counter_command = 0;	//keeps track which byte we want to save next to command
uint8_t sudoku_is_done_flag=0;//0 not started 1 start(ed) (2 working) 2 done
uint8_t x_temp= UNASSIGNED;
uint8_t y_temp= UNASSIGNED;
uint8_t counter_answer = 0;		//keeps track of the byte we want to send next
uint8_t choose_command = 0;		//choose which format of command we want
const char ok_command[4] PROGMEM = {0x4f,0x4b,0x0d,0x0a};	//1
const char done_command[3] PROGMEM = {0x44,0x0d,0x0a};		//2
char value_command[6] = {0x4e,0x10,0x10,0x10,0x0d,0x0a};	//3
uint8_t control_flag = 0;	//0 initial 
						//1 solving
						//2 break
						//3 done 

void initialize_tables(void){
	//initialize tables to all 0
	for(int i=0;i<9;i++){
		for(int j=0;j<9;j++){
			table[i][j] = UNASSIGNED;
		}
	}
}

void init(void){
	TCNT1 = 0;		//initialize timer to 0
	TIFR = 16;		//set compare flag OCF1A
	TCCR1B = 1;		//set prescaler to count clk
	OCR1A = 40000;	//set counter  compare value
	TIMSK = 16;		//enable output compare intpt
	
	UBRRH = 0;	//make sure URSEL=0 to use UBBR register
	UBRRL = 64;	//set baud rate
	//enable receibe and transmit and their interrupts
	UCSRB = (1<<TXEN)|(1<<RXEN)|(1<<RXCIE);
	//set frame format : 8data,1 stop bit ,no parity
	//asynchronous mode URSEL=1 this means we use UCSRC and not UBRRH same direction
	UCSRC = (1<<URSEL)|(3<<UCSZ0);
	
	initialize_tables();
	return;
}

void break_command(){
	cli();
	while(1){
		if(control_flag != 2){
			return;
		}
	}
}

void Sending_Results(){

	value_command[1]=(x_temp+1) + '0';			//fill the value command with the x value on 2nd position
	value_command[2]=(y_temp+1) + '0';			//fill the value command with the y value on 3rd position
	value_command[3]=table[x_temp][y_temp]+ '0';	//fill the value command with the value on 4rth position
	x_temp++;	//update x counter
	if(x_temp>=9){	//update x and y when x exceeds limits
		x_temp=0;	
		y_temp++;
	}
	return;
}

void insert(int x,int y,int value){
	table[x-1][y-1] = value;	//insert the value to the table
}

void enable_send_interrupt(){
	UCSRB = (1<<TXEN)|(1<<RXEN)|(1<<RXCIE)|(1<<UDRIE);	//enable data empty intr
}

void ascii_answer(int x,int y){	
	value_command[1] = x;		//fill the value command with the x value on 2nd position
	value_command[2] = y;		//fill the value command with the y value on 3rd position
	value_command[3] = table[(x-'0')-1][(y-'0')-1]+'0';	//fill the value command with the value on 4rth position
}

ISR(USART_RXC_vect){
	char character_f = UDR;	//read from udr
	character_f = UDR;		//reads from simulation purposes in order RXC flag go down
	register  char character asm("r15");	//takes the data from register 15 simulation porpuses

	if(character==0x0a){	//checks the character

		if(command[0]=='A'){

			choose_command=1;		//send ok message
			enable_send_interrupt();

		}else if(command[0]=='C'){
			
			initialize_tables();	//set all values to 10 
			choose_command=1;		//send ok message k
			enable_send_interrupt();

		}else if(command[0]=='N'){
				
			insert((command[1]-'0'),(command[2]-'0'),(command[3]-'0'));	//insert data to the table
			choose_command=1;		//send ok message
			enable_send_interrupt();
			led_counter++;

		}else if(command[0]=='P'){
		
			control_flag = 1;	//change state to start solving the sudoku
			choose_command=1;	//send ok message
			enable_send_interrupt();
			
		}else if(command[0]=='S'){

			x_temp=0;			//initialize the x counter
			y_temp=0;			//initialize the y counter
			Sending_Results();	
			choose_command = 3;
			enable_send_interrupt();

		}else if(command[0]=='T'){

			if( y_temp==9 ){	//if y counter exceeds 8 means we sended all the solved table
				choose_command = 2;	//send done message
				x_temp = 0;		//initialize x counter
				y_temp = 0;		//initialize y counter
			}else{
				Sending_Results();
				choose_command=3;//send value message
			}
			enable_send_interrupt();
				

		}else if(command[0]=='O'){
			
			//ended the trasmission of all table
			control_flag = 0; //go to initial state 
			
		}else if(command[0]=='B'){

			//sending ok message
			//break stop calculating
			//stop sending back 
			
			control_flag = 2;			//break 
			choose_command = 1;		//sending ok message
			enable_send_interrupt();

		}else if(command[0]=='D'){
			
			ascii_answer((command[1]),(command[2]));			
			choose_command = 3;		//sending back the value of the position
			enable_send_interrupt();
		}
		
		counter_command = 0;
			
		
	}else{
		command[counter_command] = character;	//save byte received to command 
		counter_command++;	//update counter of the command
	}
}

ISR(USART_UDRE_vect){
	if(choose_command==1){		//sending ok message
		UDR = ok_command[counter_command];	//output
		//TCNT2 = ok_command[counter_command];
		counter_command++;					//update counter
		if(counter_command==4){
			UCSRB = (1<<TXEN)|(1<<RXEN)|(1<<RXCIE);	//close data empty interrupt
			counter_command = 0;
		}
	}else if(choose_command==2){		//sending done message
		UDR = done_command[counter_command];	//output
		//TCNT2 = done_command[counter_command];
		counter_command++;					//update counter
		if(counter_command==3){
			UCSRB = (1<<TXEN)|(1<<RXEN)|(1<<RXCIE);	//close data empty interrupt
			counter_command = 0;
		}
	}else if(choose_command==3){		//sending back value of the position asked
		UDR = value_command[counter_command];	//output
		//TCNT2 = value_command[counter_command];
		counter_command++;					//update counter
		if(counter_command==6){
			UCSRB = (1<<TXEN)|(1<<RXEN)|(1<<RXCIE);	//close data empty interrupt
			counter_command = 0;
		}
	}
	
}

ISR(TIMER1_COMPA_vect){
	
	uint8_t led_on = led_counter / 10;	//calculate led on 
	if(led_on > 0){	//check the value of led_on
		PORTC = 0;
		PORTC = pow(2,led_on-1);		//output PORTC
	}else{
		PORTC = 0;
		PORTC = led_on;
	}
	TCNT1 = 0;
}



void sending_results(){

}

int SudokuSolver(uint8_t table[N][N]){

	uint8_t row,col;

	if(FindEmptyLocation(table,&row,&col)==0){
		return 1;
	}
	int i;
	for(i=1;i<=9;i++){
		if(isOk(table,row,col,i)==1){
			table[row][col]=i;
			//break the programm if we should
			if(control_flag==2){
				break_command();
			}
			if(SudokuSolver(table)){
				led_counter++;
				return 1;
			}
			table[row][col]=UNASSIGNED;
			led_counter--;
		}
	}

	return 0; //failure
}

uint8_t FindEmptyLocation(uint8_t table[N][N],uint8_t* row,uint8_t* col){
	int i;
	int j;
	for(i=0; i<N;i++){
		for(j=0;j<N;j++){
			if(table[i][j]==UNASSIGNED){
				*row=i;
				*col=j;
				return 1;
			}

		}


	}
	return 0;
}

uint8_t used(uint8_t table[N][N],uint8_t row,uint8_t col,uint8_t num){
	uint8_t j;
	uint8_t i;
	for(j=0;j<N;j++){
		if(table[row][j]==num){
			return 1;
		}
	}

	for(j=0;j<N;j++){
		if(table[j][col]==num){
			return 1;
		}
	}

	uint8_t temp_col=col-col%3;
	uint8_t temp_row=row-row%3;
	for(i=0;i<3;i++){
		for(j=0;j<3;j++){
			if(table[i+temp_row][j+temp_col]==num){
				return 1;
			}
		}
	}
	return 0;
}

uint8_t isOk(uint8_t table[N][N],uint8_t row,uint8_t col, uint8_t num){
	if(used(table,row,col,num)==0 && table[row][col]==UNASSIGNED){
		return 1;
	}
	return 0;
}


int main(void)
{
	init();
	sei();		//enable interrupts
	

	
    while(1)
    {
			if(control_flag == 1){

				if(SudokuSolver(table)==1){
					//solved table
					control_flag = 3;
				}else{
					//break the programm the table cant be solved
					control_flag = 2; 
				}
				choose_command = 2;
				enable_send_interrupt();
			}else if(control_flag == 2){
				break_command();
			}
	}
}




