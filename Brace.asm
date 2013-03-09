.include "includes/m8Adef.inc"
.include "includes/macro.inc"
.equ 	XTAL = 8000000 	
.equ 	baudrate = 9600  
.equ 	bauddivider = XTAL/(16*baudrate)-1
.equ 	led = PD7
.equ	maxDispB = 2
; .equ	dispTable = 200
.DEF 	displayByte = R18

; RAM =====================================================
		.DSEG			; ������� ���
strPtr: .BYTE 2 	; �������� ������������ ��� ���������
				 	; ������ �� ���������� ����
 
; FLASH ===================================================
		.CSEG			; ������� �������

	; ������ ���������� ===============================
		.ORG $000
		RJMP hard_init
        .ORG URXCaddr
        RJMP	RX_OK	  	; (USART,RXC) USART, Rx Complete
        .ORG UDREaddr
        RJMP	UD_OK       ; (USART,UDRE) USART Data Register Empty
        .ORG UTXCaddr
        RJMP	TX_OK      	; (USART,TXC) USART, Tx Complete
        .ORG INT_VECTORS_SIZE
    ; ����������� ���������� ==========================
RX_OK:		
		PUSHF
		CLRB UCSRB, RXCIE, tmp1 	; ������ �� ���������, ��������
		
		IN	displayByte, UDR		; ��������
	
		; ������ ����� � ����������� �� ����������
		CPI displayByte, maxDispB	; >= maxDispB
		BRSH bad
	
	gud:LDI	tmp1,Low(2*okString)	; Ok!
		LDI	tmp2,High(2*okString)
		RCALL updateLight 			; ����� ����� ����� ��������� ������
		RJMP cnt

 	bad:LDI tmp1,Low(2*failString)	; Fail
 		LDI tmp2,High(2*failString)
 		RJMP cnt

	cnt:STS	strPtr,tmp1				
		STS	strPtr+1,tmp2					
		SETB UCSRB, UDRIE, tmp1 	; ��������
		POPF
		RETI
UD_OK:
		PUSHF
		PUSH	ZL		; ��������� � ����� Z
		PUSH	ZH
 
		LDS	ZL,strPtr	; ������ ��������� � ��������� ��������
		LDS	ZH,strPtr+1
 
		LPM	tmp1,Z+		; ������� ���� �� �����. �� ����� ������
 
		CPI	tmp1,0		; ���� �� �� ����, ������ ������ ������
		BREQ STOP_RX	; ����� ������������� ��������
 
		OUT	UDR,tmp1	; ������ ������ � �����.
 
		STS	strPtr,ZL	; ��������� ��������� 
		STS	strPtr+1,ZH	; �������, � ������
Exit_RX:	
		POP	ZH		; ��� ������� �� �����, �������.
		POP	ZL
		POPF
		RETI
	; ������ ���������� �� �����������, ������� �� �����������
STOP_RX:
		OUT UDR, displayByte
		CLRB UCSRB, UDRIE, tmp1 ; ������������� ��������
		SETB UCSRB, RXCIE, tmp1 ; ��������������� ����� ��������
		RJMP	Exit_RX
TX_OK:
		RETI
	; ==================================================

okString:	.db	"Ok! ",0,0

failString: .db "Fail ",0

SetStringPts:


		RET

hard_init:	; Internal Hardware Init  =====================

		LDI 	tmp1, low(bauddivider)
		OUT 	UBRRL,tmp1
		LDI 	tmp1, high(bauddivider)
		OUT 	UBRRH,tmp1
		RJMP init

init:
		LDI tmp1,Low(RAMEND)	; ������������� �����
		OUT SPL,tmp1			; �����������!!!
		LDI tmp1,High(RAMEND)
		OUT SPH,tmp1

		RCALL uart_init
		RCALL light_init

		LDI tmp1, 1<<SREG_I ; ��������� ����������
		OUT SREG, tmp1 	; ������ ����� ������ �������������

		RCALL main

uart_init:	
		LDI 	tmp1,0
		OUT 	UCSRA, tmp1
 
		; ��������� ������ �� ������ �������
		LDI 	tmp1, (1<<RXEN)|(1<<TXEN)|(1<<RXCIE)|(0<<TXCIE)|(0<<UDRIE)
		OUT 	UCSRB, tmp1	
 
		; ������ ����� - 8 ���, ����� � ������� UCSRC, �� ��� �������� ��� ��������
		LDI 	tmp1, (1<<URSEL)|(1<<UCSZ0)|(1<<UCSZ1)
		OUT 	UCSRC, tmp1
		RET
light_init:
		SETB DDRD, led, tmp1
		CLRB PORTD,led, tmp1
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
		.ESEG			; ������� EEPROM


