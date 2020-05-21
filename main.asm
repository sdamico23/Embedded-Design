
 ************************************************************************************
*
* Title:       Analog Signal Acquisition 
*
* Objective:   CSE472 Homework 10 program: Final Exam 
*              
*
*
*Revision:     V3.1
*
*Date:         April 21st, 2020
*
*Programmer:   Stephen DAmico
*
*Company:      The Pennsylvania State University
*              Department of Computer Engineering and Computer Science
*
*Algorithm:    save user input, check if it is valid, set the clock accordingly, use 
*              interrupt to increase time, check for calculation and evaluate 
*
*Register use: A,B: used to set the clock and calculate
*              X: buff to hold input, print onto screen 
*             
*             
*Memory use:   RAM Locations from $3000 for data.
*                            from #3100 for program
*
*Input:        user input (serial port)
*
*Output:       clock set or invalid input message on Serial port, calculation if valid expression
*
*Observations: This is a program that sets a clock based on user input or evaluates an expression   
*
*Note:         All Homework programs MUST have comments similar
*              to this homework 9 program. So, please use this 
*              comment format for all your subsequent CMPEN 472
*              Homework programs. 
*
*              Adding more explanations and comments help you and 
*              others to understand your program later. 
*
*Comments:     This program is developed and simulated using CodeWarrior
*              development software and targeted for Axion Manufacuturings
*              APS12C128 board (CSM-12C128 board running at 24MHz bus clock.)
*
*************************************************************************************
;*******************************************************
; export symbols
            XDEF        Entry        ; export 'Entry' symbol
            ABSENTRY    Entry        ; for assembly entry point
;Symbols and Macros
PORTB         EQU     $0001            ; initializo portb
DDRB          EQU     $0003

;following is for the TestTerm debugger simulation only
;SCISR1        EQU     $0203            ; Serial port (SCI) Status Register 1
;SCIDRL        EQU     $0204            ; Serial port (SCI) Data Register


CRGFLG      EQU         $0037        ; Clock and Reset Generator Flags
CRGINT      EQU         $0038        ; Clock and Reset Generator Interrupts
RTICTL      EQU         $003B        ; Real Time Interrupt Control

CR          equ         $0d          ; carriage return, ASCII 'Return' key
LF          equ         $0a          ; line feed, ASCII 'next line' character
; symbols/addresses
ATDCTL2     EQU  $0082            ; Analog-to-Digital Converter (ADC) registers
ATDCTL3     EQU  $0083
ATDCTL4     EQU  $0084
ATDCTL5     EQU  $0085
ATDSTAT0    EQU  $0086
ATDDR0H     EQU  $0090
ATDDR0L     EQU  $0091
ATDDR7H     EQU  $009e
ATDDR7L     EQU  $009f

SCIBDH      EQU  $00c8            ; Serial port (SCI) Baud Rate Register H
SCIBDL      EQU  $00C9            ; Serial port (SCI) Baud Register L
SCICR2      EQU  $00CB            ; Serial port (SCI) Control Register 2
SCISR1      EQU  $00cc            ; Serial port (SCI) Status Register 1
SCIDRL      EQU  $00cf            ; Serial port (SCI) Data Register




;*******************************************************
; interrupt vector section

;            ORG     $3FF0            ; Real Time Interrupt (RTI) interrupt vector setup
 ;           DC.W    rtiisr

;*******************************************************
; code section
            ORG     $3100
Entry
;            LDS     #Entry           ; initialize the stack pointer
            
;            ldx     #msg10           ;tell user the baud rate is changed 
;            jsr     printmsg
;            jsr     nextline
             
;            ldx     #$000D           ; Change the SCI port baud rate to 115.2K
;            stx     SCIBDH  
             
;wait        jsr     getchar          ; wait for enter key
;            cmpa    #$D
 ;           bne     wait
            
            
              end