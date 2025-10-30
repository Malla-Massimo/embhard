/*
 * counter.c

 *
 *  Created on: 5 oct. 2025
 *      Author: jonat
 */
#include "io.h"
#include <stdio.h>
#include "system.h"
#include "sys/alt_irq.h"
#include <stdint.h>
#include "lcd_image.h"
#include "sys/alt_timestamp.h"

#define LCD_RESET_n 0x01
#define LCD_CS_n 0x02
#define LCD_RD_n 0x04
#define LCD_IM0 0x08

#define IMG_SIZE 320*240
#define CPU_DMA 0

enum LCD_GPIO_REG {
  LCD_DIR =0,
  LCD_PIN =1,
  LCD_PORT =2,
  LCD_SET = 3,
  LCD_CLR =4
};

enum LCD_REG {
  LCD_COMMANDE =0,
  LCD_DATA =4,
  DMA_POINTER =8,
  DMA_SIZE =12,
  DMA_CTL =16,
  DMA_STATUS =20,
  DMA_ADD =24,
  DMA_CNT = 28,
};

void read_dma_state() {
    uint32_t val;

    printf("-------------------------------------\n");

    val = IORD_32DIRECT(LCD_DMA2_0_BASE, DMA_POINTER);
    printf("ptr: %u\n", val);

    val = IORD_32DIRECT(LCD_DMA2_0_BASE, DMA_SIZE);
    printf("size: %u\n", val);

    val = IORD_32DIRECT(LCD_DMA2_0_BASE, DMA_CTL);
    printf("ctl: %u\n", val & 0xF);

    val = IORD_32DIRECT(LCD_DMA2_0_BASE, DMA_STATUS);

    printf("raw DMA_STATUS = 0x%08X\n", val);

    uint8_t dma_state  =  val        & 0xF;   // bits [3:0]
    uint8_t lcd_state  = (val >> 4)  & 0xF;   // bits [7:4]
    uint8_t lcd_start  = (val >> 8)  & 0x1;   // bit 8
    uint8_t d_c        = (val >> 9)  & 0x1;   // bit 9

    printf("dma state : %u\n", dma_state);
    printf("lcd state : %u\n", lcd_state);
    printf("lcd_start : %u\n", lcd_start);
    printf("D/C_n     : %u\n", d_c);

    val = IORD_32DIRECT(LCD_DMA2_0_BASE, DMA_ADD);
    printf("Cur add: %u\n", val);

    val = IORD_32DIRECT(LCD_DMA2_0_BASE, DMA_CNT);
    printf("Cur cnt: %u\n", val);
}


void timer_interrupt(void *context, alt_u32 id);
void dma_isr(void * context, alt_u32 id);

void LCD_Write_Command(int command);
void LCD_Write_Data(int data) ;
void init_LCD();
void LCD_DMA_IRQ_ACK();
void LCD_DMA_Size(int data);
void LCD_DMA_adress(data);
void LCD_DMA_Start();
void LCD_image(const unsigned short *image);

volatile int counter = 0;
int dma_end_flag = 0;



