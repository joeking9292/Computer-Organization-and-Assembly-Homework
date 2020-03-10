;***********************************************************
;*
;* Joseph_Noonan_and_matthew_Lavis_R_sourcecode.asm
;*
;* Enter the description of the program here
;*
;* This is the RECEIVE skeleton file for Lab 8 of ECE 375
;*
;***********************************************************
;*
;* Author: Enter your name
;*   Date: Enter Date
;*
;***********************************************************

.include "m128def.inc" ; Include definition file

;***********************************************************
;* Internal Register Definitions and Constants
;***********************************************************
.def	mpr = r16 ; Multi-Purpose Register
.def	flag = r19
.def	addressFlag = r22

.def	freezeCount = r20   ; track how many times robot has been frozen
.def	currentCommand = r21 ; Holds the current command 
.def	waitcnt = r25
.def	ilcnt = r23				; Inner Loop Counter
.def	olcnt = r24				; Outer Loop Counter

.equ	WskrR = 0 ; Right Whisker Input Bit
.equ	WskrL = 1 ; Left Whisker Input Bit
.equ	EngEnR = 4 ; Right Engine Enable Bit
.equ	EngEnL = 7 ; Left Engine Enable Bit
.equ	EngDirR = 5 ; Right Engine Direction Bit
.equ	EngDirL = 6 ; Left Engine Direction Bit

.equ	WTime = 100 ; Time to wait in wait loop

