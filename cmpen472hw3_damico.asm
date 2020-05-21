************************************************************************************
*
* Title:       LED Light Dimming
*
* Objective:   CSE472 Homework 3 program 
*              
*
*
*Revision:     V3.1
*
*Date:         Jan. 27, 2020
*
*Programmer:   Stephen DAmico
*
*Company:      The Pennsylvania State University
*              Department of Computer Engineering and Computer Science
*
*Algorithm:    Simple parallel I/O in a nested delay-loop
*
*Register use: A: Light on/off state and Switch SW1 on/off state 
*              X,Y: Delay Loop Counters
*             
*             
*Memory use:   RAM Locations from $3000 for data.
*                            from #3100 for program
*
*Input:        Parameters hard coded in the program
*              Switch SW1 at PORTP bit 0
*
*Output:       LED 1,2,3,4 at PORTB bit 4,5,6,7
*
*Observations: This is a program that dims LEDs and the dimming value can change 
*              by changing the ratio of off to on. 
*
*Note:         All Homework programs MUST have comments similar
*              to this homework 3 program. So, please use this 
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
*Parameter Declaration Section
*
*Export Symbols
           XDEF         pgstart          ; export 'pgstart' symbol
           ABSENTRY     pgstart          ; for assembly entry point
*                                       ; This is first instruction of the program 
*                                       ;  up on the start of simulation

* Symbols and Macros 
PORTA      EQU          $0000            ;i/o port addresses (port A not used)
DDRA       EQU          $0002   
 
PORTB      EQU          $0001            ; Port B is connected with LEDS
DDRB       EQU          $0003      
PUCR       EQU          $000C            ; to enable pull-up mode for PORT A, B, E, K

PTP        EQU          $0258            ; PORTP data register, used for Push Switch
PTIP       EQU          $0259            ; PORTP input register <<==============
DDRP       EQU          $025A            ; PORTP data direction register
PERP       EQU          $025C            ; PORTP pull up/down enable
PPSP       EQU          $025D            ; PORTP pull up/down selection
***************************************************************************************
*Data Section
*
           ORG          $3000            ; reserved RAM memory starting address
                                         ; Memory $3000 to $30FF are for Data
OFF        Ds          $5D               ;initial on counter
ONN        Ds          $7                ;initial off counter

StackSpace                               ;remaining memory space for stack data
                                         ; initial stack pointer position set
                                         ; to $3100 (pgstart)
                              
*
**************************************************************************************
* Program  Section
*
           
           ORG          $3100            ; Program start address, in RAM
pgstart    LDS          #pgstart         ; initialize the stack pointer

           LDAA         #%11110000       ; set PORTB bit 7,6,5,4 as output, 3,2,1,0   as input
           STAA         DDRB             ; LED 1,2,3,4 on PORTB bit 4,5,6,7
                                         ; DIP switch 1,2,3,4 on PORTB bit 4,5,6,7
           BSET         PUCR,%00000010   ; enable PORTB pull up/down feature for the 
                                         ; DIP switch 1,2,3,4 on the bits 0,1,2,3,4
           BCLR         DDRP,%00000011   ; Push Button Switch 1 and 2 at PORTP bit 0 and 1 
                                         ; set PORTP bit 0 and 1 as input
           BSET         PERP,%00000011   ; enable the pull up/down feature at PORTP bit 0 and 1
           BCLR         PPSP,%00000011   ; select pull up feature at PORTP bit 0 and 1 for the 
 
           LDAA         #%00110000       ; Turn on LED 3 and 4.
           STAA         PORTB            ; 

           
mainLoop   
           LDAA         PTIP             ; read push button SW1 at PORTB7
           ANDA         #%00000001       ; check the bit 0 only
           BEQ          sw1pushed
           
           
           LDAA         #$7               ;Load 7 to a
           STAA         ONN               ; store a to Onn counter
           LDAA         #$5D              ;load 93 to a
           STAA         OFF               ; store a to OFF counter
           BRA          start             ; branch to the initial state    
          
sw1pushed  LDAA         #$E              ; Load 14 to a
           STAA         ONN              ; store a to ONN counter
           LDAA         #$56             ; Load 86 to a
           STAA         OFF              ;store a to OFF counter

           
start      BCLR         PORTB,%00010000  ; turn LED1 on
           LDAA         ONN              ; load the ONN value to a
           
onLoop     jsr          delay10us        ; wait 10 us
           DECA                          ; decrease a by 1
           BNE          onLoop           ; loop if a is not equal to 0
           BSET         PORTB,%00010000   ; turn off led 1 
           LDAA         OFF              ; load off value to a 
offLoop    jsr          delay10us        ; wait 10 us
           DECA                          ; decrease a by 1
           BNE          offLoop          ; loop if a not equal to 1
           BRA          mainLoop         ; go back to main loop

********************************************************************************
* Subroutine Section

;***********************************************************************
; delay1us subroutine 
;
; This subroutine cause a few usec. delay
;
; Input:  a 16bit count number in 'Counter1'
; Output: time delay, cpu cycle wasted
; Registers in use: X register, as counter
; Memory locations in use: a 16bit input number in 'Counter1'
;
; Comments: one can ass more NOP instructions to lengthen 
;           the delay time. 
            
delay10us 
            PSHA
          
            LDAA          $002f              ; load a 
dly10usLoop                                 ; NOP= delay 1 clock cycle
            SUBA          #01                 ; Decrease a by 1
            BNE          dly10usLoop           ;loop to get 1 uS

            PULA
            RTS
      
*  
*Add any more subroutines here
*

           end                           ;last line of a file           