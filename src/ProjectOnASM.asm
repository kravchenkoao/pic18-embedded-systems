    list p=18f4550;
    #include <p18f4550.inc>
    
    cblock 20
	program_setup
	count
	rtc_secs
	rtc_mins
	rtc_hours
	ccp1_savedL
	ccp1_savedH
	count_delay1L
	count_delay1H
	count_delay2L
	count_delay2H
	ccp1_counter
	time_delayL
	time_delayH
	pwm_duty_cycle
	pwm_period
	multiplierL
	multiplierH
	mult16x16_arg1L
	mult16x16_arg1H
	mult16x16_arg2L
	mult16x16_arg2H
	mult16x16_res0
	mult16x16_res1
	mult16x16_res2
	mult16x16_res3
	bcd_value_32_0
	bcd_value_32_1
	bcd_value_32_2
	bcd_value_32_3
	bin_value_24_0
	bin_value_24_1
	bin_value_24_2
	output1_2
	output1_1
	output1_0
	output2_2
	output2_1
	output2_0
	output1_seg1
	output1_seg2
	output1_seg3
	output1_seg4
	output1_seg5
	output1_seg6
	output2_seg1
	output2_seg2
	output2_seg3
	output2_seg4
	output2_seg5
	output2_seg6
	temp
	temp16L
	temp16H
	temp24_0
	temp24_1
	temp24_2
	temp32_0
	temp32_1
	temp32_2
	temp32_3
	d1
	d2
	d3
    endc

#define is_clock 0
#define output_device 1	;set - output to terminal, cleared - output to 7seg
    
    org 000000
    goto start
    
    org 000008
    goto highInt
    
    org 000018
    goto lowInt
    
start
    call programSetup
    call systemInit
    call portsInit
    call USARTInit
    call TMR0Init
    call TMR1Init
;    call case2Init
    call case3Init
    goto main
    

main
    goto main
    
    
highInt
    btfsc INTCON,TMR0IF
    call TMR0Interrupt
    
    btfsc PIR1,ADIF
    call ADCInterrupt
    
    btfsc PIR1,TMR1IF
    call TMR1Interrupt
    
    btfsc PIR1,CCP1IF
    call CCP1Interrupt

    retfie

    
lowInt
    btfsc INTCON,TMR0IF
    call TMR0Interrupt
    
    retfie
    
    
programSetup
    bcf program_setup,is_clock
    bsf program_setup,output_device
    
    return
    
    
systemInit
    bsf INTCON,GIE
    bsf INTCON,PEIE
    bsf RCON,IPEN
    bsf INTCON,GIEH
    bsf INTCON,GIEL
    
    return
    
    
portsInit
    movlw 0x00
    movwf TRISD
    movlw 0x00
    movwf TRISB
    movlw 0x00
    movwf TRISA
    
    return
    
    
USARTInit
    bsf TXSTA,TXEN
    bcf TXSTA,SYNC
    bcf TXSTA,TX9
    
    bsf RCSTA,SPEN
    
    bcf BAUDCON,BRG16
    movlw .25
    movwf SPBRG
    
    bcf TRISC,6
    
    return
    

TMR0Init
    movlw  b'10000111' ; Fosc/4; 16 bit mode; PS = 1:256 
    movwf  T0CON 

    bsf  INTCON , TMR0IE
    bsf  INTCON2, TMR0IP


    movlw 0xF0
    movwf TMR0H
    clrf TMR0L
    
    return
    
    
TMR1Init
    movlw b'10000111'
    movwf T1CON
    
;    call case1TMR1Init
;    call case2TMR1Init
    call case3TMR1Init
    
    return
    

CPP1Init
    bsf TRISC,RC2
    movlw b'00000101'
    movwf CCP1CON
    bcf T3CON,T3CCP2
    
    bsf PIE1,CCP1IE
    bsf IPR1,CCP1IP
    
    clrf ccp1_counter
    
    return
    
    
TMR2Init
    movlw b'00000101'
    movwf T2CON
    
    return
    
    
CCP2Init
    bcf TRISC,RC1
    movlw b'00001100'
    movwf CCP2CON
    
    return
    

PWMInit
    decf pwm_period,w
    movwf PR2
    
    movff pwm_duty_cycle,CCPR2L
    
    return
    
    
ADCInit
    bsf PIE1,ADIE
    bsf IPR1,ADIP
    
    movlw b'00000001'
    movwf ADCON0
    
    movlw b'00001110'
    movwf ADCON1
    
    movlw b'00010010'
    movwf ADCON2
    
    bsf TRISA,AN0
    
    return
    
    
