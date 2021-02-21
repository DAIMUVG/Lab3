;Archivo:	Main_lab_3.s
;dispositivo:	PIC16F887
;Autor:		Dylan Ixcayau
;Compilador:	pic-as (v2.31), MPLABX V5.45
;
;Programa:	Botones y Timer 0
;Hardware:	Botones en el puerto B, LEDs en el puerto A y Display en el puerto C, D
;
;Creado:	15 feb, 2021
;Ultima modificacion:  feb, 2021

#include <xc.inc>

; CONFIG1
  CONFIG  FOSC = INTRC_CLKOUT   ; Oscillator Selection bits (INTOSC oscillator: CLKOUT function on RA6/OSC2/CLKOUT pin, I/O function on RA7/OSC1/CLKIN)
  CONFIG  WDTE = OFF            ; Watchdog Timer Enable bit (WDT disabled and can be enabled by SWDTEN bit of the WDTCON register)
  CONFIG  PWRTE = OFF           ; Power-up Timer Enable bit (PWRT disabled)
  CONFIG  MCLRE = OFF           ; RE3/MCLR pin function select bit (RE3/MCLR pin function is digital input, MCLR internally tied to VDD)
  CONFIG  CP = OFF              ; Code Protection bit (Program memory code protection is disabled)
  CONFIG  CPD = OFF             ; Data Code Protection bit (Data memory code protection is disabled)
  CONFIG  BOREN = OFF           ; Brown Out Reset Selection bits (BOR disabled)
  CONFIG  IESO = OFF            ; Internal External Switchover bit (Internal/External Switchover mode is disabled)
  CONFIG  FCMEN = OFF           ; Fail-Safe Clock Monitor Enabled bit (Fail-Safe Clock Monitor is disabled)
  CONFIG  LVP = ON              ; Low Voltage Programming Enable bit (RB3/PGM pin has PGM function, low voltage programming enabled)

; CONFIG2
  CONFIG  BOR4V = BOR40V        ; Brown-out Reset Selection bit (Brown-out Reset set to 4.0V)
  CONFIG  WRT = OFF             ; Flash Program Memory Self Write Enable bits (Write protection off)

  PSECT udata_bank0 ;common memory
  var: DS 1 ;1 byte
    
  PSECT resVect, class=CODE, abs, delta=2

;-----------vector reset----------------------------
ORG 00h		    ; posicion 0000h para el reset
resetVec:
    PAGESEL main
    goto    main

PSECT code, delta=2, abs
ORG 100h	;posicion para el codigo
;-----------configuracion----------------------------
    
main:				    ;Configuración de los puertos
    banksel	ANSEL
    clrf	ANSEL
    clrf	ANSELH
    
    banksel	TRISA
    movlw	11010000B
    movwf	TRISA
    
    movlw	10000000B
    movwf	TRISC
    
    clrf	TRISD
    
    movlw	11111111B
    movwf	TRISB
    
    banksel	PORTD
    clrf	PORTD
    clrf	PORTA
    clrf	PORTC
    
    call	config_reloj
    call	config_timr0
Loop:
    
    call    inc_porta
    
    btfsc   PORTB, 0		;Reviso el pin RB0
    call    inc_7seg
    
    btfsc   PORTB, 1
    call    dec_7seg
    goto    Loop	        ;loop forever

inc_porta:
    btfss   T0IF 	
    goto    $-1
    call    timr0
    incf    PORTA
    return
    
inc_7seg:
    btfsc	PORTB, 0		;Antirebote del boton
    goto	$-1	
    incf	var
    movf	var, w
    call	TABLA_7S ;Incremento el puerto
    movwf	PORTC
    return

dec_7seg:
    btfsc	PORTB, 1
    goto	$-1
    decf	var
    movf	var, w
    call	TABLA_7S
    movwf	PORTC
    return
    
config_timr0:
    banksel OPTION_REG   ;Banco de registros asociadas al puerto A
    bcf	    T0CS    ; reloj interno clock selection
    bcf	    PSA	    ;Prescaler 
    bsf	    PS2
    bsf	    PS1
    bsf	    PS0	    ;PS = 111 Tiempo en ejecutar , 256
    
    banksel TMR0
    call    timr0
    return
    
 timr0: 
    movlw   134
    movwf   TMR0
    bcf	    T0IF
    return
    
 config_reloj:
    banksel OSCCON	;Banco OSCCON 
    bcf	    IRCF2	;OSCCON configuración bit2 IRCF
    bsf	    IRCF1	;OSCCON configuracuón bit1 IRCF
    bcf	    IRCF0	;OSCCON configuración bit0 IRCF
    bsf	    SCS		;reloj interno , 250KHz
    return
;---------------------------------TABLA----------------------------------------
TABLA_7S:
    clrf    PCLATH
    bsf	    PCLATH, 0
    andlw   0x0f
    addwf   PCL
    retlw   00111111B;0
    retlw   00000110B;1
    retlw   01011011B;2
    retlw   01001111B;3
    retlw   01100110B;4
    retlw   01101101B;5
    retlw   01111101B;6
    retlw   00000111B;7
    retlw   01111111B;8
    retlw   01101111B;9
    retlw   01110111B;A
    retlw   01111100B;b
    retlw   00111001B;c
    retlw   01011110B;d
    retlw   01111001B;E
    retlw   01110001B;F
END