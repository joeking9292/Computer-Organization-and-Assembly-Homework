;***********************************************************
;*	This is the final exam template for ECE375 Winter 2020
;***********************************************************
;*	 Author: Soren Andersen
;*   Date: March 13th, 2020
;***********************************************************
.include "m128def.inc"			; Include definition file
;***********************************************************
;*	Internal Register Definitions and Constants
;*	(feel free to edit these or add others)
;***********************************************************
.def	rlo = r0				; Low byte of MUL result
.def	rhi = r1				; High byte of MUL result
.def	zero = r2				; Zero register, set to zero in INIT, useful for calculations
.def	A = r3					; A variable
.def	B = r4					; Another variable
.def	mpr = r16				; Multipurpose register 
.def	oloop = r17				; Outer Loop Counter
.def	iloop = r18				; Inner Loop Counter
.def	dataptr = r19			; data ptr

;***********************************************************
;*	Data segment variables
;*	(feel free to edit these or add others)
;***********************************************************
.dseg
.org	$0100						; data memory allocation for operands
operand1:		.byte 2				; allocate 2 bytes for a variable named op1
operand2:		.byte 2
square_comp:	.byte 4

;***********************************************************
;*	Start of Code Segment
;***********************************************************
.cseg							; Beginning of code segment
;-----------------------------------------------------------
; Interrupt Vectors
;-----------------------------------------------------------
.org	$0000					; Beginning of IVs
		rjmp 	INIT			; Reset interrupt
.org	$0046					; End of Interrupt Vectors
;-----------------------------------------------------------
; Program Initialization
;-----------------------------------------------------------
INIT:	; The initialization routine
		    ; Initialize the Stack Pointer
		ldi		mpr, low(RAMEND)
		out		SPL, mpr		; Load SPL with low byte of RAMEND
		ldi		mpr, high(RAMEND)
		out		SPH, mpr		; Load SPH with high byte of RAMEND
Main:

		clr		zero
		ldi		XL, low(Result1)	; Load low byte of address
		ldi		XH, high(Result1)	; Load high byte of address

		ldi		ZL, low(Treasure1<<1)
		ldi		ZH, high(Treasure1<<1)

		rcall MATH
		ldi		XL, low(Result1)	; Load low byte of address
		ldi		XH, high(Result1)	; Load high byte of address
		ldi		oloop, 4
		rcall square_help
			ldi		XL, low(Result2)	; Load low byte of address
		ldi		XH, high(Result2)	; Load high byte of address

		ldi		ZL, low(Treasure2<<1)
		ldi		ZH, high(Treasure2<<1)
		rcall MATH
		ldi		XL, low(Result2)	; Load low byte of address
		ldi		XH, high(Result2)	; Load high byte of address
		ldi		oloop, 4
		rcall square_help
			ldi		XL, low(Result3)	; Load low byte of address
		ldi		XH, high(Result3)	; Load high byte of address

		ldi		ZL, low(Treasure3<<1)
		ldi		ZH, high(Treasure3<<1)
		rcall MATH
		ldi		XL, low(Result3)	; Load low byte of address
		ldi		XH, high(Result3)	; Load high byte of address
		ldi		oloop, 4
		rcall square_help


		ldi		XL, low(Result1)	; Load low byte of address
		ldi		XH, high(Result1)	; Load high byte of address
		ldi oloop, 7
		rcall helper
		mov r15, mpr


		ldi		XL, low(Result2)	; Load low byte of address
		ldi		XH, high(Result2)	; Load high byte of address
		ldi oloop, 7
		rcall helper
		mov A, mpr
	
		ldi		XL, low(Result3)	; Load low byte of address
		ldi		XH, high(Result3)	; Load high byte of address
		ldi oloop, 7
		rcall helper
		mov B, mpr
	
		ldi		XL, low(Bestchoice)	; Load low byte of address
		ldi		XH, high(Bestchoice)	; Load high byte of address

		CPSE r15, A
		rcall compareOne
		rcall sameDist
compareOne:
		CPSE r15, B
		rcall compareTwo
		rcall sameDist
compareTwo:
		CPSE A, B
		rcall realcompare
		rcall sameDist

sameDist:
		CPSE A, B
		rcall sameDistFinal
		CPSE A, r15
		rcall sameDistFinal
		CPSE r15, B
		rcall sameDistFinal
		ldi mpr, -3
		st X, mpr
		jmp finish
sameDistFinal:
		ldi mpr, -2
		st X, mpr
		jmp finish
realcompare:
		cp r15, A
		BRLO RES1_smol
		cp A, B
		BRLo str_treasure2
		jmp str_treasure3
str_treasure1:
		ldi mpr, 1
		st X, mpr
		jmp finish
RES1_smol:
		cp r15, B
		BRLO str_treasure1
		jmp str_treasure3

str_treasure2:
		ldi mpr, 2
		st X, mpr
		jmp finish
str_treasure3:
		ldi mpr, 3
		st X, mpr
		jmp finish

