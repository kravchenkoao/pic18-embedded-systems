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
char command[100];
char commandCharCounter;
const char cmd_pwmon[] = "pwmon";
const char cmd_pwmoff[] = "pwmoff";
const char cmd_pwmset[] = "pwmset";
const char cmd_pwmon_response[] = "PWM is on\r";
const char cmd_pwmoff_response[] = "PWM is off\r";
const char cmd_pwmset_response[] = "PWM is set\r";
unsigned char k;

void systemInit(void);
//void TMR0Init(void);
void USARTInit(void);
//void ADCInit(void);
void PWMInit(void);

//void TMR0Interrupt(void);

void sendCharUSART(char);
void sendWordUSART(char*);
void numberToWord(unsigned int, char*);

char readCharUSART(void);
void operateCommand(char*);
char compareWithWord(char*, const char*);

//unsigned char keyboard(void);
void PWMOn(void);
void PWMOff(void);
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
//    TMR0Init();
    USARTInit();
//    ADCInit();
    PWMInit();
    
    while (1)
    {
//        sendCharUSART('\f');
//        if (press_code & 128) sendCharUSART('L');
//        if (press_code) 
//        {
//            unsigned char multiplier;
//            
//            sendCharUSART('B');
//            sendCharUSART((press_code & 7) | '0');
//            multiplier = 1 << ((press_code & 7) - 1);
//            multiplier *= (press_code & 128) ? (8) : 1;
//            sendCharUSART('M');
//            numberToWord(multiplier, buffer);
//            sendWordUSART(buffer);
//            PWMSetup(multiplier);
//        }
            
        
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
//    if (INTCONbits.TMR0IF)
//    {
//        INTCONbits.TMR0IF = 0;
//        TMR0Interrupt();
//    }
    if (PIR1bits.RCIF)
    {
        char receivedChar = readCharUSART();
        
        PIR1bits.RCIF = 0;
        if (receivedChar == '\r')
        { 
            command[commandCharCounter] = '\0';
            operateCommand(command);
            commandCharCounter = 0;
        }
        else
        {
            command[commandCharCounter++] = receivedChar;
        }
    }
//    Delay10KTCYx(250);
}


void systemInit(void)
{
    INTCONbits.GIE = 1;
    INTCONbits.PEIE = 1;
}

//void TMR0Init(void)
//{
//    T0CON = 0b10010001;
//    INTCONbits.TMR0IE = 1;
//    INTCON2bits.TMR0IP = 1;
//}

void USARTInit(void)
{
    SPBRGH = 0;
    BAUDCONbits.BRG16 = 0;
    
    SPBRG = 77;
    TXSTAbits.BRGH = 0;
    TXSTAbits.SYNC = 0;
    RCSTAbits.SPEN = 1;
    RCSTAbits.CREN = 1;
    
    TXSTAbits.TX9 = 0;
    TXSTAbits.TXEN = 1;
    
    PIE1bits.RCIE = 1;
    IPR1bits.RCIP = 1;
}

//void ADCInit(void)
//{
//    ADCON0 = 0b00000001;
//    ADCON1 = 0b00001110;
//    ADCON2 = 0b00101110;
//    
//    ADCON0bits.GO = 1;
//}

void PWMInit(void)
{
    CCP1CON = 0b00001100;
    T2CON = 0b00000000;
    TRISCbits.RC1 = 0;
    TRISCbits.RC2 = 0;
    TRISBbits.RB3 = 0;
}

void PWMOn(void)
{
    T2CONbits.TMR2ON = 1;
//    numberToWord(PR2, buffer);
//    sendWordUSART(buffer);
    if (PR2 <= 1 || PR2 >= 240) 
    {
//        sendCharUSART('o');
        T2CONbits.T2CKPS = 2;
        PR2 = 59;
        CCPR1L = (PR2 + 1) / 2;
    }
        
}

void PWMOff(void)
{
    T2CONbits.TMR2ON = 0;
}

//void TMR0Interrupt(void)
//{
//    unsigned char current_press_code = keyboard();
//    if (current_press_code) press_code = current_press_code;
//}

