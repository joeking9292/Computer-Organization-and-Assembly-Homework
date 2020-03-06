;***********************************************************
;*
;* Joseph_Noonan_and_Matthew_Levis_Lab8_sourcecode.asm
;*
;* Enter the description of the program here
;*
;* This is the TRANSMIT skeleton file for Lab 8 of ECE 375
;*
;***********************************************************
;*
;* Enter Name of file here
;*
;* Enter the description of the program here
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
.def mpr = r16 ; Multi-Purpose Register
.def action = r17

.equ EngEnR = 4 ; Right Engine Enable Bit
.equ EngEnL = 7 ; Left Engine Enable Bit
.equ EngDirR = 5 ; Right Engine Direction Bit
.equ EngDirL = 6 ; Left Engine Direction Bit
; Use these action codes between the remote and robot
; MSB = 1 thus:
; control signals are shifted right by one and ORed with 0b10000000 = $80
.equ MovFwd =  ($80|1<<(EngDirR-1)|1<<(EngDirL-1)) ;0b10110000 Move Forward Action Code
.equ MovBck =  ($80|$00) ;0b10000000 Move Backward Action Code
.equ TurnR =   ($80|1<<(EngDirL-1)) ;0b10100000 Turn Right Action Code
.equ TurnL =   ($80|1<<(EngDirR-1)) ;0b10010000 Turn Left Action Code
.equ Halt =    ($80|1<<(EngEnR-1)|1<<(EngEnL-1)) ;0b11001000 Halt Action Code
.equ freezecmd = 0b11111000

; FREEZE IS 0b11111000
.equ bit5 = 5

.equ BotID = $1A   ; in binary, this is 0b00011010

;***********************************************************
;* Start of Code Segment
;***********************************************************
.cseg ; Beginning of code segment

;***********************************************************
;* Interrupt Vectors
;***********************************************************
.org $0000 ; Beginning of IVs
rjmp INIT ; Reset interrupt

.org $0046 ; End of Interrupt Vectors

;***********************************************************
;* Program Initialization
;***********************************************************
INIT:
;Stack Pointer (VERY IMPORTANT!!!!)
; Initialize Stack Pointer
ldi mpr, low(RAMEND)
out SPL, mpr ; Load SPL with low byte of RAMEND
ldi mpr, high(RAMEND)
out SPH, mpr ; Load SPH with high byte of RAMEND

;I/O Ports (PORTD & USART)
ldi mpr, $00
out DDRD, mpr ; Set Port D Directional Register for input
ldi mpr, $FF
out PORTD, mpr ; Activate pull-up resistors


;USART1
ldi mpr, 0b00000010
sts UCSR1A, mpr

;Enable transmitter
ldi mpr, 0b00001000
sts UCSR1B, mpr

;Set frame format: 8 data bits, 2 stop bits
ldi mpr, 0b00001110
sts UCSR1C, mpr

;Set baudrate at 2400bps
ldi mpr, high(832)
sts UBRR1H, mpr
ldi mpr, low(832)
sts UBRR1L, mpr


sei


; USARTA: 0b00000010
; USARTB: 0b00000000
; USARTC: 0b00001111





;Other

;***********************************************************
;* Main Program
;***********************************************************
MAIN:
;TODO: ???
; continuously poll for buttons pressed corresponding to a given action
; set action register with action

in mpr, PIND

cpi mpr, 0b00000001; some pin specified action
breq FORWARD

cpi mpr, 0b00000010 ;some pin specified action
breq BACKWARD

cpi mpr, 0b00000100 ;some pin specified action
breq LEFT

cpi mpr, 0b00001000 ;some pin specified action
breq RIGHT

cpi mpr, 0b00010000 ;some pin specified action
breq HALT_Routine

rjmp END

FORWARD:
ldi action, MovFwd
rjmp END
BACKWARD:
ldi action, MovBck
rjmp END
LEFT:
ldi action, TurnL
rjmp END
RIGHT:
ldi action, TurnR
rjmp END
HALT_Routine:
ldi action, Halt
rjmp END
FREEZE:
ldi action, freezecmd
rjmp END
END:
rcall USART_BotID_Transmit
;rcall USART_Action_Transmit
rjmp MAIN

;***********************************************************
;* Functions and Subroutines
;***********************************************************
USART_BotID_Transmit:
lds mpr, UCSR1A
sbrs mpr, UDRE1

;sbis UCSR1A, UDRE1
rjmp USART_BotID_Transmit

; send BotID first
ldi mpr, BotID
sts UDR1, mpr
;ret

USART_Action_Transmit:

lds mpr, UCSR1A
sbrs mpr, UDRE1
;sbis UCSR1A, UDRE1
rjmp USART_Action_Transmit

; read in action specified

sts UDR1, action
;ret

USART_Transmit_Wait_to_Finish:
	lds	mpr, UCSR1A
	sbrs	mpr, TXC1
	rjmp	USART_Transmit_Wait_to_Finish

	lds	mpr, UCSR1A
	cbr	mpr, TXC1
	sts	UCSR1A, mpr

	ret






;***********************************************************
;* Stored Program Data
;***********************************************************

;***********************************************************
;* Additional Program Includes
;*******************************************