#include <p18f4550.h>
#include <delays.h>

unsigned int counter;
unsigned int adc_value;
unsigned char buffer[6];
unsigned char k;

void USARTInit(void)
{
    SPBRGH = 0;
    BAUDCONbits.BRG16 = 0;
    
    SPBRG = 77;
    TXSTAbits.BRGH = 0;
    TXSTAbits.SYNC = 0;
    RCSTAbits.SPEN = 1;
    
    TXSTAbits.TX9 = 0;
    TXSTAbits.TXEN = 1;
}

void ADCInit(void)
{
    ADCON0 = 0b00000001;
    ADCON1 = 0b00001110;
    ADCON2 = 0b00101110;
    
    ADCON0bits.GO = 1;
}

void sendCharUSART(unsigned char data)
{
    while(TXSTAbits.TRMT == 0);
    TXREG = data;
}

void sendWordUSART(unsigned char* word)
{
    int i = 0;
    sendCharUSART('\f');
    while(word[i] != '\0' && i != 5)
    {
        sendCharUSART(word[i]);
        i++;
    }
    sendCharUSART('m');
    sendCharUSART('V');
//    sendCharUSART('\r');
}

void numberToWord(unsigned int number, unsigned char* word)
{
    register unsigned char n;
    for(n = 0; n <= 4; n++)
    {
        word[n] = '0';
    }
    for(n = 0; n <= 4; n++)
    {
        word[4-n] = (number % 10) | '0';
        number /= 10;
        if (!number) break;
    }
}

#pragma code main=0x102A
void main(void)
{
    TRISB = 0;
    ADCON1 = 0x0F;
    counter = 1;
    adc_value = 0;
    
    USARTInit();
    ADCInit();
    
    while (1)
    {
        if (!ADCON0bits.GO)
        {
            adc_value = ADRESH;
            PIR1bits.ADIF = 0;
            ADCON0bits.GO = 1;
        }
        PORTB = counter;
        counter = counter << 1;
        if (counter == 256) counter = 1;
        adc_value = adc_value * 39;
        adc_value = adc_value / 2;
        numberToWord(adc_value, buffer);
        sendWordUSART(buffer);
        for (k = 0; k < 1; k++)
        {
            Delay10KTCYx(250);
        }
    }
}