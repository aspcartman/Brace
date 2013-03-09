;= Start macro.inc ===========================
.DEF	tmp1 = R16
.DEF 	tmp2 = R17
;SET BIT with stack
.MACRO	SETBM 
	.if @0 < 0x20
	SBI	@0, @1
	.else
		.if @0<0x40
	PUSH	@2
	IN	@2, @0
	ORI	@2, 1<<@1
	OUT	@0, @2
	POP	@2
		.else
	PUSH	@2
	LDS	@2, @0
	ORI	@2, 1<<@1
	STS	@0, @2
	POP	@2
		.endif
	.endif
	.ENDM
 
;SET BIT with REG
.MACRO	SETB
	.if @0 < 0x20			; Low IO
	SBI	@0, @1
	.else
		.if @0<0x40		; High IO
	IN	@2, @0
	ORI	@2, 1<<@1
	OUT	@0, @2
		.else			; Memory
	LDS	@2, @0
	ORI	@2, 1<<@1
	STS	@0, @2
		.endif
	.endif
	.ENDM
;.............................................
;Clear BIT with REG
.MACRO	CLRB
	.if @0 < 0x20			; Low IO
	CBI	@0, @1
	.else
		.if @0<0x40		; High IO
	IN	@2, @0
	ANDI	@2, ~(1<<@1)
	OUT	@0, @2
		.else			; Memory
	LDS	@2, @0
	ANDI	@2, ~(1<<@1)
	STS	@0, @2
		.endif
	.endif
	.ENDM
 
;Clear BIT with STACK
.MACRO	CLRBM 
	.if @0 < 0x20
	CBI	@0, @1
	.else
		.if @0<0x40
	PUSH	tmp2
	IN	tmp2, @0
	ANDI	tmp2, ~(1<<@1)
	OUT	@0, tmp2
	POP	tmp2
		.else
	PUSH	tmp2
	LDS	tmp2, @0
	ANDI	tmp2, ~(1<<@1)
	STS	@0, tmp2
	POP	tmp2
		.endif
	.endif
	.ENDM
;.............................................
 
.MACRO	INVB
	.if	@0 < 0x40
	IN	@2, @0
	LDI	@3, 1<<@1
	EOR	@3, @2
	OUT	@0, @3
	.else
	LDS	@2, @0
	LDI	@3, 1<<@1
	EOR	@2, @3
	STS	@0, @2
	.endif
	.ENDM
 
.MACRO	INVBM
	.if	@0 < 0x40
	PUSH	tmp1
	PUSH	tmp2
	IN	tmp1, @0
	LDI	tmp2, 1<<@1
	EOR	tmp2, tmp1
	OUT	@0, tmp2
	POP	tmp2
	POP	tmp1
	.else
	PUSH	tmp1
	PUSH	tmp2
	LDS	tmp1, @0
	LDI	tmp2, 1<<@1
	EOR	tmp2, tmp1
	STS	@0, tmp2
	POP	tmp2
	POP	tmp1
	.endif
.ENDM

;.............................................
.MACRO PUSHF ; Saves the tmp's and SREG
	PUSH tmp1
	PUSH tmp2
	IN tmp1, SREG
	PUSH tmp1
.ENDM

.MACRO POPF
	POP tmp1
	OUT SREG, tmp1
	POP tmp2
	POP tmp1
.ENDM

;.............................................
.MACRO jumpto 
	LDI ZL, low(@0) 
	LDI ZH, high(@0) 
	ADD ZL, @1
	PUSH @1
	LDI @1,0
	ADC ZH, @1
	POP @1 
	IJMP 
.ENDM
;= End macro.inc =============================













