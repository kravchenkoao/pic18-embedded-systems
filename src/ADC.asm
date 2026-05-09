    list p=18f4550;
    #include <p18f4550.inc>
    
    cblock 20
	levelH
	levelL
	d1
	d2
	d3
	count
	temp
	temp16H
	temp16L
	R0
	R1
	R2
	seg0
	seg1
	seg2
	seg3
	arg1H
	arg1L
	arg2H
	arg2L
	res0
	res1
	res2
	res3
    endc
    
    org 000000
    goto start
    
    org 000008
    goto HighInt
    
start    
    call System_Init
    call USART_Init
    call TMR0_Init
    call ADC_Init
    
;    call case3
;    call case4
    call case5
    
    goto Loop
    
Loop
    goto Loop
    
System_Init
    bsf INTCON,PEIE
    bsf INTCON,GIE
    
    return
    
USART_Init
    movlw 0x00
    movwf SPBRGH
    bcf BAUDCON,BRG16
    bcf TXSTA,BRGH
    movlw .38
    movwf SPBRG
    
    bcf TXSTA,SYNC
    bsf RCSTA,SPEN
    
    bcf TXSTA,TX9
    bsf TXSTA,TXEN
    
    return
    
TMR0_Init
    movlw b'10000111'
    movwf T0CON
    
    bsf INTCON,TMR0IE
    bsf INTCON2,TMR0IP
    
    movlw 0xFF
    movwf TMR0H
    clrf TMR0L
    
    return
    
ADC_Init
    bsf TRISA,RA0
    bsf TRISA,RA1
    
    movlw b'00001101'
    movwf ADCON1
    bsf ADCON0,ADON
    movlw b'10111110'
    movwf ADCON2
    
    return


HighInt
;    call TMR0_Interrupt
    call ADC_Interrupt
    
    retfie
    
TMR0_Interrupt
    movlw 0xFF
    movwf TMR0H
    clrf TMR0L
    bcf INTCON,TMR0IF
    
;    call case1
;    call case2
    
    return
    
    
case1    

checkTX1
    btfss TXSTA,TRMT
    goto checkTX1
    movlw 'O'
    movwf TXREG
    
checkTX2
    btfss TXSTA,TRMT
    goto checkTX2
    movlw 'k'
    movwf TXREG   
    
checkTX3
    btfss TXSTA,TRMT
    goto checkTX3
    movlw '!'
    movwf TXREG   
    
checkTX4
    btfss TXSTA,TRMT
    goto checkTX4
    movlw '\n'
    movwf TXREG   
    
checkTX5
    btfss TXSTA,TRMT
    goto checkTX5
    movlw '\r'
    movwf TXREG   
    
    return
    
    
case2
    call delayADC
    
    bsf ADCON0,GO/DONE
    
checkADC
    btfss ADCON0,GO/DONE
    goto checkADC
    
    movff ADRESH,levelH
    movff ADRESL,levelL
    
checkTX6
    btfss TXSTA,TRMT
    goto checkTX6
    
    movff levelL,TXREG
    
    return

    
ADC_Interrupt
    call delay500
    
    movff ADRESH,levelH
    movff ADRESL,levelL
    
;    clrf seg0	;case3
;    clrf seg1
;    clrf seg2
;    movff levelL,seg3	;end case3
    
;    movff levelH,temp16H    ;case4
;    movff levelL,temp16L    ;end case4
    
    movff levelH,arg1H	;case5
    movff levelL,arg1L
    movlw b'00000100'
    movwf arg2H
    movlw b'11100010'
    movwf arg2L
    
    call mult1616
    
    movff res2,temp16H
    movff res1,temp16L	;end case5
;    
;    
    
    call bin_to_bdc ;block for case4 and case5
    
    movlw 0xf0	
    andwf R1,w
    movwf seg0
    swapf seg0,f
    
    movlw 0x0f
    andwf R1,w
    movwf seg1
    
    movlw 0xf0
    andwf R2,w
    movwf seg2
    swapf seg2,f
    
    movlw 0x0f
    andwf R2,w
    movwf seg3	;end block for case4 and case5
    
    call sendUSART
    
