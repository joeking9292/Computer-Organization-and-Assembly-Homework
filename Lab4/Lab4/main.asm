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
		ldi		r20, $00		; Set Port B Data Direction Register
		out		DDRD, mpr		; for output
		ldi		r20, $FF		; Initialize Port B Data Register
		out		PORTD, mpr		; so all Port B outputs are low		
		
		; Move strings from Program Memory to Data Memory

		
		; NOTE that there is no RET or RJMP from INIT, this
		; is because the next instruction executed is the
		; first instruction of the main program

;***********************************************************
;*	Main Program
;***********************************************************
MAIN:							; The Main program
		; Display the strings on the LCD Display
		in		r20, PIND
		andi	r20, (1<<
		
		rjmp	MAIN			; jump back to main and create an infinite
								; while loop.  Generally, every main program is an
								; infinite while loop, never let the main program
								; just run off

;***********************************************************
;*	Functions and Subroutines
;***********************************************************

;-----------------------------------------------------------
; Func: Template function header
; Desc: Cut and paste this and fill in the info at the 
;		beginning of your functions
;-----------------------------------------------------------
FUNC:							; Begin a function with a label
		; Save variables by pushing them to the stack

		; Execute the function here
		
		; Restore variables by popping them from the stack,
		; in reverse order

		ret						; End a function with RET

;-----------------------------------------------------------
; Func: Flip
; Desc: Cut and paste this and fill in the info at the 
;		beginning of your functions
;-----------------------------------------------------------
FUNC:							; Begin a function with a label
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
JOE_END:

MATT_BEG:
.DB		"Matthew Levis "		; Declaring data in ProgMem
MATT_END:

;***********************************************************
;*	Additional Program Includes
;***********************************************************
.include "LCDDriver.asm"		; Include the LCD Driver