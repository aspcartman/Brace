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
		.DSEG			; Сегмент ОЗУ
strPtr: .BYTE 2 	; Указател используется для высирания
				 	; ответа на приходящий байт
 
; FLASH ===================================================
		.CSEG			; Кодовый сегмент

	; Вектор прерываний ===============================
		.ORG $000
		RJMP hard_init
        .ORG URXCaddr
        RJMP	RX_OK	  	; (USART,RXC) USART, Rx Complete
        .ORG UDREaddr
        RJMP	UD_OK       ; (USART,UDRE) USART Data Register Empty
        .ORG UTXCaddr
        RJMP	TX_OK      	; (USART,TXC) USART, Tx Complete
        .ORG INT_VECTORS_SIZE
    ; Обработчики прерываний ==========================
RX_OK:		
		PUSHF
		CLRB UCSRB, RXCIE, tmp1 	; Больше не принимаем, извините
		
		IN	displayByte, UDR		; Забираем
	
		; Рожаем ответ в зависимости от валидности
		CPI displayByte, maxDispB	; >= maxDispB
		BRSH bad
	
	gud:LDI	tmp1,Low(2*okString)	; Ok!
		LDI	tmp2,High(2*okString)
		RCALL updateLight 			; Между делом сразу обновляем светик
		RJMP cnt

 	bad:LDI tmp1,Low(2*failString)	; Fail
 		LDI tmp2,High(2*failString)
 		RJMP cnt

	cnt:STS	strPtr,tmp1				
		STS	strPtr+1,tmp2					
		SETB UCSRB, UDRIE, tmp1 	; Отвечаем
		POPF
		RETI
UD_OK:
		PUSHF
		PUSH	ZL		; Сохраняем в стеке Z
		PUSH	ZH
 
		LDS	ZL,strPtr	; Грузим указатели в индексные регистры
		LDS	ZH,strPtr+1
 
		LPM	tmp1,Z+		; Хватаем байт из флеша. Из нашей строки
 
		CPI	tmp1,0		; Если он не ноль, значит читаем дальше
		BREQ STOP_RX	; Иначе останавливаем передачу
 
		OUT	UDR,tmp1	; Выдача данных в усарт.
 
		STS	strPtr,ZL	; Сохраняем указатель 
		STS	strPtr+1,ZH	; обратно, в память
Exit_RX:	
		POP	ZH		; Все достаем из стека, выходим.
		POP	ZL
		POPF
		RETI
	; глушим прерывание по опустошению, выходим из обработчика
STOP_RX:
		OUT UDR, displayByte
		CLRB UCSRB, UDRIE, tmp1 ; Останавливаем передачу
		SETB UCSRB, RXCIE, tmp1 ; Восстанавливаем прием байтигов
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
		LDI tmp1,Low(RAMEND)	; Инициализация стека
		OUT SPL,tmp1			; Обязательно!!!
		LDI tmp1,High(RAMEND)
		OUT SPH,tmp1

		RCALL uart_init
		RCALL light_init

		LDI tmp1, 1<<SREG_I ; Включение прерываний
		OUT SREG, tmp1 	; Только после полной инициализации

		RCALL main

uart_init:	
		LDI 	tmp1,0
		OUT 	UCSRA, tmp1
 
		; Реагируем только на приход байтика
		LDI 	tmp1, (1<<RXEN)|(1<<TXEN)|(1<<RXCIE)|(0<<TXCIE)|(0<<UDRIE)
		OUT 	UCSRB, tmp1	
 
		; Формат кадра - 8 бит, пишем в регистр UCSRC, за это отвечает бит селектор
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
		.ESEG			; Сегмент EEPROM