void PWMSetup(unsigned char multiplier)
{
    char pwm_state = T2CONbits.TMR2ON;
    if (multiplier)
    {
        T2CONbits.TMR2ON = 0;
        if (multiplier < 16)
        {
            T2CONbits.T2CKPS = 2;
            PR2 = ((char)(240 / multiplier)) - 1;
//            numberToWord(PR2, buffer);
//            sendWordUSART(buffer);
        }
        else if (multiplier >= 16 && multiplier < 64)
        {
            T2CONbits.T2CKPS = 1;
            PR2 = ((char)(240 * 4 / multiplier)) - 1;
//            sendCharUSART('!');
//            numberToWord(PR2, buffer);
//            sendWordUSART(buffer);
        }
        else if (multiplier >= 64 && multiplier < 256)
        {
            T2CONbits.T2CKPS = 0;
            PR2 = ((char)(240 * 16 / multiplier)) - 1;
        }
        CCPR1L = (char)((PR2 + 1) / 2);
//        numberToWord(CCPR1L, buffer);
//        sendWordUSART(buffer);
        T2CONbits.TMR2ON = pwm_state;
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
    while(word[i] != '\0' && i != 100)
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

int wordToNumber(char* word)
{
    char i = 0;
    int number = 0;
    while (word[i] != '\0')
    {
        if (word[i] < '0' || word[i] > '9')
        {
            number = 0;
            break;
        }
        number *= 10;
        number += word[i] - '0';
        i++;
    }
//    sendCharUSART('?');
//    sendCharUSART(number);
    return number;
}

char readCharUSART(void)
{
    char receivedByte;
    receivedByte = RCREG;
    sendCharUSART(receivedByte);
    return receivedByte;
}

void operateCommand(char* command)
{
    char i = 0;
    char j = 0;
    char k = 0;
    
    char command_formatted[50];
    char command_body[20];
    char command_argument[20];
    
    unsigned long frequency;
    unsigned char multiplier;
    
    
//    while (command[i])
//    {
//        sendCharUSART(command[i]);
//        i++;
//    }
    
    while (command[i] != '\0')
    {
        if (command[i] == '\b' && j > 0)
        {
            j--;
            i++;
            continue;
        }
        command_formatted[j] = command[i];
        i++;
        j++;
    }
    command_formatted[j] = '\0';
    i = 0;
    j = 0;
    while (command_formatted[i] != ' ' && command_formatted[i] != '\0')
    {
        command_body[j] = command_formatted[i];
        i++;
        j++;
    }
    command_body[j] = '\0';
    if (command_formatted[i] != '\0') i++;
    while (command_formatted[i] != '\0')
    {
        command_argument[k] = command_formatted[i];
        i++;
        k++;
    }
    command_argument[k] = '\0';
//    sendWordUSART(command_body);
//    sendCharUSART('\r');
//    sendWordUSART(command_argument);
//    sendCharUSART('\r');
    
    if (compareWithWord(command_body, cmd_pwmon))
    {
        PWMOn();
        sendWordUSART(cmd_pwmon_response);
    } 
    else if (compareWithWord(command_body, cmd_pwmoff))
    {
        PWMOff();
        sendWordUSART(cmd_pwmoff_response);
    }
    else if (compareWithWord(command_body, cmd_pwmset))
    {
        frequency = wordToNumber(command_argument);
        if (frequency < 4) frequency = 4;
        if (frequency >= 800) frequency = 799;
        
        multiplier = frequency / 3.125;
        if (multiplier < 1) multiplier = 1;
        if (multiplier > 255) multiplier = 255;
//        sendCharUSART('^');
//        sendCharUSART(multiplier);
//        numberToWord(multiplier, buffer);
//        sendWordUSART(buffer);
//        sendCharUSART('\r');
        PWMSetup(multiplier);
        sendWordUSART(cmd_pwmset_response);
    }
}

char compareWithWord(char* word1, const char* word2)
{
    int i = 0;
    while (1)
    {
        if (word1[i] == '\0' || word2[i] == '\0') return (word1[i] == '\0') && (word2[i] == '\0');
        if (word1[i] != word2[i]) return 0;
        i++;
    }
}

/*
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
*/
