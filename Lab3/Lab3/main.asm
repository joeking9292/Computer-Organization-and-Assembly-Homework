;***********************************************************
;*
;*	Joseph_Noonan_and_Matthew_Levis_sourcecode.asm
;*
;*	This is a sample ASM program, meant to be run only via
;*	simulation. First, four registers are loaded with certain
;*	values. Then, while the simulation is paused, the user
;*	must copy these values into the data memory. Finally, a
;*	function is called, which performs an operation, using
;*	the previously-entered values in memory as input.
;*
;***********************************************************
;*
;*	 Author: Joseph Noonan, Matthew Levis
;*	   Date: January 21th, 2020
;*
;***********************************************************

.include "m128def.inc"				; Include definition file

;***********************************************************
;*	Internal Register Definitions and Constants
;***********************************************************

.def	mpr = r16
.def	i = r17
.def	A = r18
.def	B = r19

;***********************************************************
;*	Start of Code Segment
;***********************************************************
.cseg								; Beginning of code segment

;***********************************************************
;*	Interrupt Vectors
;***********************************************************
.org	$0000						; Beginning of IVs
		rjmp 	INIT				; Reset interrupt

.org	$0046						; End of Interrupt Vectors

;***********************************************************
;*	Program Initialization
;***********************************************************
INIT:								; The initialization routine
		ldi		mpr, low(RAMEND)	; initialize Stack Pointer
		out		SPL, mpr			
		ldi		mpr, high(RAMEND)
		out		SPH, mpr

;***********************************************************
;*	Main Program
;***********************************************************
MAIN:
		clr		r0					; *** SET BREAKPOINT HERE *** (#1)
		dec		r0					; initialize r0 value


		clr		r1					; *** SET BREAKPOINT HERE *** (#2)
		ldi		i, $04
LOOP:	lsl		r1					; initialize r1 value
		inc		r1
		lsl		r1
		dec		i					
		brne	LOOP				; *** SET BREAKPOINT HERE *** (#3)


		clr		r2					; *** SET BREAKPOINT HERE *** (#4)
		ldi		i, $0F
LOOP2:	inc		r2					; initialize r2 value
		cp		r2, i
		brne	LOOP2		 		; *** SET BREAKPOINT HERE *** (#5)

									; initialize r3 value
		mov		r3, r2				; *** SET BREAKPOINT HERE *** (#6)

		;		Note: At this point, you need to enter several values
		;		directly into the Data Memory. FUNCTION is written to
		;		expect memory locations $0101:$0100 and $0103:$0102
		;		to represent two 16-bit operands.
		;
		;		So at this point, the contents of r0, r1, r2, and r3
		;		MUST be manually typed into Data Memory locations
		;		$0100, $0101, $0102, and $0103 respectively.

									; call FUNCTION
		rcall	FUNCTION			; *** SET BREAKPOINT HERE *** (#7)

									; infinite loop at end of MAIN
 DONE:	rjmp	DONE

;***********************************************************
;*	Functions and Subroutines
;***********************************************************

;-----------------------------------------------------------
; Func: FUNCTION
; Desc: ???
;-----------------------------------------------------------
FUNCTION:
		ldi		XL, $00
		ldi		XH, $01
		ldi		YL, $02
		ldi		YH, $01
		ldi		ZL, $04
		ldi		ZH, $01
		ld		A, X+
		ld		B, Y+
		add		B, A
		st		Z+, B
		ld		A, X
		ld		B, Y
		adc		B, A
		st		Z+, B
		brcc	EXIT
		st		Z, XH
EXIT:
		ret							; return from rcall













