;Archivo:	Main_lab_3.s
;dispositivo:	PIC16F887
;Autor:		Dylan Ixcayau
;Compilador:	pic-as (v2.31), MPLABX V5.45
;
;Programa:	Botones y Timer 0
;Hardware:	Botones en el puerto B, LEDs en el puerto A y Display en el puerto C, D
;
;Creado:	15 feb, 2021
;Ultima modificacion:  20 feb, 2021

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
    banksel	ANSEL		    ;Llamo al banco de memoria donde estan los ANSEL
    clrf	ANSEL		    ;Pines digitales
    clrf	ANSELH
    
    banksel	TRISA		    ;Llamo al banco de memoria donde estan los TRISA y WPUB
    movlw	11010000B	    ;Configuro los puertos de salida que usare y los demas los dejo como entradas para no afectar el conteo del led
    movwf	TRISA
    
    movlw	10000000B	    
    movwf	TRISC
    
    clrf	TRISD
    movlw	11111111B		;Activo las resistencias de los puertos de B
    movwf	WPUB
    
    movlw	11111011B		;Dejo todos como los puertos como botones, menos uno que sera la alarma
    movwf	TRISB
    
    banksel	PORTD			;Llamo al banco de memoria donde estan los PORT
    clrf	PORTD			;Limpio los puertos
    clrf	PORTA
    clrf	PORTC
    clrf	PORTB
    
    call	config_reloj		;Configuracion de reloj para darle un valor al oscilador
    call	config_timr0		;Configutacion del timer0
Loop:
    btfsc	 PORTB, 0		;Reviso el pin RB0
    call	 inc_7seg		;Rutina para incrementar el display
    btfsc	 PORTB, 1		;Reviso el pin RB1
    call	 dec_7seg		;Rutina para decrementar el display
    
    movf	PORTD, w		;Muevo el valor del puerto D a W
    call	TABLA_7S		;El valor en w se compara con la tabla y arroja una nueva configuracion
    movwf	PORTC			;Saca w convertido para mostrar su valor en el display de forma hexadecimal
    btfss	T0IF			;Verifica si el timer 0 esta desbordado
    goto	Loop			;Regresa al loop desde el principio
    call	inc_porta		;Rutina para incrementar el contador del puerto A
    
    ;incf	PORTD, w		;Mueve el valor del puerto D a w
    subwf	PORTA, w		;Resta el valor de w al puerto A
    
    btfsc	STATUS, 2		;Verifica si el resultado de la resta es 0
    call	alarma			;Rutina para encender la alarma
    
    btfss	STATUS, 2		;Verifica si el resultado de la resta es diferente de 0
    bcf		PORTB, 2		;Si el resultado no es 0, no se enciende la led
    
    goto	Loop	        ;loop forever
alarma:
    bsf		PORTB, 2		;Si el resultado de la resta es 0, enciende la LED
    clrf	PORTA			;Limpia el puerto A, se reinicia
    return
    
inc_porta:
    btfss	T0IF		;Verifica si se ha desbordado el timer0	
    goto	Loop		;regresa al loop
    call	timr0		;Aqui configuro el valor del Timer
    incf	PORTA		;Incremento el puerto A
    return
    
inc_7seg:
    btfsc	PORTB, 0		;Antirebote del boton
    goto	$-1			
    incf	PORTD			;Incremento el puerto D
    return

dec_7seg:
    btfsc	PORTB, 1		;Antirebote del boton
    goto	$-1
    decf	PORTD			;decremento el puerto D
    return
    
config_timr0:
    banksel OPTION_REG	    ;Banco de registros asociadas al puerto A
    bcf	    T0CS	    ; reloj interno clock selection
    bcf	    PSA		    ;Prescaler 
    bsf	    PS2
    bsf	    PS1
    bsf	    PS0		   ;PS = 111 Tiempo en ejecutar , 256
    
    banksel TMR0
    call    timr0
    return
    
 timr0: 
    movlw   240		   ;valor en decimal del timer 0
    movwf   TMR0	   ;Se le asigna el valor
    bcf	    T0IF	   ;Se limpia
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