int main ( )
{
	alt_irq_register(TIMER_0_IRQ,(void*)2,(alt_isr_func)timer_interrupt);

    IOWR_16DIRECT(TIMER_0_BASE, 4, 0x7);   // Start + Continuous + Interrupt Enable
	IOWR_32DIRECT (GPIO_0_BASE , 0 , 0xFFFFFFFF );
    IOWR_8DIRECT(GPIO_LCD_0_BASE,LCD_DIR,0x0F); //Set all pin in out

	init_LCD();
	printf("a");
	LCD_Write_Command(0x002C);
	printf("a");
    printf("wb ptr=0x%08X rb ptr=0x%08X\n", rick_roll_1,
           IORD_32DIRECT(LCD_DMA2_0_BASE, DMA_POINTER));

    // DMA Initialization
    LCD_DMA_adress(rick_roll_1);
    LCD_DMA_Size(240*320);
    printf("a");
    alt_irq_register(LCD_DMA2_0_IRQ, NULL, (alt_isr_func)dma_isr);
    //alt_ic_irq_enable(LCD_DMA2_0_IRQ_INTERRUPT_CONTROLLER_ID, LCD_DMA2_0_IRQ);
    //alt_irq_enable_all(ALT_IRQ_ENABLED);

	while ( 1 )
	{

		if (CPU_DMA == 0){
			// With CPU
			LCD_image(rick_roll_0);
			LCD_image(rick_roll_1);
			LCD_image(rick_roll_2);
			LCD_image(rick_roll_3);
			LCD_image(rick_roll_4);
		}
		else {
			//IOWR_32DIRECT(LCD_DMA2_0_BASE,DMA_CTL,0x05);
			IOWR_32DIRECT(LCD_DMA2_0_BASE,DMA_CTL,0x01);
			while(!dma_end_flag){
				//read_dma_state();
			}
			dma_end_flag = 0;
		}

		/*
		printf ( " coun te r = %d \n " , counter);
		for(int i = 0; i<(240*320);i++ )
		{
			LCD_Write_Data(images[i]);
		}
		counter = 0;
		while(counter<400);
		*/
	}
}

void timer_interrupt(void *context, alt_u32 id){
	counter++; // increase the counter;
	// write counter value on the parallel port;
	// acknowledge IRQ on the timer;

	// Acknowledge du timer (remise à zéro du flag d’interruption)
	IOWR_32DIRECT(GPIO_0_BASE , 8 , counter);
	IOWR_16DIRECT(TIMER_0_BASE, 0, 0x0);    // éventuellement reset du statut
	IOWR_16DIRECT(TIMER_0_BASE, 4, 0x7);    // recharger ou clear selon ton timer
}