MATH:
		ldi		YL, low(operand1)	; Load low byte of address
		ldi		YH, high(operand1)	; Load high byte of address
		ldi		oloop, 2
		rcall	TEMPOLOOP2Y

		lpm		mpr, Z
		lpm		r18, Z+
		mul	mpr, r18
		st		X+, r0
		st		X+, r1
		
	;	ldi		YL, low(operand1)	; Load low byte of address
	;	ldi		YH, high(operand1)	; Load high byte of address
		st		Y+, r0
		st		Y, r1

		ldi		YL, low(operand2)	; Load low byte of address
		ldi		YH, high(operand2)	; Load high byte of address
		ldi		oloop, 2
		rcall	TEMPOLOOP2Y


		lpm		mpr, Z
		lpm		r20, Z+
		mul		mpr, r20
		st		X+, r0
		st		X+, r1
				
	;	ldi		YL, low(operand2)	; Load low byte of address
	;	ldi		YH, high(operand2)	; Load high byte of address
		st		Y+, r0
		st		Y, r1

		;FIGURE OUT HOW TO GET DATA FROM OPERAND 1 AND 2
		ldi		YL, low(operand1)	; Load low byte of address
		ldi		YH, high(operand1)	; Load high byte of address
		ldi		ZL, low(operand2)	; Load low byte of address
		ldi		ZH, high(operand2)	; Load high byte of address
		ld		mpr, Y+
		ld		r20, Z+
		add		mpr, r20
		st		X+, mpr
		ld		mpr, Y
		ld		r20, Z
		adc		mpr, r20
		st		X,	mpr 
		brcc done
		CBR	mpr, 128
		st		X, mpr
		ret
DONE:

		ret
	
TEMPOLOOP2Y:
		lpm mpr, Z
		st Y, mpr ;TRANSFER DATA ONE OPP AT A TIME
		lpm mpr, Z
		st Y, mpr ;TRANSFER DATA ONE OPP AT A TIME
		ret				; Save variable by pushing them to the stack


square_help:
		ld		mpr, X+
		dec		oloop
		cpi		oloop, 0
		brne	square_help
		ld		mpr, X+
		ld		dataptr, X+
		push oloop
		push iloop

		ldi	oloop, 0

square_root:
	ldi r17, 1
	cp r15, dataptr
	BRLO square_top

	

square_bot:
	inc	oloop
	mov	iloop, oloop
	mul iloop, iloop



	cp r0, mpr
	BRLO square_bot
	mov mpr, oloop
	pop oloop
	pop iloop
	st X, mpr
	ret

square_top:
	inc	oloop
	mov	iloop, oloop
	mul iloop, iloop


	cp r1, dataptr
	BRLO square_top
	mov mpr, oloop
	pop oloop
	pop iloop
	st X, mpr

	ret

	;do something with mpr like save it to X

finish:
		ldi XL, low(AvgDistance)
		ldi Xh, high(AvgDistance)
		add r15, A

		clr mpr
		adc mpr, zero
		add r15, B
		adc mpr, zero


		ldi iloop, 85
		mul mpr, iloop
		st X, r0
		ldi oloop, 0
		ldi	iloop, 3
avgloop:	
		cp  r15, iloop
		BRLO doneavg
		sub r15, iloop
		inc	oloop
		rjmp avgloop

doneavg:
		add oloop, r0
		st X, oloop
		
		jmp	Grading


helper:

		ld		mpr, X+
		dec		oloop
		cpi		oloop, 0
		brne	helper
		ret

;***********************************************************
;*	Procedures and Subroutines
;***********************************************************
; your code can go here as well

;***end of your code***end of your code***end of your code***end of your code***end of your code***
;******************************* Do not change below this point************************************
;******************************* Do not change below this point************************************
;******************************* Do not change below this point************************************

Grading:
		nop					; Check the results and number of cycles (The TA will set a breakpoint here)
rjmp Grading


;***********************************************************
;*	Stored Program Data
;***********************************************************

; Contents of program memory will be changed during testing
; The label names (Treasure1, Treasure2, etc) are not changed
Treasure1:	.DB	0x03, 0x03				; X, Y coordinate of treasure 1 (-7 in decimal), (-3 in decimal)
Treasure2:	.DB	0x03, 0x04				; X, Y coordinate of treasure 2 (+3 in decimal), (+4 in decimal)
Treasure3:	.DB	0x03, 0x03				; X, Y coordinate of treasure 3 (-127 in decimal), (+118 in decimal)

;***********************************************************
;*	Data Memory Allocation for Results
;***********************************************************
.dseg
.org	$0E00						; data memory allocation for results - Your grader only checks $0E00 - $0E16
Result1:		.byte 7				; x_squared, y_squared, x2_plus_y2, square_root (for treasure 1)
Result2:		.byte 7				; x_squared, y_squared, x2_plus_y2, square_root (for treasure 2)
Result3:		.byte 7				; x_squared, y_squared, x2_plus_y2, square_root (for treasure 3)
BestChoice:		.byte 1				; which treasure is closest? (indicate this with a value of 1, 2, or 3)
									; see the PDF for an explanation of the special case when 2 or more treasures
									; have an equal (rounded) distance
AvgDistance:	.byte 1				; the average distance to a treasure chest (rounded to the nearest integer)

;***********************************************************
;*	Additional Program Includes
;***********************************************************
; There are no additional file includes for this program
