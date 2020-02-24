;***********************************************************
;*
;*	Joseph_Noonan_and_Matthew_Levis_Lab7_sourcecode.asm
;*
;*	Enter the description of the program here
;*
;*	This is the skeleton file for Lab 7 of ECE 375
;*
;***********************************************************
;*
;*	 Author: Enter your name
;*	   Date: Enter Date
;*
;***********************************************************

.include "m128def.inc"			; Include definition file

;***********************************************************
;*	Internal Register Definitions and Constants
;***********************************************************
.def	mpr = r16				; Multipurpose register
.def	curSpeed = r17
.def	incrementCount = r18
.def	curSpeedLevel = r19
.def	A = r20
.def	MovFwd = r21
.def	Halt = r22

.equ	EngEnR = 4				; right Engine Enable Bit
.equ	EngEnL = 7				; left Engine Enable Bit
.equ	EngDirR = 5				; right Engine Direction Bit
.equ	EngDirL = 6				; left Engine Direction Bit

;***********************************************************
;*	Start of Code Segment
;***********************************************************
.cseg							; beginning of code segment

;***********************************************************
;*	Interrupt Vectors
;***********************************************************
.org	$0000
		rjmp	INIT			; reset interrupt

.org	$0002
		rjmp	SPEED_MIN
		reti
.org	$0004
		rjmp	SPEED_MAX
		reti
.org	$0006
		rjmp	SPEED_DOWN
		reti
.org	$0008
		rjmp	SPEED_UP
		reti
		; place instructions in interrupt vectors here, if needed

.org	$0046					; end of interrupt vectors

;***********************************************************
;*	Program Initialization
;***********************************************************
INIT:
		; Initialize Stack Pointer
		ldi		mpr, low(RAMEND)
		out		SPL, mpr		; Load SPL with low byte of RAMEND
		ldi		mpr, high(RAMEND)
		out		SPH, mpr		; Load SPH with high byte of RAMEND
		
		ldi	MovFwd, 0b01101111
		ldi Halt, 0b00001111
		
		ldi mpr, $FF
		out DDRB, mpr ; Set Port B Directional Register for output
		mov mpr, MovFwd
		out PORTB, mpr ; Activate pull-up resistors
		
		; Initialize Port D for inputs
		ldi mpr, $00
		out DDRD, mpr ; Set Port D Directional Register for input
		ldi mpr, $FF
		out PORTD, mpr ; Activate pull-up resistors

		; Configure External Interrupts, if needed

		ldi		mpr, 0b10101010 ;(1<<ISC01) | (0<<ISC00) | (1<<ISC11) | (0<<ISC10) | (1<<ISC21) | (0<<ISC20) | (1<<ISC31) | (0<<ISC30)
		sts		EICRA, mpr		; set INT0-3 to trigger on falling edge

		; Configure the External Interrupt Mask
		ldi		mpr, 0b00001111    ;(1<<INT0) | (1<<INT1) | (1<<INT2) | (1<<INT3)
		out		EIMSK, mpr


		
		; Configure 8-bit Timer/Counters
		sbi		DDRB, PB4
		ldi		A, 0b01101001
		out		TCCR0, A
		ldi		A, 0b00000010
		out		TIMSK, A

		sbi		DDRB, PB7
		ldi		A, 0b01101001
		out		TCCR2, A
		ldi		A, 0b00000010
		out		TIMSK, A

		sei

		ldi	incrementCount, 0b00010001

								; no prescaling

		; Set TekBot to Move Forward (1<<EngDirR|1<<EngDirL)


		; Enable global interrupts (if any are used)

;***********************************************************
;*	Main Program
;***********************************************************
MAIN:
		; poll Port D pushbuttons (if needed)

								; if pressed, adjust speed
								; also, adjust speed indication

		mov		mpr, MovFwd
		out		PORTB, mpr
		rjmp	MAIN			; return to top of MAIN

;***********************************************************
;*	Functions and Subroutines
;***********************************************************

;-----------------------------------------------------------
; Func:	Template function header
; Desc:	Cut and paste this and fill in the info at the 
;		beginning of your functions
;-----------------------------------------------------------
FUNC:	; Begin a function with a label

		; If needed, save variables by pushing to the stack

		; Execute the function here
		
		; Restore any saved variables by popping from stack

		ret						; End a function with RET

SPEED_UP:
	
	push mpr
	in mpr, SREG
	push mpr

	cli

	in		mpr, PORTB
	cpi		mpr, 0b01101111
	breq	MAIN

	add		curSpeed, incrementCount
	inc		curSpeedLevel

	in A, OCR0
	add A, curSpeed
	out	OCR0, A




	ldi mpr, 0xFF				; Clear the interrupt register
	out EIFR, mpr				; to prevent stacked interrupts

	pop mpr
	out SREG, mpr
	pop mpr

	reti

SPEED_DOWN:
	
	push mpr
	in mpr, SREG
	push mpr

	cli

	in		mpr, PORTB
	cpi		mpr, 0b01100000
	breq	MAIN

	sub		curSpeed, incrementCount
	dec		curSpeedLevel

	in A, OCR0
	sub A, curSpeed
	out	OCR0, A

	ldi mpr, 0xFF				; Clear the interrupt register
	out EIFR, mpr				; to prevent stacked interrupts

	pop mpr
	out SREG, mpr
	pop mpr


	reti

SPEED_MAX:
	
	push mpr
	in mpr, SREG
	push mpr

	cli

	ldi		curSpeed, 0b11111111
	ldi		curSpeedLevel, 0b00001111

	;in A, OCR0
	;add A, curSpeed
	out	OCR0, curSpeed


	ldi mpr, 0xFF				; Clear the interrupt register
	out EIFR, mpr				; to prevent stacked interrupts

	pop mpr
	out SREG, mpr
	pop mpr


	reti

SPEED_MIN:

	push mpr
	in mpr, SREG
	push mpr

	cli

	ldi		curSpeed, 0b00000000
	ldi		curSpeedLevel, 0b00000000

	;in A, OCR0
	; A, curSpeed
	out	OCR0, curSpeed

	ldi mpr, 0xFF				; Clear the interrupt register
	out EIFR, mpr				; to prevent stacked interrupts

	pop mpr
	out SREG, mpr
	pop mpr
	

	reti


;***********************************************************
;*	Stored Program Data
;***********************************************************
		; Enter any stored data you might need here

;***********************************************************
;*	Additional Program Includes
;***********************************************************
		; There are no additional file includes for this program

.include "wait.asm"	