TMR0Interrupt
    movlw 0xF0
    movwf TMR0H
    clrf TMR0L
    
;    call case1TMR0Interrupt
;    call case2TMR0Interrupt
    call case3TMR0Interrupt

    call print
    
    bcf INTCON,TMR0IF
    
    return
    

TMR1Interrupt
;    call case1TMR1Interrupt
;    call case2TMR1Interrupt
    call case3TMR1Interrupt
    
    return
    
    
CCP1Interrupt
    btfsc ccp1_counter,1
    goto callCCP1Mode2
    call CCP1InterruptMode1
    return
    
callCCP1Mode2
    call CCP1InterruptMode2
    
    return
    
    
CCP1InterruptMode1
    movff CCPR1H,temp16H
    movff CCPR1L,temp16L
    
    movf ccp1_savedL,w
    subwf temp16L,f
    movf ccp1_savedH,w
    subwfb temp16H,f

    movff CCPR1H,ccp1_savedH
    movff CCPR1L,ccp1_savedL
    
    bcf PIR1,CCP1IF
    incf ccp1_counter
    
    btfss ccp1_counter,1
    return
    
    movff temp16H,count_delay2H
    movff temp16L,count_delay2L
    
    bcf PIE1,CCP1IE
    btg CCP1CON,CCP1M0
    bcf PIR1,CCP1IF
    bsf PIE1,CCP1IE
    
    return
    
    
CCP1InterruptMode2
    movff CCPR1H,temp16H
    movff CCPR1L,temp16L
    
    clrf ccp1_counter
    
    movf ccp1_savedL,w
    subwf temp16L,f
    movf ccp1_savedH,w
    subwfb temp16H,f
    
    movff temp16H,count_delay1H
    movff temp16L,count_delay1L

    movf    count_delay2L,w
    subwf   temp16L,f
    movf    count_delay2H,w
    subwfb  temp16H,f
    
    btfss   STATUS, C
    goto exitCCP1InterruptMode2
    
    movff temp16H,count_delay1H
    movff temp16L,count_delay1L
    
    goto exitCCP1InterruptMode2
    
exitCCP1InterruptMode2
    bcf PIE1,CCP1IE
    btg CCP1CON,CCP1M0
    bcf PIR1,CCP1IF
    bsf PIE1,CCP1IE
    
    return
    
    
ADCInterrupt
    movf pwm_period,w
    mulwf ADRESH
    
    movff PRODH,pwm_duty_cycle
    decf pwm_period,w
    cpfseq pwm_duty_cycle
    incf pwm_duty_cycle
    bcf CCP2CON,5
    bcf CCP2CON,4
    movff pwm_duty_cycle,CCPR2L
    
    bcf PIR1,ADIF
    
    return
    

case1TMR1Init
    bsf PIE1, TMR1IE
    bsf IPR1, TMR1IP
    
    movlw 0x80
    movwf TMR1H
    clrf TMR1L
    
    return
    
    
case1TMR0Interrupt
    clrf temp24_2
    clrf temp24_1
    clrf temp24_0
    
    clrf mult16x16_arg1H
    movff rtc_hours, mult16x16_arg1L
    movlw b'00100111'
    movwf mult16x16_arg2H
    movlw b'00010000'
    movwf mult16x16_arg2L
    call mult16x16
    movff mult16x16_res2,temp24_2
    movff mult16x16_res1,temp24_1
    movff mult16x16_res0,temp24_0
    
    clrf mult16x16_arg1H
    movff rtc_mins, mult16x16_arg1L
    movlw b'00000000'
    movwf mult16x16_arg2H
    movlw b'01100100'
    movwf mult16x16_arg2L
    call mult16x16
    movf mult16x16_res0,w
    addwf temp24_0,f
    movf mult16x16_res1,w
    addwfc temp24_1,f
    movf mult16x16_res2,w
    addwfc temp24_2,f
    
    movf rtc_secs,w
    addwf temp24_0,f
    movlw 0x00
    addwfc temp24_1,f
    movlw 0x00
    addwfc temp24_2,f

    movff temp24_0,output1_0
    movff temp24_1,output1_1
    movff temp24_2,output1_2
    clrf output2_0
    clrf output2_1
    clrf output2_2
    
    return
    
    
case1TMR1Interrupt
    movlw 0x80
    movwf TMR1H
    clrf TMR1L
    bcf PIR1,TMR1IF
    
    incf rtc_secs,f
    movlw .59
    cpfsgt rtc_secs
    return
    clrf rtc_secs
    incf rtc_mins,f
    movlw .59
    cpfsgt rtc_mins
    return
    clrf rtc_mins
    incf rtc_hours,f
    movlw .23
    cpfsgt rtc_hours
    return
    clrf rtc_hours
    
    return
    
    
