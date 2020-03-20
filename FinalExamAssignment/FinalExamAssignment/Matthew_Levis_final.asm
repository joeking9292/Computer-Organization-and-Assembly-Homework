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
.def	minDistance = r3		; A variable
.def	sum = r24				; Another variable
.def	mpr = r16				; Multipurpose register 
.def	oloop = r17				; Outer Loop Counter
.def	iloop = r18				; Inner Loop Counter
.def	sameCount = r19			; data ptr
.def	counter = r20

.def	sumH = r21
.def	sumL = r22
.def	best = r23

;***********************************************************
;*	Data segment variables
;*	(feel free to edit these or add others)
;***********************************************************
.dseg
.org	$0100						; data memory allocation for operands
operand1:		.byte 2				; allocate 2 bytes for a variable named op1
operand2:		.byte 2
result:			.byte 2				; result will store the result of our ADD16 operation



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

		ldi		mpr, low(RAMEND)
		out		SPL, mpr		; Load SPL with low byte of RAMEND
		ldi		mpr, high(RAMEND)
		out		SPH, mpr		; Load SPH with high byte of RAMEND

		ldi		ZL, low(Treasure1<<1)
		ldi		ZH,	high(Treasure1<<1)

		ldi		XL, low(Result1)
		ldi		XH, high(Result1)

		ldi		YL, low(operand1)
		ldi		YH, high(operand1)

		ldi		oloop, 1		; oloop will count what treasure we are tracking, helpful for considering best choice
		ldi		iloop, 2
		ldi		sum, 0			; sum holds sum of all distances, helpful for computing average
		ldi		sameCount, 1	; same count holds count of those distances that are equal


MAIN:

	; in our main routine we will compute the squares, determine this sum, square root it and then consider its distance. Also, we will increment the sum with our 
	; calculated distance. Each operation requires the Z and Y registers to be loaded with the respective treasure or operand. X does not need to be re-initialized 
	; because it is always incrementing in the operations

		rcall	computeSquares
		rcall	determineSum
		rcall	squareRoot
		rcall	computeDistance
		mov		minDistance, counter
		mov		best, oloop
		add		sum, counter

		
		ldi		ZL, low(Treasure2<<1)
		ldi		ZH,	high(Treasure2<<1)
		ldi		YL, low(operand1)
		ldi		YH, high(operand1)
		rcall	initHelp			; helps to clear some registers that are needed for operations, like loop counters iloop
		inc		oloop
		rcall	computeSquares
		rcall	determineSum
		rcall	squareRoot
		rcall	computeDistance
		adc		sum, counter

		
		ldi		ZL, low(Treasure3<<1)
		ldi		ZH,	high(Treasure3<<1)
		ldi		YL, low(operand1)
		ldi		YH, high(operand1)
		rcall	initHelp
		inc		oloop
		rcall	computeSquares
		rcall	determineSum
		rcall	squareRoot
		rcall	computeDistance
		adc		sum, counter

		st		X+, best		; store the best distance whether it is 01, 02, 03 or -2 or -3 for those same cases

		rcall	computeAverage


		rjmp END


	computeSquares:
		lpm		mpr, Z+
		muls	mpr, mpr		; use muls for signed numbers
		st		X+, rlo
		st		X+, rhi

		st	Y+, rlo
		st	Y+, rhi

		dec		iloop
		brne	computeSquares

		ret

	determineSum:
		; operand 1 is x^2
		; operand 2 is y^2
		push YH				; push Y and Z onto stack so as to not destroy their previous pointers
		push YL
		push ZH
		push ZL

		ldi		ZL, low(operand1)
		ldi		ZH, high(operand1)	

		ldi		YL, low(operand2)
		ldi		YH, high(operand2)

		; similar to the ADD16 function from lab5
		; note: we are storing in the result in little
		; endian (low, then high byte)
		ld		mpr, Z+
		ld		r20, Y+
		add		r20, mpr
		st		X+, r20
		mov		sumL, r20
		ld		mpr, Z
		ld		r20, Y
		adc		r20, mpr
		st		X+, r20
		mov		sumH, r20
		brcc	EXITADD
		st		X+, ZH
	EXITADD:
		pop ZL
		pop ZH
		pop YL
		pop YH

		ret						; End a function with a ret

	; square root multiplies counter by itself until it is equal or greater than our sum that is held in two 8 bit registers
	; sumH and sumL for high and low bytes, respectively
	squareRoot:

		ldi		counter, 1

		LOOP:
			mul		counter, counter
			cpi		sumH, 0			; if our sum is large enough to have a non-empty high byte, go to other routine
			brne	sumHNotZero
			cp		rlo, sumL
			brge	done
			inc		counter
			rjmp	LOOP

		sumHNotZero:				; routine compares the high bytes of our counter multlipication result and the sum and 
									; if they are the same then we need to compare the low bytes to see which one is greater/less
									; otherwise, we keep incrementing/looping
			cp		sumH, rhi
			brlo	done			; brlo for unsigned
			cp		sumH, rhi
			breq	compareLowerBytes
			inc		counter
			rjmp	LOOP
		compareLowerBytes:			; only compare low bytes, go to done if rlo is greater than the sum
			cp		rlo, sumL
			brge	done
			inc		counter
			rjmp	LOOP
		done:
			st		X+, counter
			ret
		
	computeDistance:
		cp		counter, minDistance
		brlo	less
		breq	same
		ret
		less:						; update the minimum distance
			mov		minDistance, counter
			mov		best, oloop
			rjmp	endComputeDistance
		same:						; distances are the same, check if just 2 distances or all 3
			inc		sameCount
			cpi		sameCount, 2
			breq	twoSame
			cpi		sameCount, 3
			breq	threeSame
			twoSame:
				ldi		best, -2
				rjmp	endComputeDistance
			threeSame:
				ldi		best, -3
		endComputeDistance:
			ret
		
	; follows the division problem from the midterm
	computeAverage:
		clr		counter
		loop1:
			cpi		sum, 3
			brlo	finish
			subi	sum, 3
			inc		counter
			rjmp	loop1
		finish:
			inc		sum
			cpi		sum, 3
			breq	round
			rjmp	endComputeAvg
			round:				; we round if we are off by 1 and can round up to the nearest integer
				inc counter
		endComputeAvg:
			st		X, counter
			ret
		
initHelp:
		
		clr		sumH
		clr		sumL
		clr		counter
		ldi		iloop, 2
		ret
; To do
; your code is here
END:
		jmp	Grading

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