.equ	BotAddress = $1A;(Enter your robot's address here (8 bits))

;/////////////////////////////////////////////////////////////
;These macros are the values to make the TekBot Move.
;/////////////////////////////////////////////////////////////
.equ	MovFwd =  (1<<EngDirR|1<<EngDirL) ;0b01100000 Move Forward Action Code
.equ	MovBck =  $00 ;0b00000000 Move Backward Action Code
.equ	TurnR =   (1<<EngDirL) ;0b01000000 Turn Right Action Code
.equ	TurnL =   (1<<EngDirR) ;0b00100000 Turn Left Action Code
.equ	Halt =    (1<<EngEnR|1<<EngEnL) ;0b10010000 Halt Action Code
.equ	Frozen =  0b11111000
;.equ	bit5 = 5

;***********************************************************
;* Start of Code Segment
;***********************************************************
.cseg ; Beginning of code segment

;***********************************************************
;* Interrupt Vectors
;***********************************************************
.org $0000 ; Beginning of IVs
	rjmp	INIT ; Reset interrupt

;Should have Interrupt vectors for:
;- Left whisker

.org $0002
	rcall	leftWhisker
	reti
;- Right whisker
.org $0004
	rcall	rightWhisker
	reti
;- USART receive
.org $003C
	rcall	USART_Receive
	reti

.org $0046 ; End of Interrupt Vectors

;***********************************************************
;* Program Initialization
;***********************************************************
INIT:
	;Stack Pointer (VERY IMPORTANT!!!!)
	ldi		mpr, high(RAMEND)
	out		SPH, mpr ; Load SPH with high byte of RAMEND
	ldi		mpr, low(RAMEND)
	out		SPL, mpr ; Load SPL with low byte of RAMEND

	;I/O Ports
	ldi		mpr, $FF
	out		DDRB, mpr ; Set Port B Directional Register for output
	ldi		mpr, $00
	out		PORTB, mpr ; Activate pull-up resistors

	ldi		mpr, $00
	out		DDRD, mpr ; Set Port B Directional Register for output
	ldi		mpr, $FF
	out		PORTD, mpr ; Activate pull-up resistors

	;Set baudrate at 2400bps
	ldi		mpr, high(832)
    sts		UBRR1H, mpr
    ldi		mpr, low(832)
    sts		UBRR1L, mpr

	;USART1
	ldi		mpr, (1<<U2X1)
	sts		UCSR1A, mpr

	;Enable reciever
	ldi		mpr, 0b10011000
	sts		UCSR1B, mpr

	; Enable asynchronous, no parity, 2 stop bits
    ;ldi		mpr, (1<<UCSZ11) | (1<<UCSZ10) | (1<<USBS1) | (1<<UMSEL1)
	ldi		mpr, 0b00001110
    sts		UCSR1C, mpr

	;External Interrupts
	;Set the Interrupt Sense Control to falling edge detection
	ldi		mpr, 0b00001010
	sts		EICRA, mpr

	;Set the External Interrupt Mask
	ldi		mpr, 0b00000011 ;(1<<INT0)|(1<<INT1)
	out		EIMSK, mpr

	
	clr		freezeCount
	ldi		currentCommand, MovFwd
	clr		flag
	ldi		waitcnt, WTime
	clr		mpr
	clr		addressFlag
	

	sei

;***********************************************************
;* Main Program
;***********************************************************
MAIN:
	rjmp	MAIN

;***********************************************************
;* Functions and Subroutines
;***********************************************************

;-----------------------------------------------------------
; Func: leftWhisker
; Desc: Handles the left whisker being hit
;-----------------------------------------------------------
leftWhisker:
	; Save variable by pushing them to the stack
	push	mpr			; Save mpr
	in		mpr, SREG
	push	mpr			; Save the status register

	cli

	; Disable recieve
	ldi		mpr, (0 << RXCIE1 | 0 << RXEN1)
	sts		UCSR1B, mpr

	; Move Backwards for a second
	ldi		mpr, MovBck ; Load Move Backward command
	out		PORTB, mpr ; Send command to port
	rcall	Wait ; Call wait function

	; Turn right for a second
	ldi		mpr, TurnR ; Load Turn Left Command
	out		PORTB, mpr ; Send command to port
	rcall	Wait ; Call wait function

	;Load moving foward command to LEDs
	ldi		mpr, MovFwd
	out		PORTB, mpr

	; Renable recieve
	ldi		mpr, (1 << RXCIE1 | 1 << RXEN1)
	sts		UCSR1B, mpr

	ldi		mpr, 0xFF ; clear interrupt register to prevent stacked interrupts
	out		EIFR, mpr

	; Restore variable by popping them from the stack in reverse order
	pop		mpr
	out		SREG, mpr	; Restore status register
	pop		mpr			; Restore mpr

	ret

;-----------------------------------------------------------
; Func: rightWhisker
; Desc: Handles the right whisker being hit
;-----------------------------------------------------------
rightWhisker:
	; Save variable by pushing them to the stack
	push	mpr			; Save mpr
	in		mpr, SREG
	push	mpr			; Save the status register

	cli

	; Disable recieve
	ldi		mpr, (0 << RXCIE1 | 0 << RXEN1)
	sts		UCSR1B, mpr

	; Move Backwards for a second
	ldi		mpr, MovBck ; Load Move Backward command
	out		PORTB, mpr ; Send command to port
	ldi		waitcnt, WTime ; Wait for 1 second
	rcall	Wait ; Call wait function

	; Turn left for a second
	ldi		mpr, TurnL ; Load Turn Left Command
	out		PORTB, mpr ; Send command to port
	ldi		waitcnt, WTime ; Wait for 1 second
	rcall	Wait

	ldi		mpr, MovFwd
	out		PORTB, mpr

	; Renable recieve
	ldi		mpr, (1 << RXCIE1 | 1 << RXEN1)
	sts		UCSR1B, mpr

	ldi		mpr, 0xFF ; clear interrupt register to prevent stacked interrupts
	out		EIFR, mpr

	; Restore variable by popping them from the stack in reverse order
	pop		mpr
	out		SREG, mpr	; Restore status register
	pop		mpr			; Restore mpr

	ret

;-----------------------------------------------------------
; Func: USART_receive
; Desc: Receiving code for different commands from remote
;-----------------------------------------------------------
USART_Receive:
	cli

	lds		r17, UDR1

	; see if its a freeze signal from another robot first (comes w/out address)
	cpi		r17, 0b01010101 
	breq	HANDLE_FREEZE_SIGNAL
	
	;mov		addressFlag, r17

	/*
	;andi	r18, 0b10000000
	cpi		addressFlag, 1
	breq	ACTION ; handle bot address, make sure same

	cpi		r17, BotAddress
	brne	RECEIVE_END
	ldi		addressFlag, 1
	; we have an action from a transmitter at this point, need to make sure they are the same
	; check flag, make sure bot address matches

	cpi		flag, 0b00000001
	breq	MAIN ; GO BACK TO MAIN If the addresses arent equal
	*/

;ACTION:
	ldi		mpr, BotAddress
	cpi		mpr, BotAddress
	brne	RECEIVE_END

	; now we can perform action, action stored in r17
	cpi		r17, 0b10110000
	breq	MOVE_FORWARD

	cpi		r17, 0b10000000
	breq	MOVE_BACKWARD

	cpi		r17, 0b10100000
	breq	TURN_RIGHT

	cpi		r17, 0b10010000
	breq	TURN_LEFT

	cpi		r17, 0b11001000
	breq	HALT_COMMAND

	; CHECK IF ITS THE FREEZE CMD
	cpi		r17, 0b11111000
	breq	TRANSMIT_FREEZE_SIGNAL

RECEIVE_END:

	ldi		mpr, 0xFF
	out		EIFR, mpr

	ret

;-----------------------------------------------------------
; Section of different direction
; Desc: Used to display the proper commands to LEDs
;-----------------------------------------------------------

MOVE_FORWARD:
	cli
	ldi		mpr, MovFwd
	out		PORTB, mpr
	rjmp	RECEIVE_END

MOVE_BACKWARD:
	cli
	ldi		mpr, MovBck
	out		PORTB, mpr
	rjmp	RECEIVE_END

TURN_RIGHT:
	ldi		mpr, TurnR
	out		PORTB, mpr
	rjmp	RECEIVE_END

TURN_LEFT:
	ldi		mpr, TurnL
	out		PORTB, mpr
	rjmp	RECEIVE_END

HALT_COMMAND:
	ldi		mpr, Halt
	out		PORTB, mpr
	rjmp	RECEIVE_END

;-----------------------------------------------------------
; Func: HANDLES_FREEZE_SIGNAL
; Desc: Handles recieving a freeze signal from anotehr bot to freeze
;-----------------------------------------------------------
; HANDLE_FREEZE_SIGNAL handles when we receive a freeze signal from another robot!
HANDLE_FREEZE_SIGNAL:

	cpi		freezeCount, 3
	breq	HANDLE_FREEZE_SIGNAL

	ldi		mpr, Frozen
	out		PORTB, mpr

	cli

	; wait for 5 seconds
	rcall	Wait
	rcall	Wait
	rcall	Wait
	rcall	Wait
	rcall	Wait

	; dont respond to whiskers
	ldi		mpr, 0xFF
	out		EIFR, mpr

	; Clear USART interrupts
	lds		mpr, UCSR1A
	ori		mpr, 0b11100000
	sts		UCSR1A, mpr		


	; after being frozen 3 times, robot should stop working until its reset

	inc		freezeCount
	cpi		freezeCount, 3
	breq	HANDLE_FREEZE_SIGNAL

	out		PORTB, currentCommand
	ret


;-----------------------------------------------------------
; Func: Template function header
; Desc: Cut and paste this and fill in the info at the 
;		beginning of your functions
;-----------------------------------------------------------
; make sure botaddresses are the same, if not set flag in not equal
BOT_ADDRESS:
	cpi		r17, BotAddress
	brne	NOT_EQUAL
	ldi		flag, 0b00000000

	rjmp	MAIN

;-----------------------------------------------------------
; Func: Template function header
; Desc: Cut and paste this and fill in the info at the 
;		beginning of your functions
;-----------------------------------------------------------
	; set flag indicating not equal addresses between remote and robot
NOT_EQUAL:
	ldi		flag, 0b00000001
	rjmp	MAIN ; jump back to main because we are waiting for the second 8 bits for the action


;-----------------------------------------------------------
; Func: TRANSMIT_FREEZE_SIGNAL
; Desc: TRANSMIT_FREEZE_SIGNAL transmits the 0b01010101 freeze signal to other robots without
;        any address first
;-----------------------------------------------------------
TRANSMIT_FREEZE_SIGNAL:
	push	mpr
	cli
	; IMMEDIATELY transmit a standalone freeze signal
	; 0b01010101
	lds		mpr, UCSR1A
	sbrs	mpr, UDRE1 ; make sure data register is empty

	rjmp	TRANSMIT_FREEZE_SIGNAL

	; SEND FREEZE SIGNAL
	ldi		mpr, 0b01010101
	sts		UDR1, mpr
	
	rcall	Wait

	; Clear USART interrupts
	lds		mpr, UCSR1A
	ori		mpr, 0b11100000
	sts		UCSR1A, mpr

	; Enable interrupts globally
	sei

	pop		mpr
	
	ret

;-----------------------------------------------------------
; Func: Wait
; Desc: Wait subroutine provided by earlier labs
;-----------------------------------------------------------
; WAIT SUBROUTINE
Wait:
	push	waitcnt ; Save wait register
	push	ilcnt ; Save ilcnt register
	push	olcnt ; Save olcnt register

	Loop: ldi	olcnt, 224 ; load olcnt register
	OLoop: ldi	ilcnt, 237 ; load ilcnt register
	ILoop: dec	ilcnt ; decrement ilcnt
		brne	ILoop ; Continue Inner Loop
		dec		olcnt ; decrement olcnt
		brne	OLoop ; Continue Outer Loop
		dec		waitcnt ; Decrement wait
		brne	Loop ; Continue Wait loop

		pop		olcnt ; Restore olcnt register
		pop		ilcnt ; Restore ilcnt register
		pop		waitcnt ; Restore wait register
		ret ; Return from subroutine