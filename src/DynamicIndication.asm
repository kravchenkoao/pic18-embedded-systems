        list    p=18f4550
        #include <p18f4550.inc>

        config  fosc = hs
        config  wdt = off
        config  lvp = off
        config  pbaden = off
        config  mclre = off

        cblock  0x20
            count
            seg1
            seg2
            seg3
            seg4
            temp
            refresh
            delay1
            delay2
        endc

        org     0x0000
        goto    start

start:
;        clrf    PORTB
        clrf    PORTD

;        movlw   0x0f
;        movwf   ADCON1      

        movlw   0x07
        movwf   CMCON      

;        clrf    TRISB       
        clrf    TRISD       

        clrf    count

main:
        call    case2
        goto    main

case2:
        call    build_digits

        movlw   0x08
        movwf   refresh

show_again:
        call    show_digits
        decfsz  refresh, f
        goto    show_again

        incf    count, f

        movlw   0x65
        subwf   count, w
        btfss   STATUS, Z
        return

        clrf    count
        return

build_digits:
        clrf    seg1
        clrf    seg2
        clrf    seg3
        clrf    seg4

        movf    count, w
        movwf   temp

        movlw   0x64
        subwf   temp, w
        btfss   STATUS, Z
        goto    count_tens

        movlw   0x01
        movwf   seg2
        clrf    temp

count_tens:
        movlw   0x0a
        subwf   temp, w
        btfss   STATUS, C
        goto    count_units

        movlw   0x0a
        subwf   temp, f
        incf    seg3, f
        goto    count_tens

count_units:
        movf    temp, w
        movwf   seg4
        return

show_digits:
        movf    seg1, w
        movwf   temp
        rlncf   temp, f
        rlncf   temp, w
        movwf   PORTD
        call    short_delay

        movf    seg2, w
        movwf   temp
        rlncf   temp, f
        rlncf   temp, w
        iorlw   0x01
        movwf   PORTD
        call    short_delay

        movf    seg3, w
        movwf   temp
        rlncf   temp, f
        rlncf   temp, w
        iorlw   0x02
        movwf   PORTD
        call    short_delay

        movf    seg4, w
        movwf   temp
        rlncf   temp, f
        rlncf   temp, w
        iorlw   0x03
        movwf   PORTD
        call    short_delay

        return

short_delay:
        movlw   0x20
        movwf   delay2

delay_outer:
        movlw   0xff
        movwf   delay1

delay_inner:
        nop
        decfsz  delay1, f
        goto    delay_inner

        decfsz  delay2, f
        goto    delay_outer

        return

        end