case2Init
    movlw b'01111010'
    movwf multiplierH
    movlw b'00010010'
    movwf multiplierL
    
    call CPP1Init
    
    return
    
    
case2TMR0Init
    
    return
    
    
case2TMR1Init
    clrf TMR1H
    clrf TMR1L
    bcf PIE1, TMR1IE
    bcf IPR1, TMR1IP
    
    return
    
    
case2TMR0Interrupt
    movff count_delay1H, mult16x16_arg1H
    movff count_delay1L, mult16x16_arg1L
    
    movff multiplierH,mult16x16_arg2H
    movff multiplierL,mult16x16_arg2L
    
    call mult16x16
    
    movff mult16x16_res2,time_delayH
    movff mult16x16_res1,time_delayL
;    
    bcf STATUS,C 
    rrcf time_delayH,f
    rrcf time_delayL,f
;   
    bcf STATUS,C
    rrcf time_delayH,f
    rrcf time_delayL,f
    
    clrf output1_2
    movff time_delayH,output1_1
    movff time_delayL,output1_0

    
    movff count_delay2H, mult16x16_arg1H
    movff count_delay2L, mult16x16_arg1L
    
    movff multiplierH,mult16x16_arg2H
    movff multiplierL,mult16x16_arg2L
    
    call mult16x16
    
    movff mult16x16_res2,time_delayH
    movff mult16x16_res1,time_delayL
;    
    bcf STATUS,C 
    rrcf time_delayH,f
    rrcf time_delayL,f
;   
    bcf STATUS,C
    rrcf time_delayH,f
    rrcf time_delayL,f
    
    clrf output2_2
    movff time_delayH,output2_1
    movff time_delayL,output2_0
    
    return
    
    
case2TMR1Interrupt
;    clrf TMR1H
;    clrf TMR1L
    bcf PIR1,TMR1IF
    
    return
    
    
case3Init
    call case2Init
    call TMR2Init
    call CCP2Init
    
    movlw d'100'
    movwf pwm_period
    movlw d'25'
    movwf pwm_duty_cycle
    call PWMInit
    
    call ADCInit
    
    movlw b'00000000'
    movwf multiplierH
    movlw b'10000000'
    movwf multiplierL

    return
    
    
case3TMR0Init
    call case2TMR0Init
    
    return
    
    
case3TMR1Init
    call case2TMR1Init
    movlw b'10000001'
    movwf T1CON
    
    return
    
    
case3TMR0Interrupt
    btfss ADCON0,GO/DONE
    bsf ADCON0,GO/DONE
    
    call case2TMR0Interrupt
    
    return
    
    
case3TMR1Interrupt
    call case2TMR1Interrupt
    
    return
    

mult16x16
    movf mult16x16_arg1L,w
    mulwf mult16x16_arg2L
    
    movff PRODH,mult16x16_res1
    movff PRODL,mult16x16_res0
    
    movf mult16x16_arg1H,w
    mulwf mult16x16_arg2H
    
    movff PRODH,mult16x16_res3
    movff PRODL,mult16x16_res2
    
    movf mult16x16_arg1L,w
    mulwf mult16x16_arg2H
    
    movf PRODL,w
    addwf mult16x16_res1,f
    movf PRODH,w
    addwfc mult16x16_res2,f
    clrf WREG
    addwfc mult16x16_res3,f
    
    movf mult16x16_arg1H,w
    mulwf mult16x16_arg2L
    
    movf PRODL,w
    addwf mult16x16_res1,f
    movf PRODH,w
    addwfc mult16x16_res2,f
    clrf WREG
    addwfc mult16x16_res3,f
    
    return
    
    
print
    movff output1_2,bin_value_24_2
    movff output1_1,bin_value_24_1
    movff output1_0,bin_value_24_0
    
    call binToBCD
    
    movff bcd_value_32_2,output1_2
    movff bcd_value_32_1,output1_1
    movff bcd_value_32_0,output1_0
    
    movff output2_2,bin_value_24_2
    movff output2_1,bin_value_24_1
    movff output2_0,bin_value_24_0
    
    call binToBCD
    
    movff bcd_value_32_2,output2_2
    movff bcd_value_32_1,output2_1
    movff bcd_value_32_0,output2_0
    
    call bcdToSegments
    
    btfss program_setup,output_device
    call print7seg
    
    btfsc program_setup,output_device
    call printUSART
    
    return
    
    
