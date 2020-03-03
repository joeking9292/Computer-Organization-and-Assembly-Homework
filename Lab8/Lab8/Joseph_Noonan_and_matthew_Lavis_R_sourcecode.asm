***********************************************************
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

.equ WskrR = 0 ; Right Whisker Input Bit
.equ WskrL = 1 ; Left Whisker Input Bit
.equ EngEnR = 4 ; Right Engine Enable Bit
.equ EngEnL = 7 ; Left Engine Enable Bit
.equ EngDirR = 5 ; Right Engine Direction Bit
.equ EngDirL = 6 ; Left Engine Direction Bit

.equ BotAddress = $1A ;(Enter your robot's address here (8 bits))

;/////////////////////////////////////////////////////////////
;These macros are the values to make the TekBot Move.
;/////////////////////////////////////////////////////////////
.equ MovFwd =  (1<<EngDirR|1<<EngDirL) ;0b01100000 Move Forward Action Code
.equ MovBck =  $00 ;0b00000000 Move Backward Action Code
.equ TurnR =   (1<<EngDirL) ;0b01000000 Turn Right Action Code
.equ TurnL =   (1<<EngDirR) ;0b00100000 Turn Left Action Code
.equ Halt =    (1<<EngEnR|1<<EngEnL) ;0b10010000 Halt Action Code

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
	rjmp leftWhisker
	reti
;- Right whisker
.org $0004
	rjmp rightWhisker
	reti
;- USART receive
.org $0040
	rjmp USART_Receive
	reti

.org $0046 ; End of Interrupt Vectors

;***********************************************************
;* Program Initialization
;***********************************************************
INIT:
	;Stack Pointer (VERY IMPORTANT!!!!)
	ldi mpr, low(RAMEND)
	out SPL, mpr ; Load SPL with low byte of RAMEND
	ldi mpr, high(RAMEND)
	out SPH, mpr ; Load SPH with high byte of RAMEND

	;I/O Ports
	ldi mpr, $FF
	out DDRB, mpr ; Set Port B Directional Register for output
	mov mpr, MovFwd
	out PORTB, mpr ; Activate pull-up resistors


	;USART1
	ldi mpr, 0b00000010
	out USART1A, mpr
	;Set baudrate at 2400bps
	ldi mpr, high(832)
	sts UBRR1H, mpr
	ldi mpr, low(832)
	out UBRR1L, mpr

	;Enable receiver and enable receive interrupts
	ldi mpr, 0b10001000
	out USART1B, mpr

	;Set frame format: 8 data bits, 2 stop bits
	ldi mpr, 0b00001111
	out USART1C
	;External Interrupts
	;Set the External Interrupt Mask
	ldi mpr, 0b00000111    ;(1<<INT0) | (1<<INT1) | (1<<INT2) | (1<<INT3)
	out EIMSK, mpr

	;Set the Interrupt Sense Control to falling edge detection
	di mpr, 0b10101010 ;(1<<ISC01) | (0<<ISC00) | (1<<ISC11) | (0<<ISC10) | (1<<ISC21) | (0<<ISC20) | (1<<ISC31) | (0<<ISC30)
	sts EICRA, mpr ; set INT0-3 to trigger on falling edge

	;Other
	ldi mpr, 0b00000000

	sei

;***********************************************************
;* Main Program
;***********************************************************
MAIN:
	;TODO: ???
	rjmp MAIN

;***********************************************************
;* Functions and Subroutines
;***********************************************************

USART_Receive:
	push mpr

	cli 

	in r17, UDR1
	mov r18, r17
	andi    r18, 0b10000000
	breq BOT_ADDRESS
	; we have an action
	; check flag, make sure bot address matches
	cpi mpr, 0b00000001
	breq MAIN ; GO BACK TO MAIN If the addresses arent equal
	; now we can perform action, action stored in r17



	out PORTB, r17

	ldi mpr, 0xFF
	out	EIFR, mpr

	;;
	;;
	;;
	pop mpr
	ret


BOT_ADDRESS:
	cpi r18, BotAddress
	brne NOT_EQUAL
	ldi mpr, 0b00000000

	ldi mpr, 0xFF
	out	EIFR, mpr


	rjmp MAIN

NOT_EQUAL:
	ldi mpr, 0b00000001

	ldi mpr, 0xFF
	out	EIFR, mpr

	rjmp MAIN





;***********************************************************
;* Stored Program Data
;***********************************************************

;***********************************************************
;* Additional Program Includes
;************************************