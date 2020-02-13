;***********************************************************
;*
;*	Name: Joseph_Noonan_and_Matthew_Levis
;*
;*	This program will allow the bump bot to count how many times
;*  an interrupt is hit and display it to the screen.
;*
;*	This is the file for Lab 6 of ECE 375
;*
;***********************************************************
;*
;*	 Author: Joseph Noonan and Mattthew Levis
;*	   Date: 02/11/20
;*
;***********************************************************

.include "m128def.inc"			; Include definition file

;***********************************************************
;*	Internal Register Definitions and Constants
;***********************************************************
.def	mpr = r16				; Multipurpose register 
.def	LeftCount = r1			; Left whisker counter
.def	RightCount = r2		; Right whisker counter
.def	waitcnt = r25
.def ilcnt = r23				; Inner Loop Counter
.def olcnt = r24				; Outer Loop Counter
.equ	WTime = 100 ; Time to wait in wait loop
.equ	WskrR = 0 ; Right Whisker Input Bit
.equ	WskrL = 1 ; Left Whisker Input Bit
.equ	EngEnR = 4 ; Right Engine Enable Bit
.equ	EngEnL = 7 ; Left Engine Enable Bit
.equ	EngDirR = 5 ; Right Engine Direction Bit
.equ	EngDirL = 6 ; Left Engine Direction Bit
.equ	MovFwd = (1<<EngDirR|1<<EngDirL) ; Move Forward Command
.equ	MovBck = $00 ; Move Backward Command
.equ	TurnR = (1<<EngDirL) ; Turn Right Command
.equ	TurnL = (1<<EngDirR) ; Turn Left Command
.equ	Halt = (1<<EngEnR|1<<EngEnL) ; Halt Command

;***********************************************************
;*	Start of Code Segment
;***********************************************************
.cseg							; Beginning of code segment

;***********************************************************
;*	Interrupt Vectors
;***********************************************************
.org	$0000					; Beginning of IVs
		rjmp 	INIT			; Reset interrupt

		; Set up interrupt vectors for any interrupts being used

		; This is just an example:
;.org	$002E					; Analog Comparator IV
;		rcall	HandleAC		; Call function to handle interrupt
;		reti					; Return from interrupt
.org	$0002
	rcall HandleRightW
	reti

.org	$0004
	rcall HandleLeftW
	reti

.org	$0006
	rcall ClearRightW
	reti

.org	$0008
	rcall ClearLeftW
	reti


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
		rcall	LCDInit
		
		ldi mpr, (1<<EngEnL)|(1<<EngEnR)|(1<<EngDirR)|(1<<EngDirL)
		out DDRB, mpr ; Set Port B Directional Register for output
		; Initialize Port D for inputs
		ldi mpr, (0<<WskrL)|(0<<WskrR)
		out DDRD, mpr ; Set Port D Directional Register for input
		ldi mpr, (1<<WskrL)|(1<<WskrR)
		out PORTD, mpr ; Activate pull-up resistors
		; Initialize TekBot Forward Movement
		ldi mpr, MovFwd ; Load Move Forward Command
		out PORTB, mpr ; Send command to motors

		; Initialize external interrupts
			; Set the Interrupt Sense Control to falling edge 


		ldi		mpr, (1<<ISC01) | (0<<ISC00) | (1<<ISC11) | (0<<ISC10) | (1<<ISC21) | (0<<ISC20) | (1<<ISC31) | (0<<ISC30)
		sts		EICRA, mpr		; set INT0-3 to trigger on falling edge

		; Configure the External Interrupt Mask
		ldi		mpr,  (1<<INT0) | (1<<INT1) | (1<<INT2) | (1<<INT3)
		sts		EIMSK, mpr
		



		; Turn on interrupts
		sei
			; NOTE: This must be the last thing to do in the INIT function

;***********************************************************
;*	Main Program
;***********************************************************
MAIN:							; The Main program
		; Display the strings on the LCD Display
		ldi mpr, MovFwd ; Load FWD command
		out PORTB, mpr ; Send to motors
		rjmp MAIN ; Infinite loop. End of program.