binToBCD
    bcf STATUS,C
    movlw .24
    movwf count
    clrf bcd_value_32_3
    clrf bcd_value_32_2
    clrf bcd_value_32_1
    clrf bcd_value_32_0
binToBCDLoop
    rlcf bin_value_24_0,f
    rlcf bin_value_24_1,f    
    rlcf bin_value_24_2,f
    rlcf bcd_value_32_0,f
    rlcf bcd_value_32_1,f
    rlcf bcd_value_32_2,f
    rlcf bcd_value_32_3,f
    decfsz count,f
    goto adjDec
    return
adjDec
    clrf FSR0H
    movlw bcd_value_32_0
    movwf FSR0L
    call adjBCD
    movlw bcd_value_32_1
    movwf FSR0L
    call adjBCD
    movlw bcd_value_32_2
    movwf FSR0L
    call adjBCD
    movlw bcd_value_32_3
    movwf FSR0L
    call adjBCD
    goto binToBCDLoop
adjBCD
    movlw 3
    addwf INDF0,w
    movwf temp
    btfsc temp,3
    movwf INDF0
    movlw 30
    addwf INDF0,w
    movwf temp
    btfsc temp,7
    movwf INDF0
    return
    
    
bcdToSegments
    movlw b'11110000'
    andwf output1_2,w
    movwf temp
    swapf temp,w
    movwf output1_seg1
    
    movlw b'00001111'
    andwf output1_2,w
    movwf output1_seg2
    
    movlw b'11110000'
    andwf output1_1,w
    movwf temp
    swapf temp,w
    movwf output1_seg3
    
    movlw b'00001111'
    andwf output1_1,w
    movwf output1_seg4
    
    movlw b'11110000'
    andwf output1_0,w
    movwf temp
    swapf temp,w
    movwf output1_seg5
    
    movlw b'00001111'
    andwf output1_0,w
    movwf output1_seg6
    
    movlw b'11110000'
    andwf output2_2,w
    movwf temp
    swapf temp,w
    movwf output2_seg1
    
    movlw b'00001111'
    andwf output2_2,w
    movwf output2_seg2
    
    movlw b'11110000'
    andwf output2_1,w
    movwf temp
    swapf temp,w
    movwf output2_seg3
    
    movlw b'00001111'
    andwf output2_1,w
    movwf output2_seg4
    
    movlw b'11110000'
    andwf output2_0,w
    movwf temp
    swapf temp,w
    movwf output2_seg5
    
    movlw b'00001111'
    andwf output2_0,w
    movwf output2_seg6
    
    return
    
    
print7seg
    
setSeg1
    call delaySmall
    movlw b'00110000'
    iorwf output1_seg1,w
    clrf PORTD
    movwf PORTD
    
    btfsc program_setup,is_clock
    goto setSeg2
    
    movlw b'00110000'
    iorwf output2_seg1,w
    clrf PORTB
    movwf PORTB
    
    
setSeg2
    call delaySmall
    movlw b'01010000'
    btfsc program_setup,is_clock
    andlw b'11100000'
    iorwf output1_seg2,w
    clrf PORTD
    movwf PORTD
    
    btfsc program_setup,is_clock
    goto setSeg3
    
    movlw b'01010000'
    btfsc program_setup,is_clock
    andlw b'11100000'
    iorwf output2_seg2,w
    clrf PORTB
    movwf PORTB
    
setSeg3
    call delaySmall
    movlw b'01110000'
    btfss program_setup,is_clock
    andlw b'11100000'
    iorwf output1_seg3,w
    clrf PORTD
    movwf PORTD
    
    btfsc program_setup,is_clock
    goto setSeg4
    
    movlw b'01110000'
    btfss program_setup,is_clock
    andlw b'11100000'
    iorwf output2_seg3,w
    clrf PORTB
    movwf PORTB
    
setSeg4
    call delaySmall
    movlw b'10010000'
    btfsc program_setup,is_clock
    andlw b'11100000'
    iorwf output1_seg4,w
    clrf PORTD
    movwf PORTD
    
    btfsc program_setup,is_clock
    goto setSeg5
    
    movlw b'10010000'
    btfsc program_setup,is_clock
    andlw b'11100000'
    iorwf output2_seg4,w
    clrf PORTB
    movwf PORTB
    
setSeg5
    call delaySmall
    movlw b'10110000'
    iorwf output1_seg5,w
    clrf PORTD
    movwf PORTD
    
    btfsc program_setup,is_clock
    goto setSeg6
    
    movlw b'10110000'
    iorwf output2_seg5,w
    clrf PORTB
    movwf PORTB
    
