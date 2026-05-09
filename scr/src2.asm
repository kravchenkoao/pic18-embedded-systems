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
    
start
    call initPort
    goto main

initPort 
    movlw 0x0f
    movwf ADCON1
    
    movlw   0x07
    movwf   CMCON
    
    bsf TRISE, 0 ; SB18 ?? ???? 
    bsf TRISE, 1 ; SB19 ?? ???? 
    bsf TRISE, 2 ; SB20 ?? ???? 
    
    clrf    TRISD           ; PORTD ???? ?? ?????
    clrf    LATD            ; ???????? ?????
    
    movlw   0x3c
    movwf   TRISA
    
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
    ; ???? D ????? ?? ????? 
    return 
    
main
;    call case0
;    call case1
;    call case2
;    call case3
    call case4
    goto main
    
case0
    btfss PORTE,0
    goto pressed0
    
    movlw B'00000000'
    movwf LATD
    
    return
    
pressed0
    movlw B'00000100'
    movwf LATD
    return
    
case1
    btfss PORTE,0
    goto pressed1
    
    btfss PORTE,1
    goto pressed2
    
    btfss PORTE,2
    goto pressed3
    
    movlw 00
    movwf LATD
    return
    
pressed1
    movlw B'00000100'
    movwf LATD
    return  

pressed2
    movlw B'00001000'
    movwf LATD
    return
    
pressed3
    movlw B'00001100'
    movwf LATD
    return 
    
case2 
    btfss PORTE,1  ; ?????? SB19 ????????? ? 
    incf count,f ; ????????? ?????????? 
    
    movlw d'10'
    subwf count,w
    btfsc STATUS,C
    clrf  count
    
    
    movf count,w
    movwf temp
    rlncf temp, f
    rlncf temp, w
    movwf LATD  
    
    btfss PORTE,2 
    clrf count ; ????????? ????????? ??????? SB20 
    
    call delay
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

case3
    movlw 0x80
    btfsc show_counter,1
    movwf show_counter
    
    rlncf show_counter,f
    
    btfsc show_counter,0
    goto check_buttons
    
    clrf pressed_row
    clrf pressed_col
    clrf pressed_key
    
    btfss found_key,0
    goto calculate_key
    
    clrf found_key
    goto show_result
    
   
    
check_buttons  
    btfss PORTE,0
    goto scan_row1
    
    btfss PORTE,1
    goto scan_row2
    
    btfss PORTE,2
    goto scan_row3
    
    goto scan_row0
    
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
    
    btfss found_key,0
    goto calculate_key
    
    clrf found_key
    goto show_result
    
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
    call small_delay
    
    movff seg4,temp
    rlncf temp,f
    rlncf temp,f
    movlw 0x00
    iorwf temp,f
    movff temp,LATD
    call small_delay
    
    return
    
small_delay
    movlw d'255'
    movwf d2
    
small_delay_outer
    movlw d'255'
    movwf d1

small_delay_inner
    decfsz d1,f
    goto small_delay_inner

    decfsz d2,f
    goto small_delay_outer

    return
    end