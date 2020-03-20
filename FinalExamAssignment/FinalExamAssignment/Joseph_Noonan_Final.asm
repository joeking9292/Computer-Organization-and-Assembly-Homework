;***********************************************************
;*	This is the final exam template for ECE375 Winter 2020
;***********************************************************
;*	 Author: Youngbin Jin
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
.def	currentTreasure = r17	; Tracks which treasure we are currently calculating
.def	equalDistTreasures = r18; Counter for how many treasures share distances
.def	sqrtcounter = r19		; Counter for loop as well
.def	totalDistance = r23		; Holds the total of the distances for avg calculations
.def	sumLowByte = r20		; Useful for squareroot function
.def	sumHighByte = r24		; Useful for squareroot function
.def	closestTreasure = r25	; hold value of closest treasure
.def	shortestDistance = r5	; Self Explanitory

;***********************************************************
;*	Data segment variables
;*	(feel free to edit these or add others)
;***********************************************************
.dseg
.org	$0100						; data memory allocation for operands
operand1:		.byte 2				; allocate 2 bytes for a variable named op1
ADD16_OP1:		.byte 2				; Adder operands for adding the squares
ADD16_OP2:		.byte 2				; Adder operands for adding the squares


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
		clr		zero
		ldi		mpr, low(RAMEND)	; initialize Stack Pointer
		out		SPL, mpr			
		ldi		mpr, high(RAMEND)
		out		SPH, mpr

		ldi		ZL, low(Treasure1<<1)
		ldi		ZH, high(Treasure1<<1)

		ldi		YL, low(operand1)
		ldi		YH, high(operand1)

		ldi		XL, low(Result1)
		ldi		XH, high(Result1)

		clr		rhi
		clr		rlo
		ldi		currentTreasure, 1
		ldi		equalDistTreasures, 1

MAIN:
		rcall	SQUARE
		rcall	ADD16
		rcall	SQUARE_ROOT
		rcall	DISTANCE
		mov		shortestDistance, sqrtCounter	; Shortest distance, so far.
		mov		closestTreasure, currentTreasure	; First treasure is closest, so far.
		add		totalDistance, sqrtCounter  ; Add to the total distance

		;Reset Variables
		clr		sumHighByte
		clr		sumLowByte
		clr		sqrtCounter
		ldi		ZL, low(Treasure2<<1)
		ldi		ZH, high(Treasure2<<1)
		rcall	SQUARE
		rcall	ADD16
		rcall	SQUARE_ROOT
		rcall	DISTANCE
		adc		totalDistance, sqrtCounter	; Keep adding to total distance

		;Reset Variables
		clr		sumHighByte
		clr		sumLowByte
		clr		sqrtCounter
		ldi		ZL, low(Treasure3<<1)
		ldi		ZH, high(Treasure3<<1)
		rcall	SQUARE
		rcall	ADD16
		rcall	SQUARE_ROOT
		rcall	DISTANCE
		adc		totalDistance, sqrtCounter	; Keep adding to total distance
		st		X+, closestTreasure			; Store the closest treasure
		rcall	DISTANCE_AVG				; Get average distance

		jmp	Grading

;***********************************************************
;*	Procedures and Subroutines
;***********************************************************
SQUARE:
		;lpm		A, Z  ; problem with A register
		lpm		mpr, Z+
		muls	mpr, mpr
		st		X+, rlo
		sts		$0104, rlo
		st		X+, rhi
		sts		$0103, rhi
		;lpm		B, Z  ; problem with B register
		lpm		mpr, Z+
		muls	mpr, mpr
		st		X+, rlo
		sts		$0106, rlo
		st		X+, rhi
		sts		$0105, rhi

		ret


