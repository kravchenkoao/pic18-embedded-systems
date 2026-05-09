    list p=18f4550;
    #include <p18f4550.inc>

    cblock 20
	count
	temp
	d1
	d2
	d3
	pressed_row
	pressed_col
	pressed_key
	row_counter
	show_counter
	found_key
	seg1
	seg2
	seg3
	seg4
    endc
    
    org 00
    goto start
    
    org 0x08
    goto HighInt
    
start
    call initPort
    call initUSART
    goto main

initPort 
    movlw 0x0f
    movwf ADCON1
    
    movlw   0x07
    movwf   CMCON
    
    clrf    TRISD           
    clrf    LATD            
    clrf    TRISB
    
    movlw   0x3c
    movwf   TRISA
    
    bcf PIE1, TXIE
    bcf INTCON, PEIE
    bcf INTCON, GIE

    clrf    count
    clrf    temp
    movlw   0x01
    movwf   row_counter
    movlw   0x01
    movwf   show_counter
    clrf    pressed_row
    clrf    pressed_col
    clrf    pressed_key
    clrf    found_key
    return 
    
initUSART
    movlw 0x00
    movwf SPBRGH
    bcf BAUDCON, BRG16
    bcf TXSTA, BRGH
    movlw .38
    movwf SPBRG
    
    bsf RCSTA, SPEN
    bsf RCSTA, CREN
    bcf TXSTA, SYNC
    
    bcf TRISC, 6   ; TX
    bsf TRISC, 7   ; RX
    
    bcf TXSTA, TX9
    bsf TXSTA, TXEN
    return
    
main
;    call case0
;    call case1
    call case2
;    call case3
;    call case4
    goto main
    
case0
    incf count,f
case0_check
    btfss PIR1, TXIF
    goto case0_check
    movff count, TXREG
    
    call small_delay
    return

case1 
    incf count,f  
    movf count, w  
    sublw .10 

    btfsc STATUS, Z
    clrf count 
    movf count, w  
    addlw 0x30
    
case1_check
    btfss PIR1, TXIF 
    goto case1_check
    movwf TXREG
    
    call small_delay
    
    return    
    
case2
    btfsc PIR1,RCIF
    call RC_Service
    goto case2
    
case3
    bsf PIE1, RCIE
    bsf INTCON, PEIE
    bsf INTCON, GIE
    return
    
case4
    rlncf row_counter,f
    
    btfsc row_counter,0
    goto scan_row0
    
    btfsc row_counter,1
    goto scan_row1
    
    btfsc row_counter,2
    goto scan_row2
    
    btfsc row_counter,3
    goto scan_row3
  
    movlw 0x80
    movwf row_counter
    clrf pressed_row
    clrf pressed_col
    clrf pressed_key
    
    movff found_key,temp
    clrf found_key
    btfsc temp,0
    goto show_result
    return
    
scan_row0
    movlw 0x00
    movwf pressed_row
    bcf LATD,6
    bcf LATD,7
    goto scan_col
    
scan_row1
    movlw 0x01
    movwf pressed_row
    bsf LATD,6
    bcf LATD,7
    goto scan_col
    
scan_row2
    movlw 0x02
    movwf pressed_row
    bcf LATD,6
    bsf LATD,7
    goto scan_col
    
scan_row3
    movlw 0x03
    movwf pressed_row
    bsf LATD,6
    bsf LATD,7
    goto scan_col
   
scan_col
    movlw 0x00
    btfss PORTA,2
    movlw 0x01
    btfss PORTA,3
    movlw 0x02
    btfss PORTA,4
    movlw 0x03
    btfss PORTA,5
    movlw 0x04
    
    movwf pressed_col
    movlw 0x00
    cpfseq pressed_col
    goto calculate_key
    
    return
    
calculate_key
    bsf found_key,0
    movff pressed_row,pressed_key
    rlncf pressed_key,f
    rlncf pressed_key,f
    movf pressed_col,w
    addwf pressed_key,f
    goto set_result
    
set_result
    clrf seg1
    clrf seg2
    clrf seg3
    clrf seg4
    
    movff pressed_key,temp
    movlw d'10'
    subwf temp,w
    btfss STATUS,C
    goto set_seg4
    
    incf seg3
    movwf temp
    
set_seg4
    movff temp, seg4
    return
    
    
show_result
    movff seg3,temp
    rlncf temp,f
    rlncf temp,f
    movlw 0x01
    iorwf temp,f
    movff temp,LATD
    movff seg3,temp
    movlw 0x30
    addwf temp,f
TX_check1
    btfss PIR1, TXIF
    goto TX_check1
    movff temp, TXREG
    call small_delay
    
    movff seg4,temp
    rlncf temp,f
    rlncf temp,f
    movlw 0x00
    iorwf temp,f
    movff temp,LATD
    movff seg4,temp
    movlw 0x30
    addwf temp,f
TX_check2
    btfss PIR1, TXIF
    goto TX_check2
    movff temp,TXREG
    call small_delay
    
    movlw 0x0d
TX_check3
    btfss PIR1,TXIF
    goto TX_check3
    movwf TXREG
    call small_delay
    
    return
    
RC_Service
    movlw 0x06
    andwf RCSTA,w
    btfss STATUS,Z
    goto RC_Error
    movf RCREG,w
    movwf LATB
    movwf TXREG
    call small_delay
    return
    
RC_Error
    bcf RCSTA,CREN
    bsf RCSTA,CREN
    movlw 0xFF
    movwf LATB
    call small_delay
    return
    
HighInt 
    btfsc PIR1,RCIF 
    call RC_Service
    retfie    

small_delay
    movlw d'2'
    movwf d3
    
small_delay_outer
    movlw d'255'
    movwf d2
    
small_delay_inner1
    movlw d'255'
    movwf d1

small_delay_inner2
    decfsz d1,f
    goto small_delay_inner2

    decfsz d2,f
    goto small_delay_inner1
    
    decfsz d3,f
    goto small_delay_outer

    return

delay
    movlw d'5'
    movwf d3

delay_outer2
    movlw d'255'
    movwf d2
    
delay_outer1
    movlw d'255'
    movwf d1

delay_inner
    decfsz d1,f
    goto delay_inner

    decfsz d2,f
    goto delay_outer1
    
    decfsz d3,f
    goto delay_outer2
    
    return
   
    end