void init_LCD() {

      IOWR_8DIRECT(GPIO_LCD_0_BASE,LCD_PORT,LCD_RD_n|LCD_CS_n); // set reset on and 16 bits mode
      while (counter<100){}   // include delay of at least 120 ms use your timer or a loop
      IOWR_8DIRECT(GPIO_LCD_0_BASE,LCD_CLR,LCD_CS_n|LCD_IM0); // set reset off and 16 bits mode and enable LED_CS
      IOWR_8DIRECT(GPIO_LCD_0_BASE,LCD_SET,LCD_RESET_n|LCD_RD_n); // set reset off and 16 bits mode and enable LED_CS
      //printf("%u\n",IORD_8DIRECT(GPIO_LCD_0_BASE,LCD_PIN));
      while (counter<200){}   // include delay of at least 120 ms use your timer or a loop

      LCD_Write_Command(0x0028);     //display OFF
      LCD_Write_Command(0x0011);     //exit SLEEP mode
      LCD_Write_Data(0x0000);

      LCD_Write_Command(0x00CB);     //Power Control A
      LCD_Write_Data(0x0039);     //always 0x39
      LCD_Write_Data(0x002C);     //always 0x2C
      LCD_Write_Data(0x0000);     //always 0x00
      LCD_Write_Data(0x0034);     //Vcore = 1.6V
      LCD_Write_Data(0x0002);     //DDVDH = 5.6V

      LCD_Write_Command(0x00CF);     //Power Control B
      LCD_Write_Data(0x0000);     //always 0x00
      LCD_Write_Data(0x0081);     //PCEQ off
      LCD_Write_Data(0x0030);     //ESD protection

      LCD_Write_Command(0x00E8);     //Driver timing control A
      LCD_Write_Data(0x0085);     //non - overlap
      LCD_Write_Data(0x0001);     //EQ timing
      LCD_Write_Data(0x0079);     //Pre-charge timing


      LCD_Write_Command(0x00EA);     //Driver timing control B
      LCD_Write_Data(0x0000);        //Gate driver timing
      LCD_Write_Data(0x0000);        //always 0x00

      LCD_Write_Command(0x00ED); //Power On sequence control
      LCD_Write_Data(0x0064);        //soft start
      LCD_Write_Data(0x0003);        //power on sequence
      LCD_Write_Data(0x0012);        //power on sequence
      LCD_Write_Data(0x0081);        //DDVDH enhance on

      LCD_Write_Command(0x00F7);     //Pump ratio control
      LCD_Write_Data(0x0020);     //DDVDH=2xVCI

      LCD_Write_Command(0x00C0);    //power control 1
      LCD_Write_Data(0x0026);
      LCD_Write_Data(0x0004);     //second parameter for ILI9340 (ignored by ILI9341)

      LCD_Write_Command(0x00C1);     //power control 2
      LCD_Write_Data(0x0011);

      LCD_Write_Command(0x00C5);     //VCOM control 1
      LCD_Write_Data(0x0035);
      LCD_Write_Data(0x003E);

      LCD_Write_Command(0x00C7);     //VCOM control 2
      LCD_Write_Data(0x00BE);

      LCD_Write_Command(0x00B1);     //frame rate control
      LCD_Write_Data(0x0000);
      LCD_Write_Data(0x0010);

      LCD_Write_Command(0x003A);    //pixel format = 16 bit per pixel
      LCD_Write_Data(0x0055);

      LCD_Write_Command(0x00B6);     //display function control
      LCD_Write_Data(0x000A);
      LCD_Write_Data(0x00A2);

      LCD_Write_Command(0x00F2);     //3G Gamma control
      LCD_Write_Data(0x0002);         //off

      LCD_Write_Command(0x0026);     //Gamma curve 3
      LCD_Write_Data(0x0001);

      LCD_Write_Command(0x0036);     //memory access control = BGR
      LCD_Write_Data(0x0000);

      LCD_Write_Command(0x002A);     //column address set
      LCD_Write_Data(0x0000);
      LCD_Write_Data(0x0000);        //start 0x0000
      LCD_Write_Data(0x0000);
      LCD_Write_Data(0x00EF);        //end 0x00EF

      LCD_Write_Command(0x002B);    //page address set
      LCD_Write_Data(0x0000);
      LCD_Write_Data(0x0000);        //start 0x0000
      LCD_Write_Data(0x0001);
      LCD_Write_Data(0x003F);        //end 0x013F

      LCD_Write_Command(0x0029);
}

void LCD_Write_Command(int command) {
  IOWR_32DIRECT(LCD_DMA2_0_BASE,LCD_COMMANDE,command);

}

void LCD_Write_Data(int data) {
	IOWR_32DIRECT(LCD_DMA2_0_BASE,LCD_DATA,data);
	 //read_dma_state();
}

void LCD_DMA_Size(int data) {
    IOWR_32DIRECT(LCD_DMA2_0_BASE, DMA_SIZE, data);
}

void LCD_DMA_adress(int data) {
    IOWR_32DIRECT(LCD_DMA2_0_BASE, DMA_POINTER, data);
}

void LCD_DMA_IRQ_ACK() {
	IOWR_32DIRECT(LCD_DMA2_0_BASE,DMA_CTL,0x04);
}

void LCD_DMA_Start() {
	IOWR_32DIRECT(LCD_DMA2_0_BASE,DMA_CTL,0x01);
}

void dma_isr(void * context, alt_u32 id)
{
	printf("dma isr\n");
	dma_end_flag = 1;
	LCD_DMA_IRQ_ACK();   // clear first
	read_dma_state();    // then read debug info safely
}


void LCD_image(const unsigned short *image)
{
	int tsp_start = counter;
	for(int i=0; i<IMG_SIZE; i++){
		IOWR_32DIRECT(LCD_DMA2_0_BASE, LCD_DATA, image[i]);
		//LCD_Write_Data(images[i]);
		//read_dma_state();
	}
	int tsp = (int)counter - tsp_start;
	printf("tsp: %d\n", tsp);
	while (counter % 5 != 0)
	{}
}