setSeg6
    call delaySmall
    movlw b'11010000'
    iorwf output1_seg6,w
    clrf PORTD
    movwf PORTD
    
    btfsc program_setup,is_clock
    return
    
    movlw b'11010000'
    iorwf output2_seg6,w
    clrf PORTB
    movwf PORTB
    
    return
    
 
printUSART
    call delaySmall
    
checkTXClear
    btfss TXSTA,TRMT
    goto checkTXClear
    
    movlw '\f'
    movwf TXREG
    
checkTX1
    btfss TXSTA,TRMT
    goto checkTX1
    
    movlw 0x30
    addwf output1_seg1,w
    movwf TXREG
    
checkTX2
    btfss TXSTA,TRMT
    goto checkTX2
    
    movlw 0x30
    addwf output1_seg2,w
    movwf TXREG
    
    btfss program_setup,is_clock
    goto checkTX3
    
checkTXColon1
    btfss TXSTA,TRMT
    goto checkTXColon1
    
    movlw ':'
    movwf TXREG
    
checkTX3
    btfss TXSTA,TRMT
    goto checkTX3
    
    movlw 0x30
    addwf output1_seg3,w
    movwf TXREG
    
    btfsc program_setup,is_clock
    goto checkTX4
    
checkTXDot1
    btfss TXSTA,TRMT
    goto checkTXDot1
    
    movlw '.'
    movwf TXREG
    
checkTX4
    btfss TXSTA,TRMT
    goto checkTX4
    
    movlw 0x30
    addwf output1_seg4,w
    movwf TXREG
    
    btfss program_setup,is_clock
    goto checkTX5
    
checkTXColon2
    btfss TXSTA,TRMT
    goto checkTXColon2
    
    movlw ':'
    movwf TXREG
    
checkTX5
    btfss TXSTA,TRMT
    goto checkTX5
    
    movlw 0x30
    addwf output1_seg5,w
    movwf TXREG
    
checkTX6
    btfss TXSTA,TRMT
    goto checkTX6
    
    movlw 0x30
    addwf output1_seg6,w
    movwf TXREG

checkTX7
    btfss TXSTA,TRMT
    goto checkTX7
    
    movlw '\r'
    movwf TXREG
    
    btfsc program_setup,is_clock
    return
    
checkTX8
    btfss TXSTA,TRMT
    goto checkTX8
    
    movlw 0x30
    addwf output2_seg1,w
    movwf TXREG
    
checkTX9
    btfss TXSTA,TRMT
    goto checkTX9
    
    movlw 0x30
    addwf output2_seg2,w
    movwf TXREG
    
    btfss program_setup,is_clock
    goto checkTX10
    
checkTXColon3
    btfss TXSTA,TRMT
    goto checkTXColon3
    
    movlw ':'
    movwf TXREG
    
checkTX10
    btfss TXSTA,TRMT
    goto checkTX10
    
    movlw 0x30
    addwf output2_seg3,w
    movwf TXREG
    
    btfsc program_setup,is_clock
    goto checkTX4
    
checkTXDot2
    btfss TXSTA,TRMT
    goto checkTXDot2
    
    movlw '.'
    movwf TXREG
    
checkTX11
    btfss TXSTA,TRMT
    goto checkTX11
    
    movlw 0x30
    addwf output2_seg4,w
    movwf TXREG
    
    btfss program_setup,is_clock
    goto checkTX12
    
checkTXColon4
    btfss TXSTA,TRMT
    goto checkTXColon4
    
    movlw ':'
    movwf TXREG
    
checkTX12
    btfss TXSTA,TRMT
    goto checkTX12
    
    movlw 0x30
    addwf output2_seg5,w
    movwf TXREG
    
checkTX13
    btfss TXSTA,TRMT
    goto checkTX13
    
    movlw 0x30
    addwf output2_seg6,w
    movwf TXREG

checkTX14
    btfss TXSTA,TRMT
    goto checkTX14
    
    movlw '\r'
    movwf TXREG
    
    return

    
delayMiddle
    movlw d'12'
    movwf d3
    
delayMiddleOuter2
    movlw d'255'
    movwf d2
    
delayMiddleOuter1
    movlw d'255'
    movwf d1
    
delayMiddleInner
    decfsz d1
    goto delayMiddleInner
    
    decfsz d2
    goto delayMiddleOuter1
    
    decfsz d3
    goto delayMiddleOuter2
    
    return
    
    
delaySmall
    movlw d'100'
    movwf d2
    
delaySmallOuter
    movlw d'255'
    movwf d1
    
delaySmallInner
    decfsz d1
    goto delaySmallInner
    
    decfsz d2
    goto delaySmallOuter
    
    return
    

    
    end
