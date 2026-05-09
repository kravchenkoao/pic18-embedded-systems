#include <p18f4550.h>
#include <delays.h>

#define K1 0x01
#define K2 0x02
#define K3 0x04
#define PIN_Keys PORTE
#define PIN_K1 PORTB
#define PIN_K2 PORTB
#define PIN_K3 PORTB
#define Keypad (K1 | K2 | K3)


unsigned int counter;
unsigned int keycntr;
struct flagsStruct
{
    unsigned int clicking;
    unsigned int pushing;
};
struct flagsStruct flags;
unsigned char press_code;
unsigned int adc_value;
char buffer[6];
unsigned char k;

void systemInit(void);
void TMR0Init(void);
void USARTInit(void);
void ADCInit(void);
void PWMInit(void);

void TMR0Interrupt(void);

void sendCharUSART(char);
void sendWordUSART(char*);
void numberToWord(unsigned int, char*);

unsigned char keyboard(void);
void PWMSetup(unsigned char);

extern void _startup (void);
void ISRHigh(void);

#pragma code main=0x102A
void main(void)
{
    TRISB = 0;
    ADCON1 = 0x0F;
    counter = 1;
    keycntr = 0;
    adc_value = 0;
    
    systemInit();
    TMR0Init();
    USARTInit();
    ADCInit();
    PWMInit();
    
    while (1)
    {
        sendCharUSART('\f');
        if (press_code & 128) sendCharUSART('L');
        if (press_code) 
        {
            unsigned char multiplier;
            
            sendCharUSART('B');
            sendCharUSART((press_code & 7) | '0');
            multiplier = 1 << ((press_code & 7) - 1);
            multiplier *= (press_code & 128) ? (8) : 1;
            sendCharUSART('M');
            numberToWord(multiplier, buffer);
            sendWordUSART(buffer);
            PWMSetup(multiplier);
        }
            
        
        for (k = 0; k < 1; k++)
        {
            Delay10KTCYx(250);
        }
    }
}

#pragma code interrupt_high_vector=0x1008
void interrupt_high_vector(void)
{
    _asm goto ISRHigh _endasm
}

#pragma code

#pragma interrupt ISRHigh
void ISRHigh(void)
{
    if (INTCONbits.TMR0IF)
    {
        INTCONbits.TMR0IF = 0;
        TMR0Interrupt();
    }
//    Delay10KTCYx(250);
}


void systemInit(void)
{
    INTCONbits.GIE = 1;
    INTCONbits.PEIE = 1;
}

void TMR0Init(void)
{
    T0CON = 0b10010001;
    INTCONbits.TMR0IE = 1;
    INTCON2bits.TMR0IP = 1;
}

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

void PWMInit(void)
{
    CCP1CON = 0b00001100;
    T2CON = 0b00000000;
    TRISCbits.RC1 = 0;
    TRISCbits.RC2 = 0;

    TRISBbits.RB3 = 0;
}

void TMR0Interrupt(void)
{
    unsigned char current_press_code = keyboard();
    if (current_press_code) press_code = current_press_code;
}

void PWMSetup(unsigned char multiplier)
{
    if (multiplier)
    {
        T2CONbits.TMR2ON = 1;
        if (multiplier != 32)
        {
            T2CONbits.T2CKPS = 2;
            PR2 = (240 / multiplier) - 1;
        }
        else if (multiplier == 32)
        {
            T2CONbits.T2CKPS = 1;
            PR2 = 29;
        }
        CCPR1L = (PR2 + 1) / 2;
    }
    else
    {
        T2CONbits.TMR2ON = 0;
    }
}

void sendCharUSART(char data)
{
    while(TXSTAbits.TRMT == 0);
    TXREG = data;
}

void sendWordUSART(char* word)
{
    int i = 0;
//    sendCharUSART('\f');
    while(word[i] != '\0' && i != 5)
    {
        sendCharUSART(word[i]);
        i++;
    }
//    sendCharUSART('\r');
}

void numberToWord(unsigned int number, char* word)
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

unsigned char keyboard(void)
{
    struct flags
    {
        unsigned int clicking;
        unsigned int pushing;
    };
    unsigned char instant = (PIN_Keys & Keypad) & 0b00000111;
    
    if (instant != Keypad)
    {   
        int i;
        unsigned char button_counter = 0;
        for (i = K1; i <= K3; i*=2)
        {
            button_counter++;
            if (!(instant & i)) 
            {
                if (!flags.clicking)
                {
                    flags.clicking = 1;
                    return button_counter;
                }

                if ((!flags.pushing) && (keycntr > 12))
                {
                    flags.pushing = 1;
                    return button_counter | 0x80;
                }
                keycntr++;
            }
        }
    }
    else
    {
        flags.pushing = 0;
        flags.clicking = 0;
        keycntr = 0;
    }
    return 0;
}