SQUARE_ROOT:	; Adapted from Goins slides (slide 9) for the Final Exam
		ldi		sqrtCounter, 1		; Counter starts at 1
		clr		zero				; Clear Zero for comparisons

		LOOP1:		; Loop stores square root counter mulitplied by itself b/c 
			mul		sqrtCounter, sqrtCounter
			cp		sumHighByte, zero
			brne	LOOP2
			cp		sumLowByte, rlo
			brge	DONE
			inc		sqrtCounter
			rjmp	LOOP1

		LOOP2:		; Needed another loop to encompass larger addition results
			cp		sumHighByte, rhi
			breq	LOOP3
			cp		sumHighByte, rhi
			brlo	DONE
			inc		sqrtCounter
			rjmp	LOOP1
		
		LOOP3:
			cp		sumLowByte, rlo
			brge	DONE
			inc		sqrtCounter
			rjmp	LOOP1

		DONE:
			st		X+, sqrtCounter
			ret

DISTANCE:
	cp shortestDistance, sqrtCounter
	breq	EQUALTO
	brlo	LESSTHAN
	ret		; Return to MAIN if neither

	EQUALTO:
		inc		equalDistTreasures
		cpi		equalDistTreasures, 3
		breq	ALLTREASUREEQUAL
		cpi		equalDistTreasures, 2
		breq	ONETREASUREEQUAL
	ALLTREASUREEQUAL:
		ldi		closestTreasure, -3
	ONETREASUREEQUAL:
		ldi		closestTreasure, -2
		ret
	LESSTHAN:
		mov		shortestDistance, sqrtCounter ; Since they were less, store the new shortest treasure
		ret

DISTANCE_AVG:
	clr mpr
	clr sqrtCounter		; Just using the counter for misc. purpose here
	;ldi XL, low(AvgDistance)
	;ldi Xh, high(AvgDistance)

	AVG_LOOP:
		ldi		mpr, 3
		cp		totalDistance, mpr
		brlo	AVG_LOOP2
		sub		totalDistance, mpr ; Subtract 3
		inc		sqrtCounter
		rjmp	AVG_LOOP

	AVG_LOOP2:
		inc		totalDistance
		cp		totalDistance, mpr ; Compare value of 3
		breq	AVG_LOOP3
		rjmp	DONE2

	AVG_LOOP3:		; Takes care of our rounding up issue
		inc		sqrtCounter

	DONE2: ; DONE2 because I needed another name instead of DONE
		st	X, sqrtCounter
		ret



;-----------------------------------------------------------
; Func: ADD16
; Desc: Adds two 16-bit numbers and generates a 24-bit number
;		where the high byte of the result contains the carry
;		out bit.
;-----------------------------------------------------------
; Taken from my Lab 5 code

ADD16:
		push    A               ; Save A register
        push    B               ; Save B register
        push    rhi             ; Save rhi register
        push    rlo             ; Save rlo register
        push    zero            ; Save zero register
        push    ZH              ; Save X-ptr
        push    ZL
        push    YH              ; Save Y-ptr
        push    YL                          

		; Load beginning address of first operand into X
		ldi		ZL, low(ADD16_OP1)	; Load low byte of address
		ldi		ZH, high(ADD16_OP1)	; Load high byte of address

		; Load beginning address of second operand into Y
		ldi		YL, low(ADD16_OP2)
		ldi		YH, high(ADD16_OP2)

		; Execute the function
		ld		mpr, Z+
		ld		r20, Y+
		add		r20, mpr
		st		X+, r20
		mov		sumLowByte, r20
		ld		mpr, Z
		ld		r20, Y
		adc		r20, mpr
		st		X+, r20
		mov		sumHighByte, r20
		brcc	EXITADD
		st		X+, ZH
	EXITADD:
        pop     YL
        pop     YH
        pop     ZL
        pop     ZH
        pop     zero
        pop     rlo
        pop     rhi
        pop     B
        pop     A
        ret                     ; End a function with RET


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
Treasure1:	.DB	0xF9, 0xFD				; X, Y coordinate of treasure 1 (-7 in decimal), (-3 in decimal)
Treasure2:	.DB	0x03, 0x04				; X, Y coordinate of treasure 2 (+3 in decimal), (+4 in decimal)
Treasure3:	.DB	0x81, 0x76				; X, Y coordinate of treasure 3 (-127 in decimal), (+118 in decimal)

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