;    call delay500
    
    bcf PIR1,ADIF
    bsf	ADCON0,GO/DONE
    
    return
    

case3
    bcf INTCON,TMR0IE
    bcf INTCON2,TMR0IP
    
    bsf PIE1,ADIE
    bsf IPR1,ADIP
    
    bsf ADCON0,GO/DONE
    
    return
    

case4
    bcf INTCON,TMR0IE
    bcf INTCON2,TMR0IP
    
    bsf PIE1,ADIE
    bsf IPR1,ADIP
    
    bsf ADCON0,GO/DONE
    
    return
    
case5
    bcf INTCON,TMR0IE
    bcf INTCON2,TMR0IP
    
    bsf PIE1,ADIE
    bsf IPR1,ADIP
    
    bsf ADCON0,GO/DONE
    
    return

mult1616
    movf arg1L,w
    mulwf arg2L
    
    movff PRODH,res1
    movff PRODL,res0
    
    movf arg1H,w
    mulwf arg2H
    
    movff PRODH,res3
    movff PRODL,res2
    
    movf arg1L,w
    mulwf arg2H
    
    movf PRODL,w
    addwf res1,f
    movf PRODH,w
    addwfc res2,f
    clrf WREG
    addwfc res3,f
    
    movf arg1H,w
    mulwf arg2L
    
    movf PRODL,w
    addwf res1,f
    movf PRODH,w
    addwfc res2,f
    clrf WREG
    addwfc res3,f
    
    return
    
sendUSART
    
checkTX13
    btfss TXSTA,TRMT
    goto checkTX13
    
    movlw '\f'
    movwf TXREG
    
checkTX7
    btfss TXSTA,TRMT
    goto checkTX7
    
    movlw 0x30
    addwf seg0,w
    movwf TXREG
    
checkTX8
    btfss TXSTA,TRMT
    goto checkTX8
    
    movlw 0x30
    addwf seg1,w
    movwf TXREG

checkTX9
    btfss TXSTA,TRMT
    goto checkTX9
    
    movlw 0x30
    addwf seg2,w
    movwf TXREG
    
checkTX10
    btfss TXSTA,TRMT
    goto checkTX10
    
    movlw 0x30
    addwf seg3,w
    movwf TXREG

checkTX11
    btfss TXSTA,TRMT
    goto checkTX11
    
    movlw '\n'
    movwf TXREG
    
checkTX12
    btfss TXSTA,TRMT
    goto checkTX12
    
    movlw '\r'
    movwf TXREG
    
    return
    
bin_to_bdc
    bcf STATUS,C
    movlw .16
    movwf count
    clrf R0
    clrf R1
    clrf R2
loop16a2
    rlcf temp16L,f
    rlcf temp16H,f
    rlcf R2,f
    rlcf R1,f
    rlcf R0,f
    decfsz count,f
    goto AdjDec2
    return
AdjDec2
    movlw R2
    clrf FSR0H
    movwf FSR0L
    call AdjBCD2
    movlw R1
    movwf FSR0L
    call AdjBCD2
    movlw R0
    movwf FSR0L
    call AdjBCD2
    goto loop16a2
AdjBCD2
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
    
    
delayADC    
    movlw d'99'
    movwf d1
    
delayADC_inner
    dcfsnz d1
    return
    goto delayADC_inner
    

delay500
    movlw d'18'
    movwf d3
delay500_outer2
    movlw d'255'
    movwf d2
delay500_outer1
    movlw d'255'
    movwf d1
delay500_inner
    nop
    nop
    decfsz d1
    goto delay500_inner
    
    decfsz d2
    goto delay500_outer1
    
    decfsz d3
    goto delay500_outer2
    
    return
    
    end
