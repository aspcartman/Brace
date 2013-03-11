.include "includes/m8Adef.inc"
.include "includes/macro.inc"
.equ 	XTAL = 8000000 	
.equ 	baudrate = 9600  
.equ 	bauddivider = XTAL/(16*baudrate)-1
.equ 	led = PD7
.equ	maxDispB = 2
.DEF 	displayByte = R18

; RAM =====================================================
		.DSEG		; RAM
strPtr: .BYTE 2 	; Pointer to a string, that are being printed
					; to UART

; FLASH ===================================================
		.CSEG	
	; Interrupt Vector ====================================
		.ORG $000
		RJMP init
		.ORG URXCaddr
		RJMP	RX_OK	  	; (USART,RXC) USART, Rx Complete
		.ORG UDREaddr
		RJMP	UD_OK       ; (USART,UDRE) USART Data Register Empty
		.ORG UTXCaddr
		RJMP	TX_OK      	; (USART,TXC) USART, Tx Complete
		.ORG INT_VECTORS_SIZE

	; Interrupts ==========================================
	; The path is
	; RX_OK 
	;	|
	;	ˇ
	; Forbid an RX interruption
	;	|
	;	ˇ
	; Read a Byte 
	;	|
	;	ˇ
	; If it's bad ---> Set strPtr to the Fail string in codeSeg
	; If it's good --> Set strPtr to "Ok"		|
	;							|				|
	;							ˇ				|
	; 					Call updateLigth <------┼---> A vector table with the good byte
	; 							|				|		as offset. RET
	; 							ˇ				|
	;				Enable UDR empty interrupt <┘
	;			UDR is now empty and the transfer of bytes
	;			will immidiately begin. But simulator shows,
	;			that there are some ticks in main though
	; RETI to main
	; ...
	; UD_OK 
	; Reading char, ++ptr, saving and yet again. On \0 exiting.
	
RX_OK:		
		PUSHF
		CLRB UCSRB, RXCIE, tmp1 	; Shutting the door. We have a 2
									; byte cache, if smth happens
		
		IN	displayByte, UDR		; Getting the byte
		CPI displayByte, maxDispB	; >= maxDispB
		BRSH bad
	good:
        LDI	tmp1,Low(2*okString)	; Ok!
		LDI	tmp2,High(2*okString)
		RCALL updateLight 			; Updating Screen
		RJMP cnt
	bad:
        LDI tmp1,Low(2*failString)	; Fail
		LDI tmp2,High(2*failString)
		RJMP cnt
	cnt:
        STS	strPtr,tmp1				
		STS	strPtr+1,tmp2					
		SETB UCSRB, UDRIE, tmp1 	; Answering the call (UDR is empty, so UD_OK is called)
		POPF
		RETI
UD_OK:
		PUSHF
		PUSH	ZL		
		PUSH	ZH
 
		LDS	ZL,strPtr	
		LDS	ZH,strPtr+1
 
		LPM	tmp1,Z+		; Taking a byte from a string
 
		CPI	tmp1,0		; \0 check
		BREQ STOP_RX	
 
		OUT	UDR,tmp1	; Pooping to UART
 
		STS	strPtr,ZL	; Saving the pointer
		STS	strPtr+1,ZH	; back to mem
Exit_RX:	
		POP	ZH			; Getting everything back
		POP	ZL			; and exiting
		POPF
		RETI
STOP_RX:
		OUT UDR, displayByte
		CLRB UCSRB, UDRIE, tmp1 ; Stropping the transfer
		SETB UCSRB, RXCIE, tmp1 ; Listening again
		RJMP	Exit_RX

TX_OK:
		RETI
	; ==================================================

okString:	.db	"Ok! ",0,0
failString: .db "Fail ",0

init:
		LDI tmp1,Low(RAMEND)	; Stack Init
		OUT SPL,tmp1			
		LDI tmp1,High(RAMEND)
		OUT SPH,tmp1

		RCALL uart_init
		RCALL light_init

		SETB SREG,SREG_I,tmp1
		RCALL main

uart_init:	
        LDI tmp1, low(bauddivider) ; UART Baudrate 
		OUT UBRRL,tmp1
		LDI tmp1, high(bauddivider)
		OUT UBRRH,tmp1

		LDI 	tmp1,0
		OUT 	UCSRA, tmp1
 
		; Enabling UART, accepting bytes
		LDI 	tmp1, (1<<RXEN)|(1<<TXEN)|(1<<RXCIE)|(0<<TXCIE)|(0<<UDRIE)
		OUT 	UCSRB, tmp1	
 
		; 8bit frame
		LDI 	tmp1, (1<<URSEL)|(1<<UCSZ0)|(1<<UCSZ1)
		OUT 	UCSRC, tmp1
		RET

light_init:
		SETB DDRD, led, tmp1 	; Making leg a output
		CLRB PORTD,led, tmp1 	; With gnd on it
		RET

main:
		NOP
		RJMP main 

updateLight:
		PUSHF
		jumpto dispTable, displayByte

dispTable: 
		RJMP off
		RJMP on

	off:
		CLRB PORTD,led
		RJMP done
	on:
		SETB PORTD,led
		RJMP done
	done:
		POPF
		RET

; EEPROM ==================================================
		.ESEG			; Сегмент EEPROM


