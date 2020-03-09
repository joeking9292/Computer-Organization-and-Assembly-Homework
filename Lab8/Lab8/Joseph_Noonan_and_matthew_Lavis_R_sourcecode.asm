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
.def mpr = r16 ; Multi-Purpose Register
.def flag = r19

.def freezeCount = r20   ; track how many times robot has been frozen
.def currentCommand = r21 ; Holds the current command 
.def	waitcnt = r25
.def	ilcnt = r23				; Inner Loop Counter
.def	olcnt = r24				; Outer Loop Counter

.equ WskrR = 0 ; Right Whisker Input Bit
.equ WskrL = 1 ; Left Whisker Input Bit
.equ EngEnR = 4 ; Right Engine Enable Bit
.equ EngEnL = 7 ; Left Engine Enable Bit
.equ EngDirR = 5 ; Right Engine Direction Bit
.equ EngDirL = 6 ; Left Engine Direction Bit

.equ WTime = 100 ; Time to wait in wait loop

.equ BotAddress = $1A ;(Enter your robot's address here (8 bits))

;/////////////////////////////////////////////////////////////
;These macros are the values to make the TekBot Move.
;/////////////////////////////////////////////////////////////
.equ MovFwd =  (1<<EngDirR|1<<EngDirL) ;0b01100000 Move Forward Action Code
.equ MovBck =  $00 ;0b00000000 Move Backward Action Code
.equ TurnR =   (1<<EngDirL) ;0b01000000 Turn Right Action Code
.equ TurnL =   (1<<EngDirR) ;0b00100000 Turn Left Action Code
.equ Halt =    (1<<EngEnR|1<<EngEnL) ;0b10010000 Halt Action Code
.equ bit5 = 5

;***********************************************************
;* Start of Code Segment
;***********************************************************
.cseg ; Beginning of code segment

;***********************************************************
;* Interrupt Vectors
;***********************************************************
.org $0000 ; Beginning of IVs
	rjmp INIT ; Reset interrupt

;Should have Interrupt vectors for:
;- Left whisker
.org $0002
	rcall leftWhisker
	reti
;- Right whisker
.org $0004
	rcall rightWhisker
	reti
;- USART receive
.org $003C
	rcall USART_Receive
	reti

.org $0046 ; End of Interrupt Vectors

;***********************************************************
;* Program Initialization
;***********************************************************
INIT:
	;Stack Pointer (VERY IMPORTANT!!!!)
	ldi mpr, high(RAMEND)
	out SPH, mpr ; Load SPH with high byte of RAMEND
	ldi mpr, low(RAMEND)
	out SPL, mpr ; Load SPL with low byte of RAMEND
	

	;I/O Ports
	ldi mpr, $FF
	out DDRB, mpr ; Set Port B Directional Register for output
	ldi mpr, $00
	out PORTB, mpr ; Activate pull-up resistors

	ldi mpr, 0b00000100
	out DDRD, mpr ; Set Port B Directional Register for output
	ldi mpr, 0b11110011
	out PORTD, mpr ; Activate pull-up resistors


	;USART1
	ldi mpr, $02
	sts UCSR1A, mpr

	;Enable reciever
	ldi mpr, (1<<RXCIE1) | (1<<RXEN1)
	sts UCSR1B, mpr

	;Set frame format: 8 data bits, 2 stop bits
	ldi mpr, (1<<UCSZ11) | (1<<UCSZ10) | (1<<USBS1) | (1<<UMSEL1)
	sts UCSR1C, mpr

	;Set baudrate at 2400bps
	ldi mpr, $03
	sts UBRR1H, mpr
	ldi mpr, $40
	sts UBRR1L, mpr

	;Set the External Interrupt Mask
	ldi mpr, 0b00000011
	out EIMSK, mpr

	;External Interrupts
	;Set the Interrupt Sense Control to falling edge detection
	ldi mpr, 0b10101010
	sts EICRA, mpr

	ldi freezeCount, 0b00000000
	ldi currentCommand, 0b00000000
	ldi flag, 0b00000000
	ldi waitcnt, WTime

	ldi mpr, MovFwd
	out PORTB, mpr

	sei

;***********************************************************
;* Main Program
;***********************************************************
MAIN:
	rjmp MAIN

;***********************************************************
;* Functions and Subroutines
;***********************************************************

leftWhisker:
	; Save variable by pushing them to the stack
	push	mpr			; Save mpr
	in		mpr, SREG
	push	mpr			; Save the status register

	cli

	; Move Backwards for a second
	ldi mpr, MovBck ; Load Move Backward command
	out PORTB, mpr ; Send command to port
	ldi waitcnt, WTime ; Wait for 1 second
	rcall Wait ; Call wait function

	; Turn right for a second
	ldi mpr, TurnR ; Load Turn Left Command
	out PORTB, mpr ; Send command to port
	ldi waitcnt, WTime ; Wait for 1 second
	rcall Wait ; Call wait function

	ldi mpr, MovFwd
	out PORTB, mpr

	ldi mpr, 0xFF ; clear interrupt register to prevent stacked interrupts
	out EIFR, mpr

	; Restore variable by popping them from the stack in reverse order
	pop		mpr
	out		SREG, mpr	; Restore status register
	pop		mpr			; Restore mpr

	ret

rightWhisker:
	; Save variable by pushing them to the stack
	push	mpr			; Save mpr
	in		mpr, SREG
	push	mpr			; Save the status register

	cli

	; Move Backwards for a second
	ldi mpr, MovBck ; Load Move Backward command
	out PORTB, mpr ; Send command to port
	ldi waitcnt, WTime ; Wait for 1 second
	rcall Wait ; Call wait function

	; Turn left for a second
	ldi mpr, TurnL ; Load Turn Left Command
	out PORTB, mpr ; Send command to port
	ldi waitcnt, WTime ; Wait for 1 second
	rcall Wait

	ldi mpr, MovFwd
	out PORTB, mpr

	ldi mpr, 0xFF ; clear interrupt register to prevent stacked interrupts
	out EIFR, mpr

	; Restore variable by popping them from the stack in reverse order
	pop		mpr
	out		SREG, mpr	; Restore status register
	pop		mpr			; Restore mpr

	ret


USART_Receive:
	push mpr

	lds r17, UDR1

	cpi r17, 0b01010101 ; see if its a freeze signal from another robot first (comes w/out address)
	breq HANDLE_FREEZE_SIGNAL

	mov r18, r17
	andi    r18, 0b10000000

	breq BOT_ADDRESS ; handle bot address, make sure same

	; we have an action from a transmitter at this point, need to make sure they are the same
	; check flag, make sure bot address matches

	cpi flag, 0b00000001
	breq MAIN ; GO BACK TO MAIN If the addresses arent equal

	; now we can perform action, action stored in r17

	; CHECK IF ITS THE FREEZE CMD
	cpi r17, 0b11111000
	breq TRANSMIT_FREEZE_SIGNAL


	out PORTB, r17 ; output action to led lights

	ldi mpr, 0xFF
	out EIFR, mpr

	pop mpr
	ret


; make sure botaddresses are the same, if not set flag in not equal
BOT_ADDRESS:
	cpi r17, BotAddress
	brne NOT_EQUAL
	ldi flag, 0b00000000

	ldi mpr, 0xFF
	out EIFR, mpr


	rjmp MAIN

	; set flag indicating not equal addresses between remote and robot
NOT_EQUAL:
	ldi flag, 0b00000001

	ldi mpr, 0xFF
	out EIFR, mpr

	rjmp MAIN ; jump back to main because we are waiting for the second 8 bits for the action





	; TRANSMIT_FREEZE_SIGNAL transmits the 0b01010101 freeze signal to other robots without
	; any address first
TRANSMIT_FREEZE_SIGNAL:
	push mpr
	cli
	; IMMEDIATELY transmit a standalone freeze signal
	; 0b01010101
	lds mpr, UCSR1A
	sbrs mpr, UDRE1 ; make sure data register is empty

	rjmp TRANSMIT_FREEZE_SIGNAL

	; SEND FREEZE SIGNAL
	ldi mpr, 0b01010101
	sts UDR1, mpr
	
	rcall	Wait

	; Clear USART interrupts
	lds		mpr, UCSR1A
	ori		mpr, 0b11100000
	sts		UCSR1A, mpr

	; Enable interrupts globally
	sei

	pop mpr
	
	ret



; HANDLE_FREEZE_SIGNAL handles when we receive a freeze signal from another robot!
HANDLE_FREEZE_SIGNAL:

	cpi freezeCount, 3
	breq HANDLE_FREEZE_SIGNAL

	push mpr

	ldi mpr, Halt
	out PORTB, mpr

	cli

	; wait for 5 seconds
	rcall Wait
	rcall Wait
	rcall Wait
	rcall Wait
	rcall Wait

	; dont respond to whiskers
	ldi mpr, 0xFF
	out EIFR, mpr

	; Clear USART interrupts
	lds		mpr, UCSR1A
	ori		mpr, 0b11100000
	sts		UCSR1A, mpr		


	; after being frozen 3 times, robot should stop working until its reset

	inc freezeCount
	cpi freezeCount, 3
	breq HANDLE_FREEZE_SIGNAL

	out PORTB, currentCommand

	sei

	pop mpr
	ret

; WAIT SUBROUTINE
Wait:
	push waitcnt ; Save wait register
	push ilcnt ; Save ilcnt register
	push olcnt ; Save olcnt register

	Loop: ldi olcnt, 224 ; load olcnt register
	OLoop: ldi ilcnt, 237 ; load ilcnt register
	ILoop: dec ilcnt ; decrement ilcnt
		brne ILoop ; Continue Inner Loop
		dec olcnt ; decrement olcnt
		brne OLoop ; Continue Outer Loop
		dec waitcnt ; Decrement wait
		brne Loop ; Continue Wait loop

		pop olcnt ; Restore olcnt register
		pop ilcnt ; Restore ilcnt register
		pop waitcnt ; Restore wait register
		ret ; Return from subroutine