;***********************************************************
;*
;* Joseph_Noonan_and_Matthew_Levis_Lab8_Tx_sourcecode.asm
;*
;* Code for the Transmitter for Lab 8
;*
;* This is the TRANSMIT skeleton file for Lab 8 of ECE 375
;*
;***********************************************************
;*
;* Author: Matthew Levis and Joseph Noonan
;* Date: 2/27/2020
;*
;***********************************************************

.include "m128def.inc" ; Include definition file

;***********************************************************
;* Internal Register Definitions and Constants
;***********************************************************
.def	mpr = r16 ; Multi-Purpose Register
.def	action = r17
.def	flag = r19

.equ	EngEnR = 4 ; Right Engine Enable Bit
.equ	EngEnL = 7 ; Left Engine Enable Bit
.equ	EngDirR = 5 ; Right Engine Direction Bit
.equ	EngDirL = 6 ; Left Engine Direction Bit
; Use these action codes between the remote and robot
; MSB = 1 thus:
; control signals are shifted right by one and ORed with 0b10000000 = $80
.equ	MovFwd =  ($80|1<<(EngDirR-1)|1<<(EngDirL-1)) ;0b10110000 Move Forward Action Code
.equ	MovBck =  ($80|$00) ;0b10000000 Move Backward Action Code
.equ	TurnR =   ($80|1<<(EngDirL-1)) ;0b10100000 Turn Right Action Code
.equ	TurnL =   ($80|1<<(EngDirR-1)) ;0b10010000 Turn Left Action Code
.equ	Halt =    ($80|1<<(EngEnR-1)|1<<(EngEnL-1)) ;0b11001000 Halt Action Code
.equ	freezecmd = 0b11111000

; FREEZE IS 0b11111000
.equ	bit5 = 5

.equ	BotID = $1A  ; in binary, this is 0b00011010

;***********************************************************
;* Start of Code Segment
;***********************************************************
.cseg ; Beginning of code segment

;***********************************************************
;* Interrupt Vectors
;***********************************************************
.org $0000 ; Beginning of IVs
	rjmp	INIT ; Reset interrupt

.org $0046 ; End of Interrupt Vectors

;***********************************************************
;* Program Initialization
;***********************************************************
INIT:
	;Stack Pointer (VERY IMPORTANT!!!!)
	; Initialize Stack Pointer
	ldi		mpr, low(RAMEND)
	out		SPL, mpr ; Load SPL with low byte of RAMEND
	ldi		mpr, high(RAMEND)
	out		SPH, mpr ; Load SPH with high byte of RAMEND

	;I/O Ports (PORTD & USART)
	ldi		mpr, $00
	out		DDRD, mpr ; Set Port D Directional Register for input
	ldi		mpr, $FF
	out		PORTD, mpr ; Activate pull-up resistors

	;I/O Ports (PORTD & USART)
	ldi		mpr, $00
	out		DDRB, mpr ; Set Port D Directional Register for input
	ldi		mpr, $FF
	out		PORTB, mpr ; Activate pull-up resistors
	
;USART1
	ldi mpr, (1<<PE1)
	out DDRE, mpr

	ldi		mpr, (1<<U2X1)
	sts		UCSR1A, mpr

	;Set baudrate at 2400bps
	lds		mpr, UBRR1H      ;Save reserved bits
	ori		mpr, high(832)
    sts		UBRR1H, mpr
    ldi		mpr, low(832)
    sts		UBRR1L, mpr

	;Enable transmitter
	ldi		mpr, (1<<TXEN1)
	sts		UCSR1B, mpr

	;Set frame format: 8 data bits, 2 stop bits
	ldi		mpr,  (0<<UMSEL1 | 1<<USBS1 | 1<<UCSZ11 | 1<<UCSZ10)
	sts		UCSR1C, mpr

	clr		mpr

;Other

;***********************************************************
;* Main Program
;***********************************************************
MAIN:
	; continuously poll for buttons pressed corresponding to a given action
	; set action register with action

	sbis PIND, 7; some pin specified action
	rjmp FORWARD

	sbis PIND, 6 ;some pin specified action
	rjmp BACKWARD

	sbis PIND, 1 ;some pin specified action
	rjmp LEFT

	sbis PIND, 0 ;some pin specified action
	rjmp RIGHT

	sbis PIND, 5 ;some pin specified action
	rjmp HALT_Routine

	sbis PIND, 4
	rjmp FREEZE

	rjmp END

;***********************************************************
;*	Functions and Subroutines
;***********************************************************
FORWARD:
	ldi		action, MovFwd
	rjmp	END
BACKWARD:
	ldi		action, MovBck
	rjmp	END
LEFT:
	ldi action, TurnL
	rjmp	END
RIGHT:
	ldi		action, TurnR
	rjmp	END
HALT_Routine:
	ldi		action, Halt
	rjmp	END
FREEZE:
	ldi		action, freezecmd
	rjmp	END
END:
	rcall	USART_BotID_Transmit
	rcall	USART_Action_Transmit
	rjmp	MAIN

;***********************************************************
;* Name: USART_BOTID_TRANSMIT & USART_ACTION_TRANSMIT
;  Description: Code for transmitting the ID and action code to the robot
;***********************************************************
USART_BotID_Transmit:
	lds		mpr, UCSR1A
	sbrs	mpr, UDRE1
	rjmp	USART_BotID_Transmit

	; send BotID first
	ldi		mpr, BotID
	sts		UDR1, mpr

USART_Action_Transmit:

	lds		mpr, UCSR1A
	sbrs	mpr, UDRE1
	rjmp	USART_Action_Transmit

	; read in action specified

	sts		UDR1, action

	clr		action
	ret


USART_Transmit_Wait_to_Finish:
	lds		mpr, UCSR1A
	sbrs	mpr, TXC1
	rjmp	USART_Transmit_Wait_to_Finish
	ret