;***********************************************************
;*	Functions and Subroutines
;***********************************************************

;-----------------------------------------------------------
;	You will probably want several functions, one to handle the 
;	left whisker interrupt, one to handle the right whisker 
;	interrupt, and maybe a wait function
;------------------------------------------------------------

HandleRightW:

	push	mpr
	push	waitcnt
	in		mpr, SREG
	push	mpr

	; move backwards for a second
	ldi mpr, MovBck
	out PORTB, mpr
	ldi waitcnt, WTime
	rcall WaitLoop

	; turn left for a second
	ldi mpr, TurnL ; Load Turn Left Command
	out PORTB, mpr ; Send command to port
	ldi waitcnt, WTime ; Wait for 1 second
	rcall WaitLoop ; Call wait function


	ldi		YL, low(LCDLn1Addr)
	ldi		YH, high(LCDLn1Addr)

	inc		RightCount
	st		Y, RightCount
	
	rcall	LCDWrite

	pop mpr
	out SREG, mpr
	pop waitcnt
	pop mpr


	ret



HandleLeftW:

	push	mpr
	push	waitcnt
	in		mpr, SREG
	push	mpr


	; move backwards for a second
	ldi mpr, MovBck
	out PORTB, mpr
	ldi waitcnt, WTime
	rcall WaitLoop


	; turn right for a second
	ldi mpr, TurnR ; Load Turn Left Command
	out PORTB, mpr ; Send command to port
	ldi waitcnt, WTime ; Wait for 1 second
	rcall WaitLoop ; Call wait function

	ldi		YL, low(LCDLn2Addr)
	ldi		YH, high(LCDLn2Addr)

	inc		LeftCount
	st		Y, LeftCount

	rcall	LCDWrite

	pop mpr
	out SREG, mpr
	pop waitcnt
	pop mpr

	ret



ClearRightW:

	push	mpr
	push	waitcnt
	in		mpr, SREG
	push	mpr

	ldi		YL, low(LCDLn1Addr)
	ldi		YH, high(LCDLn2Addr)

	clr		RightCount
	st		Y, RightCount
	
	rcall	LCDClrLn1


	pop mpr
	out SREG, mpr
	pop waitcnt
	pop mpr

	ret



ClearLeftW:

	push	mpr
	push	waitcnt
	in		mpr, SREG
	push	mpr

	ldi		YL, low(LCDLn1Addr)
	ldi		YH, high(LCDLn2Addr)

	clr		LeftCount
	st		Y, LeftCount
	
	rcall	LCDClrLn2

	pop mpr
	out SREG, mpr
	pop waitcnt
	pop mpr

	ret

;----------------------------------------------------------------
; Sub: Wait
; Desc: A wait loop that waits approx. waitcnt*10ms.
;----------------------------------------------------------------
WaitLoop:
	OLoop:
		ldi olcnt, 224 ; (1) Load middle-loop count
	MLoop:
		ldi ilcnt, 237 ; (1) Load inner-loop count
	ILoop:
		dec ilcnt ; (1) Decrement inner-loop count
		brne Iloop ; (2/1) Continue inner-loop
		dec olcnt ; (1) Decrement middle-loop count
		brne Mloop ; (2/1) Continue middle-loop
		dec waitcnt ; (1) Decrement outer-loop count
		brne OLoop ; (2/1) Continue outer-loop
		ret ; Return from subroutine



;-----------------------------------------------------------
; Func: Template function header
; Desc: Cut and paste this and fill in the info at the 
;		beginning of your functions
;-----------------------------------------------------------
FUNC:							; Begin a function with a label

		; Save variable by pushing them to the stack

		; Execute the function here
		
		; Restore variable by popping them from the stack in reverse order

		ret						; End a function with RET

;***********************************************************
;*	Stored Program Data
;***********************************************************

; Enter any stored data you might need here

;***********************************************************
;*	Additional Program Includes
;***********************************************************
.include "LCDDriver.asm"
.include "wait.asm"				; Include the wait ACM