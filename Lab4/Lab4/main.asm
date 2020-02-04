;***********************************************************
;*
;*	Joseph_Noonan_and_Matthew_Levis_Lab4_sourcecode.asm
;*
;*	This is the file for Lab 4 of ECE 375 which handles
;*  displaying the names of Jospeh Noonan and Matthew Levis
;*  to the screen on the AVR Board.
;*  The names can also be filled or cleared from the screen.
;*
;***********************************************************
;*
;*	 Author: Joseph Noonan and Matthew Levis
;*	   Date: 1/28/20
;*
;***********************************************************

.include "m128def.inc"			; Include definition file

;***********************************************************
;*	Internal Register Definitions and Constants
;***********************************************************
.def	mpr = r16				; Multipurpose register is
								; required for LCD Driver 

;***********************************************************
;*	Start of Code Segment
;***********************************************************
.cseg							; Beginning of code segment

;***********************************************************
;*	Interrupt Vectors
;***********************************************************
.org	$0000					; Beginning of IVs
		rjmp INIT				; Reset interrupt

.org	$0046					; End of Interrupt Vectors

;***********************************************************
;*	Program Initialization
;***********************************************************
INIT:							; The initialization routine
		; Initialize Stack Pointer
		ldi		mpr, low(RAMEND)
		out		SPL, mpr		; Load SPL with low byte of RAMEND
		ldi		mpr, high(RAMEND)
		out		SPH, mpr		; Load SPH with high byte of RAMEND
		
		; Initialize LCD Display
		RCALL LCDInit

		; Initialize Port D for Input
		ldi		r20, $00		; Set Port D Data Direction Register
		out		DDRD, mpr		; for output
		ldi		r20, $FF		; Initialize Port D Data Register
		out		PORTD, mpr		; so all Port D outputs are low
		
		; Move strings from Program Memory to Data Memory
		ldi		ZL, low(JOE_BEG<<1)
		ldi		ZH, high(JOE_BEG<<1)
		ldi		YL, low(LCDLn1Addr)
		ldi		YH, high(LCDLn1Addr)
		ldi		count, 14

LOOP:
		lpm		mpr, Z+
		st		Y+, mpr
		dec		count
		brne	LOOP

		ldi		ZL, low(MATT_BEG<<1)
		ldi		ZH, high(MATT_BEG<<1)
		ldi		YL, low(LCDLn2Addr)
		ldi		YH, high(LCDLn2Addr)
		ldi		count, 14

LOOP2:
		lpm		mpr, Z+
		st		Y+, mpr
		dec		count
		brne	LOOP2

		; NOTE that there is no RET or RJMP from INIT, this
		; is because the next instruction executed is the
		; first instruction of the main program

;***********************************************************
;*	Main Program
;***********************************************************
MAIN:							; The Main program
		; Display the strings on the LCD Display
		in		mpr, PIND
		andi	mpr, (1<<0|1<<1)
		cpi		mpr, 0b10000000
IF:		brne	ELIF	
		rcall	LCDClr
		rjmp	NEXT
ELIF:	cpi		mpr, 0b00000010
		brne	ELSE
		rcall	FUNC
		rcall	LCDWrLn2
		rcall	LCDWrLn1
		rjmp	NEXT
ELSE:	cpi		mpr, 0b00000001
		brne	NEXT
		rcall	INIT
		rcall	LCDWrLn1
		rcall	LCDWrLn2
		rjmp	NEXT
NEXT:
		; jump back to main and create an infinite
								; while loop.  Generally, every main program is an
								; infinite while loop, never let the main program
								; just run off
		rjmp MAIN

;***********************************************************
;*	Functions and Subroutines
;***********************************************************

;-----------------------------------------------------------
; Func: Template function header
; Desc: Cut and paste this and fill in the info at the 
;		beginning of your functions
;-----------------------------------------------------------
FUNC:							; Begin a function with a label
		ldi		ZL, low(MATT_BEG<<1)
		ldi		ZH, high(MATT_BEG<<1)
		ldi		YL, low(LCDLn1Addr)
		ldi		YH, high(LCDLn1Addr)
		ldi		count, 14

LOOP3:
		lpm		mpr, Z+
		st		Y+, mpr
		dec		count
		brne	LOOP3

		ldi		ZL, low(JOE_BEG<<1)
		ldi		ZH, high(JOE_BEG<<1)
		ldi		YL, low(LCDLn2Addr)
		ldi		YH, high(LCDLn2Addr)
		ldi		count, 14

LOOP4:
		lpm		mpr, Z+
		st		Y+, mpr
		dec		count
		brne	LOOP4



		; Save variables by pushing them to the stack

		; Execute the function here
		
		; Restore variables by popping them from the stack,
		; in reverse order

		ret						; End a function with RET

;***********************************************************
;*	Stored Program Data
;***********************************************************

;-----------------------------------------------------------
; An example of storing a string. Note the labels before and
; after the .DB directive; these can help to access the data
;-----------------------------------------------------------
JOE_BEG:
.DB		"Joseph Noonan "		; Declaring data in ProgMem

MATT_BEG:
.DB		"Matthew Levis "		; Declaring data in ProgMem

;***********************************************************
;*	Additional Program Includes
;***********************************************************
.include "LCDDriver.asm"		; Include the LCD Driver
.include "wait.asm"				; Include the wait ACM